const express = require('express');
const router = express.Router();

// Import controllers
const {
    createEsewaPayment,
    handleEsewaSuccess,
    handleEsewaFailure,
    getPaymentStatus,
    getUserPayments,
    processRefund,
    getPaymentStats
} = require('../controllers/paymentController');

// Import middleware
const { protect: authenticate } = require('../middleware/authMiddleware');
const { rbacMiddleware } = require('../middleware/rbacMiddleware');

// ==================== eSewa Payment Routes ====================

/**
 * @route   POST /api/payments/esewa/create
 * @desc    Create eSewa payment intent
 * @access  Private (Authenticated users)
 */
router.post('/esewa/create', authenticate, createEsewaPayment);

/**
 * @route   GET /api/payments/esewa/success
 * @desc    Handle eSewa payment success callback
 * @access  Public (eSewa callback)
 */
router.get('/esewa/success', handleEsewaSuccess);

/**
 * @route   GET /api/payments/esewa/failure
 * @desc    Handle eSewa payment failure callback
 * @access  Public (eSewa callback)
 */
router.get('/esewa/failure', handleEsewaFailure);

// ==================== Payment Management Routes ====================

/**
 * @route   GET /api/payments/:transactionId/status
 * @desc    Get payment status by transaction ID
 * @access  Private (Payment owner or admin)
 */
router.get('/:transactionId/status', authenticate, getPaymentStatus);

/**
 * @route   GET /api/payments/user
 * @desc    Get user's payment history
 * @access  Private (Authenticated users)
 */
router.get('/user', authenticate, getUserPayments);

/**
 * @route   POST /api/payments/:paymentId/refund
 * @desc    Process payment refund
 * @access  Private (Payment owner or admin)
 */
router.post('/:paymentId/refund', authenticate, processRefund);

// ==================== Admin Routes ====================

/**
 * @route   GET /api/payments/stats
 * @desc    Get payment statistics
 * @access  Private (Admin only)
 */
router.get('/stats', authenticate, rbacMiddleware([], ['admin', 'superadmin']), getPaymentStats);

module.exports = router;