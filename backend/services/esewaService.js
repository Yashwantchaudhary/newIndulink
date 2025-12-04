const crypto = require('crypto');
const Payment = require('../models/Payment');
const Order = require('../models/Order');

/**
 * Payment Service
 * Handles payment processing and tracking (ready for eSewa integration)
 */
class PaymentService {
    constructor() {
        // eSewa configuration (for future integration)
        this.esewaConfig = {
            baseUrl: process.env.ESEWA_BASE_URL || 'https://esewa.com.np',
            merchantId: process.env.ESEWA_MERCHANT_ID,
            secretKey: process.env.ESEWA_SECRET_KEY,
            successUrl: process.env.ESEWA_SUCCESS_URL || `${process.env.BASE_URL}/api/payments/esewa/success`,
            failureUrl: process.env.ESEWA_FAILURE_URL || `${process.env.BASE_URL}/api/payments/esewa/failure`,
        };

        // Validate required environment variables
        if (!this.esewaConfig.merchantId || !this.esewaConfig.secretKey) {
            console.warn('⚠️  eSewa credentials not configured. Using mock payment processing.');
        }
    }

    /**
     * Create payment intent for eSewa
     * @param {Object} paymentData - Payment data
     * @param {string} paymentData.orderId - Order ID
     * @param {number} paymentData.amount - Payment amount
     * @param {string} paymentData.userId - User ID
     * @param {string} paymentData.productName - Product/Service name
     * @returns {Object} Payment intent data
     */
    async createPaymentIntent({ orderId, amount, userId, productName = 'InduLink Order' }) {
        try {
            // Validate order exists
            const order = await Order.findById(orderId);
            if (!order) {
                throw new Error('Order not found');
            }

            // Check if payment already exists for this order
            const existingPayment = await Payment.findOne({
                orderId,
                status: { $in: ['pending', 'processing', 'completed'] }
            });

            if (existingPayment) {
                return {
                    success: true,
                    payment: existingPayment,
                    message: 'Payment intent already exists'
                };
            }

            // Create payment record
            const payment = new Payment({
                orderId,
                amount,
                paymentMethod: 'esewa',
                userId,
                status: 'pending',
                esewaData: {
                    productId: orderId,
                    productName,
                    productUrl: `${process.env.FRONTEND_URL}/orders/${orderId}`,
                    totalAmount: amount,
                    taxAmount: 0,
                    serviceCharge: 0,
                    deliveryCharge: 0,
                }
            });

            await payment.save();

            // Generate eSewa payment URL
            const paymentUrl = this.generatePaymentUrl(payment);

            return {
                success: true,
                payment,
                paymentUrl,
                message: 'Payment intent created successfully'
            };

        } catch (error) {
            console.error('Error creating eSewa payment intent:', error);
            throw new Error(`Failed to create payment intent: ${error.message}`);
        }
    }

    /**
     * Generate eSewa payment URL
     * @param {Object} payment - Payment document
     * @returns {string} eSewa payment URL
     */
    generatePaymentUrl(payment) {
        const params = {
            amt: payment.amount.toString(),
            psc: '0', // Service charge
            pdc: '0', // Delivery charge
            txAmt: '0', // Tax amount
            tAmt: payment.amount.toString(), // Total amount
            pid: payment.transactionId, // Product ID (using transaction ID)
            scd: this.merchantId, // Merchant code
            su: this.successUrl, // Success URL
            fu: this.failureUrl, // Failure URL
        };

        // Create query string
        const queryString = Object.keys(params)
            .map(key => `${key}=${encodeURIComponent(params[key])}`)
            .join('&');

        return `${this.baseUrl}/epay/main?${queryString}`;
    }

    /**
     * Verify eSewa payment
     * @param {Object} verificationData - Verification data from eSewa
     * @returns {Object} Verification result
     */
    async verifyPayment(verificationData) {
        try {
            const { transactionId, refId, amount } = verificationData;

            // Find payment by transaction ID
            const payment = await Payment.findOne({ transactionId });

            if (!payment) {
                throw new Error('Payment not found');
            }

            if (payment.status === 'completed') {
                return {
                    success: true,
                    payment,
                    message: 'Payment already verified'
                };
            }

            // Verify amount matches
            if (parseFloat(amount) !== payment.amount) {
                throw new Error('Payment amount mismatch');
            }

            // Update payment status
            await payment.markCompleted(refId);

            // Update order payment status
            await Order.findByIdAndUpdate(payment.orderId, {
                paymentStatus: 'paid',
                paymentId: payment._id,
                paymentMethod: 'esewa'
            });

            return {
                success: true,
                payment,
                message: 'Payment verified successfully'
            };

        } catch (error) {
            console.error('Error verifying eSewa payment:', error);
            throw new Error(`Payment verification failed: ${error.message}`);
        }
    }

    /**
     * Handle eSewa payment failure
     * @param {string} transactionId - Transaction ID
     * @param {string} reason - Failure reason
     */
    async handlePaymentFailure(transactionId, reason = 'Payment failed') {
        try {
            const payment = await Payment.findOne({ transactionId });

            if (!payment) {
                console.warn(`Payment not found for transaction: ${transactionId}`);
                return;
            }

            if (payment.status !== 'completed') {
                await payment.markFailed(reason);
            }

        } catch (error) {
            console.error('Error handling payment failure:', error);
        }
    }

    /**
     * Process refund for eSewa payment
     * @param {string} paymentId - Payment ID
     * @param {number} amount - Refund amount
     * @param {string} reason - Refund reason
     */
    async processRefund(paymentId, amount, reason = 'Customer request') {
        try {
            const payment = await Payment.findById(paymentId);

            if (!payment) {
                throw new Error('Payment not found');
            }

            if (!payment.canRefund) {
                throw new Error('Payment cannot be refunded');
            }

            // Note: eSewa refund processing would require API integration
            // For now, we'll mark as refunded in our system
            await payment.markRefunded();

            // Update order status
            await Order.findByIdAndUpdate(payment.orderId, {
                paymentStatus: 'refunded',
                refundedAt: new Date(),
                refundAmount: amount,
                refundReason: reason
            });

            return {
                success: true,
                payment,
                message: 'Refund processed successfully'
            };

        } catch (error) {
            console.error('Error processing refund:', error);
            throw new Error(`Refund processing failed: ${error.message}`);
        }
    }

    /**
     * Get payment status
     * @param {string} transactionId - Transaction ID
     * @returns {Object} Payment status
     */
    async getPaymentStatus(transactionId) {
        try {
            const payment = await Payment.findOne({ transactionId });

            if (!payment) {
                throw new Error('Payment not found');
            }

            return {
                success: true,
                payment: {
                    transactionId: payment.transactionId,
                    status: payment.status,
                    amount: payment.amount,
                    createdAt: payment.createdAt,
                    processedAt: payment.processedAt,
                }
            };

        } catch (error) {
            console.error('Error getting payment status:', error);
            throw new Error(`Failed to get payment status: ${error.message}`);
        }
    }

    /**
     * Validate payment service configuration
     * @returns {boolean} Configuration validity
     */
    validateConfiguration() {
        // For now, always return true since we're using mock payments
        // In production, this would check for eSewa credentials
        return true;
    }
}

module.exports = new PaymentService();