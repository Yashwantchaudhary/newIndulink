/// 💾 Cache Service
/// Advanced caching system with MongoDB for INDULINK platform

const mongoose = require('mongoose');
const crypto = require('crypto');

class CacheService {
    constructor() {
        this.isConnected = false;
        this.CacheEntry = null;
        this.initMongoCache();
    }

    // Initialize MongoDB cache collection
    async initMongoCache() {
        try {
            // Define cache schema
            const cacheSchema = new mongoose.Schema({
                key: {
                    type: String,
                    required: true,
                    unique: true,
                    index: true
                },
                data: {
                    type: mongoose.Schema.Types.Mixed,
                    required: true
                },
                type: {
                    type: String,
                    default: 'general',
                    index: true
                },
                timestamp: {
                    type: Date,
                    default: Date.now,
                    index: true
                },
                expiresAt: {
                    type: Date,
                    index: true
                },
                size: {
                    type: Number,
                    default: 0
                },
                priority: {
                    type: Number,
                    default: 0
                },
                tags: [String]
            }, {
                timestamps: true,
                collection: 'cache_entries'
            });

            // Add indexes
            cacheSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
            cacheSchema.index({ type: 1, priority: -1, timestamp: -1 });

            this.CacheEntry = mongoose.model('CacheEntry', cacheSchema);

            // Clean expired entries on startup
            await this.cleanupExpired();

            this.isConnected = true;
            console.log('✅ MongoDB cache initialized successfully');

        } catch (error) {
            console.error('❌ Failed to initialize MongoDB cache:', error);
            this.isConnected = false;
        }
    }

    // ==================== BASIC CACHE OPERATIONS ====================

    // Set cache value with optional TTL
    async set(key, value, ttl = null) {
        if (!this.isConnected || !this.CacheEntry) {
            console.warn('⚠️ MongoDB cache not connected, skipping cache set');
            return false;
        }

        try {
            const serializedValue = JSON.stringify(value);
            const size = Buffer.byteLength(serializedValue, 'utf8');
            const expiresAt = ttl ? new Date(Date.now() + ttl * 1000) : null;

            await this.CacheEntry.findOneAndUpdate(
                { key },
                {
                    key,
                    data: value,
                    size,
                    expiresAt,
                    timestamp: new Date()
                },
                { upsert: true, new: true }
            );

            return true;
        } catch (error) {
            console.error('❌ Cache set error:', error);
            return false;
        }
    }

    // Get cache value
    async get(key) {
        if (!this.isConnected || !this.CacheEntry) {
            console.warn('⚠️ MongoDB cache not connected, skipping cache get');
            return null;
        }

        try {
            const entry = await this.CacheEntry.findOne({
                key,
                $or: [
                    { expiresAt: null },
                    { expiresAt: { $gt: new Date() } }
                ]
            });

            return entry ? entry.data : null;
        } catch (error) {
            console.error('❌ Cache get error:', error);
            return null;
        }
    }

    // Delete cache key
    async delete(key) {
        if (!this.isConnected || !this.CacheEntry) {
            console.warn('⚠️ MongoDB cache not connected, skipping cache delete');
            return false;
        }

        try {
            await this.CacheEntry.deleteOne({ key });
            return true;
        } catch (error) {
            console.error('❌ Cache delete error:', error);
            return false;
        }
    }

    // Check if key exists
    async exists(key) {
        if (!this.isConnected || !this.CacheEntry) return false;

        try {
            const count = await this.CacheEntry.countDocuments({
                key,
                $or: [
                    { expiresAt: null },
                    { expiresAt: { $gt: new Date() } }
                ]
            });
            return count > 0;
        } catch (error) {
            console.error('❌ Cache exists error:', error);
            return false;
        }
    }

    // Set multiple keys
    async mset(keyValuePairs) {
        if (!this.isConnected || !this.CacheEntry) return false;

        try {
            const operations = Object.entries(keyValuePairs).map(([key, value]) => ({
                updateOne: {
                    filter: { key },
                    update: {
                        key,
                        data: value,
                        size: Buffer.byteLength(JSON.stringify(value), 'utf8'),
                        timestamp: new Date()
                    },
                    upsert: true
                }
            }));

            await this.CacheEntry.bulkWrite(operations);
            return true;
        } catch (error) {
            console.error('❌ Cache mset error:', error);
            return false;
        }
    }

