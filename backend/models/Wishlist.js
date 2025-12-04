const mongoose = require('mongoose');

const wishlistSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            unique: true,
        },
        products: [{
            productId: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Product',
            },
            addedAt: {
                type: Date,
                default: Date.now,
            },
        }],
    },
    {
        timestamps: true,
    }
);

// No additional indexes needed as userId has unique constraint

module.exports = mongoose.model('Wishlist', wishlistSchema);
