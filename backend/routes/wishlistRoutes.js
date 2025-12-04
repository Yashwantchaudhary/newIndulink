const express = require('express');
const wishlistRouter = express.Router();
const {
    getWishlist,
    addToWishlist,
    removeFromWishlist,
    clearWishlist,
    checkWishlist
} = require('../controllers/wishlistController');
const { protect } = require('../middleware/authMiddleware');

// Wishlist routes
wishlistRouter.get('/', protect, getWishlist);
wishlistRouter.get('/check/:productId', protect, checkWishlist);
wishlistRouter.post('/:productId', protect, addToWishlist);
wishlistRouter.post('/', protect, addToWishlist);
wishlistRouter.delete('/:productId', protect, removeFromWishlist);
wishlistRouter.delete('/', protect, clearWishlist);

module.exports = wishlistRouter;
