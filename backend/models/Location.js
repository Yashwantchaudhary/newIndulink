const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, 'Location name is required'],
            trim: true,
            maxlength: [100, 'Name cannot exceed 100 characters'],
        },
        code: {
            type: String,
            required: [true, 'Location code is required'],
            trim: true,
            unique: true,
            maxlength: [20, 'Code cannot exceed 20 characters'],
        },
        address: {
            street: String,
            city: String,
            state: String,
            postalCode: String,
            country: String,
        },
        type: {
            type: String,
            enum: ['warehouse', 'store', 'distribution_center', 'factory', 'office', 'virtual'],
            default: 'warehouse',
        },
        capacity: {
            type: Number,
            min: [0, 'Capacity cannot be negative'],
            description: 'Maximum storage capacity',
        },
        currentUsage: {
            type: Number,
            min: [0, 'Current usage cannot be negative'],
            default: 0,
        },
        isActive: {
            type: Boolean,
            default: true,
        },
        manager: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        contact: {
            name: String,
            email: String,
            phone: String,
        },
        operatingHours: {
            open: String,
            close: String,
            timezone: String,
        },
        coordinates: {
            latitude: Number,
            longitude: Number,
        },
        notes: {
            type: String,
            maxlength: [500, 'Notes cannot exceed 500 characters'],
        },
    },
    {
        timestamps: true,
    }
);

// Indexes for performance
locationSchema.index({ code: 1 }, { unique: true });
locationSchema.index({ name: 1 });
locationSchema.index({ type: 1 });
locationSchema.index({ 'address.city': 1 });
locationSchema.index({ 'address.country': 1 });

// Virtual for usage percentage
locationSchema.virtual('usagePercentage').get(function () {
    return this.capacity > 0 ? Math.round((this.currentUsage / this.capacity) * 100) : 0;
});

// Virtual for available capacity
locationSchema.virtual('availableCapacity').get(function () {
    return this.capacity > 0 ? this.capacity - this.currentUsage : 0;
});

// Ensure virtuals are included in JSON
locationSchema.set('toJSON', { virtuals: true });
locationSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Location', locationSchema);