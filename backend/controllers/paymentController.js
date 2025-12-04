const esewaService = require('../services/esewaService');
const Payment = require('../models/Payment');
const Order = require('../models/Order');

/**
 * Payment Controller
 * Handles payment-related operations including eSewa integration
 */

/**
 * Create payment intent for eSewa
 * POST /api/payments/esewa/create
 */
const createEsewaPayment = async (req, res) => {
    try {
        const { orderId, amount, productName } = req.body;
        const userId = req.user.id;

        // Validate required fields
        if (!orderId || !amount) {
            return res.status(400).json({
                success: false,
                message: 'Order ID and amount are required'
            });
        }

        // Validate amount
        if (amount <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Amount must be greater than 0'
            });
        }

        // Check if eSewa is configured
        if (!esewaService.validateConfiguration()) {
            return res.status(503).json({
                success: false,
                message: 'Payment service is not configured'
            });
        }

        // Create payment intent
        const result = await esewaService.createPaymentIntent({
            orderId,
            amount: parseFloat(amount),
            userId,
            productName: productName || 'InduLink Order'
        });

        res.status(201).json({
            success: true,
            data: {
                payment: {
                    id: result.payment._id,
                    transactionId: result.payment.transactionId,
                    amount: result.payment.amount,
                    status: result.payment.status,
                    createdAt: result.payment.createdAt
                },
                paymentUrl: result.paymentUrl
            },
            message: result.message
        });

    } catch (error) {
        console.error('Error creating eSewa payment:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to create payment'
        });
    }
};

/**
 * Handle eSewa payment success callback
 * GET /api/payments/esewa/success
 */
const handleEsewaSuccess = async (req, res) => {
    try {
        const { oid, amt, refId } = req.query;

        // oid = transactionId, amt = amount, refId = eSewa reference
        if (!oid || !amt || !refId) {
            return res.status(400).json({
                success: false,
                message: 'Missing required parameters'
            });
        }

        // Verify payment
        const result = await esewaService.verifyPayment({
            transactionId: oid,
            refId,
            amount: amt
        });

        // Redirect to frontend success page with payment details
        const successUrl = `${process.env.FRONTEND_URL}/payment/success?transactionId=${oid}&status=success`;
        res.redirect(successUrl);

    } catch (error) {
        console.error('Error handling eSewa success:', error);

        // Redirect to frontend failure page
        const failureUrl = `${process.env.FRONTEND_URL}/payment/failure?error=${encodeURIComponent(error.message)}`;
        res.redirect(failureUrl);
    }
};

/**
 * Handle eSewa payment failure callback
 * GET /api/payments/esewa/failure
 */
const handleEsewaFailure = async (req, res) => {
    try {
        const { oid } = req.query; // oid = transactionId

        if (oid) {
            await esewaService.handlePaymentFailure(oid, 'Payment cancelled by user');
        }

        // Redirect to frontend failure page
        const failureUrl = `${process.env.FRONTEND_URL}/payment/failure?transactionId=${oid}&status=failed`;
        res.redirect(failureUrl);

    } catch (error) {
        console.error('Error handling eSewa failure:', error);

        const failureUrl = `${process.env.FRONTEND_URL}/payment/failure?error=payment_failed`;
        res.redirect(failureUrl);
    }
};

/**
 * Get payment status
 * GET /api/payments/:transactionId/status
 */
const getPaymentStatus = async (req, res) => {
    try {
        const { transactionId } = req.params;

        const result = await esewaService.getPaymentStatus(transactionId);

        res.json({
            success: true,
            data: result.payment
        });

    } catch (error) {
        console.error('Error getting payment status:', error);
        res.status(404).json({
            success: false,
            message: error.message || 'Payment not found'
        });
    }
};

/**
 * Get user payments
 * GET /api/payments/user
 */
const getUserPayments = async (req, res) => {
    try {
        const userId = req.user.id;
        const { page = 1, limit = 10, status } = req.query;

        const query = { userId };
        if (status) {
            query.status = status;
        }

        const payments = await Payment.find(query)
            .populate('orderId', 'orderNumber status total')
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await Payment.countDocuments(query);

        res.json({
            success: true,
            data: {
                payments: payments.map(payment => ({
                    id: payment._id,
                    transactionId: payment.transactionId,
                    orderId: payment.orderId?._id,
                    orderNumber: payment.orderId?.orderNumber,
                    amount: payment.amount,
                    paymentMethod: payment.paymentMethod,
                    status: payment.status,
                    createdAt: payment.createdAt,
                    processedAt: payment.processedAt
                })),
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });

    } catch (error) {
        console.error('Error getting user payments:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch payments'
        });
    }
};

/**
 * Process refund
 * POST /api/payments/:paymentId/refund
 */
const processRefund = async (req, res) => {
    try {
        const { paymentId } = req.params;
        const { amount, reason } = req.body;
        const userId = req.user.id;

        // Find payment and verify ownership
        const payment = await Payment.findOne({ _id: paymentId, userId });

        if (!payment) {
            return res.status(404).json({
                success: false,
                message: 'Payment not found'
            });
        }

        if (!payment.canRefund) {
            return res.status(400).json({
                success: false,
                message: 'Payment cannot be refunded'
            });
        }

        const refundAmount = amount || payment.amount;

        if (refundAmount > payment.amount) {
            return res.status(400).json({
                success: false,
                message: 'Refund amount cannot exceed payment amount'
            });
        }

        const result = await esewaService.processRefund(
            paymentId,
            refundAmount,
            reason || 'Customer requested refund'
        );

        res.json({
            success: true,
            data: {
                payment: {
                    id: result.payment._id,
                    transactionId: result.payment.transactionId,
                    status: result.payment.status,
                    refundAmount
                }
            },
            message: result.message
        });

    } catch (error) {
        console.error('Error processing refund:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to process refund'
        });
    }
};

/**
 * Get payment statistics (Admin only)
 * GET /api/payments/stats
 */
const getPaymentStats = async (req, res) => {
    try {
        const stats = await Payment.aggregate([
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 },
                    totalAmount: { $sum: '$amount' }
                }
            }
        ]);

        const totalPayments = await Payment.countDocuments();
        const totalAmount = await Payment.aggregate([
            { $match: { status: 'completed' } },
            { $group: { _id: null, total: { $sum: '$amount' } } }
        ]);

        res.json({
            success: true,
            data: {
                totalPayments,
                totalAmount: totalAmount[0]?.total || 0,
                statusBreakdown: stats.reduce((acc, stat) => {
                    acc[stat._id] = {
                        count: stat.count,
                        amount: stat.totalAmount
                    };
                    return acc;
                }, {})
            }
        });

    } catch (error) {
        console.error('Error getting payment stats:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch payment statistics'
        });
    }
};

module.exports = {
    createEsewaPayment,
    handleEsewaSuccess,
    handleEsewaFailure,
    getPaymentStatus,
    getUserPayments,
    processRefund,
    getPaymentStats
};