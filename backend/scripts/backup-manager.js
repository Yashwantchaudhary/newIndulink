const mongoose = require('mongoose');
const { MongoClient } = require('mongodb');
const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

require('dotenv').config();

/**
 * Backup and Recovery Manager for MongoDB Atlas
 * Handles automated backups, point-in-time recovery, and disaster recovery
 */

class BackupManager {
  constructor() {
    this.client = null;
    this.db = null;
    this.backupDir = path.join(process.cwd(), 'backups');
  }

  async connect() {
    try {
      this.client = new MongoClient(process.env.MONGODB_URI);
      await this.client.connect();
      this.db = this.client.db();
      console.log('✅ Connected to MongoDB Atlas for backup operations');
      return true;
    } catch (error) {
      console.error('❌ Failed to connect to MongoDB Atlas:', error.message);
      return false;
    }
  }

  async ensureBackupDirectory() {
    try {
      await fs.mkdir(this.backupDir, { recursive: true });
      console.log(`📁 Backup directory ready: ${this.backupDir}`);
    } catch (error) {
      console.error('❌ Failed to create backup directory:', error.message);
    }
  }

  async createBackup(backupName = null) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupFileName = backupName || `backup-${timestamp}`;
    const backupPath = path.join(this.backupDir, backupFileName);

    console.log(`💾 Creating backup: ${backupFileName}`);

