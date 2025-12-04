const Product = require('../models/Product');
const Category = require('../models/Category');

// Get WebSocket service instance (will be set by server.js)
let webSocketService = null;

const setWebSocketService = (service) => {
    webSocketService = service;
};

// @desc    Get all products with advanced search and filtering
// @route   GET /api/products
// @access  Public
exports.getProducts = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        // Build filter
        const filter = { status: 'active' };

        // Category filtering
        if (req.query.category) {
            filter.category = req.query.category;
        }

        // Supplier filtering
        if (req.query.supplier) {
            filter.supplier = req.query.supplier;
        }

        // Price range filtering
        if (req.query.minPrice || req.query.maxPrice) {
            filter.price = {};
            if (req.query.minPrice) filter.price.$gte = parseFloat(req.query.minPrice);
            if (req.query.maxPrice) filter.price.$lte = parseFloat(req.query.maxPrice);
        }

        // Stock availability filtering
        if (req.query.inStock === 'true') {
            filter.stock = { $gt: 0 };
        } else if (req.query.inStock === 'false') {
            filter.stock = { $eq: 0 };
        }

        // Rating filtering
        if (req.query.minRating) {
            filter.averageRating = { $gte: parseFloat(req.query.minRating) };
        }

        // Featured products filtering
        if (req.query.featured === 'true') {
            filter.isFeatured = true;
        }

        // SKU/Barcode search
        if (req.query.sku) {
            filter.sku = { $regex: req.query.sku, $options: 'i' };
        }

        // Tags filtering
        if (req.query.tags) {
            const tags = req.query.tags.split(',').map(tag => tag.trim());
            filter.tags = { $in: tags };
        }

        // Advanced search query with multiple fields
        if (req.query.search || req.query.q) {
            const searchTerm = req.query.search || req.query.q;
            const searchFields = req.query.searchFields ? req.query.searchFields.split(',') : ['title', 'description', 'tags'];

            if (searchFields.includes('all')) {
                filter.$text = { $search: searchTerm };
            } else {
                const orConditions = searchFields.map(field => {
                    const condition = {};
                    condition[field] = { $regex: searchTerm, $options: 'i' };
                    return condition;
                });
                filter.$or = orConditions;
            }
        }

        // Sort with multiple criteria
        let sort = { createdAt: -1 }; // Default: newest first
        if (req.query.sort) {
            const sortParams = req.query.sort.split(',');
            sortParams.forEach(param => {
                if (param === 'price_asc') sort.price = 1;
                if (param === 'price_desc') sort.price = -1;
                if (param === 'rating') sort.averageRating = -1;
                if (param === 'popular') sort.purchaseCount = -1;
                if (param === 'newest') sort.createdAt = -1;
                if (param === 'oldest') sort.createdAt = 1;
                if (param === 'name_asc') sort.title = 1;
                if (param === 'name_desc') sort.title = -1;
            });
        }

        // Advanced pagination with cursor-based pagination support
        let cursorQuery = {};
        if (req.query.cursor) {
            try {
                const cursor = JSON.parse(req.query.cursor);
                if (cursor._id) {
                    cursorQuery = { _id: { $gt: cursor._id } };
                }
            } catch (error) {
                console.log('Invalid cursor format, ignoring');
            }
        }

        const products = await Product.find({ ...filter, ...cursorQuery })
            .populate('category', 'name')
            .populate('supplier', 'firstName lastName businessName')
            .sort(sort)
            .skip(skip)
            .limit(limit);

        const total = await Product.countDocuments(filter);

        // Get next cursor for pagination
        let nextCursor = null;
        if (products.length > 0) {
            nextCursor = {
                _id: products[products.length - 1]._id,
                createdAt: products[products.length - 1].createdAt
            };
        }

        res.status(200).json({
            success: true,
            count: products.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            nextCursor: nextCursor,
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

// @desc    Get product statistics
// @route   GET /api/products/stats
// @access  Public
exports.getProductStats = async (req, res, next) => {
    try {
        const totalProducts = await Product.countDocuments();
        const activeProducts = await Product.countDocuments({ status: 'active' });
        const featuredProducts = await Product.countDocuments({ isFeatured: true });
        const outOfStockProducts = await Product.countDocuments({ stock: 0 });

        // Get total value of all products
        const products = await Product.find().select('price stock');
        const totalValue = products.reduce((sum, product) => sum + (product.price * product.stock), 0);

        res.status(200).json({
            success: true,
            data: {
                totalProducts,
                activeProducts,
                featuredProducts,
                outOfStockProducts,
                totalValue,
                count: totalProducts
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Advanced product search with full-text and fuzzy matching
// @route   POST /api/products/search
// @access  Public
exports.advancedProductSearch = async (req, res, next) => {
    try {
        const {
            query,
            filters = {},
            sort = 'relevance',
            page = 1,
            limit = 20,
            searchFields = ['title', 'description', 'tags', 'sku'],
            fuzzy = false,
            boost = {}
        } = req.body;

        const skip = (page - 1) * limit;

        // Build advanced search query
        let searchQuery = {};

        if (query) {
            if (fuzzy) {
                // Fuzzy search using regex with levenshtein distance approximation
                const fuzzyRegex = this.createFuzzyRegex(query);
                const orConditions = searchFields.map(field => {
                    const condition = {};
                    condition[field] = fuzzyRegex;
                    return condition;
                });
                searchQuery.$or = orConditions;
            } else {
                // Standard text search
                if (searchFields.includes('all')) {
                    searchQuery.$text = { $search: query };
                } else {
                    const orConditions = searchFields.map(field => {
                        const condition = {};
                        condition[field] = { $regex: query, $options: 'i' };
                        return condition;
                    });
                    searchQuery.$or = orConditions;
                }
            }
        }

        // Apply filters
        const filterConditions = this.buildAdvancedFilters(filters);
        if (Object.keys(filterConditions).length > 0) {
            searchQuery = { ...searchQuery, ...filterConditions };
        }

        // Apply sorting
        let sortOptions = this.buildAdvancedSort(sort, boost);

        // Execute search
        const products = await Product.find(searchQuery)
            .populate('category', 'name')
            .populate('supplier', 'firstName lastName businessName')
            .sort(sortOptions)
            .skip(skip)
            .limit(limit);

        const total = await Product.countDocuments(searchQuery);

        res.status(200).json({
            success: true,
            count: products.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            query: query,
            filters: filters,
            sort: sort,
            data: products,
        });
    } catch (error) {
        next(error);
    }
};

// Helper method to create fuzzy regex
exports.createFuzzyRegex = (term) => {
    if (!term || term.length < 2) return { $regex: term, $options: 'i' };

    // Simple fuzzy matching - allow for common typos and variations
    const variations = [
        term,
        term + 's', // plural
        term.replace(/s$/, ''), // singular
        term.replace(/ing$/, ''), // remove ing
        term.replace(/ed$/, ''), // remove ed
        term.replace(/[aeiou]/g, '.'), // vowel variations
    ];

    const regexPattern = variations.map(v => v.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
        .join('|');

    return { $regex: regexPattern, $options: 'i' };
};

// Helper method to build advanced filters
exports.buildAdvancedFilters = (filters) => {
    const conditions = {};

    if (filters.categories && filters.categories.length > 0) {
        conditions.category = { $in: filters.categories };
    }

    if (filters.suppliers && filters.suppliers.length > 0) {
        conditions.supplier = { $in: filters.suppliers };
    }

    if (filters.priceRange) {
        conditions.price = {};
        if (filters.priceRange.min !== undefined) {
            conditions.price.$gte = parseFloat(filters.priceRange.min);
        }
        if (filters.priceRange.max !== undefined) {
            conditions.price.$lte = parseFloat(filters.priceRange.max);
        }
    }

    if (filters.stockStatus) {
        if (filters.stockStatus === 'in_stock') {
            conditions.stock = { $gt: 0 };
        } else if (filters.stockStatus === 'out_of_stock') {
            conditions.stock = { $eq: 0 };
        } else if (filters.stockStatus === 'low_stock') {
            conditions.stock = { $lt: 10, $gt: 0 };
        }
    }

    if (filters.ratingRange) {
        conditions.averageRating = {};
        if (filters.ratingRange.min !== undefined) {
            conditions.averageRating.$gte = parseFloat(filters.ratingRange.min);
        }
        if (filters.ratingRange.max !== undefined) {
            conditions.averageRating.$lte = parseFloat(filters.ratingRange.max);
        }
    }

    if (filters.featured !== undefined) {
        conditions.isFeatured = filters.featured;
    }

    if (filters.tags && filters.tags.length > 0) {
        conditions.tags = { $in: filters.tags };
    }

    if (filters.skuPattern) {
        conditions.sku = { $regex: filters.skuPattern, $options: 'i' };
    }

    if (filters.status && filters.status.length > 0) {
        conditions.status = { $in: filters.status };
    }

    if (filters.dateRange) {
        conditions.createdAt = {};
        if (filters.dateRange.from) {
            conditions.createdAt.$gte = new Date(filters.dateRange.from);
        }
        if (filters.dateRange.to) {
            conditions.createdAt.$lte = new Date(filters.dateRange.to);
        }
    }

    return conditions;
};

// Helper method to build advanced sort options
exports.buildAdvancedSort = (sort, boost = {}) => {
    const sortOptions = {};

    switch (sort) {
        case 'relevance':
            // For text search relevance, we'll use MongoDB's text score
            sortOptions.score = { $meta: 'textScore' };
            break;
        case 'price_asc':
            sortOptions.price = 1;
            break;
        case 'price_desc':
            sortOptions.price = -1;
            break;
        case 'rating':
            sortOptions.averageRating = -1;
            break;
        case 'popular':
            sortOptions.purchaseCount = -1;
            break;
        case 'newest':
            sortOptions.createdAt = -1;
            break;
        case 'oldest':
            sortOptions.createdAt = 1;
            break;
        case 'name_asc':
            sortOptions.title = 1;
            break;
        case 'name_desc':
            sortOptions.title = -1;
            break;
        case 'stock_high':
            sortOptions.stock = -1;
            break;
        case 'stock_low':
            sortOptions.stock = 1;
            break;
        default:
            sortOptions.createdAt = -1;
    }

    // Apply boost factors if provided
    if (boost.price) {
            sortOptions.price = boost.price > 0 ? 1 : -1;
        }
    if (boost.rating) {
            sortOptions.averageRating = boost.rating > 0 ? 1 : -1;
        }
    if (boost.popularity) {
            sortOptions.purchaseCount = boost.popularity > 0 ? 1 : -1;
        }

    return sortOptions;
};

// @desc    Get supplier product statistics
// @route   GET /api/products/stats/supplier/:supplierId
// @access  Private (Supplier or Admin)
exports.getSupplierProductStats = async (req, res, next) => {
    try {
        const supplierId = req.params.supplierId;

        // Check if user is authorized to access this supplier's data
        if (req.user.role !== 'admin' && req.user.id !== supplierId) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to access this supplier data',
            });
        }

        const totalProducts = await Product.countDocuments({ supplier: supplierId });
        const activeProducts = await Product.countDocuments({ supplier: supplierId, status: 'active' });
        const featuredProducts = await Product.countDocuments({ supplier: supplierId, isFeatured: true });
        const outOfStockProducts = await Product.countDocuments({ supplier: supplierId, stock: 0 });

        // Get total value of supplier's products
        const products = await Product.find({ supplier: supplierId }).select('price stock');
        const totalValue = products.reduce((sum, product) => sum + (product.price * product.stock), 0);

        res.status(200).json({
            success: true,
            data: {
                totalProducts,
                activeProducts,
                featuredProducts,
                outOfStockProducts,
                totalValue,
                count: totalProducts
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Bulk update products
// @route   PUT /api/products/bulk
// @access  Private (Supplier - own products only, Admin)
exports.bulkUpdateProducts = async (req, res, next) => {
    try {
        const { productIds, updates, operation = 'update' } = req.body;

        if (!productIds || !Array.isArray(productIds) || productIds.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Product IDs array is required'
            });
        }

        if (!updates || typeof updates !== 'object' || Object.keys(updates).length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Updates object is required'
            });
        }

        // Check user authorization
        const userId = req.user.id;
        const userRole = req.user.role;

        // Find products to update
        const products = await Product.find({ _id: { $in: productIds } });

        if (products.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No products found with the provided IDs'
            });
        }

        // Check ownership for non-admin users
        if (userRole !== 'admin') {
            const unauthorizedProducts = products.filter(
                product => product.supplier.toString() !== userId
            );

            if (unauthorizedProducts.length > 0) {
                return res.status(403).json({
                    success: false,
                    message: 'Not authorized to update some of the requested products',
                    unauthorizedProductIds: unauthorizedProducts.map(p => p._id)
                });
            }
        }

        // Perform bulk operation
        let result;
        switch (operation) {
            case 'update':
                result = await this.performBulkUpdate(products, updates, userId);
                break;
            case 'activate':
                result = await this.performBulkActivation(products, userId);
                break;
            case 'deactivate':
                result = await this.performBulkDeactivation(products, userId);
                break;
            case 'feature':
                result = await this.performBulkFeaturing(products, userId);
                break;
            case 'unfeature':
                result = await this.performBulkUnfeaturing(products, userId);
                break;
            case 'price_adjustment':
                result = await this.performBulkPriceAdjustment(products, updates, userId);
                break;
            case 'stock_adjustment':
                result = await this.performBulkStockAdjustment(products, updates, userId);
                break;
            default:
                return res.status(400).json({
                    success: false,
                    message: `Invalid operation type: ${operation}`
                });
        }

        // Send real-time updates via WebSocket
        if (webSocketService && result.updatedProducts) {
            result.updatedProducts.forEach(product => {
                webSocketService.notifyProductUpdate(product._id, 'updated', product, userId);
            });
        }

        res.status(200).json({
            success: true,
            message: `Bulk ${operation} completed successfully`,
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Bulk delete products
// @route   DELETE /api/products/bulk
// @access  Private (Supplier - own products only, Admin)
exports.bulkDeleteProducts = async (req, res, next) => {
    try {
        const { productIds } = req.body;

        if (!productIds || !Array.isArray(productIds) || productIds.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Product IDs array is required'
            });
        }

        // Check user authorization
        const userId = req.user.id;
        const userRole = req.user.role;

        // Find products to delete
        const products = await Product.find({ _id: { $in: productIds } });

        if (products.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No products found with the provided IDs'
            });
        }

        // Check ownership for non-admin users
        if (userRole !== 'admin') {
            const unauthorizedProducts = products.filter(
                product => product.supplier.toString() !== userId
            );

            if (unauthorizedProducts.length > 0) {
                return res.status(403).json({
                    success: false,
                    message: 'Not authorized to delete some of the requested products',
                    unauthorizedProductIds: unauthorizedProducts.map(p => p._id)
                });
            }
        }

        // Perform bulk deletion
        const result = await this.performBulkDeletion(products, userId);

        // Send real-time updates via WebSocket
        if (webSocketService && result.deletedProductIds) {
            result.deletedProductIds.forEach(productId => {
                webSocketService.notifyProductUpdate(productId, 'deleted', { _id: productId }, userId);
            });
        }

        res.status(200).json({
            success: true,
            message: 'Bulk deletion completed successfully',
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Export products in bulk
// @route   POST /api/products/export
// @access  Private (Supplier - own products only, Admin)
exports.exportProducts = async (req, res, next) => {
    try {
        const { format = 'csv', productIds, filters = {} } = req.body;
        const userId = req.user.id;
        const userRole = req.user.role;

        // Build query based on filters or productIds
        let query;
        if (productIds && productIds.length > 0) {
            query = { _id: { $in: productIds } };
        } else {
            query = this.buildExportQuery(filters, userId, userRole);
        }

        // Get products to export
        const products = await Product.find(query)
            .populate('category', 'name')
            .populate('supplier', 'firstName lastName businessName');

        if (products.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No products found matching the criteria'
            });
        }

        // Export based on format
        const exportService = require('../services/dataExportService');
        const filename = `products_export_${Date.now()}`;
        let result;

        switch (format.toLowerCase()) {
            case 'json':
                result = await exportService.exportToJSON(products, filename);
                break;
            case 'pdf':
                result = await exportService.exportToPDF(products, filename, {
                    title: 'Product Export'
                });
                break;
            case 'csv':
            default:
                result = await exportService.exportToCSV(products, filename);
        }

        // Set appropriate headers for file download
        const mimeTypes = {
            json: 'application/json',
            csv: 'text/csv',
            pdf: 'application/pdf'
        };

        res.setHeader('Content-Type', mimeTypes[format] || 'application/octet-stream');
        res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);

        // Stream the file
        const fs = require('fs');
        const fileStream = fs.createReadStream(result.filePath);
        fileStream.pipe(res);

        // Clean up file after streaming
        fileStream.on('end', () => {
            setTimeout(() => {
                try {
                    fs.unlinkSync(result.filePath);
                } catch (error) {
                    console.error('Error cleaning up export file:', error);
                }
            }, 5000); // Delete after 5 seconds
        });

    } catch (error) {
        next(error);
    }
};

// Helper method to perform bulk update
exports.performBulkUpdate = async (products, updates, userId) => {
    const results = {
        successCount: 0,
        failureCount: 0,
        updatedProducts: [],
        errors: []
    };

    for (const product of products) {
        try {
            // Apply updates
            Object.keys(updates).forEach(key => {
                if (key !== '_id' && key !== 'createdAt' && key !== 'updatedAt') {
                    product[key] = updates[key];
                }
            });

            // Save updated product
            const updatedProduct = await product.save();

            results.successCount++;
            results.updatedProducts.push(updatedProduct);

            // Update category product count if category changed
            if (updates.category && updates.category !== product.category) {
                await Category.findByIdAndUpdate(product.category, {
                    $inc: { productCount: -1 }
                });
                await Category.findByIdAndUpdate(updates.category, {
                    $inc: { productCount: 1 }
                });
            }

        } catch (error) {
            results.failureCount++;
            results.errors.push({
                productId: product._id,
                error: error.message
            });
        }
    }

    return results;
};

// Helper method to perform bulk activation
exports.performBulkActivation = async (products, userId) => {
    const results = {
        successCount: 0,
        failureCount: 0,
        updatedProducts: [],
        errors: []
    };

    for (const product of products) {
        try {
            if (product.status !== 'active') {
                product.status = 'active';
                const updatedProduct = await product.save();
                results.successCount++;
                results.updatedProducts.push(updatedProduct);
            }
        } catch (error) {
            results.failureCount++;
            results.errors.push({
                productId: product._id,
                error: error.message
            });
        }
    }

    return results;
};

// Helper method to perform bulk deactivation
exports.performBulkDeactivation = async (products, userId) => {
    const results = {
        successCount: 0,
        failureCount: 0,
        updatedProducts: [],
        errors: []
    };

    for (const product of products) {
        try {
            if (product.status !== 'inactive') {
                product.status = 'inactive';
                const updatedProduct = await product.save();
                results.successCount++;
                results.updatedProducts.push(updatedProduct);
            }
        } catch (error) {
            results.failureCount++;
            results.errors.push({
                productId: product._id,
                error: error.message
            });
        }
    }

    return results;
};

// Helper method to perform bulk featuring
exports.performBulkFeaturing = async (products, userId) => {
    const results = {
        successCount: 0,
        failureCount: 0,
        updatedProducts: [],
        errors: []
    };

    for (const product of products) {
        try {
            if (!product.isFeatured) {
                product.isFeatured = true;
                const updatedProduct = await product.save();
                results.successCount++;
                results.updatedProducts.push(updatedProduct);
            }
        } catch (error) {
            results.failureCount++;
            results.errors.push({
                productId: product._id,
                error: error.message
            });
        }
    }

    return results;
};

// Helper method to perform bulk unfeaturing
exports.performBulkUnfeaturing = async (products, userId) => {
    const results = {
        successCount: 0,
        failureCount: 0,
        updatedProducts: [],
        errors: []
    };

    for (const product of products) {
        try {
            if (product.isFeatured) {
                product.isFeatured = false;
                const updatedProduct = await product.save();
                results.successCount++;
                results.updatedProducts.push(updatedProduct);
            }
        } catch (error) {
            results.failureCount++;
            results.errors.push({
                productId: product._id,
                error: error.message
            });
        }
    }

    return results;
};

// Helper method to perform bulk price adjustment
exports.performBulkPriceAdjustment = async (products, updates, userId) => {
    const results = {
        successCount: 0,
        failureCount: 0,
        updatedProducts: [],
        errors: []
    };

    const { adjustmentType, value } = updates;

    for (const product of products) {
        try {
            let newPrice = product.price;

            switch (adjustmentType) {
                case 'percentage_increase':
                    newPrice = product.price * (1 + value / 100);
                    break;
                case 'percentage_decrease':
                    newPrice = product.price * (1 - value / 100);
                    break;
                case 'fixed_increase':
                    newPrice = product.price + value;
                    break;
                case 'fixed_decrease':
                    newPrice = product.price - value;
                    break;
                case 'set_price':
                    newPrice = value;
                    break;
                default:
                    throw new Error(`Invalid adjustment type: ${adjustmentType}`);
            }

            // Ensure price doesn't go negative
            newPrice = Math.max(0, newPrice);

            product.price = newPrice;
            const updatedProduct = await product.save();
            results.successCount++;
            results.updatedProducts.push(updatedProduct);

        } catch (error) {
            results.failureCount++;
            results.errors.push({
                productId: product._id,
                error: error.message
            });
        }
    }

    return results;
};

// Helper method to perform bulk stock adjustment
exports.performBulkStockAdjustment = async (products, updates, userId) => {
    const results = {
        successCount: 0,
        failureCount: 0,
        updatedProducts: [],
        errors: []
    };

    const { adjustmentType, value } = updates;

    for (const product of products) {
        try {
            let newStock = product.stock;

            switch (adjustmentType) {
                case 'percentage_increase':
                    newStock = product.stock * (1 + value / 100);
                    break;
                case 'percentage_decrease':
                    newStock = product.stock * (1 - value / 100);
                    break;
                case 'fixed_increase':
                    newStock = product.stock + value;
                    break;
                case 'fixed_decrease':
                    newStock = product.stock - value;
                    break;
                case 'set_stock':
                    newStock = value;
                    break;
                default:
                    throw new Error(`Invalid adjustment type: ${adjustmentType}`);
            }

            // Ensure stock doesn't go negative
            newStock = Math.max(0, newStock);

            // Update stock status if needed
            const oldStatus = product.stock === 0 ? 'out_of_stock' : 'active';
            product.stock = newStock;
            const newStatus = newStock === 0 ? 'out_of_stock' : 'active';

            if (oldStatus !== newStatus) {
                product.status = newStatus;
            }

            const updatedProduct = await product.save();
            results.successCount++;
            results.updatedProducts.push(updatedProduct);

        } catch (error) {
            results.failureCount++;
            results.errors.push({
                productId: product._id,
                error: error.message
            });
        }
    }

    return results;
};

// Helper method to perform bulk deletion
exports.performBulkDeletion = async (products, userId) => {
    const results = {
        successCount: 0,
        failureCount: 0,
        deletedProductIds: [],
        errors: []
    };

    for (const product of products) {
        try {
            // Update category product count
            await Category.findByIdAndUpdate(product.category, {
                $inc: { productCount: -1 }
            });


            // Delete product
            await product.remove();

            results.successCount++;
            results.deletedProductIds.push(product._id);

        } catch (error) {
            results.failureCount++;
            results.errors.push({
                productId: product._id,
                error: error.message
            });
        }
    }

    return results;
};

// Helper method to build export query
exports.buildExportQuery = (filters, userId, userRole) => {
    const query = { status: 'active' }; // Default to active products only

    // Apply user-specific filtering for non-admin users
    if (userRole !== 'admin') {
        query.supplier = userId;
    }

    // Apply additional filters if provided
    if (filters.categories && filters.categories.length > 0) {
        query.category = { $in: filters.categories };
    }

    if (filters.status && filters.status.length > 0) {
        query.status = { $in: filters.status };
    }

    if (filters.featured !== undefined) {
        query.isFeatured = filters.featured;
    }

    if (filters.dateRange) {
        query.createdAt = {};
        if (filters.dateRange.from) {
            query.createdAt.$gte = new Date(filters.dateRange.from);
        }
        if (filters.dateRange.to) {
            query.createdAt.$lte = new Date(filters.dateRange.to);
        }
    }

    return query;
};

