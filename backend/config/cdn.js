// CDN Configuration for image caching and optimization
const cdnConfig = {
    // Cache settings for different content types
    cacheSettings: {
        images: {
            maxAge: 86400, // 24 hours in seconds
            cacheControl: 'public, max-age=86400, immutable',
            etag: true,
            lastModified: true
        },
        documents: {
            maxAge: 3600, // 1 hour
            cacheControl: 'public, max-age=3600',
            etag: true,
            lastModified: true
        },
        static: {
            maxAge: 31536000, // 1 year
            cacheControl: 'public, max-age=31536000, immutable',
            etag: true,
            lastModified: true
        }
    },

    // CDN headers for different content types
    getCacheHeaders: function(contentType) {
        const settings = this.cacheSettings[contentType] || this.cacheSettings.static;
        return {
            'Cache-Control': settings.cacheControl,
            'ETag': settings.etag,
            'Last-Modified': settings.lastModified,
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'X-XSS-Protection': '1; mode=block'
        };
    },

    // Image optimization settings
    imageOptimization: {
        formats: ['webp', 'avif', 'jpg', 'png'],
        qualities: {
            webp: 85,
            avif: 80,
            jpg: 85,
            png: 90
        },
        sizes: [320, 640, 1024, 1920]
    },

    // CDN provider settings (for future use)
    provider: {
        name: 'local', // 'cloudflare', 'aws', 'local'
        baseUrl: process.env.CDN_BASE_URL || '',
        apiKey: process.env.CDN_API_KEY || ''
    }
};

module.exports = cdnConfig;