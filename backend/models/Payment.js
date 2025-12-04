const mongoose = require('mongoose');

/**
 * Payment Model
 * Tracks all payment transactions including eSewa payments
 */
const paymentSchema = new mongoose.Schema(
    {
        // Transaction identifiers
        transactionId: {
            type: String,
            required: true,
            unique: true,
            index: true,
        },
        esewaRefId: {
            type: String,
            sparse: true, // Only for eSewa transactions
        },

        // Order relationship
        orderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Order',
            required: true,
            index: true,
        },

        // Payment details
        amount: {
            type: Number,
            required: true,
            min: 0,
        },
        currency: {
            type: String,
            default: 'NPR',
            enum: ['NPR', 'USD'],
        },

        // Payment method and status
        paymentMethod: {
            type: String,
            required: true,
            enum: ['esewa', 'cash_on_delivery', 'bank_transfer'],
        },
        status: {
            type: String,
            required: true,
            enum: ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'],
            default: 'pending',
            index: true,
        },

        // eSewa specific fields
        esewaData: {
            productId: String,
            productName: String,
            productUrl: String,
            totalAmount: Number,
            taxAmount: Number,
            serviceCharge: Number,
            deliveryCharge: Number,
        },

        // Additional metadata
        metadata: {
            type: mongoose.Schema.Types.Mixed,
        },

        // Processing information
        processedAt: Date,
        failedReason: String,

        // User reference (for auditing)
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            index: true,
        },
    },
    {
        timestamps: true,
    }
);

// Indexes for performance
paymentSchema.index({ createdAt: -1 });
paymentSchema.index({ userId: 1, status: 1 });
paymentSchema.index({ orderId: 1, status: 1 });

// Virtual for checking if payment is successful
paymentSchema.virtual('isSuccessful').get(function() {
    return this.status === 'completed';
});

// Virtual for checking if payment can be refunded
paymentSchema.virtual('canRefund').get(function() {
    return this.status === 'completed' && this.paymentMethod === 'esewa';
});

// Instance method to mark as completed
paymentSchema.methods.markCompleted = function(esewaRefId = null) {
    this.status = 'completed';
    this.processedAt = new Date();
    if (esewaRefId) {
        this.esewaRefId = esewaRefId;
    }
    return this.save();
};

// Instance method to mark as failed
paymentSchema.methods.markFailed = function(reason = null) {
    this.status = 'failed';
    this.processedAt = new Date();
    if (reason) {
        this.failedReason = reason;
    }
    return this.save();
};

// Instance method to mark as refunded
paymentSchema.methods.markRefunded = function() {
    this.status = 'refunded';
    this.processedAt = new Date();
    return this.save();
};

// Static method to find payment by transaction ID
paymentSchema.statics.findByTransactionId = function(transactionId) {
    return this.findOne({ transactionId });
};

// Static method to find payments by order
paymentSchema.statics.findByOrder = function(orderId) {
    return this.find({ orderId }).sort({ createdAt: -1 });
};

// Pre-save middleware to generate transaction ID if not provided
paymentSchema.pre('save', function(next) {
    if (!this.transactionId) {
        // Generate unique transaction ID
        const timestamp = Date.now();
        const random = Math.random().toString(36).substring(2, 8).toUpperCase();
        this.transactionId = `TXN${timestamp}${random}`;
    }
    next();
});

module.exports = mongoose.model('Payment', paymentSchema);