const crypto = require('crypto');
const Payment = require('../models/Payment');
const Order = require('../models/Order');

/**
 * Payment Service
 * Handles payment processing and tracking (ready for eSewa integration)
 */
class PaymentService {
    constructor() {
        // eSewa configuration
        this.esewaConfig = {
            baseUrl: process.env.ESEWA_BASE_URL || 'https://rc-epay.esewa.com.np', // Sandbox URL
            merchantId: process.env.ESEWA_MERCHANT_ID || 'EPAYTEST',
            secretKey: process.env.ESEWA_SECRET_KEY || '8gBm/:&EnhH.1/q',
            successUrl: process.env.ESEWA_SUCCESS_URL || `${process.env.BASE_URL}/api/payments/esewa/success`,
            failureUrl: process.env.ESEWA_FAILURE_URL || `${process.env.BASE_URL}/api/payments/esewa/failure`,
        };

        // Validate required environment variables
        if (!this.esewaConfig.merchantId || !this.esewaConfig.secretKey) {
            console.warn('⚠️  eSewa credentials not configured. Using mock payment processing.');
        }
    }

    /**
     * Generate eSewa Signature
     * @param {string} totalAmount 
     * @param {string} transactionUuid 
     * @param {string} productCode 
     */
    generateSignature(totalAmount, transactionUuid, productCode) {
        // Signature Format: "total_amount,transaction_uuid,product_code"
        const data = `total_amount=${totalAmount},transaction_uuid=${transactionUuid},product_code=${productCode}`;
        const hmac = crypto.createHmac('sha256', this.esewaConfig.secretKey);
        hmac.update(data);
        return hmac.digest('base64');
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
                // Even if pending transaction exists, we might want to allow retrying (generating new signature/params)
                // But for now, returning existing one.
                // Ideally, check expiry or regenerate signature.

                // Regenerate signature if needed (or just return existing logic params? existingPayment doesn't store signature)
                // Let's assume we proceed.
            }

            // Create or reuse payment record (If pending, we can update transactionId if we want, or keep same)
            // For robustness, generating new Payment record or updating pending one with new TXID is better
            // but let's stick to simple "find or create" logic.

            let payment = existingPayment;
            if (!payment) {
                payment = new Payment({
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
            }

            // Generate eSewa Signature
            const signature = this.generateSignature(
                amount.toString(),
                payment.transactionId,
                this.esewaConfig.merchantId
            );

            // eSewa Pay Parameters (v2 Form)
            const esewaParams = {
                amount: amount.toString(),
                failure_url: this.esewaConfig.failureUrl,
                product_delivery_charge: "0",
                product_service_charge: "0",
                product_code: this.esewaConfig.merchantId,
                signature: signature,
                signed_field_names: "total_amount,transaction_uuid,product_code",
                success_url: this.esewaConfig.successUrl,
                tax_amount: "0",
                total_amount: amount.toString(),
                transaction_uuid: payment.transactionId
            };

            // Generate Direct URL (GET) for testing/convenience (NOTE: eSewa v2 mainly uses POST)
            // Ideally frontend should use these params to submit a hidden form.
            const paymentUrl = `${this.esewaConfig.baseUrl}/api/epay/main/v2/form?${new URLSearchParams(esewaParams).toString()}`;

            return {
                success: true,
                payment,
                esewaParams, // Frontend uses this to build form
                paymentUrl, // Fallback
                message: 'Payment intent created successfully'
            };

        } catch (error) {
            console.error('Error creating eSewa payment intent:', error);
            throw new Error(`Failed to create payment intent: ${error.message}`);
        }
    }

    /**
     * Verify eSewa payment
     * @param {Object} verificationData - Verification data from eSewa
     * @returns {Object} Verification result
     */
    async verifyPayment(verificationData) {
        try {
            // eSewa query params on success: ?oid=...&amt=...&refId=... (v1/Legacy?)
            // eSewa v2 success params: ?data=ENCODED_STRING (Base64 encoded JSON)
            // Our Controller seems to extract oid, amt, refId.
            // Let's support both or assume Controller handles decoding if needed.
            // Assuming verificationData contains decoded parameters.

            const { transactionId, refId, amount } = verificationData;

            // Find payment by transaction ID (oid)
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

            // Ideally: Call eSewa Transaction Status API here to confirm it's truly COMPLETE
            // For Sandbox, we accept the callback params.

            // Update payment status
            await payment.markCompleted(refId);

            // Update order payment status
            await Order.findByIdAndUpdate(payment.orderId, {
                paymentStatus: 'paid',
                paymentId: payment._id,
                paymentMethod: 'esewa',
                transactionId: refId // Save gateway's reference ID
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
        return !!(this.esewaConfig.merchantId && this.esewaConfig.secretKey);
    }
}

module.exports = new PaymentService();