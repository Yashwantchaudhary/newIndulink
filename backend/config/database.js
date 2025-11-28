const mongoose = require('mongoose');

const connectDatabase = async () => {
  try {
    // Production-ready connection options
    const options = {
      // Connection pooling
      maxPoolSize: 10, // Maximum number of connections in the connection pool
      minPoolSize: 2, // Minimum number of connections in the connection pool
      maxIdleTimeMS: 30000, // Close connections after 30 seconds of inactivity
      serverSelectionTimeoutMS: 5000, // Keep trying to send operations for 5 seconds
      socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
      bufferCommands: false, // Disable mongoose buffering
      bufferMaxEntries: 0, // Disable mongoose buffering

      // Retry logic
      retryWrites: true,
      retryReads: true,

      // Heartbeat and monitoring
      heartbeatFrequencyMS: 10000, // Check server every 10 seconds
      heartbeatTimeoutMS: 5000, // Timeout after 5 seconds

      // Write concern
      w: 'majority',
      wtimeoutMS: 2500,

      // Read preference for scaling
      readPreference: process.env.NODE_ENV === 'production' ? 'secondaryPreferred' : 'primary',
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

    // Monitor connection pool stats
    setInterval(() => {
      const stats = mongoose.connection.db?.stats || {};
      console.log(`📊 MongoDB Pool Stats - Active: ${mongoose.connection.readyState}, Pool Size: ${stats.connections || 'N/A'}`);
    }, 300000); // Log every 5 minutes

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

    // Exponential backoff retry logic
    const retryWithBackoff = (attempt = 1, maxAttempts = 5) => {
      if (attempt > maxAttempts) {
        console.error('❌ Max retry attempts reached. Manual intervention required.');
        return;
      }

      const delay = Math.min(1000 * Math.pow(2, attempt), 30000); // Exponential backoff, max 30s
      console.log(`🔄 Retrying MongoDB connection in ${delay}ms (attempt ${attempt}/${maxAttempts})...`);

      setTimeout(() => {
        connectDatabase().catch(() => retryWithBackoff(attempt + 1, maxAttempts));
      }, delay);
    };

    retryWithBackoff();
  }
};

module.exports = connectDatabase;
