const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
    {
        sender: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        receiver: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        content: {
            type: String,
            required: [true, 'Message content is required'],
            trim: true,
            maxlength: [1000, 'Message cannot exceed 1000 characters'],
        },
        conversationId: {
            type: String,
            index: true,
        },
        isRead: {
            type: Boolean,
            default: false,
        },
        readAt: Date,
        attachments: [
            {
                url: String,
                type: {
                    type: String,
                    enum: ['image', 'document'],
                },
                name: String,
            },
        ],
    },
    {
        timestamps: true,
    }
);

// Generate conversation ID before saving
messageSchema.pre('save', function (next) {
    if (!this.conversationId) {
        // Create a consistent conversation ID for both users
        const ids = [this.sender.toString(), this.receiver.toString()].sort();
        this.conversationId = `${ids[0]}_${ids[1]}`;
    }
    next();
});

// Update readAt timestamp when message is marked as read
messageSchema.pre('save', function (next) {
    if (this.isModified('isRead') && this.isRead && !this.readAt) {
        this.readAt = new Date();
    }
    next();
});

// Indexes for performance
messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ sender: 1, receiver: 1, createdAt: -1 });
messageSchema.index({ receiver: 1, isRead: 1 });

module.exports = mongoose.model('Message', messageSchema);
