const express = require('express');
const router = express.Router();
const {
    getSupplierDashboard,
    getCustomerDashboard,
    getAdminDashboard,
} = require('../controllers/dashboardController');
const {
    getSalesAnalytics,
    getProductAnalytics,
    getUserAnalytics,
    getSystemAnalytics,
    getDashboardAnalytics,
    exportAnalyticsReport,
} = require('../controllers/analyticsController');
const { protect, requireCustomer, requireSupplier, requireAdmin } = require('../middleware/authMiddleware');

// Dashboard routes
router.get('/supplier', protect, requireSupplier, getSupplierDashboard);
router.get('/customer', protect, requireCustomer, getCustomerDashboard);
router.get('/admin', protect, requireAdmin, getAdminDashboard);

// Analytics routes
router.get('/analytics/sales', protect, getSalesAnalytics);
router.get('/analytics/products', protect, getProductAnalytics);
router.get('/analytics/users', protect, getUserAnalytics);
router.get('/analytics/system', protect, getSystemAnalytics);
router.get('/analytics/dashboard', protect, getDashboardAnalytics);
router.get('/analytics/export/:type', protect, exportAnalyticsReport);

module.exports = router;

