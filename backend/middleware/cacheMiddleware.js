// middleware/cache.js
'use strict';

const cacheService = require('../services/cacheService');
const crypto = require('crypto');

/**
 * Generate cache key from request
 * - Normalizes query params order
 * - Includes user id (if present) to support per-user caches
 * - Hashes long URLs to keep keys short
 */
const getCacheKey = (req) => {
  const method = (req.method || 'GET').toUpperCase();
  const userId = req.user ? (req.user.id || req.user._id || 'user') : 'anonymous';

  // Normalize URL: path + sorted query string
  const url = req.originalUrl || req.url || req.path || '/';
  const [path, rawQuery] = url.split('?');
  let normalizedQuery = '';
  if (rawQuery) {
    const params = new URLSearchParams(rawQuery);
    const entries = Array.from(params.entries()).sort(([a], [b]) => a.localeCompare(b));
    normalizedQuery = entries.map(([k, v]) => `${k}=${v}`).join('&');
  }

  const base = `${method}:${userId}:${path}${normalizedQuery ? '?' + normalizedQuery : ''}`;

  // If base is long, hash it to keep Redis key length reasonable
  if (base.length > 200) {
    const hash = crypto.createHash('sha256').update(base).digest('hex').slice(0, 16);
    return `${method}:${userId}:${path}:hash:${hash}`;
  }

  return base;
};

/**
 * Cache middleware factory
 * options:
 *  - ttl: seconds (default 300)
 *  - tags: function(req, resData) => array of tags to associate with this cache entry (optional)
 *  - bypassHeader: header name to bypass cache (default 'x-cache-bypass')
 */
const cacheMiddleware = (options = {}) => {
  const {
    ttl = 300,
    tags = null,
    bypassHeader = 'x-cache-bypass',
    cacheStatusHeader = 'X-Cache'
  } = options;

  return async (req, res, next) => {
    try {
      // Only cache GET requests
      if (req.method !== 'GET') return next();

      // Allow clients to bypass cache
      if (req.headers && req.headers[bypassHeader]) {
        res.setHeader(cacheStatusHeader, 'BYPASS');
        return next();
      }

      const key = getCacheKey(req);

      // Try to read from cache
      const cached = await cacheService.get(key);
      if (cached !== null && typeof cached !== 'undefined') {
        // Return cached response
        res.setHeader(cacheStatusHeader, 'HIT');
        // If cached contains status and headers, use them
        if (cached && cached.__meta) {
          const { status = 200, headers = {}, body } = cached.__meta;
          // set headers (avoid overwriting essential headers)
          for (const [h, v] of Object.entries(headers)) {
            try { res.setHeader(h, v); } catch (e) { /* ignore invalid headers */ }
          }
          return res.status(status).json(body);
        }
        // Fallback: assume cached is body
        return res.status(200).json(cached);
      }

      // Cache miss: override res.send/res.json to capture response
      res.setHeader(cacheStatusHeader, 'MISS');

      const originalSend = res.send.bind(res);

      let bodyBuffer = null;
      let capturedStatus = 200;
      let capturedHeaders = {};

      // Wrap res.send to capture body
      res.send = function (body) {
        try {
          capturedStatus = res.statusCode || capturedStatus;
          // capture headers (shallow copy)
          capturedHeaders = {};
          for (const [k, v] of Object.entries(res.getHeaders ? res.getHeaders() : {})) {
            capturedHeaders[k] = v;
          }

          // Only cache JSON or stringifiable responses and successful status codes
          const contentType = (res.getHeader && res.getHeader('content-type')) || '';
          const isJson = contentType.includes('application/json') || typeof body === 'object';

          if (capturedStatus >= 200 && capturedStatus < 300 && isJson) {
            // Normalize body to JSON object
            const bodyObj = typeof body === 'string' ? tryParseJson(body) : body;
            const meta = {
              __meta: {
                status: capturedStatus,
                headers: capturedHeaders,
                body: bodyObj
              }
            };

            // Determine tags (if tags function provided)
            const entryTags = typeof tags === 'function' ? safeCallTags(tags, req, bodyObj) : [];

            // Fire-and-forget set
            cacheService.set(key, meta, ttl, entryTags).catch(err => {
              console.error('cache set failed:', err && err.message ? err.message : err);
            });
          }
        } catch (err) {
          console.error('Error capturing response for cache:', err && err.message ? err.message : err);
        }

        // Call original send
        return originalSend(body);
      };

      return next();
    } catch (err) {
      console.error('Cache middleware error:', err && err.message ? err.message : err);
      return next();
    }
  };
};

/**
 * Helpers
 */
function tryParseJson(str) {
  try {
    return JSON.parse(str);
  } catch {
    return str;
  }
}

function safeCallTags(tagsFn, req, body) {
  try {
    const result = tagsFn(req, body);
    if (!Array.isArray(result)) return [];
    return result.filter(Boolean).map(String);
  } catch (err) {
    console.error('tags function error:', err && err.message ? err.message : err);
    return [];
  }
}

/**
 * Invalidate cache helpers
 */
const invalidateCache = async (pattern) => {
  try {
    const deleted = await cacheService.delPattern(pattern);
    console.log(`✅ Cache invalidated pattern=${pattern} deleted=${deleted}`);
  } catch (err) {
    console.error('Cache invalidation error:', err && err.message ? err.message : err);
  }
};

const invalidateUserCache = async (userId) => {
  if (!userId) return;
  // pattern: METHOD:userId:/path...
  await invalidateCache(`*:${userId}:*`);
};

const invalidateEndpointCache = async (endpointPath) => {
  if (!endpointPath) return;
  // pattern: GET:*:/api/products*
  await invalidateCache(`GET:*:${endpointPath}*`);
};

const invalidateTag = async (tag) => {
  try {
    await cacheService.invalidateTag(tag);
    console.log(`✅ Cache invalidated tag=${tag}`);
  } catch (err) {
    console.error('Tag invalidation error:', err && err.message ? err.message : err);
  }
};

module.exports = {
  cacheMiddleware,
  getCacheKey,
  invalidateCache,
  invalidateUserCache,
  invalidateEndpointCache,
  invalidateTag
};
