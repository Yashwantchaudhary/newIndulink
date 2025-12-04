const mongoose = require('mongoose');

const reorderAlertSchema = new mongoose.Schema(
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
        threshold: {
            type: Number,
            required: [true, 'Reorder threshold is required'],
            min: [0, 'Threshold cannot be negative'],
        },
        currentStock: {
            type: Number,
            required: [true, 'Current stock is required'],
            min: [0, 'Current stock cannot be negative'],
        },
        status: {
            type: String,
            enum: ['pending', 'triggered', 'acknowledged', 'resolved', 'cancelled'],
            default: 'pending',
        },
        priority: {
            type: String,
            enum: ['low', 'medium', 'high', 'critical'],
            default: 'medium',
        },
        triggeredAt: {
            type: Date,
        },
        acknowledgedAt: {
            type: Date,
        },
        acknowledgedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        resolvedAt: {
            type: Date,
        },
        resolvedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        notes: {
            type: String,
            maxlength: [500, 'Notes cannot exceed 500 characters'],
        },
        // Suggested reorder quantity based on historical data
        suggestedQuantity: {
            type: Number,
            min: [0, 'Suggested quantity cannot be negative'],
        },
        // Lead time for reordering
        leadTimeDays: {
            type: Number,
            min: [0, 'Lead time cannot be negative'],
        },
        // Supplier information
        supplier: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        // Alert history
        alertHistory: [{
            status: {
                type: String,
                enum: ['triggered', 'acknowledged', 'resolved', 'cancelled'],
                required: true,
            },
            timestamp: {
                type: Date,
                default: Date.now,
            },
            user: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User',
            },
            notes: {
                type: String,
                maxlength: [200, 'Alert notes cannot exceed 200 characters'],
            },
        }],
    },
    {
        timestamps: true,
    }
);

// Indexes for performance
reorderAlertSchema.index({ product: 1, location: 1 }, { unique: true });
reorderAlertSchema.index({ status: 1 });
reorderAlertSchema.index({ priority: 1 });
reorderAlertSchema.index({ triggeredAt: 1 });
reorderAlertSchema.index({ acknowledgedAt: 1 });

// Virtual for days since triggered
reorderAlertSchema.virtual('daysSinceTriggered').get(function () {
    if (!this.triggeredAt) return null;
    const now = new Date();
    const triggered = new Date(this.triggeredAt);
    return Math.floor((now - triggered) / (1000 * 60 * 60 * 24));
});

// Virtual for isOverdue
reorderAlertSchema.virtual('isOverdue').get(function () {
    if (!this.triggeredAt || this.status !== 'triggered') return false;
    const daysTriggered = this.daysSinceTriggered;
    return daysTriggered > (this.leadTimeDays || 3); // Consider overdue if not resolved within lead time or 3 days
});

// Ensure virtuals are included in JSON
reorderAlertSchema.set('toJSON', { virtuals: true });
reorderAlertSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('ReorderAlert', reorderAlertSchema);