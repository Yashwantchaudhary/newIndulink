const express = require('express');
const router = express.Router();
const {
    // Product Management
    getMyProducts,
    createProduct,
    updateProduct,
    deleteProduct,
    // Order Management
    getSupplierOrders,
    updateOrderStatus,
    getOrderDetails,
    // Analytics
    getSupplierAnalytics,
    getSalesReport,
    // Profile Management
    updateSupplierProfile,
} = require('../controllers/supplierController');
const { getSupplierDashboard } = require('../controllers/dashboardController');
const { protect, requireSupplier } = require('../middleware/authMiddleware');
const { uploadMultiple, uploadSingle, compressProductImages, compressProfileImages } = require('../middleware/upload');

// All supplier routes require authentication and supplier role
router.use(protect);
router.use(requireSupplier);

// ==================== PRODUCT MANAGEMENT ====================
router.get('/products', getMyProducts);
router.post('/products', uploadMultiple('images', 5), compressProductImages, createProduct);
router.put('/products/:id', uploadMultiple('images', 5), compressProductImages, updateProduct);
router.delete('/products/:id', deleteProduct);

// ==================== ORDER MANAGEMENT ====================
router.get('/orders', getSupplierOrders);
router.get('/orders/:id', getOrderDetails);
router.put('/orders/:id/status', updateOrderStatus);

// ==================== ANALYTICS & REPORTS ====================
router.get('/analytics', getSupplierAnalytics);
router.get('/reports/sales', getSalesReport);

// ==================== DASHBOARD ====================
router.get('/dashboard', getSupplierDashboard);

// ==================== PROFILE MANAGEMENT ====================
router.put('/profile', uploadSingle('logo'), compressProfileImages, updateSupplierProfile);

// ==================== FILE UPLOADS ====================
// Product images (handled in product routes above)
// Profile logo (handled in profile route above)
// Additional documents
router.post('/documents', uploadMultiple('documents', 5), (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Documents uploaded successfully',
        files: req.files
    });
});

module.exports = router;