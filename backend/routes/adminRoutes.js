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
  // Category Management
  getAllCategories,
  // System Stats
  getSystemStats,
} = require('../controllers/adminController');

const { protect, requireAdmin } = require('../middleware/authMiddleware');
const uploads = require('../middleware/upload');

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

// Upload user profile/avatar
// single file field name: 'avatar'
router.post('/users/:id/avatar', uploads.uploadSingle('avatar'), (req, res, next) => {
  // file available at req.file
  // controller can handle saving file path or you can call a controller here
  res.status(200).json({ message: 'Avatar uploaded', file: req.file });
});

// ==================== PRODUCT MANAGEMENT ROUTES ====================
router.get('/products', getAllProducts);
router.put('/products/:id/approve', approveProduct);
router.put('/products/:id/feature', featureProduct);
router.post('/products/bulk-update', bulkProductUpdate);

// Upload product images
// multiple files field name: 'images', max 10
router.post('/products/:id/images', uploads.uploadMultiple('images', 10), (req, res, next) => {
  // files available at req.files
  res.status(200).json({ message: 'Product images uploaded', files: req.files });
});

// ==================== ORDER MANAGEMENT ROUTES ====================
router.get('/orders', getAllOrders);
router.get('/orders/analytics', getOrderAnalytics);
router.put('/orders/:id/status', updateOrderStatus);

// ==================== REVIEW MANAGEMENT ROUTES ====================
// (Admin may need to upload review images or moderate them)
router.post('/reviews/:id/images', uploads.uploadMultiple('images', 5), (req, res, next) => {
  res.status(200).json({ message: 'Review images uploaded', files: req.files });
});

// ==================== RFQ & MESSAGE ATTACHMENTS ====================
// RFQ attachments: allow images and documents
router.post('/rfq/:id/attachments', uploads.uploadMultiple('attachments', 10), (req, res, next) => {
  res.status(200).json({ message: 'RFQ attachments uploaded', files: req.files });
});

// Message attachments: allow images and documents
router.post('/messages/:id/attachments', uploads.uploadMultiple('attachments', 10), (req, res, next) => {
  res.status(200).json({ message: 'Message attachments uploaded', files: req.files });
});

// ==================== SUPPLIER MANAGEMENT ROUTES ====================
router.get('/suppliers', getAllSuppliers);
router.put('/suppliers/:id/approve', approveSupplier);
router.put('/suppliers/:id/suspend', suspendSupplier);

// ==================== CATEGORY MANAGEMENT ROUTES ====================
router.get('/categories', getAllCategories);

// Optionally allow supplier document uploads (e.g., licenses)
router.post('/suppliers/:id/documents', uploads.uploadMultiple('documents', 5), (req, res, next) => {
  res.status(200).json({ message: 'Supplier documents uploaded', files: req.files });
});

// ==================== DASHBOARD ROUTES ====================
router.get('/dashboard', getSystemStats);

// ==================== SYSTEM STATS ROUTES ====================
router.get('/stats', getSystemStats);

module.exports = router;