    // Get multiple keys
    async mget(keys) {
        if (!this.isConnected || !this.CacheEntry) return {};

        try {
            const entries = await this.CacheEntry.find({
                key: { $in: keys },
                $or: [
                    { expiresAt: null },
                    { expiresAt: { $gt: new Date() } }
                ]
            });

            const result = {};
            keys.forEach(key => {
                const entry = entries.find(e => e.key === key);
                result[key] = entry ? entry.data : null;
            });

            return result;
        } catch (error) {
            console.error('❌ Cache mget error:', error);
            return {};
        }
    }

    // ==================== ADVANCED CACHE OPERATIONS ====================

    // Set with sub-document for complex data
    async hset(key, field, value) {
        if (!this.isConnected || !this.CacheEntry) return false;

        try {
            await this.CacheEntry.findOneAndUpdate(
                { key },
                {
                    $set: {
                        [`data.${field}`]: value,
                        timestamp: new Date()
                    }
                },
                { upsert: true }
            );
            return true;
        } catch (error) {
            console.error('❌ Cache hset error:', error);
            return false;
        }
    }

    // Get from sub-document
    async hget(key, field) {
        if (!this.isConnected || !this.CacheEntry) return null;

        try {
            const entry = await this.CacheEntry.findOne({
                key,
                $or: [
                    { expiresAt: null },
                    { expiresAt: { $gt: new Date() } }
                ]
            });

            if (!entry || !entry.data || typeof entry.data !== 'object') return null;

            return entry.data[field] || null;
        } catch (error) {
            console.error('❌ Cache hget error:', error);
            return null;
        }
    }

    // Get all fields from sub-document
    async hgetall(key) {
        if (!this.isConnected || !this.CacheEntry) return {};

        try {
            const entry = await this.CacheEntry.findOne({
                key,
                $or: [
                    { expiresAt: null },
                    { expiresAt: { $gt: new Date() } }
                ]
            });

            return (entry && entry.data && typeof entry.data === 'object') ? entry.data : {};
        } catch (error) {
            console.error('❌ Cache hgetall error:', error);
            return {};
        }
    }

    // Set multiple sub-document fields
    async hmset(key, fieldValuePairs) {
        if (!this.isConnected || !this.CacheEntry) return false;

        try {
            const updateObj = { timestamp: new Date() };
            for (const [field, value] of Object.entries(fieldValuePairs)) {
                updateObj[`data.${field}`] = value;
            }

            await this.CacheEntry.findOneAndUpdate(
                { key },
                { $set: updateObj },
                { upsert: true }
            );
            return true;
        } catch (error) {
            console.error('❌ Cache hmset error:', error);
            return false;
        }
    }

    // ==================== CACHE KEY MANAGEMENT ====================

    // Generate cache key with prefix
    generateKey(prefix, ...parts) {
        const sanitizedParts = parts.map(part =>
            typeof part === 'string' ? part.replace(/[^a-zA-Z0-9_-]/g, '_') : part.toString()
        );
        return `${prefix}:${sanitizedParts.join(':')}`;
    }

    // Generate user-specific cache key
    getUserKey(userId, type, ...additional) {
        return this.generateKey('user', userId, type, ...additional);
    }

    // Generate product-specific cache key
    getProductKey(productId, type = '') {
        return this.generateKey('product', productId, type);
    }

    // Generate category-specific cache key
    getCategoryKey(categoryId, type = '') {
        return this.generateKey('category', categoryId, type);
    }

    // Generate search cache key
    getSearchKey(query, filters = {}) {
        const filterHash = crypto.createHash('md5')
            .update(JSON.stringify(filters))
            .digest('hex')
            .substring(0, 8);
        return this.generateKey('search', query, filterHash);
    }

    // ==================== CACHE STRATEGIES ====================

    // Cache with fallback to database
    async getWithFallback(key, fallbackFn, ttl = 3600) {
        // Try to get from cache first
        let data = await this.get(key);

        if (data !== null) {
            console.log(`✅ Cache hit for key: ${key}`);
            return data;
        }

        console.log(`ℹ️ Cache miss for key: ${key}, fetching from database`);

        // Fallback to database
        try {
            data = await fallbackFn();

            if (data !== null) {
                // Cache the result
                await this.set(key, data, ttl);
                console.log(`💾 Cached data for key: ${key}`);
            }

            return data;
        } catch (error) {
            console.error('❌ Fallback function error:', error);
            throw error;
        }
    }

