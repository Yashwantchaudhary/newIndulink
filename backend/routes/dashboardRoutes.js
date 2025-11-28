const express = require('express');
const router = express.Router();
const {
    getSupplierDashboard,
    getCustomerDashboard,
    getAdminDashboard,
} = require('../controllers/dashboardController');
const {
    getSalesTrends,
    getProductPerformance,
    getCustomerBehavior,
    getSupplierPerformance,
    getComparativeAnalysis,
    getPredictiveInsights,
    getUserSegmentation,
    exportCSV,
    exportPDF,
} = require('../controllers/analyticsController');
const { protect, requireCustomer, requireSupplier, requireAdmin } = require('../middleware/authMiddleware');

// Dashboard routes
router.get('/supplier', protect, requireSupplier, getSupplierDashboard);
router.get('/customer', protect, requireCustomer, getCustomerDashboard);
router.get('/admin', protect, requireAdmin, getAdminDashboard);

// Analytics routes
router.get('/analytics/sales-trends', protect, getSalesTrends);
router.get('/analytics/product-performance', protect, getProductPerformance);
router.get('/analytics/customer-behavior', protect, getCustomerBehavior);
router.get('/analytics/supplier-performance', protect, getSupplierPerformance);
router.get('/analytics/compare', protect, getComparativeAnalysis);
router.get('/analytics/predictive-insights', protect, getPredictiveInsights);
router.get('/analytics/user-segmentation', protect, getUserSegmentation);
router.get('/analytics/export/csv', protect, exportCSV);
router.get('/analytics/export/pdf', protect, exportPDF);

module.exports = router;

