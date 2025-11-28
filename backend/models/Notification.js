const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        type: {
            type: String,
            enum: ['order', 'promotion', 'message', 'system', 'review', 'rfq', 'product'],
            required: true,
        },
        title: {
            type: String,
            required: true,
            maxlength: 100,
        },
        message: {
            type: String,
            required: true,
            maxlength: 500,
        },
        data: {
            type: mongoose.Schema.Types.Mixed,
            default: {},
        },
        isRead: {
            type: Boolean,
            default: false,
        },
        readAt: Date,
        // For supplier-sent notifications
        sentBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        audience: {
            type: String,
            enum: ['all', 'active', 'new', 'inactive'],
        },
    },
    {
        timestamps: true,
    }
);

// Mark as read method
notificationSchema.methods.markAsRead = function () {
    this.isRead = true;
    this.readAt = new Date();
    return this.save();
};

// Indexes for performance
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ isRead: 1 });
notificationSchema.index({ type: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
