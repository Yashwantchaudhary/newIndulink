const mongoose = require('mongoose');

const inventoryTransactionSchema = new mongoose.Schema(
    {
        transactionType: {
            type: String,
            enum: ['purchase', 'sale', 'transfer', 'adjustment', 'return', 'damage', 'write-off'],
            required: [true, 'Transaction type is required'],
        },
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Product',
            required: [true, 'Product reference is required'],
        },
        fromLocation: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Location',
        },
        toLocation: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Location',
        },
        quantity: {
            type: Number,
            required: [true, 'Quantity is required'],
            min: [0, 'Quantity cannot be negative'],
        },
        unitPrice: {
            type: Number,
            min: [0, 'Unit price cannot be negative'],
        },
        totalValue: {
            type: Number,
            min: [0, 'Total value cannot be negative'],
        },
        batchNumber: {
            type: String,
            trim: true,
            sparse: true,
        },
        serialNumbers: [{
            type: String,
            trim: true,
        }],
        referenceId: {
            type: String,
            trim: true,
            description: 'Reference to order, purchase order, transfer request, etc.',
        },
        referenceType: {
            type: String,
            enum: ['order', 'purchase_order', 'transfer', 'adjustment', 'return', 'other'],
        },
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'User reference is required'],
        },
        supplier: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        customer: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        status: {
            type: String,
            enum: ['pending', 'completed', 'cancelled', 'reversed'],
            default: 'completed',
        },
        notes: {
            type: String,
            maxlength: [500, 'Notes cannot exceed 500 characters'],
        },
        // For stock adjustments
        adjustmentReason: {
            type: String,
            enum: ['damage', 'loss', 'theft', 'count_correction', 'expiration', 'other'],
            sparse: true,
        },
        // For transfers
        transferStatus: {
            type: String,
            enum: ['initiated', 'in_transit', 'received', 'cancelled'],
            sparse: true,
        },
        // For returns
        returnReason: {
            type: String,
            enum: ['defective', 'wrong_item', 'no_longer_needed', 'other'],
            sparse: true,
        },
    },
    {
        timestamps: true,
    }
);

// Indexes for performance
inventoryTransactionSchema.index({ product: 1, transactionType: 1 });
inventoryTransactionSchema.index({ fromLocation: 1, toLocation: 1 });
inventoryTransactionSchema.index({ user: 1 });
inventoryTransactionSchema.index({ referenceId: 1 });
inventoryTransactionSchema.index({ transactionType: 1, createdAt: -1 });
inventoryTransactionSchema.index({ batchNumber: 1 });
inventoryTransactionSchema.index({ 'serialNumbers': 1 });

// Ensure virtuals are included in JSON
inventoryTransactionSchema.set('toJSON', { virtuals: true });
inventoryTransactionSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('InventoryTransaction', inventoryTransactionSchema);