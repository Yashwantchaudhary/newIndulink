const express = require('express');
const router = express.Router();
const {
    getProducts,
    getProduct,
    createProduct,
    updateProduct,
    deleteProduct,
    getMyProducts,
    getProductBySKU,
    getProductStats,
    getSupplierProductStats,
    advancedProductSearch,
    bulkUpdateProducts,
    bulkDeleteProducts,
    exportProducts
} = require('../controllers/productController');
const { protect, requireSupplier } = require('../middleware/authMiddleware');
const { uploadMultiple } = require('../middleware/upload');

// Public routes
router.get('/', getProducts);
router.post('/search', advancedProductSearch);
router.get('/barcode/:sku', getProductBySKU);
router.get('/stats', getProductStats);
router.get('/stats/supplier/:supplierId', protect, getSupplierProductStats);

// Featured products route - MUST be before /:id to avoid conflict
router.get('/featured', async (req, res, next) => {
    try {
        const Product = require('../models/Product');
        const limit = parseInt(req.query.limit) || 10;

        const products = await Product.find({
            isFeatured: true,
            status: 'active'
        })
            .populate('category', 'name')
            .populate('supplier', 'firstName lastName businessName')
            .limit(limit);

        res.status(200).json({
            success: true,
            count: products.length,
            data: products
        });
    } catch (error) {
        next(error);
    }
});

router.get('/:id', getProduct);

// Protected routes (require authentication)
router.use(protect);

// Bulk operations routes
router.put('/bulk', bulkUpdateProducts);
router.delete('/bulk', bulkDeleteProducts);
router.post('/export', exportProducts);

// Note: Supplier product management moved to /api/supplier/products

module.exports = router;
