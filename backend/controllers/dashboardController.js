const Order = require('../models/Order');
const Product = require('../models/Product');
const User = require('../models/User');

// @desc    Get supplier dashboard analytics
// @route   GET /api/dashboard/supplier
// @access  Private (Supplier)
exports.getSupplierDashboard = async (req, res, next) => {
    try {
        const supplierId = req.user.id;

        // Get date range (default: last 30 days)
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - 30);

        // Total revenue
        const revenueData = await Order.aggregate([
            {
                $match: {
                    supplier: req.user._id,
                    status: { $in: ['delivered', 'shipped', 'processing'] },
                    createdAt: { $gte: startDate, $lte: endDate },
                },
            },
            {
                $group: {
                    _id: null,
                    totalRevenue: { $sum: '$total' },
                    totalOrders: { $sum: 1 },
                    averageOrderValue: { $avg: '$total' },
                },
            },
        ]);

        // Orders by status
        const ordersByStatus = await Order.aggregate([
            {
                $match: {
                    supplier: req.user._id,
                },
            },
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 },
                },
            },
        ]);

        // Top selling products
        const topProducts = await Order.aggregate([
            {
                $match: {
                    supplier: req.user._id,
                    status: 'delivered',
                },
            },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.product',
                    totalQuantity: { $sum: '$items.quantity' },
                    totalRevenue: { $sum: '$items.subtotal' },
                },
            },
            { $sort: { totalQuantity: -1 } },
            { $limit: 10 },
        ]);

        // Populate product details
        await Product.populate(topProducts, {
            path: '_id',
            select: 'title images price',
        });

        // Revenue over time (daily for last 30 days)
        const revenueOverTime = await Order.aggregate([
            {
                $match: {
                    supplier: req.user._id,
                    status: { $in: ['delivered', 'shipped', 'processing'] },
                    createdAt: { $gte: startDate, $lte: endDate },
                },
            },
            {
                $group: {
                    _id: {
                        $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
                    },
                    revenue: { $sum: '$total' },
                    orders: { $sum: 1 },
                },
            },
            { $sort: { _id: 1 } },
        ]);

        // Product statistics
        const productStats = await Product.aggregate([
            {
                $match: {
                    supplier: req.user._id,
                },
            },
            {
                $group: {
                    _id: null,
                    totalProducts: { $sum: 1 },
                    activeProducts: {
                        $sum: { $cond: [{ $eq: ['$status', 'active'] }, 1, 0] },
                    },
                    outOfStock: {
                        $sum: { $cond: [{ $eq: ['$stock', 0] }, 1, 0] },
                    },
                    totalStock: { $sum: '$stock' },
                },
            },
        ]);

        // Recent orders
        const recentOrders = await Order.find({ supplier: supplierId })
            .populate('customer', 'firstName lastName')
            .sort({ createdAt: -1 })
            .limit(5);

        // Format data to match frontend expectations
        const revenue = revenueData[0] || {
            totalRevenue: 0,
            totalOrders: 0,
            averageOrderValue: 0,
        };

        const productStatsData = productStats[0] || {
            totalProducts: 0,
            activeProducts: 0,
            outOfStock: 0,
            totalStock: 0,
        };

        // Format recent orders for frontend
        const formattedRecentOrders = recentOrders.map(order => ({
            orderNumber: order.orderNumber,
            customerName: order.customer ? `${order.customer.firstName} ${order.customer.lastName}` : 'Unknown',
            amount: order.total,
            status: order.status,
        }));

        // Format top products for frontend
        const formattedTopProducts = topProducts.map(product => ({
            name: product._id ? product._id.title : 'Unknown Product',
            soldCount: product.totalQuantity,
            revenue: product.totalRevenue,
        }));

        // Calculate trends by comparing with previous period
        const previousPeriodStart = new Date(startDate);
        previousPeriodStart.setDate(previousPeriodStart.getDate() - 30);
        const previousPeriodEnd = new Date(startDate);

        // Previous period revenue
        const previousRevenueData = await Order.aggregate([
            {
                $match: {
                    supplier: req.user._id,
                    status: { $in: ['delivered', 'shipped', 'processing'] },
                    createdAt: { $gte: previousPeriodStart, $lt: previousPeriodEnd },
                },
            },
            {
                $group: {
                    _id: null,
                    totalRevenue: { $sum: '$total' },
                    totalOrders: { $sum: 1 },
                },
            },
        ]);

        const previousRevenue = previousRevenueData[0] || { totalRevenue: 0, totalOrders: 0 };

        // Calculate percentage changes
        const revenueTrend = previousRevenue.totalRevenue > 0
            ? ((revenue.totalRevenue - previousRevenue.totalRevenue) / previousRevenue.totalRevenue) * 100
            : (revenue.totalRevenue > 0 ? 100 : 0);

        const ordersTrend = previousRevenue.totalOrders > 0
            ? ((revenue.totalOrders - previousRevenue.totalOrders) / previousRevenue.totalOrders) * 100
            : (revenue.totalOrders > 0 ? 100 : 0);

        // Product trend (compare current active products with previous)
        const previousProductStats = await Product.aggregate([
            {
                $match: {
                    supplier: req.user._id,
                    createdAt: { $lt: startDate },
                },
            },
            {
                $group: {
                    _id: null,
                    totalProducts: { $sum: 1 },
                },
            },
        ]);

        const previousProducts = previousProductStats[0]?.totalProducts || 0;
        const productsTrend = previousProducts > 0
            ? ((productStatsData.totalProducts - previousProducts) / previousProducts) * 100
            : (productStatsData.totalProducts > 0 ? 100 : 0);

        // Get unread notifications count
        const Notification = require('../models/Notification');
        const unreadNotifications = await Notification.countDocuments({
            userId: req.user._id,
            isRead: false
        });

        // Extract revenue data for chart
        const revenueDataPoints = revenueOverTime.map(item => item.revenue);

        res.status(200).json({
            success: true,
            totalRevenue: revenue.totalRevenue,
            totalOrders: revenue.totalOrders,
            totalProducts: productStatsData.totalProducts,
            lowStockCount: productStatsData.outOfStock,
            unreadNotifications,
            revenueTrend: Math.round(revenueTrend * 100) / 100, // Round to 2 decimal places
            ordersTrend: Math.round(ordersTrend * 100) / 100,
            productsTrend: Math.round(productsTrend * 100) / 100,
            revenueData: revenueDataPoints,
            recentOrders: formattedRecentOrders,
            topProducts: formattedTopProducts,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get admin/host dashboard analytics
// @route   GET /api/dashboard/admin
// @access  Private (Admin)
exports.getAdminDashboard = async (req, res, next) => {
    try {
        // Platform-wide analytics
        const platformAnalytics = await Order.aggregate([
            {
                $match: {
                    status: { $in: ['delivered', 'shipped', 'processing'] },
                },
            },
            {
                $group: {
                    _id: null,
                    totalPlatformRevenue: { $sum: '$total' },
                    totalOrders: { $sum: 1 },
                    averageOrderValue: { $avg: '$total' },
                },
            },
        ]);

        // User statistics
        const userStats = await User.aggregate([
            {
                $group: {
                    _id: '$role',
                    count: { $sum: 1 },
                },
            },
        ]);

        const totalActiveUsers = userStats.reduce((sum, stat) => sum + stat.count, 0);
        const totalSuppliers = userStats.find(stat => stat._id === 'supplier')?.count || 0;
        const totalCustomers = userStats.find(stat => stat._id === 'customer')?.count || 0;

        // User growth (last 2 months)
        const now = new Date();
        const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);

        const thisMonthUsers = await User.countDocuments({
            createdAt: { $gte: thisMonth },
        });

        const lastMonthUsers = await User.countDocuments({
            createdAt: { $gte: lastMonth, $lt: thisMonth },
        });

        const growthRate = lastMonthUsers > 0
            ? ((thisMonthUsers - lastMonthUsers) / lastMonthUsers) * 100
            : 0;

        // Revenue breakdown (simplified - assuming 10% platform fee)
        const platformRevenue = (platformAnalytics[0]?.totalPlatformRevenue || 0) * 0.1;
        const supplierRevenue = (platformAnalytics[0]?.totalPlatformRevenue || 0) * 0.9;

        // Recent users
        const recentUsers = await User.find({})
            .select('firstName lastName email role createdAt isActive')
            .sort({ createdAt: -1 })
            .limit(10);

        // Recent orders
        const recentOrders = await Order.find({})
            .populate('customer', 'firstName lastName')
            .populate('supplier', 'firstName lastName businessName')
            .populate('items.product', 'title images')
            .sort({ createdAt: -1 })
            .limit(10);

        // System health (mock data for now)
        const systemHealth = {
            status: 'healthy',
            uptime: 99.9,
            activeConnections: Math.floor(Math.random() * 100) + 50,
            services: {
                database: {
                    name: 'Database',
                    status: 'healthy',
                    message: 'All systems operational',
                    lastChecked: new Date(),
                },
                api: {
                    name: 'API Server',
                    status: 'healthy',
                    message: 'Response time: 45ms',
                    lastChecked: new Date(),
                },
                storage: {
                    name: 'File Storage',
                    status: 'healthy',
                    message: 'Available space: 85%',
                    lastChecked: new Date(),
                },
            },
        };

        // Format data to match frontend AdminDashboardData expectations
        res.status(200).json({
            success: true,
            totalUsers: totalActiveUsers,
            totalSuppliers,
            totalCustomers,
            totalProducts: await Product.countDocuments(),
            totalOrders: platformAnalytics[0]?.totalOrders || 0,
            totalRevenue: platformAnalytics[0]?.totalPlatformRevenue || 0,
            platformCommission: platformRevenue,
            revenueData: [], // TODO: Add revenue chart data
            recentUsers: recentUsers.map(user => ({
                name: `${user.firstName} ${user.lastName}`,
                email: user.email,
                role: user.role,
            })),
            topSuppliers: [], // TODO: Add top suppliers
            usersByRole: {
                'customer': totalCustomers,
                'supplier': totalSuppliers,
                'admin': userStats.find(stat => stat._id === 'admin')?.count || 0,
            },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get customer dashboard analytics
// @route   GET /api/dashboard/customer
// @access  Private (Customer)
exports.getCustomerDashboard = async (req, res, next) => {
    try {
        // Order statistics
        const orderStats = await Order.aggregate([
            {
                $match: {
                    customer: req.user._id,
                },
            },
            {
                $group: {
                    _id: null,
                    totalOrders: { $sum: 1 },
                    totalSpent: {
                        $sum: {
                            $cond: [
                                { $eq: ['$status', 'delivered'] },
                                '$total',
                                0,
                            ],
                        },
                    },
                    deliveredOrders: {
                        $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] },
                    },
                },
            },
        ]);

        // Recent orders
        const recentOrders = await Order.find({ customer: req.user.id })
            .populate('supplier', 'firstName lastName businessName')
            .populate('items.product', 'title images')
            .sort({ createdAt: -1 })
            .limit(5);

        // Active orders (not delivered or cancelled)
        const activeOrders = await Order.find({
            customer: req.user.id,
            status: { $nin: ['delivered', 'cancelled'] },
        })
            .populate('supplier', 'firstName lastName businessName')
            .populate('items.product', 'title images')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            data: {
                stats: orderStats[0] || {
                    totalOrders: 0,
                    totalSpent: 0,
                    deliveredOrders: 0,
                },
                recentOrders,
                activeOrders,
            },
        });
    } catch (error) {
        next(error);
    }
};
