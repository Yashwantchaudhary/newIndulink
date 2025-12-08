const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
    product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true,
    },
    productSnapshot: {
        title: String,
        image: String,
        sku: String,
    },
    quantity: {
        type: Number,
        required: true,
        min: 1,
    },
    price: {
        type: Number,
        required: true,
    },
    subtotal: {
        type: Number,
        required: true,
    },
});

const orderSchema = new mongoose.Schema(
    {
        orderNumber: {
            type: String,
            unique: true,
        },
        customer: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        supplier: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        items: [orderItemSchema],
        // Pricing
        subtotal: {
            type: Number,
            required: true,
        },
        tax: {
            type: Number,
            required: true,
        },
        shippingCost: {
            type: Number,
            required: true,
        },
        total: {
            type: Number,
            required: true,
        },
        // Shipping address
        shippingAddress: {
            fullName: String,
            phone: String,
            addressLine1: String,
            addressLine2: String,
            city: String,
            state: String,
            postalCode: String,
            country: String,
        },
        // Order status workflow
        status: {
            type: String,
            enum: [
                'pending_approval',
                'pending',
                'confirmed',
                'processing',
                'shipped',
                'out_for_delivery',
                'delivered',
                'cancelled',
                'refunded',
            ],
            default: 'pending_approval',
        },
        // Payment information
        paymentMethod: {
            type: String,
            enum: ['cash_on_delivery', 'esewa', 'khalti', 'online', 'wallet'],
            default: 'cash_on_delivery',
        },
        paymentStatus: {
            type: String,
            enum: ['pending', 'paid', 'failed', 'refunded'],
            default: 'pending',
        },
        paymentId: String,
        transactionId: String, // External gateway transaction ID
        // Tracking
        trackingNumber: String,
        estimatedDelivery: Date,
        // Status timestamps
        approvedAt: Date,
        rejectedAt: Date,
        confirmedAt: Date,
        shippedAt: Date,
        deliveredAt: Date,
        cancelledAt: Date,
        // Notes
        customerNote: String,
        supplierNote: String,
        cancellationReason: String,
    },
    {
        timestamps: true,
    }
);

// Generate order number before saving
orderSchema.pre('save', async function (next) {
    if (this.isNew) {
        try {
            const count = await mongoose.model('Order').countDocuments();
            this.orderNumber = `IND${Date.now()}${String(count + 1).padStart(4, '0')}`;
        } catch (error) {
            // Fallback order number generation
            this.orderNumber = `IND${Date.now()}${Math.random().toString(36).substr(2, 4).toUpperCase()}`;
        }
    }
    next();
});

// Update status timestamps
orderSchema.pre('save', function (next) {
    if (this.isModified('status')) {
        const now = new Date();
        switch (this.status) {
            case 'pending':
                this.approvedAt = now;
                break;
            case 'confirmed':
                this.confirmedAt = now;
                break;
            case 'shipped':
                this.shippedAt = now;
                break;
            case 'delivered':
                this.deliveredAt = now;
                this.paymentStatus = 'paid';
                break;
            case 'cancelled':
                this.cancelledAt = now;
                break;
        }
    }
    next();
});

// Indexes for performance
orderSchema.index({ customer: 1, createdAt: -1 });
orderSchema.index({ supplier: 1, status: 1, createdAt: -1 });
orderSchema.index({ status: 1 });

module.exports = mongoose.model('Order', orderSchema);
