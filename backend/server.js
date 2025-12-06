require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');

const connectDatabase = require('./config/database');
const errorHandler = require('./middleware/errorHandler');
const { languageMiddleware } = require('./middleware/languageMiddleware');
const {
    authRateLimiter,
    registerRateLimiter,
    passwordResetRateLimiter,
    securityHeaders,
    securityCors
} = require('./middleware/securityMiddleware');

// Initialize Express app
const app = express();
const http = require('http');
const server = http.createServer(app);
const { Server } = require('socket.io');

const io = new Server(server, {
    cors: {
        origin: ["http://localhost:3000", "http://127.0.0.1:3000", "*"], // Allow all for Flutter app
        methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
        credentials: true
    }
});

// Socket.io connection handler
io.on('connection', (socket) => {
    console.log(`🔌 New client connected: ${socket.id}`);

    // Join user-specific room if authenticated (client should emit 'join' event)
    socket.on('join', (userId) => {
        if (userId) {
            socket.join(`user_${userId}`);
            console.log(`👤 Socket ${socket.id} joined room: user_${userId}`);
        }
    });

    socket.on('disconnect', () => {
        console.log(`❌ Client disconnected: ${socket.id}`);
    });
});

// Make io available in routes
app.use((req, res, next) => {
    req.io = io;
    next();
});

// Connect to Database
connectDatabase();


// CORS Configuration
app.use(cors());

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

// Enhanced Security Middleware
app.use(securityHeaders);
app.use(securityCors);

// Enhanced Rate Limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});
app.use('/api/', limiter);

// Specific rate limiting for auth routes
app.use('/api/auth/register', registerRateLimiter);
app.use('/api/auth/login', authRateLimiter);
app.use('/api/auth/forgot-password', passwordResetRateLimiter);
app.use('/api/auth/reset-password', passwordResetRateLimiter);

// Body Parser Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging Middleware
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
} else {
    app.use(morgan('combined'));
}

// Language Middleware (for localization support)
app.use(languageMiddleware);


// Static Files (for uploaded images)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));


// ==================== API ROUTES BY ROLE ====================

// 🔐 Authentication Routes (Public)
app.use('/api/auth', require('./routes/authRoutes'));

// 👥 General/User Routes (Authenticated)
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes'));
app.use('/api/reviews', require('./routes/reviewRoutes'));
app.use('/api/messages', require('./routes/messageRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/wishlist', require('./routes/wishlistRoutes'));
app.use('/api/addresses', require('./routes/addressRoutes'));

// 🔍 Filter Routes (Public)
app.use('/api/filters', require('./routes/filterRoutes'));

// 🛒 Customer Routes (Customer + Admin)
app.use('/api/cart', require('./routes/cartRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));

// 🏭 Supplier Routes (Supplier + Admin)
app.use('/api/supplier', require('./routes/supplierRoutes'));

// 📊 Dashboard Routes (Role-based)
app.use('/api/dashboard', require('./routes/dashboardRoutes'));

// 📋 RFQ Routes (All authenticated users)
app.use('/api/rfq', require('./routes/rfqRoutes'));

// 👨‍💼 Admin Routes (Admin only)
app.use('/api/admin', require('./routes/adminRoutes'));

// 👥 Enhanced User Management Routes (Admin only)
app.use('/api/admin/users', require('./routes/userManagementRoutes'));

// 📊 Export/Import Routes (Authenticated users)
app.use('/api/export', require('./routes/exportRoutes'));

// 📈 Analytics Routes (Authenticated users)
app.use('/api/analytics', require('./routes/analyticsRoutes'));

// 💳 Payment Routes (Various access levels)
app.use('/api/payments', require('./routes/paymentRoutes'));

// Seeding Routes (Admin only - for development/testing)
app.use('/api/seed', require('./routes/seedingRoutes'));

// 📤 Upload Routes (Authenticated users)
app.use('/api/upload', require('./routes/uploadRoutes'));


// Health Check Route
app.get('/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Indulink API is healthy',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV,
        uptime: process.uptime(),
        memory: process.memoryUsage()
    });
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
server.listen(PORT, '0.0.0.0', () => {
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
    process.exit(1);
});

module.exports = app;
