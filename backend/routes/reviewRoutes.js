const express = require('express');
const router = express.Router();
const {
    getProductReviews,
    createReview,
    updateReview,
    deleteReview,
    markReviewHelpful,
    addSupplierResponse,
    getReviewStats,
    getUserReviewStats,
} = require('../controllers/reviewController');
const { protect, requireCustomer, requireSupplier } = require('../middleware/authMiddleware');
const { uploadMultiple } = require('../middleware/upload');

// Public route - get product reviews
router.get('/product/:productId', getProductReviews);

// Customer routes
router.post('/', protect, requireCustomer, uploadMultiple('images', 3), createReview);
router.put('/:id', protect, requireCustomer, updateReview);
router.delete('/:id', protect, requireCustomer, deleteReview);

// Any authenticated user can mark as helpful
router.put('/:id/helpful', protect, markReviewHelpful);

// Supplier routes
router.put('/:id/response', protect, requireSupplier, addSupplierResponse);

// Stats routes
router.get('/stats', getReviewStats);
router.get('/stats/user/:userId', protect, getUserReviewStats);

module.exports = router;
