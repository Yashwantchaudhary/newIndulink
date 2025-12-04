const express = require('express');
const router = express.Router();
const {
    createOrder,
    getCustomerOrders,
    getSupplierOrders,
    getOrder,
    updateOrderStatus,
    approveOrder,
    rejectOrder,
    cancelOrder,
    getOrderStats,
    getSupplierOrderStats,
    searchOrders,
    bulkUpdateOrderStatus,
    exportOrders,
    updateOrderTracking,
    processRefund,
    getOrderAnalytics
} = require('../controllers/orderController');
const { protect, requireCustomer, requireSupplier, requireAdmin } = require('../middleware/authMiddleware');

// Customer routes
router.post('/', protect, requireCustomer, createOrder);
router.get('/', protect, requireCustomer, getCustomerOrders);
router.put('/:id/cancel', protect, requireCustomer, cancelOrder);

// Supplier routes
router.get('/supplier', protect, requireSupplier, getSupplierOrders);
router.put('/:id/status', protect, requireSupplier, updateOrderStatus);
router.put('/:id/approve', protect, requireSupplier, approveOrder);
router.put('/:id/reject', protect, requireSupplier, rejectOrder);

// Common routes (both customer and supplier can view)
router.get('/:id', protect, getOrder);

// Admin and analytics routes
router.get('/stats', protect, requireAdmin, getOrderStats);
router.get('/stats/supplier/:supplierId', protect, requireAdmin, getSupplierOrderStats);
router.get('/search', protect, searchOrders);
router.put('/bulk/status', protect, requireAdmin, bulkUpdateOrderStatus);
router.get('/export', protect, requireAdmin, exportOrders);
router.put('/:id/tracking', protect, requireSupplier, updateOrderTracking);
router.put('/:id/refund', protect, requireAdmin, processRefund);
router.get('/analytics', protect, requireAdmin, getOrderAnalytics);

module.exports = router;
