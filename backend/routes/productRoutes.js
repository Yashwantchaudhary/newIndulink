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
} = require('../controllers/productController');
const { protect, requireSupplier } = require('../middleware/authMiddleware');
const { uploadMultiple } = require('../middleware/upload');

// Public routes
router.get('/', getProducts);
router.get('/barcode/:sku', getProductBySKU);
router.get('/:id', getProduct);

// Note: Supplier product management moved to /api/supplier/products

module.exports = router;
