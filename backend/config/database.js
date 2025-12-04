const mongoose = require('mongoose');

const connectDatabase = async () => {
  try {
    // Optimized connection options for better performance and memory usage
    const options = {
      // Connection pooling - minimal for development, optimized for production
      maxPoolSize: process.env.MONGO_MAX_POOL_SIZE ? parseInt(process.env.MONGO_MAX_POOL_SIZE) : (process.env.NODE_ENV === 'production' ? 10 : 2),
      minPoolSize: process.env.MONGO_MIN_POOL_SIZE ? parseInt(process.env.MONGO_MIN_POOL_SIZE) : (process.env.NODE_ENV === 'production' ? 2 : 0),
      maxIdleTimeMS: 30000, // 30 seconds - standard timeout
      serverSelectionTimeoutMS: 5000, // 5 seconds for faster startup
      socketTimeoutMS: 45000, // 45 seconds

      // Retry logic
      retryWrites: true,
      retryReads: true,

      // Heartbeat - less frequent to reduce overhead
      heartbeatFrequencyMS: 10000, // 10 seconds

      // Write concern
      w: 'majority',
      wtimeoutMS: 2500,

      // Read preference
      readPreference: 'primary',

      // Connection settings
      connectTimeoutMS: 10000, // 10 seconds for faster startup
      maxConnecting: 2,
      appName: 'Indulink-Ecommerce',
    };

    const conn = await mongoose.connect(process.env.MONGODB_URI, options);

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    console.log(`📊 Connection pool size: ${options.maxPoolSize}`);
    console.log(`🔄 Read preference: ${options.readPreference}`);

    // Handle connection events with enhanced monitoring
    mongoose.connection.on('connected', () => {
      console.log('📡 MongoDB connected successfully');
    });

    mongoose.connection.on('error', (err) => {
      console.error(`❌ MongoDB connection error: ${err.message}`);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('⚠️  MongoDB disconnected - attempting reconnection...');
      // Auto-reconnect with exponential backoff
      setTimeout(() => {
        console.log('🔄 Auto-reconnecting to MongoDB...');
        connectDatabase();
      }, 5000);
    });

    mongoose.connection.on('reconnected', () => {
      console.log('🔄 MongoDB reconnected successfully');
    });

    mongoose.connection.on('reconnectFailed', () => {
      console.error('❌ MongoDB reconnection failed - manual intervention required');
    });

    // Light connection monitoring - only in production or when explicitly enabled
    if (process.env.NODE_ENV === 'production' || process.env.ENABLE_DB_MONITORING === 'true') {
      setInterval(() => {
        const memoryUsage = process.memoryUsage();
        const memoryUsagePercent = (memoryUsage.heapUsed / memoryUsage.heapTotal) * 100;

        console.log(`💾 Memory Usage: ${memoryUsagePercent.toFixed(1)}% (Heap: ${(memoryUsage.heapUsed / 1024 / 1024).toFixed(1)}MB / ${(memoryUsage.heapTotal / 1024 / 1024).toFixed(1)}MB)`);

        if (memoryUsagePercent > 90) {
          console.warn('⚠️ High memory usage detected');
        }
      }, 300000); // Every 5 minutes instead of every minute
    }

    // Graceful shutdown with connection draining
    const gracefulShutdown = async (signal) => {
      console.log(`📴 Received ${signal}. Starting graceful shutdown...`);

      try {
        // Stop accepting new connections
        await mongoose.connection.close(false);
        console.log('✅ MongoDB connection closed gracefully');
        process.exit(0);
      } catch (error) {
        console.error('❌ Error during graceful shutdown:', error);
        process.exit(1);
      }
    };

    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

  } catch (error) {
    console.error(`❌ Error connecting to MongoDB: ${error.message}`);
    console.log('⚠️  Server will continue running without database connection.');
    console.log('📝 API endpoints may fail until database connection is established.');
    console.log('');
    console.log('🔧 To fix MongoDB Atlas connection:');
    console.log('   1. Go to https://cloud.mongodb.com/');
    console.log('   2. Navigate to Network Access');
    console.log('   3. Add your current IP address to the whitelist');
    console.log('   4. Or add 0.0.0.0/0 to allow all IPs (development only)');
    console.log('');

    // Exponential backoff retry logic with enhanced error handling
    const retryWithBackoff = (attempt = 1, maxAttempts = 5) => {
      if (attempt > maxAttempts) {
        console.error('❌ Max retry attempts reached. Manual intervention required.');
        return;
      }

      const delay = Math.min(1000 * Math.pow(2, attempt), 30000); // Exponential backoff, max 30s
      console.log(`🔄 Retrying MongoDB connection in ${delay}ms (attempt ${attempt}/${maxAttempts})...`);

      setTimeout(() => {
        connectDatabase().catch((error) => {
          console.error(`🔄 Retry attempt ${attempt} failed: ${error.message}`);
          retryWithBackoff(attempt + 1, maxAttempts);
        });
      }, delay);
    };

    // Query performance monitoring and optimization
    const optimizeQueryPerformance = () => {
      // Monitor slow queries
      mongoose.connection.on('query', (query) => {
        const start = Date.now();
        query.on('end', () => {
          const duration = Date.now() - start;
          if (duration > 1000) { // Log queries taking longer than 1 second
            console.warn(`⚠️ Slow query detected (${duration}ms): ${query.getQuery().collection?.name || 'unknown'} - ${JSON.stringify(query.getQuery().filter || {})}`);
          }
        });
      });

      // Index usage monitoring - disabled in development to reduce overhead
      if (process.env.NODE_ENV === 'production' && process.env.ENABLE_INDEX_MONITORING === 'true') {
        setInterval(() => {
          mongoose.connection.db?.listCollections().toArray((err, collections) => {
            if (err) return;
            collections.forEach(collection => {
              mongoose.connection.db?.collection(collection.name).stats((err, stats) => {
                if (err) return;
                const indexUsage = stats?.indexDetails || {};
                Object.entries(indexUsage).forEach(([indexName, indexStats]) => {
                  if (indexStats?.accesses?.since?.ops < 1) {
                    console.log(`📊 Unused index detected: ${collection.name}.${indexName} (${indexStats.accesses.since.ops} operations)`);
                  }
                });
              });
            });
          });
        }, 3600000); // Check every hour only in production
      }
    };

    // Initialize query optimization
    optimizeQueryPerformance();

    retryWithBackoff();
  }
};

module.exports = connectDatabase;
