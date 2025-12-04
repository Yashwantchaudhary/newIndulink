const express = require('express');
const {
    getAddresses,
    addAddress,
    updateAddress,
    deleteAddress,
    setDefaultAddress,
    getAddressStats,
    getUserAddressStats,
} = require('../controllers/addressController');

const { protect, requireAdmin } = require('../middleware/authMiddleware');

const router = express.Router();

// All routes require authentication
router.use(protect);

// Address CRUD routes
router.route('/')
    .get(getAddresses)
    .post(addAddress);

router.route('/:id')
    .put(updateAddress)
    .delete(deleteAddress);

// Set default address
router.put('/:id/set-default', setDefaultAddress);

// Admin stats route
router.get('/stats', requireAdmin, getAddressStats);

// User-specific stats route
router.get('/stats/:userId', protect, getUserAddressStats);

module.exports = router;