    try {
      // Create backup directory
      await fs.mkdir(backupPath, { recursive: true });

      // Get all collections
      const collections = await this.db.listCollections().toArray();
      const userCollections = collections.filter(col => !col.name.startsWith('system.'));

      console.log(`📋 Backing up ${userCollections.length} collections...`);

      const backupMetadata = {
        timestamp: new Date().toISOString(),
        database: this.db.databaseName,
        collections: [],
        totalDocuments: 0,
        backupSize: 0
      };

      // Backup each collection
      for (const collection of userCollections) {
        const collectionName = collection.name;
        console.log(`   📄 Backing up collection: ${collectionName}`);

        try {
          const coll = this.db.collection(collectionName);
          const documents = await coll.find({}).toArray();
          const indexes = await coll.indexes();

          // Save collection data
          const collectionData = {
            name: collectionName,
            documents: documents,
            indexes: indexes,
            documentCount: documents.length
          };

          const collectionFile = path.join(backupPath, `${collectionName}.json`);
          await fs.writeFile(collectionFile, JSON.stringify(collectionData, null, 2));

          backupMetadata.collections.push({
            name: collectionName,
            documentCount: documents.length,
            fileSize: Buffer.byteLength(JSON.stringify(collectionData))
          });

          backupMetadata.totalDocuments += documents.length;

          console.log(`   ✅ Backed up ${documents.length} documents from ${collectionName}`);

        } catch (error) {
          console.error(`   ❌ Failed to backup collection ${collectionName}:`, error.message);
          backupMetadata.collections.push({
            name: collectionName,
            error: error.message,
            documentCount: 0
          });
        }
      }

      // Calculate total backup size
      const files = await fs.readdir(backupPath);
      let totalSize = 0;
      for (const file of files) {
        const filePath = path.join(backupPath, file);
        const stats = await fs.stat(filePath);
        totalSize += stats.size;
      }
      backupMetadata.backupSize = totalSize;

      // Save backup metadata
      const metadataFile = path.join(backupPath, 'backup-metadata.json');
      await fs.writeFile(metadataFile, JSON.stringify(backupMetadata, null, 2));

      console.log(`✅ Backup completed: ${backupFileName}`);
      console.log(`   📊 Total collections: ${backupMetadata.collections.length}`);
      console.log(`   📄 Total documents: ${backupMetadata.totalDocuments}`);
      console.log(`   💾 Backup size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);

      return {
        success: true,
        backupName: backupFileName,
        path: backupPath,
        metadata: backupMetadata
      };

    } catch (error) {
      console.error('❌ Backup failed:', error.message);
      return { success: false, error: error.message };
    }
  }

  async listBackups() {
    try {
      const items = await fs.readdir(this.backupDir);
      const backups = [];

      for (const item of items) {
        const itemPath = path.join(this.backupDir, item);
        const stats = await fs.stat(itemPath);

        if (stats.isDirectory()) {
          const metadataFile = path.join(itemPath, 'backup-metadata.json');

          try {
            const metadataContent = await fs.readFile(metadataFile, 'utf8');
            const metadata = JSON.parse(metadataContent);

            backups.push({
              name: item,
              path: itemPath,
              created: metadata.timestamp,
              collections: metadata.collections?.length || 0,
              totalDocuments: metadata.totalDocuments || 0,
              size: metadata.backupSize || 0,
              sizeMB: ((metadata.backupSize || 0) / 1024 / 1024).toFixed(2)
            });
          } catch (error) {
            // If metadata file doesn't exist or is corrupted, add basic info
            backups.push({
              name: item,
              path: itemPath,
              created: stats.birthtime.toISOString(),
              error: 'Metadata file missing or corrupted'
            });
          }
        }
      }

      // Sort by creation date (newest first)
      backups.sort((a, b) => new Date(b.created) - new Date(a.created));

      return backups;

    } catch (error) {
      console.error('❌ Failed to list backups:', error.message);
      return [];
    }
  }

  async restoreBackup(backupName, options = {}) {
    const {
      overwrite = false,
      collections = null, // Array of collection names to restore, null means all
      dryRun = false
    } = options;

    const backupPath = path.join(this.backupDir, backupName);

    console.log(`${dryRun ? '🔍 Dry run: ' : '🔄 '}Restoring backup: ${backupName}`);

    try {
      // Check if backup exists
      const stats = await fs.stat(backupPath);
      if (!stats.isDirectory()) {
        throw new Error('Backup directory not found');
      }

      // Read backup metadata
      const metadataFile = path.join(backupPath, 'backup-metadata.json');
      const metadataContent = await fs.readFile(metadataFile, 'utf8');
      const metadata = JSON.parse(metadataContent);

      console.log(`📋 Backup contains ${metadata.collections?.length || 0} collections`);
      console.log(`📄 Total documents: ${metadata.totalDocuments || 0}`);

      if (dryRun) {
        console.log('🔍 Dry run completed - no changes made');
        return { success: true, dryRun: true, metadata };
      }

      // Get collections to restore
      let collectionsToRestore = metadata.collections || [];
      if (collections) {
        collectionsToRestore = collectionsToRestore.filter(col =>
          collections.includes(col.name)
        );
        console.log(`🎯 Restoring only specified collections: ${collections.join(', ')}`);
      }

      const restoreResults = {
        totalCollections: collectionsToRestore.length,
        successfulRestores: 0,
        failedRestores: 0,
        totalDocumentsRestored: 0
      };

      // Restore each collection
      for (const collectionInfo of collectionsToRestore) {
        const collectionName = collectionInfo.name;
        console.log(`🔄 Restoring collection: ${collectionName}`);

        try {
          const collectionFile = path.join(backupPath, `${collectionName}.json`);
          const collectionContent = await fs.readFile(collectionFile, 'utf8');
          const collectionData = JSON.parse(collectionContent);

          const coll = this.db.collection(collectionName);

          // Check if collection has existing data
          const existingCount = await coll.countDocuments();
          if (existingCount > 0 && !overwrite) {
            console.log(`   ⚠️  Collection ${collectionName} has ${existingCount} existing documents`);
            console.log(`   ⏭️  Skipping (use overwrite=true to replace)`);
            restoreResults.failedRestores++;
            continue;
          }

          // Clear existing data if overwrite is enabled
          if (existingCount > 0 && overwrite) {
            await coll.deleteMany({});
            console.log(`   🗑️  Cleared ${existingCount} existing documents`);
          }

          // Restore documents
          if (collectionData.documents && collectionData.documents.length > 0) {
            // Remove _id fields to avoid conflicts
            const documentsToInsert = collectionData.documents.map(doc => {
              const { _id, ...docWithoutId } = doc;
              return docWithoutId;
            });

            const result = await coll.insertMany(documentsToInsert, { ordered: false });
            console.log(`   ✅ Restored ${result.insertedCount} documents to ${collectionName}`);
            restoreResults.totalDocumentsRestored += result.insertedCount;
          }

          // Restore indexes (skip default _id index)
          if (collectionData.indexes) {
            for (const index of collectionData.indexes) {
              if (index.name === '_id_') continue;

              try {
                await coll.createIndex(index.key, {
                  name: index.name,
                  unique: index.unique || false,
                  sparse: index.sparse || false,
                  background: true
                });
                console.log(`   📊 Restored index: ${index.name}`);
              } catch (error) {
                if (error.code === 85) {
                  console.log(`   ℹ️  Index ${index.name} already exists`);
                } else {
                  console.error(`   ❌ Failed to restore index ${index.name}:`, error.message);
                }
              }
            }
          }

          restoreResults.successfulRestores++;

        } catch (error) {
          console.error(`❌ Failed to restore collection ${collectionName}:`, error.message);
          restoreResults.failedRestores++;
        }
      }

      console.log(`\n📊 Restore Summary:`);
      console.log(`   Collections processed: ${restoreResults.totalCollections}`);
      console.log(`   Successful restores: ${restoreResults.successfulRestores}`);
      console.log(`   Failed restores: ${restoreResults.failedRestores}`);
      console.log(`   Documents restored: ${restoreResults.totalDocumentsRestored}`);

      return {
        success: true,
        results: restoreResults,
        metadata
      };

    } catch (error) {
      console.error('❌ Restore failed:', error.message);
      return { success: false, error: error.message };
    }
  }

  async cleanupOldBackups(retentionDays = 30) {
    console.log(`🧹 Cleaning up backups older than ${retentionDays} days...`);

    try {
      const backups = await this.listBackups();
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

      let deletedCount = 0;
      let freedSpace = 0;

      for (const backup of backups) {
        const backupDate = new Date(backup.created);

        if (backupDate < cutoffDate) {
          console.log(`   🗑️  Deleting old backup: ${backup.name} (${backup.created})`);

          try {
            // Calculate space before deletion
            const backupStats = await this.getDirectorySize(backup.path);
            freedSpace += backupStats.size;

            // Delete the backup directory
            await fs.rm(backup.path, { recursive: true, force: true });
            deletedCount++;

            console.log(`   ✅ Deleted ${backup.name} (${(backupStats.size / 1024 / 1024).toFixed(2)} MB)`);
          } catch (error) {
            console.error(`   ❌ Failed to delete ${backup.name}:`, error.message);
          }
        }
      }

      console.log(`🧹 Cleanup completed: ${deletedCount} backups deleted, ${(freedSpace / 1024 / 1024).toFixed(2)} MB freed`);

      return { deletedCount, freedSpace };

    } catch (error) {
      console.error('❌ Cleanup failed:', error.message);
      return { deletedCount: 0, freedSpace: 0, error: error.message };
    }
  }

  async getDirectorySize(dirPath) {
    let totalSize = 0;
    let fileCount = 0;

    async function calculateSize(itemPath) {
      const stats = await fs.stat(itemPath);

      if (stats.isDirectory()) {
        const items = await fs.readdir(itemPath);
        for (const item of items) {
          await calculateSize(path.join(itemPath, item));
        }
      } else {
        totalSize += stats.size;
        fileCount++;
      }
    }

    await calculateSize(dirPath);
    return { size: totalSize, files: fileCount };
  }

  async scheduleAutomatedBackup(cronExpression = '0 2 * * *') {
    console.log(`📅 Scheduling automated backup with cron: ${cronExpression}`);

    // This would typically integrate with a job scheduler like node-cron
    // For now, we'll create a script that can be called by cron

    const scheduleScript = `#!/bin/bash
# Automated MongoDB Atlas Backup Script
# Add this to crontab: ${cronExpression} /path/to/backup-script.sh

cd "$(dirname "$0")"
node -e "
const BackupManager = require('./backup-manager.js');
async function runBackup() {
  const manager = new BackupManager();
  await manager.connect();
  await manager.ensureBackupDirectory();
  const result = await manager.createBackup();
  await manager.disconnect();
  console.log('Automated backup completed:', result.success ? 'SUCCESS' : 'FAILED');
  process.exit(result.success ? 0 : 1);
}
runBackup().catch(console.error);
"
`;

    const scriptPath = path.join(this.backupDir, 'automated-backup.sh');
    await fs.writeFile(scriptPath, scheduleScript);
    await fs.chmod(scriptPath, '755');

    console.log(`✅ Created automated backup script: ${scriptPath}`);
    console.log(`📝 Add to crontab: ${cronExpression} ${scriptPath}`);

    return scriptPath;
  }

  async disconnect() {
    if (this.client) {
      await this.client.close();
      console.log('✅ Disconnected from MongoDB Atlas');
    }
  }
}

// CLI Interface
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  if (!command || args.includes('--help') || args.includes('-h')) {
    console.log(`
MongoDB Atlas Backup Manager

Usage:
  node backup-manager.js <command> [options]

Commands:
  create [name]           Create a new backup (optional custom name)
  list                    List all available backups
  restore <name>          Restore a backup
  cleanup [days]          Clean up backups older than X days (default: 30)
  schedule [cron]         Create automated backup script (default: '0 2 * * *')
  dry-restore <name>      Dry run restore without making changes

Options:
  --collections <list>    Comma-separated list of collections to restore
  --overwrite             Overwrite existing data during restore
  --help, -h             Show this help

Examples:
  node backup-manager.js create
  node backup-manager.js create my-backup-2024
  node backup-manager.js list
  node backup-manager.js restore backup-2024-01-01T00-00-00-000Z
  node backup-manager.js restore backup-2024-01-01T00-00-00-000Z --overwrite
  node backup-manager.js restore backup-2024-01-01T00-00-00-000Z --collections users,products
  node backup-manager.js cleanup 7
  node backup-manager.js schedule "0 */6 * * *"
`);
    return;
  }

  const manager = new BackupManager();
  const connected = await manager.connect();
  if (!connected) process.exit(1);

  await manager.ensureBackupDirectory();

  try {
    switch (command) {
      case 'create':
        const backupName = args[1];
        await manager.createBackup(backupName);
        break;

      case 'list':
        const backups = await manager.listBackups();
        if (backups.length === 0) {
          console.log('No backups found');
        } else {
          console.log('Available backups:');
          backups.forEach(backup => {
            console.log(`  ${backup.name}`);
            console.log(`    Created: ${backup.created}`);
            console.log(`    Collections: ${backup.collections || 'N/A'}`);
            console.log(`    Documents: ${backup.totalDocuments || 'N/A'}`);
            console.log(`    Size: ${backup.sizeMB || 'N/A'} MB`);
            console.log('');
          });
        }
        break;

      case 'restore':
      case 'dry-restore':
        const restoreName = args[1];
        if (!restoreName) {
          console.error('❌ Backup name required for restore');
          process.exit(1);
        }

        const collectionsArg = args.find(arg => arg.startsWith('--collections='));
        const collections = collectionsArg ? collectionsArg.split('=')[1].split(',') : null;
        const overwrite = args.includes('--overwrite');
        const dryRun = command === 'dry-restore';

        const result = await manager.restoreBackup(restoreName, {
          overwrite,
          collections,
          dryRun
        });

        if (!result.success) {
          process.exit(1);
        }
        break;

      case 'cleanup':
        const retentionDays = parseInt(args[1]) || 30;
        await manager.cleanupOldBackups(retentionDays);
        break;

      case 'schedule':
        const cronExpression = args[1] || '0 2 * * *';
        await manager.scheduleAutomatedBackup(cronExpression);
        break;

      default:
        console.error(`❌ Unknown command: ${command}`);
        console.log('Use --help for available commands');
        process.exit(1);
    }
  } catch (error) {
    console.error('❌ Command failed:', error.message);
    process.exit(1);
  } finally {
    await manager.disconnect();
  }
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = BackupManager;