const express = require('express');
const router = express.Router();
const {
    getProfile,
    updateProfile,
    uploadProfileImage,
    addAddress,
    updateAddress,
    deleteAddress,
    toggleWishlist,
    getWishlist,
    getUsers,
    updateUser,
    deleteUser,
    registerFCMToken,
    unregisterFCMToken,
    updateNotificationPreferences,
    getNotificationPreferences,
    updateLanguage,
    getLanguage,
    getLanguage,
    getUserStats,
    getPublicProfile,
} = require('../controllers/userController');
const { protect, requireCustomer, requireAdmin } = require('../middleware/authMiddleware');
const { uploadSingle } = require('../middleware/upload');

// Public routes
router.get('/:id/public-profile', getPublicProfile);

// Profile routes
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfile);
router.post('/profile/image', protect, uploadSingle('profileImage'), uploadProfileImage);

// Address routes
router.post('/addresses', protect, addAddress);
router.put('/addresses/:addressId', protect, updateAddress);
router.delete('/addresses/:addressId', protect, deleteAddress);

// Wishlist routes (customer only)
router.get('/wishlist', protect, requireCustomer, getWishlist);
router.put('/wishlist/:productId', protect, requireCustomer, toggleWishlist);

// FCM token routes
router.post('/fcm-token', protect, registerFCMToken);
router.delete('/fcm-token', protect, unregisterFCMToken);

// Notification preferences routes
router.get('/notification-preferences', protect, getNotificationPreferences);
router.put('/notification-preferences', protect, updateNotificationPreferences);

// Language preference routes
router.get('/language', protect, getLanguage);
router.put('/language', protect, updateLanguage);

// Admin routes
router.get('/', protect, requireAdmin, getUsers);
router.put('/:id', protect, requireAdmin, updateUser);
router.delete('/:id', protect, requireAdmin, deleteUser);
router.get('/stats', protect, requireAdmin, getUserStats);

module.exports = router;
