const cacheService = require('../services/cacheService');

/**
 * Caching Middleware for API Responses
 * Implements intelligent caching strategy for different endpoints
 */

/**
 * Generate cache key from request
 */
const getCacheKey = (req) => {
    const { method, originalUrl, user } = req;
    const userId = user ? user.id : 'anonymous';
    return `${method}:${userId}:${originalUrl}`;
};

/**
 * Cache middleware with configurable TTL
 * @param {number} ttl - Time to live in seconds
 */
const cacheMiddleware = (ttl = 300) => {
    return async (req, res, next) => {
        // Only cache GET requests
        if (req.method !== 'GET') {
            return next();
        }

        const cacheKey = getCacheKey(req);

        try {
            // Try to get from cache
            const cachedData = await cacheService.get(cacheKey);

            if (cachedData) {
                console.log(`✅ Cache HIT: ${cacheKey}`);
                return res.json(cachedData);
            }

            console.log(`⚠️  Cache MISS: ${cacheKey}`);

            // Store the original res.json
            const originalJson = res.json.bind(res);

            // Override res.json to cache the response
            res.json = (data) => {
                // Only cache successful responses
                if (res.statusCode === 200) {
                    cacheService.set(cacheKey, data, ttl).catch(err => {
                        console.error('Failed to cache response:', err);
                    });
                }
                return originalJson(data);
            };

            next();
        } catch (error) {
            console.error('Cache middleware error:', error);
            next();
        }
    };
};

/**
 * Invalidate cache for specific patterns
 */
const invalidateCache = async (pattern) => {
    try {
        await cacheService.del(pattern);
        console.log(`✅ Cache invalidated: ${pattern}`);
    } catch (error) {
        console.error('Cache invalidation error:', error);
    }
};

/**
 * Invalidate user-specific cache
 */
const invalidateUserCache = async (userId) => {
    await invalidateCache(`*:${userId}:*`);
};

/**
 * Invalidate endpoint cache
 */
const invalidateEndpointCache = async (endpoint) => {
    await invalidateCache(`GET:*:${endpoint}*`);
};

module.exports = {
    cacheMiddleware,
    invalidateCache,
    invalidateUserCache,
    invalidateEndpointCache,
    getCacheKey,
};
