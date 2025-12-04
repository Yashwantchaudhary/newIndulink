/// 🔍 Filter Controller
/// Handles advanced filtering and faceted search for products

const Product = require('../models/Product');
const Category = require('../models/Category');
const User = require('../models/User');

// Helper method to get category filter options
const getCategoryOptions = async (baseFilter = {}) => {
    const categories = await Category.find({ ...baseFilter })
        .select('name slug _id')
        .sort({ name: 1 });

    return categories.map(cat => ({
        value: cat._id,
        label: cat.name,
        slug: cat.slug,
        count: 0 // Would be populated with actual counts in a real implementation
    }));
};

// Helper method to get supplier filter options
const getSupplierOptions = async (baseFilter = {}) => {
    const suppliers = await User.find({
        role: 'supplier',
        ...baseFilter
    })
    .select('firstName lastName businessName _id')
    .sort({ businessName: 1 });

    return suppliers.map(supplier => ({
        value: supplier._id,
        label: supplier.businessName || `${supplier.firstName} ${supplier.lastName}`,
        count: 0 // Would be populated with actual counts in a real implementation
    }));
};

// Helper method to get price range
const getPriceRange = async (baseFilter = {}) => {
    const result = await Product.aggregate([
        { $match: { ...baseFilter, status: 'active' } },
        {
            $group: {
                _id: null,
                minPrice: { $min: '$price' },
                maxPrice: { $max: '$price' },
                avgPrice: { $avg: '$price' }
            }
        }
    ]);

    return {
        min: result[0]?.minPrice || 0,
        max: result[0]?.maxPrice || 1000,
        avg: result[0]?.avgPrice || 0
    };
};

// Helper method to get rating range
const getRatingRange = async (baseFilter = {}) => {
    const result = await Product.aggregate([
        { $match: { ...baseFilter, status: 'active' } },
        {
            $group: {
                _id: null,
                minRating: { $min: '$averageRating' },
                maxRating: { $max: '$averageRating' },
                avgRating: { $avg: '$averageRating' }
            }
        }
    ]);

    return {
        min: result[0]?.minRating || 0,
        max: result[0]?.maxRating || 5,
        avg: result[0]?.avgRating || 0
    };
};

// Helper method to get tag options
const getTagOptions = async (baseFilter = {}) => {
    const tags = await Product.aggregate([
        { $match: { ...baseFilter, status: 'active' } },
        { $unwind: '$tags' },
        {
            $group: {
                _id: '$tags',
                count: { $sum: 1 }
            }
        },
        { $sort: { count: -1 } },
        { $limit: 50 }
    ]);

    return tags.map(tag => ({
        value: tag._id,
        label: tag._id,
        count: tag.count
    }));
};

// Helper method to get status options
const getStatusOptions = async (baseFilter = {}) => {
    const statuses = await Product.aggregate([
        { $match: { ...baseFilter } },
        {
            $group: {
                _id: '$status',
                count: { $sum: 1 }
            }
        },
        { $sort: { count: -1 } }
    ]);

    return statuses.map(status => ({
        value: status._id,
        label: status._id,
        count: status.count
    }));
};

// Helper method to get updated facets based on current filters
const getUpdatedFacets = async (currentFilters) => {
    // Build base filter excluding the facet we're calculating
    const baseFilter = { status: 'active' };

    if (currentFilters.categories) {
        baseFilter.category = { $in: currentFilters.categories };
    }

    if (currentFilters.suppliers) {
        baseFilter.supplier = { $in: currentFilters.suppliers };
    }

    if (currentFilters.priceRange) {
        baseFilter.price = {};
        if (currentFilters.priceRange.min) {
            baseFilter.price.$gte = currentFilters.priceRange.min;
        }
        if (currentFilters.priceRange.max) {
            baseFilter.price.$lte = currentFilters.priceRange.max;
        }
    }

    // Get updated facet counts
    const [categories, suppliers, priceRange, ratingRange, tags, statuses] = await Promise.all([
        getCategoryOptions(baseFilter),
        getSupplierOptions(baseFilter),
        getPriceRange(baseFilter),
        getRatingRange(baseFilter),
        getTagOptions(baseFilter),
        getStatusOptions(baseFilter)
    ]);

    return {
        categories,
        suppliers,
        priceRange,
        ratingRange,
        tags,
        statuses
    };
};

