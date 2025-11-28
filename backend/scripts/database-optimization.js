const mongoose = require('mongoose');
require('dotenv').config();

/**
 * Database Optimization and Scaling Script
 * Handles index creation, performance monitoring, and scaling configurations
 */

class DatabaseOptimizer {
  constructor() {
    this.connection = null;
    this.db = null;
  }

  async connect() {
    try {
      const options = {
        maxPoolSize: parseInt(process.env.DB_MAX_POOL_SIZE) || 20,
        minPoolSize: parseInt(process.env.DB_MIN_POOL_SIZE) || 5,
        maxIdleTimeMS: parseInt(process.env.DB_MAX_IDLE_TIME) || 60000,
        serverSelectionTimeoutMS: 5000,
        socketTimeoutMS: 45000,
        readPreference: 'secondaryPreferred',
        retryWrites: true,
        retryReads: true,
      };

      this.connection = await mongoose.connect(process.env.MONGODB_URI, options);
      this.db = mongoose.connection.db;

      console.log('✅ Connected to MongoDB Atlas for optimization');
      return true;
    } catch (error) {
      console.error('❌ Failed to connect:', error);
      return false;
    }
  }

  async createIndexes() {
    console.log('🔧 Creating optimized indexes...');

    const indexes = [
      // Users collection
      {
        collection: 'users',
        indexes: [
          { key: { email: 1 }, options: { unique: true, name: 'email_unique' } },
          { key: { phone: 1 }, options: { sparse: true, name: 'phone_index' } },
          { key: { role: 1 }, options: { name: 'role_index' } },
          { key: { createdAt: -1 }, options: { name: 'created_at_desc' } },
          { key: { 'location.coordinates': '2dsphere' }, options: { name: 'location_2dsphere' } },
        ]
      },

      // Products collection
      {
        collection: 'products',
        indexes: [
          { key: { name: 'text', description: 'text' }, options: { name: 'text_search' } },
          { key: { category: 1 }, options: { name: 'category_index' } },
          { key: { price: 1 }, options: { name: 'price_asc' } },
          { key: { createdAt: -1 }, options: { name: 'created_at_desc' } },
          { key: { seller: 1 }, options: { name: 'seller_index' } },
          { key: { status: 1 }, options: { name: 'status_index' } },
          { key: { category: 1, price: -1 }, options: { name: 'category_price_desc' } },
          { key: { tags: 1 }, options: { name: 'tags_index' } },
        ]
      },

      // Orders collection
      {
        collection: 'orders',
        indexes: [
          { key: { user: 1 }, options: { name: 'user_index' } },
          { key: { status: 1 }, options: { name: 'status_index' } },
          { key: { createdAt: -1 }, options: { name: 'created_at_desc' } },
          { key: { 'shipping.address': 1 }, options: { name: 'shipping_address' } },
          { key: { total: 1 }, options: { name: 'total_asc' } },
          { key: { user: 1, createdAt: -1 }, options: { name: 'user_orders_desc' } },
        ]
      },

      // Categories collection
      {
        collection: 'categories',
        indexes: [
          { key: { name: 1 }, options: { unique: true, name: 'name_unique' } },
          { key: { parent: 1 }, options: { name: 'parent_index' } },
          { key: { level: 1 }, options: { name: 'level_index' } },
        ]
      },

      // Reviews collection
      {
        collection: 'reviews',
        indexes: [
          { key: { product: 1 }, options: { name: 'product_index' } },
          { key: { user: 1 }, options: { name: 'user_index' } },
          { key: { rating: -1 }, options: { name: 'rating_desc' } },
          { key: { createdAt: -1 }, options: { name: 'created_at_desc' } },
          { key: { product: 1, createdAt: -1 }, options: { name: 'product_reviews_desc' } },
        ]
      },

      // Carts collection
      {
        collection: 'carts',
        indexes: [
          { key: { user: 1 }, options: { unique: true, name: 'user_unique' } },
          { key: { updatedAt: -1 }, options: { name: 'updated_at_desc' } },
        ]
      },

      // Messages collection
      {
        collection: 'messages',
        indexes: [
          { key: { conversation: 1 }, options: { name: 'conversation_index' } },
          { key: { sender: 1 }, options: { name: 'sender_index' } },
          { key: { createdAt: -1 }, options: { name: 'created_at_desc' } },
          { key: { conversation: 1, createdAt: -1 }, options: { name: 'conversation_messages_desc' } },
        ]
      },

      // Conversations collection
      {
        collection: 'conversations',
        indexes: [
          { key: { participants: 1 }, options: { name: 'participants_index' } },
          { key: { updatedAt: -1 }, options: { name: 'updated_at_desc' } },
          { key: { type: 1 }, options: { name: 'type_index' } },
        ]
      },

      // Notifications collection
      {
        collection: 'notifications',
        indexes: [
          { key: { user: 1 }, options: { name: 'user_index' } },
          { key: { read: 1 }, options: { name: 'read_index' } },
          { key: { createdAt: -1 }, options: { name: 'created_at_desc' } },
          { key: { user: 1, read: 1, createdAt: -1 }, options: { name: 'user_notifications' } },
        ]
      },

      // RFQs collection
      {
        collection: 'rfqs',
        indexes: [
          { key: { buyer: 1 }, options: { name: 'buyer_index' } },
          { key: { status: 1 }, options: { name: 'status_index' } },
          { key: { category: 1 }, options: { name: 'category_index' } },
          { key: { createdAt: -1 }, options: { name: 'created_at_desc' } },
          { key: { deadline: 1 }, options: { name: 'deadline_asc' } },
        ]
      },

      // Wishlists collection
      {
        collection: 'wishlists',
        indexes: [
          { key: { user: 1 }, options: { name: 'user_index' } },
          { key: { product: 1 }, options: { name: 'product_index' } },
          { key: { user: 1, product: 1 }, options: { unique: true, name: 'user_product_unique' } },
        ]
      },

      // Loyalty Transactions collection
      {
        collection: 'loyaltytransactions',
        indexes: [
          { key: { user: 1 }, options: { name: 'user_index' } },
          { key: { type: 1 }, options: { name: 'type_index' } },
          { key: { createdAt: -1 }, options: { name: 'created_at_desc' } },
          { key: { user: 1, createdAt: -1 }, options: { name: 'user_transactions_desc' } },
        ]
      },
    ];

    for (const { collection, indexes: collectionIndexes } of indexes) {
      try {
        const collectionExists = await this.db.listCollections({ name: collection }).hasNext();
        if (!collectionExists) {
          console.log(`⚠️  Collection '${collection}' does not exist, skipping indexes`);
          continue;
        }

        console.log(`📊 Creating indexes for ${collection}...`);
        const coll = this.db.collection(collection);

        for (const index of collectionIndexes) {
          try {
            await coll.createIndex(index.key, index.options);
            console.log(`✅ Created index: ${index.options.name} on ${collection}`);
          } catch (error) {
            if (error.code === 85) {
              console.log(`ℹ️  Index ${index.options.name} already exists on ${collection}`);
            } else {
              console.error(`❌ Failed to create index ${index.options.name} on ${collection}:`, error.message);
            }
          }
        }
      } catch (error) {
        console.error(`❌ Error processing collection ${collection}:`, error.message);
      }
    }

    console.log('✅ Index creation completed');
  }

