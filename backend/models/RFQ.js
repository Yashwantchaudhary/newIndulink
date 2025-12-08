
const mongoose = require('mongoose');

const rfqItemSchema = new mongoose.Schema({
    productId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true,
    },
    productSnapshot: {
        title: String,
        image: String,
    },
    quantity: {
        type: Number,
        required: true,
        min: 1,
    },
    specifications: String,
});

const quoteSchema = new mongoose.Schema({
    supplierId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    items: [{
        productId: mongoose.Schema.Types.ObjectId,
        quantity: Number,
        unitPrice: Number,
        subtotal: Number,
    }],
    totalAmount: {
        type: Number,
        required: true,
    },
    validUntil: Date,
    notes: String,
    status: {
        type: String,
        enum: ['pending', 'accepted', 'rejected'],
        default: 'pending',
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

const rfqSchema = new mongoose.Schema(
    {
        rfqNumber: {
            type: String,
            unique: true,
            required: true,
        },
        customerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        items: [rfqItemSchema],
        status: {
            type: String,
            enum: ['pending', 'quoted', 'accepted', 'rejected', 'closed', 'awarded'],
            default: 'pending',
        },
        quotes: [quoteSchema],
        selectedQuoteId: {
            type: mongoose.Schema.Types.ObjectId,
        },
        deliveryAddress: {
            fullName: String,
            phone: String,
            addressLine1: String,
            addressLine2: String,
            city: String,
            state: String,
            postalCode: String,
            country: String,
        },
        notes: String,
        expiresAt: {
            type: Date,
            required: true,
        },
        closedAt: Date,
    },
    {
        timestamps: true,
    }
);

// Generate RFQ number before validation
rfqSchema.pre('validate', async function (next) {
    if (this.isNew) {
        const count = await mongoose.model('RFQ').countDocuments();
        this.rfqNumber = `RFQ${Date.now()}${String(count + 1).padStart(4, '0')}`;
    }
    next();
});

// Indexes for performance
rfqSchema.index({ customerId: 1, createdAt: -1 });
rfqSchema.index({ status: 1 });

module.exports = mongoose.model('RFQ', rfqSchema);