// Helper method to build filter query
const buildFilterQuery = (filters) => {
    const query = { status: 'active' }; // Default to active products only

    if (filters.categories && filters.categories.length > 0) {
        query.category = { $in: filters.categories };
    }

    if (filters.suppliers && filters.suppliers.length > 0) {
        query.supplier = { $in: filters.suppliers };
    }

    if (filters.priceRange) {
        query.price = {};
        if (filters.priceRange.min !== undefined) {
            query.price.$gte = parseFloat(filters.priceRange.min);
        }
        if (filters.priceRange.max !== undefined) {
            query.price.$lte = parseFloat(filters.priceRange.max);
        }
    }

    if (filters.stockStatus) {
        if (filters.stockStatus === 'in_stock') {
            query.stock = { $gt: 0 };
        } else if (filters.stockStatus === 'out_of_stock') {
            query.stock = { $eq: 0 };
        } else if (filters.stockStatus === 'low_stock') {
            query.stock = { $lt: 10, $gt: 0 };
        }
    }

    if (filters.ratingRange) {
        query.averageRating = {};
        if (filters.ratingRange.min !== undefined) {
            query.averageRating.$gte = parseFloat(filters.ratingRange.min);
        }
        if (filters.ratingRange.max !== undefined) {
            query.averageRating.$lte = parseFloat(filters.ratingRange.max);
        }
    }

    if (filters.featured !== undefined) {
        query.isFeatured = filters.featured;
    }

    if (filters.tags && filters.tags.length > 0) {
        query.tags = { $in: filters.tags };
    }

    if (filters.skuPattern) {
        query.sku = { $regex: filters.skuPattern, $options: 'i' };
    }

    if (filters.status && filters.status.length > 0) {
        query.status = { $in: filters.status };
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

    if (filters.searchQuery) {
        query.$or = [
            { title: { $regex: filters.searchQuery, $options: 'i' } },
            { description: { $regex: filters.searchQuery, $options: 'i' } },
            { tags: { $regex: filters.searchQuery, $options: 'i' } },
            { sku: { $regex: filters.searchQuery, $options: 'i' } }
        ];
    }

    return query;
};

// Helper method to build sort options
const buildSortOptions = (sort) => {
    const sortOptions = {};

    switch (sort) {
        case 'price_asc':
            sortOptions.price = 1;
            break;
        case 'price_desc':
            sortOptions.price = -1;
            break;
        case 'rating_desc':
            sortOptions.averageRating = -1;
            break;
        case 'popular_desc':
            sortOptions.purchaseCount = -1;
            break;
        case 'createdAt_desc':
            sortOptions.createdAt = -1;
            break;
        case 'createdAt_asc':
            sortOptions.createdAt = 1;
            break;
        case 'title_asc':
            sortOptions.title = 1;
            break;
        case 'title_desc':
            sortOptions.title = -1;
            break;
        case 'stock_desc':
            sortOptions.stock = -1;
            break;
        case 'stock_asc':
            sortOptions.stock = 1;
            break;
        default:
            sortOptions.createdAt = -1;
    }

    return sortOptions;
};

// @desc    Get available filter options for products
// @route   GET /api/filters/products
// @access  Public
const getProductFilterOptions = async (req, res, next) => {
    try {
        // Get base filter from query if provided
        const baseFilter = {};
        if (req.query.category) {
            baseFilter.category = req.query.category;
        }

        // Get all available filter options
        const [categories, suppliers, priceRange, ratingRange, tags, statuses] = await Promise.all([
            getCategoryOptions(baseFilter),
            getSupplierOptions(baseFilter),
            getPriceRange(baseFilter),
            getRatingRange(baseFilter),
            getTagOptions(baseFilter),
            getStatusOptions(baseFilter)
        ]);

        res.status(200).json({
            success: true,
            data: {
                categories,
                suppliers,
                priceRange,
                ratingRange,
                tags,
                statuses,
                stockStatus: ['in_stock', 'out_of_stock', 'low_stock'],
                featured: [true, false]
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get filtered products with faceted search
// @route   POST /api/filters/products
// @access  Public
const getFilteredProducts = async (req, res, next) => {
    try {
        const {
            filters = {},
            sort = 'createdAt_desc',
            page = 1,
            limit = 20,
            includeFacets = true
        } = req.body;

        const skip = (page - 1) * limit;

        // Build filter query
        const filterQuery = buildFilterQuery(filters);

        // Apply sorting
        const sortOptions = buildSortOptions(sort);

        // Execute main query
        const products = await Product.find(filterQuery)
            .populate('category', 'name')
            .populate('supplier', 'firstName lastName businessName')
            .sort(sortOptions)
            .skip(skip)
            .limit(limit);

        const total = await Product.countDocuments(filterQuery);

        // Get updated facets if requested
        let facets = {};
        if (includeFacets) {
            facets = await getUpdatedFacets(filters);
        }

        res.status(200).json({
            success: true,
            count: products.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            facets,
            data: products
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get product suggestions based on filters
// @route   GET /api/filters/suggestions
// @access  Public
const getProductSuggestions = async (req, res, next) => {
    try {
        const query = req.query.q || '';
        const limit = parseInt(req.query.limit) || 10;

        if (!query || query.length < 2) {
            return res.status(200).json({
                success: true,
                data: []
            });
        }

        // Search across multiple fields
        const suggestions = await Product.find({
            $or: [
                { title: { $regex: query, $options: 'i' } },
                { description: { $regex: query, $options: 'i' } },
                { tags: { $regex: query, $options: 'i' } },
                { sku: { $regex: query, $options: 'i' } }
            ]
        })
        .select('title sku tags category')
        .limit(limit);

        res.status(200).json({
            success: true,
            data: suggestions
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getProductFilterOptions,
    getFilteredProducts,
    getProductSuggestions,
    buildFilterQuery,
    buildSortOptions,
    getCategoryOptions,
    getSupplierOptions,
    getPriceRange,
    getRatingRange,
    getTagOptions,
    getStatusOptions,
    getUpdatedFacets
};