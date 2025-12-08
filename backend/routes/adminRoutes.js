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
  getAdminAnalytics,
  getCartAnalytics,
} = require('../controllers/adminController');

// Import product controller functions
const {
  getProduct: getProductDetails,
  createProduct: createProductAdmin,
  updateProduct: updateProductAdmin,
  deleteProduct: deleteProductAdmin
} = require('../controllers/productController');

// Import category controller functions
const {
  getCategories: getAllCategoriesForAdmin,
  getCategory: getCategoryDetails,
  createCategory: createCategoryAdmin,
  updateCategory: updateCategoryAdmin,
  deleteCategory: deleteCategoryAdmin,
  getCategoryStats
} = require('../controllers/categoryController');

// Import review controller functions
const {
  getAllReviews,
  getReviewById,
  approveReview,
  rejectReview,
  deleteReview
} = require('../controllers/reviewController');

// Import order controller functions
const {
  getOrderById,
  deleteOrder
} = require('../controllers/orderController');

// Import RFQ controller functions
const {
  getRFQById,
  updateRFQStatus,
  deleteRFQ
} = require('../controllers/rfqController');

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
router.post('/users/:id/avatar', uploads.uploadSingle('avatar'), (req, res, next) => {
  res.status(200).json({ message: 'Avatar uploaded', file: req.file });
});

// ==================== PRODUCT MANAGEMENT ROUTES (FULL CRUD) ====================
router.get('/products', getAllProducts);
router.get('/products/:id', getProductDetails);
router.post('/products', uploads.uploadMultiple('images', 10), createProductAdmin);
router.put('/products/:id', uploads.uploadMultiple('images', 10), updateProductAdmin);
router.delete('/products/:id', deleteProductAdmin);
router.put('/products/:id/approve', approveProduct);
router.put('/products/:id/feature', featureProduct);
router.post('/products/bulk-update', bulkProductUpdate);

// Upload product images
router.post('/products/:id/images', uploads.uploadMultiple('images', 10), (req, res, next) => {
  res.status(200).json({ message: 'Product images uploaded', files: req.files });
});

// ==================== ORDER MANAGEMENT ROUTES (FULL CRUD) ====================
router.get('/orders', getAllOrders);
router.get('/orders/analytics', getOrderAnalytics);
router.get('/orders/:id', getOrderById);
router.put('/orders/:id/status', updateOrderStatus);
router.delete('/orders/:id', deleteOrder);

// ==================== REVIEW MANAGEMENT ROUTES (FULL CRUD) ====================
router.get('/reviews', getAllReviews);
router.get('/reviews/:id', getReviewById);
router.put('/reviews/:id/approve', approveReview);
router.put('/reviews/:id/reject', rejectReview);
router.delete('/reviews/:id', deleteReview);

// Upload review images
router.post('/reviews/:id/images', uploads.uploadMultiple('images', 5), (req, res, next) => {
  res.status(200).json({ message: 'Review images uploaded', files: req.files });
});

// ==================== RFQ MANAGEMENT ROUTES (FULL CRUD) ====================
router.get('/rfq', (req, res, next) => {
  // Admin sees all RFQs - use existing getRFQs from rfqController
  next();
});
router.get('/rfq/:id', getRFQById);
router.put('/rfq/:id/status', updateRFQStatus);
router.delete('/rfq/:id', deleteRFQ);

// RFQ attachments
router.post('/rfq/:id/attachments', uploads.uploadMultiple('attachments', 10), (req, res, next) => {
  res.status(200).json({ message: 'RFQ attachments uploaded', files: req.files });
});

// ==================== SUPPLIER MANAGEMENT ROUTES ====================
router.get('/suppliers', getAllSuppliers);
router.get('/suppliers/:id', getUserDetails); // Reuse getUserDetails
router.put('/suppliers/:id/approve', approveSupplier);
router.put('/suppliers/:id/suspend', suspendSupplier);
router.delete('/suppliers/:id', deleteUser); // Reuse deleteUser

// Supplier document uploads
router.post('/suppliers/:id/documents', uploads.uploadMultiple('documents', 5), (req, res, next) => {
  res.status(200).json({ message: 'Supplier documents uploaded', files: req.files });
});

// ==================== CATEGORY MANAGEMENT ROUTES (FULL CRUD) ====================
router.get('/categories', getAllCategoriesForAdmin);
router.get('/categories/stats', getCategoryStats);
router.get('/categories/:id', getCategoryDetails);
router.post('/categories', createCategoryAdmin);
router.put('/categories/:id', updateCategoryAdmin);
router.delete('/categories/:id', deleteCategoryAdmin);

// ==================== MESSAGE ATTACHMENTS ====================
router.post('/messages/:id/attachments', uploads.uploadMultiple('attachments', 10), (req, res, next) => {
  res.status(200).json({ message: 'Message attachments uploaded', files: req.files });
});

// ==================== DASHBOARD ROUTES ====================
router.get('/dashboard', getSystemStats);

// ==================== ANALYTICS ROUTES ====================
router.get('/analytics', getAdminAnalytics);
router.get('/carts/analytics', getCartAnalytics);

// ==================== SYSTEM STATS ROUTES ====================
router.get('/stats', getSystemStats);

module.exports = router;
