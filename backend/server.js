require('dotenv').config();

// // Initialize New Relic APM (must be first)
// if (process.env.NEW_RELIC_LICENSE_KEY) {
//     require('newrelic');
// }

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');

const connectDatabase = require('./config/database');
// const { initializeFirebase } = require('./config/firebase'); // Commented out for local testing
const cdnConfig = require('./config/cdn');
const errorHandler = require('./middleware/errorHandler');
const { languageMiddleware } = require('./middleware/languageMiddleware');
const { apiMonitoring } = require('./middleware/apiMonitoring');
const infrastructureMonitor = require('./services/infrastructureMonitor');

// Initialize Express app
const app = express();

// Connect to Database
connectDatabase();

// Initialize Firebase Admin SDK
// initializeFirebase(); // Commented out for local testing without firebase config

// CORS Configuration (must come before other middleware)
const allowedOrigins = process.env.ALLOWED_ORIGINS || '*';

const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests with no origin (like mobile apps, Postman, or cURL)
        if (!origin) return callback(null, true);

        // Allow localhost origins for development (web browsers)
        if (origin && (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:'))) {
            return callback(null, true);
        }

        // If ALLOWED_ORIGINS is '*', allow all origins
        if (allowedOrigins === '*') {
            return callback(null, true);
        }

        // Otherwise, check if origin is in the allowed list
        const allowedList = allowedOrigins.split(',').map(o => o.trim());
        if (allowedList.indexOf(origin) !== -1 || allowedList.includes('*')) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    optionsSuccessStatus: 200,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'X-Request-ID'],
    exposedHeaders: ['Authorization'],
};
app.use(cors(corsOptions));

// Security Middleware (configured for CORS compatibility)
app.use(helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
    crossOriginOpenerPolicy: { policy: "unsafe-none" },
    crossOriginEmbedderPolicy: false,
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "'unsafe-inline'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "http://10.10.9.113:*", "http://localhost:*", "https://10.10.9.113:*", "https://localhost:*"],
            frameAncestors: ["'self'"],
            baseUri: ["'self'"],
            formAction: ["'self'"],
        },
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    }
}));

// Rate Limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});
app.use('/api/', limiter);

// Body Parser Middleware
app.use(express.json({ limit: '10mb', verify: (req, res, buf) => {
  if (req.url.includes('/auth/register')) {
    console.log('Raw register request body:', buf.toString());
  }
} }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Compression Middleware
app.use(compression());

// Logging Middleware
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
} else {
    app.use(morgan('combined'));
}

// Language Middleware (for localization support)
app.use(languageMiddleware);

// API Monitoring Middleware
app.use('/api', apiMonitoring);

// CDN Middleware for setting cache headers
app.use('/uploads', (req, res, next) => {
    // Set CDN cache headers for images
    const headers = cdnConfig.getCacheHeaders('images');
    Object.entries(headers).forEach(([key, value]) => {
        res.setHeader(key, value);
    });
    next();
});

// Static Files (for uploaded images)
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
    maxAge: cdnConfig.cacheSettings.images.maxAge * 1000, // Convert to milliseconds
    etag: true,
    lastModified: true
}));

// Static Files (for monitoring dashboard)
app.use('/monitoring', express.static(path.join(__dirname, 'public'), {
    maxAge: 300000, // 5 minutes cache
    etag: true,
    lastModified: true
}));

// API Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes'));
app.use('/api/cart', require('./routes/cartRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/reviews', require('./routes/reviewRoutes'));
app.use('/api/messages', require('./routes/messageRoutes'));
app.use('/api/dashboard', require('./routes/dashboardRoutes'));
app.use('/api/rfq', require('./routes/rfqRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/wishlist', require('./routes/wishlistRoutes'));
app.use('/api/admin', require('./routes/adminRoutes')); // Admin routes

// Seeding Routes (Admin only - for development/testing)
// app.use('/api/seed', require('./routes/seedingRoutes'));

// CDN Routes for image optimization and cache management
// app.use('/cdn', require('./routes/cdnRoutes'));

// Health Check Route
app.get('/health', (req, res) => {
    const infrastructureReport = infrastructureMonitor.getInfrastructureReport();
    const healthStatus = infrastructureReport.alerts.status;

    res.status(healthStatus.status === 'healthy' ? 200 : 503).json({
        success: healthStatus.status === 'healthy',
        message: `Indulink API is ${healthStatus.status}`,
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV,
        infrastructure: infrastructureReport,
        uptime: process.uptime(),
        memory: process.memoryUsage()
    });
});

// API Metrics Route (for monitoring dashboards)
app.get('/api/metrics', (req, res) => {
    const { getMetricsSummary } = require('./middleware/apiMonitoring');
    const apiMetrics = getMetricsSummary();
    const infrastructureMetrics = infrastructureMonitor.getInfrastructureReport();

    res.status(200).json({
        success: true,
        message: 'System metrics retrieved successfully',
        data: {
            api: apiMetrics,
            infrastructure: infrastructureMetrics,
            timestamp: new Date().toISOString()
        }
    });
});

// Infrastructure Metrics Route (detailed system metrics)
app.get('/api/infrastructure', (req, res) => {
    const report = infrastructureMonitor.getInfrastructureReport();

    res.status(200).json({
        success: true,
        message: 'Infrastructure metrics retrieved successfully',
        data: report
    });
});

// Monitoring Dashboard Route
app.get('/monitoring', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'monitoring-dashboard.html'));
});

// API Root Route
app.get('/api', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Indulink E-commerce API',
        version: '1.0.0',
        endpoints: {
            auth: '/api/auth',
            products: '/api/products',
            categories: '/api/categories',
            cart: '/api/cart',
            orders: '/api/orders',
            users: '/api/users',
        },
    });
});

// Root Route
app.get('/', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Welcome to Indulink E-commerce API',
        version: '1.0.0',
        documentation: '/api/docs',
    });
});

// 404 Handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found',
        path: req.originalUrl,
    });
});

// Error Handler Middleware (must be last)
app.use(errorHandler);

// Start Server
const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║   🚀  Indulink E-commerce API Server                 ║
║                                                       ║
║   ✓ Server running on port ${PORT} (0.0.0.0)           ║
║   ✓ Environment: ${process.env.NODE_ENV || 'development'}                    ║
║   ✓ API Base: http://localhost:${PORT}/api           ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
  `);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
    console.error(`❌ Unhandled Promise Rejection: ${err.message}`);
    server.close(() => process.exit(1));
});

module.exports = app;