    // Cache with background refresh
    async getWithBackgroundRefresh(key, fallbackFn, ttl = 3600, refreshThreshold = 300) {
        const data = await this.get(key);

        if (data !== null) {
            // Check if data needs background refresh
            const ttlRemaining = await this.getTTL(key);

            if (ttlRemaining > 0 && ttlRemaining <= refreshThreshold) {
                console.log(`🔄 Background refresh triggered for key: ${key}`);

                // Trigger background refresh (don't await)
                fallbackFn().then(async (freshData) => {
                    if (freshData !== null) {
                        await this.set(key, freshData, ttl);
                        console.log(`🔄 Background refresh completed for key: ${key}`);
                    }
                }).catch(error => {
                    console.error('❌ Background refresh error:', error);
                });
            }

            return data;
        }

        // Cache miss, fetch and cache
        return await this.getWithFallback(key, fallbackFn, ttl);
    }

    // Get TTL for key
    async getTTL(key) {
        if (!this.isConnected || !this.CacheEntry) return -1;

        try {
            const entry = await this.CacheEntry.findOne({ key });
            if (!entry || !entry.expiresAt) return -1;

            const remaining = entry.expiresAt.getTime() - Date.now();
            return Math.max(0, Math.floor(remaining / 1000));
        } catch (error) {
            console.error('❌ Cache TTL error:', error);
            return -1;
        }
    }

    // ==================== BULK OPERATIONS ====================

    // Clear cache by pattern
    async clearByPattern(pattern) {
        if (!this.isConnected || !this.CacheEntry) return 0;

        try {
            // Convert Redis-style pattern to MongoDB regex
            const regex = new RegExp(pattern.replace(/\*/g, '.*').replace(/\?/g, '.'));
            const result = await this.CacheEntry.deleteMany({ key: { $regex: regex } });
            console.log(`🧹 Cleared ${result.deletedCount} entries matching pattern: ${pattern}`);
            return result.deletedCount;
        } catch (error) {
            console.error('❌ Clear by pattern error:', error);
            return 0;
        }
    }

    // Find keys by pattern
    async scanKeys(pattern) {
        if (!this.isConnected || !this.CacheEntry) return [];

        try {
            const regex = new RegExp(pattern.replace(/\*/g, '.*').replace(/\?/g, '.'));
            const entries = await this.CacheEntry.find({ key: { $regex: regex } }, { key: 1 });
            return entries.map(entry => entry.key);
        } catch (error) {
            console.error('❌ Scan keys error:', error);
            return [];
        }
    }

    // ==================== USER-SPECIFIC CACHE ====================

    // Cache user data
    async cacheUserData(userId, data, ttl = 3600) {
        const key = this.getUserKey(userId, 'data');
        return await this.set(key, data, ttl);
    }

    // Get cached user data
    async getUserData(userId) {
        const key = this.getUserKey(userId, 'data');
        return await this.get(key);
    }

    // Cache user products
    async cacheUserProducts(userId, products, ttl = 1800) {
        const key = this.getUserKey(userId, 'products');
        return await this.set(key, products, ttl);
    }

    // Get cached user products
    async getUserProducts(userId) {
        const key = this.getUserKey(userId, 'products');
        return await this.get(key);
    }

    // Cache user orders
    async cacheUserOrders(userId, orders, ttl = 900) {
        const key = this.getUserKey(userId, 'orders');
        return await this.set(key, orders, ttl);
    }

    // Get cached user orders
    async getUserOrders(userId) {
        const key = this.getUserKey(userId, 'orders');
        return await this.get(key);
    }

    // ==================== PRODUCT CACHE ====================

    // Cache product data
    async cacheProduct(productId, product, ttl = 3600) {
        const key = this.getProductKey(productId);
        return await this.set(key, product, ttl);
    }

    // Get cached product
    async getProduct(productId) {
        const key = this.getProductKey(productId);
        return await this.get(key);
    }

    // Cache product list
    async cacheProductList(filters, products, ttl = 1800) {
        const key = this.getSearchKey('products', filters);
        return await this.set(key, products, ttl);
    }

    // Get cached product list
    async getProductList(filters) {
        const key = this.getSearchKey('products', filters);
        return await this.get(key);
    }

    // ==================== CATEGORY CACHE ====================

    // Cache category data
    async cacheCategory(categoryId, category, ttl = 3600) {
        const key = this.getCategoryKey(categoryId);
        return await this.set(key, category, ttl);
    }

