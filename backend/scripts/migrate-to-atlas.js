const mongoose = require('mongoose');
const { MongoClient } = require('mongodb');
require('dotenv').config();

/**
 * Migration Script: Local MongoDB to MongoDB Atlas
 * Safely migrates data from local database to Atlas with validation
 */

class AtlasMigrator {
  constructor() {
    this.localClient = null;
    this.atlasClient = null;
    this.localDb = null;
    this.atlasDb = null;
  }

  async connectLocal() {
    try {
      // Connect to local MongoDB (default localhost:27017)
      const localUri = process.env.MONGODB_LOCAL_URI || 'mongodb://localhost:27017/indulink';
      this.localClient = new MongoClient(localUri);
      await this.localClient.connect();
      this.localDb = this.localClient.db();
      console.log('✅ Connected to local MongoDB');
      return true;
    } catch (error) {
      console.error('❌ Failed to connect to local MongoDB:', error.message);
      return false;
    }
  }

  async connectAtlas() {
    try {
      // Connect to MongoDB Atlas
      this.atlasClient = new MongoClient(process.env.MONGODB_URI);
      await this.atlasClient.connect();
      this.atlasDb = this.atlasClient.db();
      console.log('✅ Connected to MongoDB Atlas');
      return true;
    } catch (error) {
      console.error('❌ Failed to connect to MongoDB Atlas:', error.message);
      return false;
    }
  }

  async getCollections() {
    try {
      const collections = await this.localDb.listCollections().toArray();
      return collections.map(col => col.name).filter(name => !name.startsWith('system.'));
    } catch (error) {
      console.error('❌ Failed to get collections:', error.message);
      return [];
    }
  }

  async getDocumentCount(collectionName) {
    try {
      const localCount = await this.localDb.collection(collectionName).countDocuments();
      const atlasCount = await this.atlasDb.collection(collectionName).countDocuments();
      return { local: localCount, atlas: atlasCount };
    } catch (error) {
      console.error(`❌ Failed to count documents in ${collectionName}:`, error.message);
      return { local: 0, atlas: 0 };
    }
  }

  async validateCollection(collectionName) {
    console.log(`🔍 Validating collection: ${collectionName}`);

    const counts = await this.getDocumentCount(collectionName);
    console.log(`   Local: ${counts.local} documents`);
    console.log(`   Atlas: ${counts.atlas} documents`);

    if (counts.atlas > 0) {
      console.log(`⚠️  Collection ${collectionName} already has data in Atlas`);

      const overwrite = process.argv.includes('--overwrite');
      if (!overwrite) {
        console.log(`   Skipping ${collectionName}. Use --overwrite to replace existing data.`);
        return false;
      } else {
        console.log(`   Overwriting existing data in ${collectionName} (--overwrite flag used)`);
      }
    }

    return true;
  }

  async migrateCollection(collectionName, batchSize = 1000) {
    console.log(`🚀 Migrating collection: ${collectionName}`);

    try {
      const collection = this.localDb.collection(collectionName);
      const totalDocs = await collection.countDocuments();

      if (totalDocs === 0) {
        console.log(`   No documents to migrate in ${collectionName}`);
        return { success: true, migrated: 0 };
      }

      // Clear existing data in Atlas if overwrite is enabled
      if (process.argv.includes('--overwrite')) {
        await this.atlasDb.collection(collectionName).deleteMany({});
        console.log(`   Cleared existing data in Atlas collection ${collectionName}`);
      }

      let migrated = 0;
      let cursor = collection.find({}).batchSize(batchSize);

      while (await cursor.hasNext()) {
        const batch = [];
        for (let i = 0; i < batchSize && await cursor.hasNext(); i++) {
          const doc = await cursor.next();
          // Remove MongoDB internal fields
          delete doc._id;
          batch.push(doc);
        }

        if (batch.length > 0) {
          try {
            const result = await this.atlasDb.collection(collectionName).insertMany(batch, {
              ordered: false // Continue on duplicate key errors
            });
            migrated += result.insertedCount;
            console.log(`   Migrated ${migrated}/${totalDocs} documents...`);
          } catch (error) {
            if (error.code === 11000) {
              console.log(`   Skipping duplicate documents in ${collectionName}`);
            } else {
              console.error(`❌ Error inserting batch in ${collectionName}:`, error.message);
            }
          }
        }
      }

      console.log(`✅ Successfully migrated ${migrated} documents to ${collectionName}`);
      return { success: true, migrated };

    } catch (error) {
      console.error(`❌ Failed to migrate collection ${collectionName}:`, error.message);
      return { success: false, migrated: 0, error: error.message };
    }
  }

  async migrateIndexes(collectionName) {
    try {
      console.log(`📊 Migrating indexes for: ${collectionName}`);

      const localIndexes = await this.localDb.collection(collectionName).indexes();
      const atlasIndexes = await this.atlasDb.collection(collectionName).indexes();

      // Get existing index names in Atlas
      const existingIndexNames = atlasIndexes.map(idx => idx.name);

      for (const index of localIndexes) {
        // Skip default _id index
        if (index.name === '_id_') continue;

        if (existingIndexNames.includes(index.name)) {
          console.log(`   Index ${index.name} already exists in Atlas`);
          continue;
        }

        try {
          await this.atlasDb.collection(collectionName).createIndex(index.key, {
            name: index.name,
            unique: index.unique || false,
            sparse: index.sparse || false,
            background: true // Create in background to avoid blocking
          });
          console.log(`   ✅ Created index: ${index.name}`);
        } catch (error) {
          if (error.code === 85) {
            console.log(`   Index ${index.name} already exists`);
          } else {
            console.error(`   ❌ Failed to create index ${index.name}:`, error.message);
          }
        }
      }
    } catch (error) {
      console.error(`❌ Failed to migrate indexes for ${collectionName}:`, error.message);
    }
  }

