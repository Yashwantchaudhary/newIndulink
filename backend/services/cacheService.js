const redis = require('redis');
const util = require('util');

/**
 * Redis Cache Service for Performance Optimization
 * Implements caching strategy for frequently accessed data
 */
class CacheService {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    /**
     * Initialize Redis connection
     */
    async connect() {
        try {
            this.client = redis.createClient({
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379,
                password: process.env.REDIS_PASSWORD || undefined,
                retry_strategy: (options) => {
                    if (options.error && options.error.code === 'ECONNREFUSED') {
                        console.error('Redis connection refused');
                        return new Error('Redis connection refused');
                    }
                    if (options.total_retry_time > 1000 * 60 * 60) {
                        return new Error('Redis retry time exhausted');
                    }
                    if (options.attempt > 10) {
                        return undefined;
                    }
                    return Math.min(options.attempt * 100, 3000);
                },
            });

            // Promisify Redis methods
            this.client.get = util.promisify(this.client.get).bind(this.client);
            this.client.set = util.promisify(this.client.set).bind(this.client);
            this.client.del = util.promisify(this.client.del).bind(this.client);
            this.client.keys = util.promisify(this.client.keys).bind(this.client);
            this.client.ttl = util.promisify(this.client.ttl).bind(this.client);

            this.client.on('connect', () => {
                console.log('✅ Redis connected successfully');
                this.isConnected = true;
            });

            this.client.on('error', (err) => {
                console.error('❌ Redis error:', err);
                this.isConnected = false;
            });

            this.client.on('end', () => {
                console.log('⚠️  Redis connection closed');
                this.isConnected = false;
            });

        } catch (error) {
            console.error('Failed to initialize Redis:', error);
            this.isConnected = false;
        }
    }

    /**
     * Get cached data
     * @param {string} key - Cache key
     * @returns {Promise<any>} - Parsed cached data or null
     */
    async get(key) {
        if (!this.isConnected) {
            console.warn('Redis not connected, skipping cache get');
            return null;
        }

        try {
            const data = await this.client.get(key);
            return data ? JSON.parse(data) : null;
        } catch (error) {
            console.error('Cache get error:', error);
            return null;
        }
    }

    /**
     * Set cached data with TTL
     * @param {string} key - Cache key
     * @param {any} value - Data to cache
     * @param {number} ttl - Time to live in seconds (default: 5 minutes)
     */
    async set(key, value, ttl = 300) {
        if (!this.isConnected) {
            console.warn('Redis not connected, skipping cache set');
            return;
        }

        try {
            await this.client.set(key, JSON.stringify(value), 'EX', ttl);
        } catch (error) {
            console.error('Cache set error:', error);
        }
    }

    /**
     * Delete cached data
     * @param {string} key - Cache key or pattern
     */
    async del(key) {
        if (!this.isConnected) {
            return;
        }

        try {
            // If key contains wildcard, find and delete matching keys
            if (key.includes('*')) {
                const keys = await this.client.keys(key);
                if (keys.length > 0) {
                    await Promise.all(keys.map(k => this.client.del(k)));
                }
            } else {
                await this.client.del(key);
            }
        } catch (error) {
            console.error('Cache delete error:', error);
        }
    }

    /**
     * Clear all cached data (use with caution)
     */
    async clear() {
        if (!this.isConnected) {
            return;
        }

        try {
            await this.client.flushall();
            console.log('✅ Cache cleared successfully');
        } catch (error) {
            console.error('Cache clear error:', error);
        }
    }

    /**
     * Get cache statistics
     */
    async getStats() {
        if (!this.isConnected) {
            return { connected: false };
        }

        try {
            const info = await util.promisify(this.client.info).bind(this.client)();
            return {
                connected: true,
                info,
            };
        } catch (error) {
            return { connected: false, error: error.message };
        }
    }

    /**
     * Disconnect from Redis
     */
    disconnect() {
        if (this.client) {
            this.client.quit();
            this.isConnected = false;
        }
    }
}

// Export singleton instance
const cacheService = new CacheService();
module.exports = cacheService;