    // Get cached category
    async getCategory(categoryId) {
        const key = this.getCategoryKey(categoryId);
        return await this.get(key);
    }

    // Cache categories list
    async cacheCategoriesList(categories, ttl = 3600) {
        const key = this.generateKey('categories', 'list');
        return await this.set(key, categories, ttl);
    }

    // Get cached categories list
    async getCategoriesList() {
        const key = this.generateKey('categories', 'list');
        return await this.get(key);
    }

    // ==================== SEARCH CACHE ====================

    // Cache search results
    async cacheSearchResults(query, filters, results, ttl = 1800) {
        const key = this.getSearchKey(query, filters);
        return await this.set(key, results, ttl);
    }

    // Get cached search results
    async getSearchResults(query, filters) {
        const key = this.getSearchKey(query, filters);
        return await this.get(key);
    }

    // ==================== CACHE INVALIDATION ====================

    // Invalidate user cache
    async invalidateUserCache(userId) {
        const patterns = [
            this.getUserKey(userId, '*'),
            this.generateKey('search', '*', '*', userId) // Search results involving this user
        ];

        let totalCleared = 0;
        for (const pattern of patterns) {
            totalCleared += await this.clearByPattern(pattern);
        }

        console.log(`🧹 Invalidated cache for user ${userId}, cleared ${totalCleared} keys`);
        return totalCleared;
    }

    // Invalidate product cache
    async invalidateProductCache(productId) {
        const patterns = [
            this.getProductKey(productId, '*'),
            this.generateKey('search', '*', '*') // All search results (could be optimized)
        ];

        let totalCleared = 0;
        for (const pattern of patterns) {
            totalCleared += await this.clearByPattern(pattern);
        }

        console.log(`🧹 Invalidated cache for product ${productId}, cleared ${totalCleared} keys`);
        return totalCleared;
    }

    // Invalidate category cache
    async invalidateCategoryCache(categoryId) {
        const patterns = [
            this.getCategoryKey(categoryId, '*'),
            this.generateKey('categories', '*'),
            this.generateKey('search', '*', '*') // Search results might include category filters
        ];

        let totalCleared = 0;
        for (const pattern of patterns) {
            totalCleared += await this.clearByPattern(pattern);
        }

        console.log(`🧹 Invalidated cache for category ${categoryId}, cleared ${totalCleared} keys`);
        return totalCleared;
    }

    // ==================== CACHE STATISTICS ====================

    // Get cache statistics
    async getStats() {
        if (!this.isConnected || !this.CacheEntry) {
            return {
                connected: false,
                entries: 0,
                totalSize: 0
            };
        }

        try {
            const stats = await this.CacheEntry.aggregate([
                {
                    $group: {
                        _id: null,
                        totalEntries: { $sum: 1 },
                        totalSize: { $sum: '$size' },
                        oldestEntry: { $min: '$timestamp' },
                        newestEntry: { $max: '$timestamp' }
                    }
                }
            ]);

            const result = stats[0] || { totalEntries: 0, totalSize: 0 };

            return {
                connected: true,
                entries: result.totalEntries,
                totalSize: result.totalSize,
                oldestEntry: result.oldestEntry,
                newestEntry: result.newestEntry
            };
        } catch (error) {
            console.error('❌ Cache stats error:', error);
            return {
                connected: false,
                entries: 0,
                totalSize: 0
            };
        }
    }

    // ==================== CLEANUP ====================

    // Clear all cache
    async clearAll() {
        if (!this.isConnected || !this.CacheEntry) return false;

        try {
            await this.CacheEntry.deleteMany({});
            console.log('🧹 Cleared all cache');
            return true;
        } catch (error) {
            console.error('❌ Clear all error:', error);
            return false;
        }
    }

    // Cleanup expired entries
    async cleanupExpired() {
        if (!this.isConnected || !this.CacheEntry) return 0;

        try {
            const result = await this.CacheEntry.deleteMany({
                expiresAt: { $lt: new Date() }
            });
            if (result.deletedCount > 0) {
                console.log(`🧹 Cleaned up ${result.deletedCount} expired cache entries`);
            }
            return result.deletedCount;
        } catch (error) {
            console.error('❌ Cleanup expired error:', error);
            return 0;
        }
    }

    // Graceful shutdown
    async close() {
        // MongoDB connection is managed by mongoose
        this.isConnected = false;
        console.log('✅ Cache service closed');
    }
}

module.exports = new CacheService();