  async analyzePerformance() {
    console.log('📊 Analyzing database performance...');

    try {
      // Get database stats
      const stats = await this.db.stats();
      console.log('📈 Database Statistics:');
      console.log(`   Collections: ${stats.collections}`);
      console.log(`   Objects: ${stats.objects}`);
      console.log(`   Data Size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`   Storage Size: ${(stats.storageSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`   Indexes: ${stats.indexes}`);
      console.log(`   Index Size: ${(stats.indexSize / 1024 / 1024).toFixed(2)} MB`);

      // Analyze slow queries (if available)
      const slowQueries = await this.db.collection('system.profile').find({
        millis: { $gt: 100 } // Queries taking more than 100ms
      }).sort({ ts: -1 }).limit(10).toArray();

      if (slowQueries.length > 0) {
        console.log('\n🐌 Slow Queries (last 10):');
        slowQueries.forEach((query, index) => {
          console.log(`${index + 1}. ${query.millis}ms - ${JSON.stringify(query.command)}`);
        });
      }

      // Check index usage
      const collections = await this.db.listCollections().toArray();
      console.log('\n📊 Index Usage Analysis:');

      for (const collection of collections) {
        try {
          const coll = this.db.collection(collection.name);
          const indexes = await coll.indexes();

          console.log(`\nCollection: ${collection.name}`);
          for (const index of indexes) {
            console.log(`   Index: ${index.name} - Key: ${JSON.stringify(index.key)}`);
          }
        } catch (error) {
          console.log(`   Error analyzing ${collection.name}: ${error.message}`);
        }
      }

    } catch (error) {
      console.error('❌ Error analyzing performance:', error.message);
    }
  }

  async optimizeQueries() {
    console.log('🔧 Optimizing query patterns...');

    // This would typically involve analyzing query patterns and suggesting optimizations
    // For now, we'll create some compound indexes for common query patterns

    const queryOptimizations = [
      // Common product search patterns
      {
        collection: 'products',
        index: { category: 1, price: -1, rating: -1 },
        name: 'category_price_rating_desc'
      },
      // Order analytics
      {
        collection: 'orders',
        index: { status: 1, createdAt: -1, total: -1 },
        name: 'status_created_total_desc'
      },
      // User activity
      {
        collection: 'users',
        index: { role: 1, createdAt: -1, lastLogin: -1 },
        name: 'role_created_lastlogin_desc'
      },
    ];

    for (const opt of queryOptimizations) {
      try {
        const coll = this.db.collection(opt.collection);
        await coll.createIndex(opt.index, { name: opt.name });
        console.log(`✅ Created optimization index: ${opt.name} on ${opt.collection}`);
      } catch (error) {
        if (error.code !== 85) {
          console.error(`❌ Failed to create optimization index on ${opt.collection}:`, error.message);
        }
      }
    }
  }

  async setupMonitoring() {
    console.log('📊 Setting up database monitoring...');

    // Enable profiling for slow queries (development only)
    if (process.env.NODE_ENV !== 'production') {
      try {
        await this.db.setProfilingLevel(1, { slowms: 100 });
        console.log('✅ Enabled profiling for queries > 100ms');
      } catch (error) {
        console.error('❌ Failed to enable profiling:', error.message);
      }
    }

    // Create monitoring collections if they don't exist
    const monitoringCollections = [
      'performance_metrics',
      'query_logs',
      'connection_stats'
    ];

    for (const collection of monitoringCollections) {
      try {
        const exists = await this.db.listCollections({ name: collection }).hasNext();
        if (!exists) {
          await this.db.createCollection(collection);
          console.log(`✅ Created monitoring collection: ${collection}`);
        }
      } catch (error) {
        console.error(`❌ Failed to create monitoring collection ${collection}:`, error.message);
      }
    }
  }

  async disconnect() {
    if (this.connection) {
      await mongoose.disconnect();
      console.log('✅ Disconnected from MongoDB Atlas');
    }
  }

  async runOptimization() {
    console.log('🚀 Starting Database Optimization Process...\n');

    const connected = await this.connect();
    if (!connected) return;

    try {
      await this.createIndexes();
      console.log('');

      await this.analyzePerformance();
      console.log('');

      await this.optimizeQueries();
      console.log('');

      await this.setupMonitoring();
      console.log('');

      console.log('🎉 Database optimization completed successfully!');
    } catch (error) {
      console.error('❌ Optimization failed:', error);
    } finally {
      await this.disconnect();
    }
  }
}

// Run optimization if called directly
if (require.main === module) {
  const optimizer = new DatabaseOptimizer();
  optimizer.runOptimization().catch(console.error);
}

module.exports = DatabaseOptimizer;