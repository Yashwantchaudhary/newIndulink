const express = require('express');
const router = express.Router();
const { protect, requireAdmin } = require('../middleware/authMiddleware');
const dataSeeder = require('../services/dataSeeder');

// All seeding routes require admin authentication
router.use(protect);
router.use(requireAdmin);

// Seed all data collections
router.post('/seed-all', async (req, res) => {
    try {
        const result = await dataSeeder.seedAll();
        res.status(200).json(result);
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error seeding database',
            error: error.message
        });
    }
});

// Seed specific collections
router.post('/seed-categories', async (req, res) => {
    try {
        await dataSeeder.seedCategories();
        res.status(200).json({
            success: true,
            message: 'Categories seeded successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error seeding categories',
            error: error.message
        });
    }
});

router.post('/seed-users', async (req, res) => {
    try {
        await dataSeeder.seedUsers();
        res.status(200).json({
            success: true,
            message: 'Users seeded successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error seeding users',
            error: error.message
        });
    }
});

router.post('/seed-products', async (req, res) => {
    try {
        await dataSeeder.seedProducts();
        res.status(200).json({
            success: true,
            message: 'Products seeded successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error seeding products',
            error: error.message
        });
    }
});

router.post('/seed-orders', async (req, res) => {
    try {
        await dataSeeder.seedOrders();
        res.status(200).json({
            success: true,
            message: 'Orders seeded successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error seeding orders',
            error: error.message
        });
    }
});

router.post('/seed-reviews', async (req, res) => {
    try {
        await dataSeeder.seedReviews();
        res.status(200).json({
            success: true,
            message: 'Reviews seeded successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error seeding reviews',
            error: error.message
        });
    }
});

// Clear all data (development only)
router.post('/clear-all', async (req, res) => {
    try {
        if (process.env.NODE_ENV === 'production') {
            return res.status(403).json({
                success: false,
                message: 'Cannot clear data in production environment'
            });
        }

        await dataSeeder.clearCollections();
        res.status(200).json({
            success: true,
            message: 'All collections cleared successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error clearing collections',
            error: error.message
        });
    }
});

// Get seeding status
router.get('/status', async (req, res) => {
    try {
        const status = {
            users: await require('../models/User').countDocuments(),
            products: await require('../models/Product').countDocuments(),
            categories: await require('../models/Category').countDocuments(),
            orders: await require('../models/Order').countDocuments(),
            reviews: await require('../models/Review').countDocuments(),
            carts: await require('../models/Cart').countDocuments(),
            wishlists: await require('../models/Wishlist').countDocuments(),
            notifications: await require('../models/Notification').countDocuments()
        };

        res.status(200).json({
            success: true,
            message: 'Database status retrieved successfully',
            data: status
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error getting database status',
            error: error.message
        });
    }
});

module.exports = router;