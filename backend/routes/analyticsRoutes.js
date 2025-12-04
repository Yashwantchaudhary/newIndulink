/// 📊 Analytics Routes
/// API endpoints for analytics and reporting

const express = require('express');
const {
    getUserAnalytics,
    getSalesAnalytics,
    getProductAnalytics,
    getSystemAnalytics,
    getDashboardAnalytics,
    getCustomAnalytics,
    exportAnalyticsReport,
    getAnalyticsConfig
} = require('../controllers/analyticsController');

const { protect, authorize } = require('../middleware/authMiddleware');

const router = express.Router();

// All routes require authentication
router.use(protect);

// Public analytics config
router.get('/config', getAnalyticsConfig);

// Dashboard analytics (role-based)
router.get('/dashboard', getDashboardAnalytics);

// User analytics (Admin only)
router.get('/users', authorize('admin'), getUserAnalytics);

// Sales analytics (Admin and Supplier)
router.get('/sales', authorize('admin', 'supplier'), getSalesAnalytics);

// Product analytics (Admin and Supplier)
router.get('/products', authorize('admin', 'supplier'), getProductAnalytics);

// System analytics (Admin only)
router.get('/system', authorize('admin'), getSystemAnalytics);

// Custom analytics (Admin only)
router.post('/custom', authorize('admin'), getCustomAnalytics);

// Export analytics reports (Admin only)
router.get('/export/:type', authorize('admin'), exportAnalyticsReport);

// Product-specific analytics routes (commented out - functions not implemented)
// router.get('/products/performance', authorize('admin', 'supplier'), getComprehensiveProductAnalytics);
// router.get('/products/trends', authorize('admin', 'supplier'), getProductTrendAnalysis);
// router.post('/products/compare', authorize('admin', 'supplier'), getProductComparisonAnalytics);

module.exports = router;