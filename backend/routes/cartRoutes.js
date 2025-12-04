const express = require('express');
const router = express.Router();
const {
    getCart,
    addToCart,
    updateCartItem,
    removeFromCart,
    clearCart,
} = require('../controllers/cartController');
const { protect, requireCustomer } = require('../middleware/authMiddleware');

// All cart routes require customer authentication
router.use(protect);
router.use(requireCustomer);

router.get('/', getCart);
router.post('/', addToCart);
router.post('/add', addToCart);
router.put('/:itemId', updateCartItem);
router.delete('/:itemId', removeFromCart);
router.delete('/', clearCart);

module.exports = router;
