/// 🔍 Filter Routes
/// API endpoints for advanced filtering and faceted search

const express = require('express');
const router = express.Router();
const {
    getProductFilterOptions,
    getFilteredProducts,
    getProductSuggestions
} = require('../controllers/filterController');
const { protect } = require('../middleware/authMiddleware');

// Public routes
router.get('/products', getProductFilterOptions);
router.post('/products', getFilteredProducts);
router.get('/suggestions', getProductSuggestions);

// Protected routes (for user-specific filtering)
router.use(protect);
router.get('/products/me', (req, res) => {
    // This would be for user-specific product filtering
    res.status(200).json({
        success: true,
        message: 'User-specific filtering endpoint'
    });
});

module.exports = router;