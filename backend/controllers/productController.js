const Product = require('../models/Product');
const Category = require('../models/Category');
const cdnConfig = require('../config/cdn');

// Get WebSocket service instance (will be set by server.js)
let webSocketService = null;

const setWebSocketService = (service) => {
    webSocketService = service;
};

// @desc    Get all products with filters and pagination
// @route   GET /api/products
// @access  Public
exports.getProducts = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        // Build filter
        const filter = { status: 'active' };

        if (req.query.category) {
            filter.category = req.query.category;
        }

        if (req.query.supplier) {
            filter.supplier = req.query.supplier;
        }

        if (req.query.minPrice || req.query.maxPrice) {
            filter.price = {};
            if (req.query.minPrice) filter.price.$gte = parseFloat(req.query.minPrice);
            if (req.query.maxPrice) filter.price.$lte = parseFloat(req.query.maxPrice);
        }

        if (req.query.inStock === 'true') {
            filter.stock = { $gt: 0 };
        }

        // Search query
        if (req.query.search || req.query.q) {
            const searchTerm = req.query.search || req.query.q;
            filter.$text = { $search: searchTerm };
        }

        // Sort
        let sort = { createdAt: -1 }; // Default: newest first
        if (req.query.sort === 'price_asc') sort = { price: 1 };
        if (req.query.sort === 'price_desc') sort = { price: -1 };
        if (req.query.sort === 'rating') sort = { averageRating: -1 };
        if (req.query.sort === 'popular') sort = { purchaseCount: -1 };

        const products = await Product.find(filter)
            .populate('category', 'name')
            .populate('supplier', 'firstName lastName businessName')
            .sort(sort)
            .skip(skip)
            .limit(limit);

        const total = await Product.countDocuments(filter);

        res.status(200).json({
            success: true,
            count: products.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            data: products,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get single product
// @route   GET /api/products/:id
// @access  Public
exports.getProduct = async (req, res, next) => {
    try {
        const product = await Product.findById(req.params.id)
            .populate('category', 'name slug')
            .populate('supplier', 'firstName lastName businessName businessDescription profileImage');

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found',
            });
        }

        // Increment view count
        product.viewCount += 1;
        await product.save();

        res.status(200).json({
            success: true,
            data: product,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Create product
// @route   POST /api/products
// @access  Private (Supplier)
exports.createProduct = async (req, res, next) => {
    try {
        // Set supplier as current user
        req.body.supplier = req.user.id;

        // Handle uploaded images
        if (req.files && req.files.length > 0) {
            req.body.images = req.files.map((file, index) => ({
                url: `/uploads/products/${file.filename}`,
                alt: req.body.title,
                isPrimary: index === 0,
            }));
        }

        const product = await Product.create(req.body);

        // Update category product count
        await Category.findByIdAndUpdate(product.category, {
            $inc: { productCount: 1 },
        });

        // Send new product notification to all customers
        try {
            const { sendNewProductNotification } = require('../services/notificationService');
            await sendNewProductNotification(req.user.id, product._id, product.title);
        } catch (notificationError) {
            console.error('Error sending new product notification:', notificationError);
            // Don't fail the product creation if notification fails
        }

        // Send real-time update via WebSocket
        if (webSocketService) {
            webSocketService.notifyProductUpdate(product._id, 'created', product, req.user.id);
        }

        res.status(201).json({
            success: true,
            message: 'Product created successfully',
            data: product,
        });
    } catch (error) {
        next(error);
    }
};

// Export WebSocket service setter
module.exports.setWebSocketService = setWebSocketService;

// @desc    Update product
// @route   PUT /api/products/:id
// @access  Private (Supplier - own products only)
exports.updateProduct = async (req, res, next) => {
    try {
        let product = await Product.findById(req.params.id);

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found',
            });
        }

        // Check ownership
        if (product.supplier.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this product',
            });
        }

        // Handle new images
        if (req.files && req.files.length > 0) {
            const newImages = req.files.map((file, index) => ({
                url: `/uploads/products/${file.filename}`,
                alt: req.body.title || product.title,
                isPrimary: product.images.length === 0 && index === 0,
            }));
            req.body.images = [...product.images, ...newImages];
        }

        product = await Product.findByIdAndUpdate(req.params.id, req.body, {
            new: true,
            runValidators: true,
        });

        // Purge CDN cache for product images
        if (product.images && product.images.length > 0) {
            const imageUrls = product.images.map(img => img.url);
            try {
                await cdnConfig.purgeCache(imageUrls);
                console.log('CDN cache purged for updated product images');
            } catch (cacheError) {
                console.error('Failed to purge CDN cache:', cacheError);
                // Don't fail the update if cache purging fails
            }
        }

        // Send real-time update via WebSocket
        if (webSocketService) {
            webSocketService.notifyProductUpdate(product._id, 'updated', product, req.user.id);
        }

        res.status(200).json({
            success: true,
            message: 'Product updated successfully',
            data: product,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete product
// @route   DELETE /api/products/:id
// @access  Private (Supplier - own products only)
exports.deleteProduct = async (req, res, next) => {
    try {
        const product = await Product.findById(req.params.id);

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found',
            });
        }

        // Check ownership
        if (product.supplier.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this product',
            });
        }

        // Update category product count
        await Category.findByIdAndUpdate(product.category, {
            $inc: { productCount: -1 },
        });

        // Purge CDN cache for product images before deletion
        if (product.images && product.images.length > 0) {
            const imageUrls = product.images.map(img => img.url);
            try {
                await cdnConfig.purgeCache(imageUrls);
                console.log('CDN cache purged for deleted product images');
            } catch (cacheError) {
                console.error('Failed to purge CDN cache:', cacheError);
                // Don't fail the deletion if cache purging fails
            }
        }

        await product.remove();

        // Send real-time update via WebSocket
        if (webSocketService) {
            webSocketService.notifyProductUpdate(product._id, 'deleted', product, req.user.id);
        }

        res.status(200).json({
            success: true,
            message: 'Product deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get supplier's products
// @route   GET /api/products/supplier/me
// @access  Private (Supplier)
exports.getMyProducts = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const filter = { supplier: req.user.id };

        if (req.query.status) {
            filter.status = req.query.status;
        }

        const products = await Product.find(filter)
            .populate('category', 'name')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        const total = await Product.countDocuments(filter);

        res.status(200).json({
            success: true,
            count: products.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            data: products,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get product by SKU/Barcode
// @route   GET /api/products/barcode/:sku
// @access  Public
exports.getProductBySKU = async (req, res, next) => {
    try {
        const product = await Product.findOne({ sku: req.params.sku })
            .populate('category', 'name slug')
            .populate('supplier', 'firstName lastName businessName businessDescription profileImage');

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found with this barcode/SKU',
            });
        }

        res.status(200).json({
            success: true,
            data: product,
        });
    } catch (error) {
        next(error);
    }
};

