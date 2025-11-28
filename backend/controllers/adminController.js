const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Category = require('../models/Category');

/**
 * Admin Controller
 * Handles all admin-specific operations including user, product, category, order, and supplier management
 */

// ==================== USER MANAGEMENT ====================

/**
 * Get all users with pagination and filters
 * @route GET /api/admin/users
 * @access Admin
 */
exports.getAllUsers = async (req, res, next) => {
    try {
        const {
            page = 1,
            limit = 20,
            role,
            isActive,
            search,
            sortBy = 'createdAt',
            sortOrder = 'desc',
        } = req.query;

        // Build filter query
        const filter = {};

        if (role) filter.role = role;
        if (isActive !== undefined) filter.isActive = isActive === 'true';
        if (search) {
            filter.$or = [
                { firstName: { $regex: search, $options: 'i' } },
                { lastName: { $regex: search, $options: 'i' } },
                { email: { $regex: search, $options: 'i' } },
            ];
        }

        // Calculate pagination
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const sortOptions = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

        // Execute query
        const [users, total] = await Promise.all([
            User.find(filter)
                .select('-password -refreshToken')
                .sort(sortOptions)
                .limit(parseInt(limit))
                .skip(skip)
                .lean(),
            User.countDocuments(filter),
        ]);

        res.status(200).json({
            success: true,
            data: users,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                pages: Math.ceil(total / parseInt(limit)),
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get user details by ID
 * @route GET /api/admin/users/:id
 * @access Admin
 */
exports.getUserDetails = async (req, res, next) => {
    try {
        const user = await User.findById(req.params.id)
            .select('-password -refreshToken')
            .lean();

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Get additional stats
        const [orderCount, totalSpent] = await Promise.all([
            Order.countDocuments({ customer: req.params.id }),
            Order.aggregate([
                { $match: { customer: req.params.id, status: 'delivered' } },
                { $group: { _id: null, total: { $sum: '$total' } } },
            ]),
        ]);

        res.status(200).json({
            success: true,
            data: {
                ...user,
                stats: {
                    orderCount,
                    totalSpent: totalSpent[0]?.total || 0,
                },
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Create new user (any role)
 * @route POST /api/admin/users
 * @access Admin
 */
exports.createUser = async (req, res, next) => {
    try {
        const {
            firstName,
            lastName,
            email,
            password,
            phone,
            role,
            businessName,
            businessDescription,
        } = req.body;

        // Check if user exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: 'User with this email already exists',
            });
        }

        // Create user
        const userData = {
            firstName,
            lastName,
            email,
            password,
            phone,
            role: role || 'customer',
            isActive: true,
        };

        // Add supplier-specific fields if role is supplier
        if (role === 'supplier' && businessName) {
            userData.businessName = businessName;
            userData.businessDescription = businessDescription;
        }

        const user = await User.create(userData);

        // Remove sensitive data
        user.password = undefined;
        user.refreshToken = undefined;

        res.status(201).json({
            success: true,
            message: 'User created successfully',
            data: user,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Update user
 * @route PUT /api/admin/users/:id
 * @access Admin
 */
exports.updateUser = async (req, res, next) => {
    try {
        const {
            firstName,
            lastName,
            phone,
            role,
            isActive,
            businessName,
            businessDescription,
        } = req.body;

        // Build update object
        const updateData = {};
        if (firstName) updateData.firstName = firstName;
        if (lastName) updateData.lastName = lastName;
        if (phone) updateData.phone = phone;
        if (role) updateData.role = role;
        if (isActive !== undefined) updateData.isActive = isActive;
        if (businessName) updateData.businessName = businessName;
        if (businessDescription) updateData.businessDescription = businessDescription;

        const user = await User.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true, runValidators: true }
        ).select('-password -refreshToken');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'User updated successfully',
            data: user,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Delete user (soft delete)
 * @route DELETE /api/admin/users/:id
 * @access Admin
 */
exports.deleteUser = async (req, res, next) => {
    try {
        const user = await User.findByIdAndUpdate(
            req.params.id,
            { isActive: false },
            { new: true }
        ).select('-password -refreshToken');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'User deactivated successfully',
            data: user,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Toggle user active status
 * @route PUT /api/admin/users/:id/toggle-status
 * @access Admin
 */
exports.toggleUserStatus = async (req, res, next) => {
    try {
        const user = await User.findById(req.params.id).select('-password -refreshToken');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        user.isActive = !user.isActive;
        await user.save();

        res.status(200).json({
            success: true,
            message: `User ${user.isActive ? 'activated' : 'deactivated'} successfully`,
            data: user,
        });
    } catch (error) {
        next(error);
    }
};

// ==================== PRODUCT MANAGEMENT ====================

/**
 * Get all products with admin view
 * @route GET /api/admin/products
 * @access Admin
 */
exports.getAllProducts = async (req, res, next) => {
    try {
        const {
            page = 1,
            limit = 20,
            category,
            supplier,
            status,
            search,
            sortBy = 'createdAt',
            sortOrder = 'desc',
        } = req.query;

        // Build filter query
        const filter = {};

        if (category) filter.category = category;
        if (supplier) filter.supplier = supplier;
        if (status) filter.status = status;
        if (search) {
            filter.$or = [
                { name: { $regex: search, $options: 'i' } },
                { description: { $regex: search, $options: 'i' } },
                { sku: { $regex: search, $options: 'i' } },
            ];
        }

        // Calculate pagination
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const sortOptions = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

        // Execute query
        const [products, total] = await Promise.all([
            Product.find(filter)
                .populate('supplier', 'firstName lastName businessName email')
                .populate('category', 'name')
                .sort(sortOptions)
                .limit(parseInt(limit))
                .skip(skip)
                .lean(),
            Product.countDocuments(filter),
        ]);

        res.status(200).json({
            success: true,
            data: products,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                pages: Math.ceil(total / parseInt(limit)),
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Approve product
 * @route PUT /api/admin/products/:id/approve
 * @access Admin
 */
exports.approveProduct = async (req, res, next) => {
    try {
        const product = await Product.findByIdAndUpdate(
            req.params.id,
            { status: 'active' },
            { new: true }
        ).populate('supplier', 'firstName lastName businessName');

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Product approved successfully',
            data: product,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Feature product
 * @route PUT /api/admin/products/:id/feature
 * @access Admin
 */
exports.featureProduct = async (req, res, next) => {
    try {
        const { isFeatured } = req.body;

        const product = await Product.findByIdAndUpdate(
            req.params.id,
            { isFeatured },
            { new: true }
        ).populate('supplier', 'firstName lastName businessName');

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found',
            });
        }

        res.status(200).json({
            success: true,
            message: `Product ${isFeatured ? 'featured' : 'unfeatured'} successfully`,
            data: product,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Bulk product update
 * @route POST /api/admin/products/bulk-update
 * @access Admin
 */
exports.bulkProductUpdate = async (req, res, next) => {
    try {
        const { productIds, updates } = req.body;

        if (!productIds || !Array.isArray(productIds) || productIds.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Product IDs array is required',
            });
        }

        const result = await Product.updateMany(
            { _id: { $in: productIds } },
            updates,
            { runValidators: true }
        );

        res.status(200).json({
            success: true,
            message: 'Products updated successfully',
            data: {
                matchedCount: result.matchedCount,
                modifiedCount: result.modifiedCount,
            },
        });
    } catch (error) {
        next(error);
    }
};

// ==================== ORDER MANAGEMENT ====================

/**
 * Get all orders
 * @route GET /api/admin/orders
 * @access Admin
 */
exports.getAllOrders = async (req, res, next) => {
    try {
        const {
            page = 1,
            limit = 20,
            status,
            search,
            startDate,
            endDate,
            sortBy = 'createdAt',
            sortOrder = 'desc',
        } = req.query;

        // Build filter query
        const filter = {};

        if (status) filter.status = status;
        if (startDate || endDate) {
            filter.createdAt = {};
            if (startDate) filter.createdAt.$gte = new Date(startDate);
            if (endDate) filter.createdAt.$lte = new Date(endDate);
        }
        if (search) {
            filter.orderNumber = { $regex: search, $options: 'i' };
        }

        // Calculate pagination
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const sortOptions = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

        // Execute query
        const [orders, total] = await Promise.all([
            Order.find(filter)
                .populate('customer', 'firstName lastName email')
                .populate({
                    path: 'items.product',
                    select: 'name images price',
                })
                .sort(sortOptions)
                .limit(parseInt(limit))
                .skip(skip)
                .lean(),
            Order.countDocuments(filter),
        ]);

        res.status(200).json({
            success: true,
            data: orders,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                pages: Math.ceil(total / parseInt(limit)),
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get order analytics
 * @route GET /api/admin/orders/analytics
 * @access Admin
 */
exports.getOrderAnalytics = async (req, res, next) => {
    try {
        const { startDate, endDate } = req.query;

        // Build date filter
        const dateFilter = {};
        if (startDate || endDate) {
            dateFilter.createdAt = {};
            if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
            if (endDate) dateFilter.createdAt.$lte = new Date(endDate);
        }

        // Get analytics
        const [
            totalOrders,
            ordersByStatus,
            totalRevenue,
            avgOrderValue,
        ] = await Promise.all([
            Order.countDocuments(dateFilter),
            Order.aggregate([
                { $match: dateFilter },
                { $group: { _id: '$status', count: { $sum: 1 } } },
            ]),
            Order.aggregate([
                { $match: { ...dateFilter, status: 'delivered' } },
                { $group: { _id: null, total: { $sum: '$total' } } },
            ]),
            Order.aggregate([
                { $match: dateFilter },
                { $group: { _id: null, avg: { $avg: '$total' } } },
            ]),
        ]);

        res.status(200).json({
            success: true,
            data: {
                totalOrders,
                ordersByStatus,
                totalRevenue: totalRevenue[0]?.total || 0,
                avgOrderValue: avgOrderValue[0]?.avg || 0,
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Update order status (admin override)
 * @route PUT /api/admin/orders/:id/status
 * @access Admin
 */
exports.updateOrderStatus = async (req, res, next) => {
    try {
        const { status, note } = req.body;

        const order = await Order.findByIdAndUpdate(
            req.params.id,
            {
                status,
                ...(note && {
                    $push: {
                        statusHistory: {
                            status,
                            note,
                            updatedBy: req.user._id,
                            timestamp: new Date(),
                        },
                    },
                }),
            },
            { new: true }
        ).populate('customer', 'firstName lastName email');

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Order status updated successfully',
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

// ==================== SUPPLIER MANAGEMENT ====================

/**
 * Get all suppliers with metrics
 * @route GET /api/admin/suppliers
 * @access Admin
 */
exports.getAllSuppliers = async (req, res, next) => {
    try {
        const {
            page = 1,
            limit = 20,
            isActive,
            search,
            sortBy = 'createdAt',
            sortOrder = 'desc',
        } = req.query;

        // Build filter query
        const filter = { role: 'supplier' };

        if (isActive !== undefined) filter.isActive = isActive === 'true';
        if (search) {
            filter.$or = [
                { firstName: { $regex: search, $options: 'i' } },
                { lastName: { $regex: search, $options: 'i' } },
                { businessName: { $regex: search, $options: 'i' } },
                { email: { $regex: search, $options: 'i' } },
            ];
        }

        // Calculate pagination
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const sortOptions = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

        // Execute query
        const suppliers = await User.find(filter)
            .select('-password -refreshToken')
            .sort(sortOptions)
            .limit(parseInt(limit))
            .skip(skip)
            .lean();

        // Get metrics for each supplier
        const suppliersWithMetrics = await Promise.all(
            suppliers.map(async (supplier) => {
                const [productCount, orderCount, totalRevenue] = await Promise.all([
                    Product.countDocuments({ supplier: supplier._id }),
                    Order.countDocuments({ 'items.supplier': supplier._id }),
                    Order.aggregate([
                        { $unwind: '$items' },
                        { $match: { 'items.supplier': supplier._id, status: 'delivered' } },
                        { $group: { _id: null, total: { $sum: { $multiply: ['$items.price', '$items.quantity'] } } } },
                    ]),
                ]);

                return {
                    ...supplier,
                    metrics: {
                        productCount,
                        orderCount,
                        totalRevenue: totalRevenue[0]?.total || 0,
                    },
                };
            })
        );

        const total = await User.countDocuments(filter);

        res.status(200).json({
            success: true,
            data: suppliersWithMetrics,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                pages: Math.ceil(total / parseInt(limit)),
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Approve supplier
 * @route PUT /api/admin/suppliers/:id/approve
 * @access Admin
 */
exports.approveSupplier = async (req, res, next) => {
    try {
        const supplier = await User.findOneAndUpdate(
            { _id: req.params.id, role: 'supplier' },
            { isActive: true, isEmailVerified: true },
            { new: true }
        ).select('-password -refreshToken');

        if (!supplier) {
            return res.status(404).json({
                success: false,
                message: 'Supplier not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Supplier approved successfully',
            data: supplier,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Suspend supplier
 * @route PUT /api/admin/suppliers/:id/suspend
 * @access Admin
 */
exports.suspendSupplier = async (req, res, next) => {
    try {
        const supplier = await User.findOneAndUpdate(
            { _id: req.params.id, role: 'supplier' },
            { isActive: false },
            { new: true }
        ).select('-password -refreshToken');

        if (!supplier) {
            return res.status(404).json({
                success: false,
                message: 'Supplier not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Supplier suspended successfully',
            data: supplier,
        });
    } catch (error) {
        next(error);
    }
};

// ==================== SYSTEM STATS ====================

/**
 * Get system statistics
 * @route GET /api/admin/stats
 * @access Admin
 */
exports.getSystemStats = async (req, res, next) => {
    try {
        const [
            totalUsers,
            totalProducts,
            totalOrders,
            totalRevenue,
            usersByRole,
            recentUsers,
        ] = await Promise.all([
            User.countDocuments({ isActive: true }),
            Product.countDocuments(),
            Order.countDocuments(),
            Order.aggregate([
                { $match: { status: 'delivered' } },
                { $group: { _id: null, total: { $sum: '$total' } } },
            ]),
            User.aggregate([
                { $group: { _id: '$role', count: { $sum: 1 } } },
            ]),
            User.find({ isActive: true })
                .select('firstName lastName email role createdAt')
                .sort({ createdAt: -1 })
                .limit(10)
                .lean(),
        ]);

        res.status(200).json({
            success: true,
            data: {
                totalUsers,
                totalProducts,
                totalOrders,
                totalRevenue: totalRevenue[0]?.total || 0,
                usersByRole,
                recentUsers,
            },
        });
    } catch (error) {
        next(error);
    }
};
