const express = require('express');
const router = express.Router();
const {
    // User Management
    getAllUsers,
    getUserDetails,
    createUser,
    updateUser,
    deleteUser,
    toggleUserStatus,
    // Product Management
    getAllProducts,
    approveProduct,
    featureProduct,
    bulkProductUpdate,
    // Order Management
    getAllOrders,
    getOrderAnalytics,
    updateOrderStatus,
    // Supplier Management
    getAllSuppliers,
    approveSupplier,
    suspendSupplier,
    // System Stats
    getSystemStats,
} = require('../controllers/adminController');
const { protect, requireAdmin } = require('../middleware/authMiddleware');

// All routes require admin authentication
router.use(protect);
router.use(requireAdmin);

// ==================== USER MANAGEMENT ROUTES ====================
router.get('/users', getAllUsers);
router.get('/users/:id', getUserDetails);
router.post('/users', createUser);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);
router.put('/users/:id/toggle-status', toggleUserStatus);

// ==================== PRODUCT MANAGEMENT ROUTES ====================
router.get('/products', getAllProducts);
router.put('/products/:id/approve', approveProduct);
router.put('/products/:id/feature', featureProduct);
router.post('/products/bulk-update', bulkProductUpdate);

// ==================== ORDER MANAGEMENT ROUTES ====================
router.get('/orders', getAllOrders);
router.get('/orders/analytics', getOrderAnalytics);
router.put('/orders/:id/status', updateOrderStatus);

// ==================== SUPPLIER MANAGEMENT ROUTES ====================
router.get('/suppliers', getAllSuppliers);
router.put('/suppliers/:id/approve', approveSupplier);
router.put('/suppliers/:id/suspend', suspendSupplier);

// ==================== SYSTEM STATS ROUTES ====================
router.get('/stats', getSystemStats);

module.exports = router;