  async validateMigration(collectionName) {
    console.log(`✅ Validating migration for: ${collectionName}`);

    const counts = await this.getDocumentCount(collectionName);

    if (counts.local === counts.atlas) {
      console.log(`   ✅ Validation passed: ${counts.atlas} documents`);
      return true;
    } else {
      console.log(`   ⚠️  Validation warning: Local(${counts.local}) != Atlas(${counts.atlas})`);
      return false;
    }
  }

  async runMigration() {
    console.log('🚀 Starting Migration from Local MongoDB to MongoDB Atlas\n');

    // Connect to both databases
    const localConnected = await this.connectLocal();
    const atlasConnected = await this.connectAtlas();

    if (!localConnected || !atlasConnected) {
      console.error('❌ Cannot proceed without both database connections');
      return;
    }

    try {
      // Get all collections to migrate
      const collections = await this.getCollections();
      console.log(`📋 Found ${collections.length} collections to migrate:`);
      collections.forEach(col => console.log(`   - ${col}`));
      console.log('');

      const results = {
        totalCollections: collections.length,
        successfulMigrations: 0,
        failedMigrations: 0,
        totalDocumentsMigrated: 0
      };

      // Migrate each collection
      for (const collection of collections) {
        console.log(`\n${'='.repeat(50)}`);
        console.log(`Processing collection: ${collection}`);
        console.log(`${'='.repeat(50)}\n`);

        // Validate before migration
        const shouldMigrate = await this.validateCollection(collection);
        if (!shouldMigrate) {
          console.log(`⏭️  Skipping collection: ${collection}\n`);
          continue;
        }

        // Perform migration
        const migrationResult = await this.migrateCollection(collection);

        if (migrationResult.success) {
          results.successfulMigrations++;
          results.totalDocumentsMigrated += migrationResult.migrated;

          // Migrate indexes
          await this.migrateIndexes(collection);

          // Validate migration
          await this.validateMigration(collection);

        } else {
          results.failedMigrations++;
          console.log(`❌ Migration failed for ${collection}: ${migrationResult.error}`);
        }

        console.log('');
      }

      // Print summary
      console.log(`${'='.repeat(60)}`);
      console.log('📊 MIGRATION SUMMARY');
      console.log(`${'='.repeat(60)}`);
      console.log(`Total Collections: ${results.totalCollections}`);
      console.log(`Successful Migrations: ${results.successfulMigrations}`);
      console.log(`Failed Migrations: ${results.failedMigrations}`);
      console.log(`Total Documents Migrated: ${results.totalDocumentsMigrated}`);
      console.log(`${'='.repeat(60)}`);

      if (results.failedMigrations === 0) {
        console.log('🎉 Migration completed successfully!');
      } else {
        console.log('⚠️  Migration completed with some failures. Please review the logs above.');
      }

    } catch (error) {
      console.error('❌ Migration process failed:', error);
    } finally {
      // Close connections
      if (this.localClient) await this.localClient.close();
      if (this.atlasClient) await this.atlasClient.close();
      console.log('✅ Database connections closed');
    }
  }

  async dryRun() {
    console.log('🔍 Performing dry run (no data will be migrated)\n');

    const localConnected = await this.connectLocal();
    const atlasConnected = await this.connectAtlas();

    if (!localConnected || !atlasConnected) {
      return;
    }

    try {
      const collections = await this.getCollections();
      console.log(`📋 Collections that would be migrated:`);

      for (const collection of collections) {
        const counts = await this.getDocumentCount(collection);
        console.log(`   ${collection}: ${counts.local} documents (Atlas has ${counts.atlas})`);
      }

      console.log('\n💡 To perform actual migration, run without --dry-run flag');
      console.log('💡 To overwrite existing Atlas data, add --overwrite flag');

    } catch (error) {
      console.error('❌ Dry run failed:', error);
    } finally {
      if (this.localClient) await this.localClient.close();
      if (this.atlasClient) await this.atlasClient.close();
    }
  }
}

// CLI Interface
async function main() {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
MongoDB Atlas Migration Tool

Usage:
  node migrate-to-atlas.js [options]

Options:
  --dry-run          Show what would be migrated without making changes
  --overwrite        Overwrite existing data in Atlas (use with caution)
  --help, -h         Show this help message

Environment Variables:
  MONGODB_LOCAL_URI  Local MongoDB connection string (default: mongodb://localhost:27017/indulink)
  MONGODB_URI        MongoDB Atlas connection string (required)

Examples:
  node migrate-to-atlas.js --dry-run
  node migrate-to-atlas.js --overwrite
  MONGODB_LOCAL_URI=mongodb://localhost:27017/myapp node migrate-to-atlas.js
`);
    return;
  }

  const migrator = new AtlasMigrator();

  if (args.includes('--dry-run')) {
    await migrator.dryRun();
  } else {
    await migrator.runMigration();
  }
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = AtlasMigrator;