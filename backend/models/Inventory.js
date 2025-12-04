const mongoose = require('mongoose');

const inventorySchema = new mongoose.Schema(
    {
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Product',
            required: [true, 'Product reference is required'],
        },
        location: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Location',
            required: [true, 'Location reference is required'],
        },
        quantity: {
            type: Number,
            required: [true, 'Quantity is required'],
            min: [0, 'Quantity cannot be negative'],
            default: 0,
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
        expirationDate: {
            type: Date,
            sparse: true,
        },
        receivedDate: {
            type: Date,
            default: Date.now,
        },
        lastUpdated: {
            type: Date,
            default: Date.now,
        },
        status: {
            type: String,
            enum: ['active', 'quarantined', 'expired', 'damaged', 'reserved'],
            default: 'active',
        },
        costPrice: {
            type: Number,
            min: [0, 'Cost price cannot be negative'],
        },
        supplier: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        notes: {
            type: String,
            maxlength: [500, 'Notes cannot exceed 500 characters'],
        },
        // For tracking inventory movements
        movementHistory: [{
            type: {
                type: String,
                enum: ['received', 'transferred', 'sold', 'adjusted', 'returned', 'damaged'],
                required: true,
            },
            quantity: {
                type: Number,
                required: true,
            },
            fromLocation: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Location',
            },
            toLocation: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Location',
            },
            timestamp: {
                type: Date,
                default: Date.now,
            },
            user: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User',
            },
            reference: {
                type: String,
                trim: true,
            },
        }],
    },
    {
        timestamps: true,
    }
);

// Indexes for performance
inventorySchema.index({ product: 1, location: 1 }, { unique: true });
inventorySchema.index({ product: 1, status: 1 });
inventorySchema.index({ location: 1, status: 1 });
inventorySchema.index({ expirationDate: 1 });
inventorySchema.index({ batchNumber: 1 });
inventorySchema.index({ 'serialNumbers': 1 });

// Virtual for total value
inventorySchema.virtual('inventoryValue').get(function () {
    return this.quantity * (this.costPrice || 0);
});

// Update lastUpdated before save
inventorySchema.pre('save', function (next) {
    this.lastUpdated = new Date();
    next();
});

// Ensure virtuals are included in JSON
inventorySchema.set('toJSON', { virtuals: true });
inventorySchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Inventory', inventorySchema);