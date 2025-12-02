/// 📊 Advanced Analytics Service
/// Comprehensive analytics and reporting for INDULINK platform

const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Category = require('../models/Category');
const Review = require('../models/Review');
const RFQ = require('../models/RFQ');
const Message = require('../models/Message');
const Notification = require('../models/Notification');

class AnalyticsService {
    // ==================== USER ANALYTICS ====================

    async getUserAnalytics(timeframe = '30d') {
        const startDate = this.getStartDate(timeframe);

        const [
            totalUsers,
            newUsers,
            activeUsers,
            userGrowth,
            userDemographics,
            userEngagement
        ] = await Promise.all([
            this.getTotalUsers(),
            this.getNewUsers(startDate),
            this.getActiveUsers(timeframe),
            this.getUserGrowth(timeframe),
            this.getUserDemographics(),
            this.getUserEngagement(timeframe)
        ]);

        return {
            summary: {
                totalUsers,
                newUsers: newUsers.length,
                activeUsers: activeUsers.length,
                growthRate: userGrowth.growthRate
            },
            growth: userGrowth,
            demographics: userDemographics,
            engagement: userEngagement,
            timeframe
        };
    }

    async getTotalUsers() {
        return await User.countDocuments();
    }

    async getNewUsers(startDate) {
        return await User.find({
            createdAt: { $gte: startDate }
        }).select('name email role createdAt');
    }

    async getActiveUsers(timeframe) {
        const startDate = this.getStartDate(timeframe);
        const endDate = new Date();

        // Users who have performed actions in the timeframe
        const activeUserIds = new Set();

        // Find users who placed orders
        const orderUsers = await Order.distinct('user', {
            createdAt: { $gte: startDate, $lte: endDate }
        });
        orderUsers.forEach(id => activeUserIds.add(id.toString()));

        // Find users who sent messages
        const messageUsers = await Message.distinct('sender', {
            createdAt: { $gte: startDate, $lte: endDate }
        });
        messageUsers.forEach(id => activeUserIds.add(id.toString()));

        // Find users who created RFQs
        const rfqUsers = await RFQ.distinct('customer', {
            createdAt: { $gte: startDate, $lte: endDate }
        });
        rfqUsers.forEach(id => activeUserIds.add(id.toString()));

        return await User.find({
            _id: { $in: Array.from(activeUserIds) }
        }).select('name email role');
    }

    async getUserGrowth(timeframe) {
        const periods = this.getGrowthPeriods(timeframe);
        const growthData = [];

        for (const period of periods) {
            const count = await User.countDocuments({
                createdAt: {
                    $gte: period.start,
                    $lt: period.end
                }
            });
            growthData.push({
                period: period.label,
                count,
                date: period.start
            });
        }

        const currentPeriod = growthData[growthData.length - 1]?.count || 0;
        const previousPeriod = growthData[growthData.length - 2]?.count || 0;
        const growthRate = previousPeriod > 0
            ? ((currentPeriod - previousPeriod) / previousPeriod) * 100
            : 0;

        return {
            data: growthData,
            growthRate: Math.round(growthRate * 100) / 100
        };
    }

    async getUserDemographics() {
        const users = await User.find({}).select('role createdAt');

        const roleDistribution = users.reduce((acc, user) => {
            acc[user.role] = (acc[user.role] || 0) + 1;
            return acc;
        }, {});

        // Registration trends by month
        const monthlyRegistrations = users.reduce((acc, user) => {
            const month = user.createdAt.toISOString().substring(0, 7); // YYYY-MM
            acc[month] = (acc[month] || 0) + 1;
            return acc;
        }, {});

        return {
            roleDistribution,
            monthlyRegistrations: Object.entries(monthlyRegistrations)
                .map(([month, count]) => ({ month, count }))
                .sort((a, b) => a.month.localeCompare(b.month))
        };
    }

    async getUserEngagement(timeframe) {
        const startDate = this.getStartDate(timeframe);

        const [
            totalOrders,
            totalMessages,
            totalRfqs,
            avgSessionDuration
        ] = await Promise.all([
            Order.countDocuments({ createdAt: { $gte: startDate } }),
            Message.countDocuments({ createdAt: { $gte: startDate } }),
            RFQ.countDocuments({ createdAt: { $gte: startDate } }),
            this.calculateAvgSessionDuration(timeframe)
        ]);

        const totalUsers = await this.getTotalUsers();
        const activeUsers = await this.getActiveUsers(timeframe);

        return {
            engagementRate: totalUsers > 0 ? (activeUsers.length / totalUsers) * 100 : 0,
            avgOrdersPerUser: activeUsers.length > 0 ? totalOrders / activeUsers.length : 0,
            avgMessagesPerUser: activeUsers.length > 0 ? totalMessages / activeUsers.length : 0,
            avgRfqsPerUser: activeUsers.length > 0 ? totalRfqs / activeUsers.length : 0,
            avgSessionDuration
        };
    }

    // ==================== SALES ANALYTICS ====================

    async getSalesAnalytics(timeframe = '30d') {
        const startDate = this.getStartDate(timeframe);

        const [
            totalRevenue,
            orderCount,
            avgOrderValue,
            salesByCategory,
            salesBySupplier,
            salesTrend,
            topProducts
        ] = await Promise.all([
            this.getTotalRevenue(startDate),
            this.getOrderCount(startDate),
            this.getAvgOrderValue(startDate),
            this.getSalesByCategory(startDate),
            this.getSalesBySupplier(startDate),
            this.getSalesTrend(timeframe),
            this.getTopProducts(startDate)
        ]);

        return {
            summary: {
                totalRevenue,
                orderCount,
                avgOrderValue,
                conversionRate: await this.getConversionRate(timeframe)
            },
            byCategory: salesByCategory,
            bySupplier: salesBySupplier,
            trend: salesTrend,
            topProducts,
            timeframe
        };
    }

    async getTotalRevenue(startDate) {
        const result = await Order.aggregate([
            { $match: { createdAt: { $gte: startDate }, status: 'delivered' } },
            { $group: { _id: null, total: { $sum: '$total' } } }
        ]);
        return result[0]?.total || 0;
    }

    async getOrderCount(startDate) {
        return await Order.countDocuments({
            createdAt: { $gte: startDate },
            status: { $ne: 'cancelled' }
        });
    }

    async getAvgOrderValue(startDate) {
        const result = await Order.aggregate([
            { $match: { createdAt: { $gte: startDate }, status: 'delivered' } },
            { $group: { _id: null, avgValue: { $avg: '$total' }, count: { $sum: 1 } } }
        ]);
        return result[0]?.avgValue || 0;
    }

    async getSalesByCategory(startDate) {
        const result = await Order.aggregate([
            { $match: { createdAt: { $gte: startDate }, status: 'delivered' } },
            { $unwind: '$items' },
            {
                $lookup: {
                    from: 'products',
                    localField: 'items.product',
                    foreignField: '_id',
                    as: 'product'
                }
            },
            { $unwind: '$product' },
            {
                $lookup: {
                    from: 'categories',
                    localField: 'product.category',
                    foreignField: '_id',
                    as: 'category'
                }
            },
            { $unwind: '$category' },
            {
                $group: {
                    _id: '$category._id',
                    name: { $first: '$category.name' },
                    revenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
                    orders: { $addToSet: '$_id' }
                }
            },
            {
                $project: {
                    name: 1,
                    revenue: 1,
                    orderCount: { $size: '$orders' }
                }
            },
            { $sort: { revenue: -1 } }
        ]);

        return result;
    }

    async getSalesBySupplier(startDate) {
        const result = await Order.aggregate([
            { $match: { createdAt: { $gte: startDate }, status: 'delivered' } },
            { $unwind: '$items' },
            {
                $lookup: {
                    from: 'products',
                    localField: 'items.product',
                    foreignField: '_id',
                    as: 'product'
                }
            },
            { $unwind: '$product' },
            {
                $lookup: {
                    from: 'users',
                    localField: 'product.supplier',
                    foreignField: '_id',
                    as: 'supplier'
                }
            },
            { $unwind: '$supplier' },
            {
                $group: {
                    _id: '$supplier._id',
                    name: { $first: '$supplier.name' },
                    revenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
                    orders: { $addToSet: '$_id' }
                }
            },
            {
                $project: {
                    name: 1,
                    revenue: 1,
                    orderCount: { $size: '$orders' }
                }
            },
            { $sort: { revenue: -1 } }
        ]);

        return result;
    }

    async getSalesTrend(timeframe) {
        const periods = this.getGrowthPeriods(timeframe);
        const trendData = [];

        for (const period of periods) {
            const revenue = await this.getTotalRevenue(period.start);
            trendData.push({
                period: period.label,
                revenue,
                date: period.start
            });
        }

        return trendData;
    }

    async getTopProducts(startDate, limit = 10) {
        const result = await Order.aggregate([
            { $match: { createdAt: { $gte: startDate }, status: 'delivered' } },
            { $unwind: '$items' },
            {
                $lookup: {
                    from: 'products',
                    localField: 'items.product',
                    foreignField: '_id',
                    as: 'product'
                }
            },
            { $unwind: '$product' },
            {
                $group: {
                    _id: '$product._id',
                    name: { $first: '$product.title' },
                    image: { $first: '$product.images' },
                    revenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
                    quantity: { $sum: '$items.quantity' },
                    orders: { $addToSet: '$_id' }
                }
            },
            {
                $project: {
                    name: 1,
                    image: { $arrayElemAt: ['$image', 0] },
                    revenue: 1,
                    quantity: 1,
                    orderCount: { $size: '$orders' }
                }
            },
            { $sort: { revenue: -1 } },
            { $limit: limit }
        ]);

        return result;
    }

    async getConversionRate(timeframe) {
        const startDate = this.getStartDate(timeframe);

        const [totalVisitors, totalOrders] = await Promise.all([
            // This would typically come from a separate analytics service
            // For now, we'll use a proxy based on user registrations
            User.countDocuments({ createdAt: { $gte: startDate } }),
            Order.countDocuments({ createdAt: { $gte: startDate } })
        ]);

        return totalVisitors > 0 ? (totalOrders / totalVisitors) * 100 : 0;
    }

    // ==================== PRODUCT ANALYTICS ====================

    async getProductAnalytics(timeframe = '30d') {
        const startDate = this.getStartDate(timeframe);

        const [
            totalProducts,
            activeProducts,
            lowStockProducts,
            productPerformance,
            categoryPerformance,
            inventoryStatus
        ] = await Promise.all([
            Product.countDocuments(),
            Product.countDocuments({ isActive: true }),
            Product.countDocuments({ stock: { $lt: 10 } }),
            this.getProductPerformance(startDate),
            this.getCategoryPerformance(startDate),
            this.getInventoryStatus()
        ]);

        return {
            summary: {
                totalProducts,
                activeProducts,
                inactiveProducts: totalProducts - activeProducts,
                lowStockProducts
            },
            performance: productPerformance,
            categories: categoryPerformance,
            inventory: inventoryStatus,
            timeframe
        };
    }

    async getProductPerformance(startDate) {
        const result = await Product.aggregate([
            {
                $lookup: {
                    from: 'orders',
                    let: { productId: '$_id' },
                    pipeline: [
                        { $match: { createdAt: { $gte: startDate }, status: 'delivered' } },
                        { $unwind: '$items' },
                        { $match: { $expr: { $eq: ['$items.product', '$$productId'] } } },
                        {
                            $group: {
                                _id: null,
                                revenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
                                quantity: { $sum: '$items.quantity' },
                                orders: { $addToSet: '$_id' }
                            }
                        }
                    ],
                    as: 'sales'
                }
            },
            {
                $addFields: {
                    salesData: { $arrayElemAt: ['$sales', 0] }
                }
            },
            {
                $project: {
                    title: 1,
                    price: 1,
                    stock: 1,
                    isActive: 1,
                    images: { $arrayElemAt: ['$images', 0] },
                    revenue: { $ifNull: ['$salesData.revenue', 0] },
                    quantitySold: { $ifNull: ['$salesData.quantity', 0] },
                    orderCount: {
                        $size: { $ifNull: ['$salesData.orders', []] }
                    }
                }
            },
            { $sort: { revenue: -1 } }
        ]);

        return result;
    }

    async getCategoryPerformance(startDate) {
        const result = await Category.aggregate([
            {
                $lookup: {
                    from: 'products',
                    localField: '_id',
                    foreignField: 'category',
                    as: 'products'
                }
            },
            {
                $lookup: {
                    from: 'orders',
                    let: { categoryId: '$_id' },
                    pipeline: [
                        { $match: { createdAt: { $gte: startDate }, status: 'delivered' } },
                        { $unwind: '$items' },
                        {
                            $lookup: {
                                from: 'products',
                                localField: 'items.product',
                                foreignField: '_id',
                                as: 'product'
                            }
                        },
                        { $unwind: '$product' },
                        { $match: { $expr: { $eq: ['$product.category', '$$categoryId'] } } },
                        {
                            $group: {
                                _id: null,
                                revenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
                                quantity: { $sum: '$items.quantity' }
                            }
                        }
                    ],
                    as: 'sales'
                }
            },
            {
                $addFields: {
                    salesData: { $arrayElemAt: ['$sales', 0] },
                    productCount: { $size: '$products' }
                }
            },
            {
                $project: {
                    name: 1,
                    productCount: 1,
                    revenue: { $ifNull: ['$salesData.revenue', 0] },
                    quantitySold: { $ifNull: ['$salesData.quantity', 0] }
                }
            },
            { $sort: { revenue: -1 } }
        ]);

        return result;
    }

    async getInventoryStatus() {
        const result = await Product.aggregate([
            {
                $group: {
                    _id: {
                        $switch: {
                            branches: [
                                { case: { $lt: ['$stock', 5] }, then: 'critical' },
                                { case: { $lt: ['$stock', 10] }, then: 'low' },
                                { case: { $lt: ['$stock', 50] }, then: 'medium' }
                            ],
                            default: 'high'
                        }
                    },
                    count: { $sum: 1 },
                    products: { $push: { title: '$title', stock: '$stock' } }
                }
            }
        ]);

        const statusMap = {};
        result.forEach(item => {
            statusMap[item._id] = {
                count: item.count,
                products: item.products.slice(0, 5) // Top 5 products in each category
            };
        });

        return statusMap;
    }

    // ==================== SYSTEM ANALYTICS ====================

    async getSystemAnalytics(timeframe = '24h') {
        const startDate = this.getStartDate(timeframe);

        const [
            apiMetrics,
            errorMetrics,
            performanceMetrics,
            userActivity
        ] = await Promise.all([
            this.getAPIMetrics(startDate),
            this.getErrorMetrics(startDate),
            this.getPerformanceMetrics(startDate),
            this.getUserActivityMetrics(startDate)
        ]);

        return {
            api: apiMetrics,
            errors: errorMetrics,
            performance: performanceMetrics,
            activity: userActivity,
            timeframe
        };
    }

    async getAPIMetrics(startDate) {
        // This would typically come from API monitoring middleware
        // For now, return mock data structure
        return {
            totalRequests: 0,
            avgResponseTime: 0,
            successRate: 100,
            endpoints: []
        };
    }

    async getErrorMetrics(startDate) {
        // This would typically come from error logging
        return {
            totalErrors: 0,
            errorRate: 0,
            topErrors: []
        };
    }

    async getPerformanceMetrics(startDate) {
        // This would typically come from performance monitoring
        return {
            avgLoadTime: 0,
            memoryUsage: 0,
            cpuUsage: 0,
            uptime: 0
        };
    }

    async getUserActivityMetrics(startDate) {
        const [
            totalSessions,
            avgSessionDuration,
            pageViews,
            bounceRate
        ] = await Promise.all([
            this.getTotalSessions(startDate),
            this.calculateAvgSessionDuration(timeframe),
            this.getPageViews(startDate),
            this.getBounceRate(startDate)
        ]);

        return {
            totalSessions,
            avgSessionDuration,
            pageViews,
            bounceRate
        };
    }

    // ==================== HELPER METHODS ====================

    getStartDate(timeframe) {
        const now = new Date();
        const units = {
            '1h': 1 * 60 * 60 * 1000,
            '24h': 24 * 60 * 60 * 1000,
            '7d': 7 * 24 * 60 * 60 * 1000,
            '30d': 30 * 24 * 60 * 60 * 1000,
            '90d': 90 * 24 * 60 * 60 * 1000,
            '1y': 365 * 24 * 60 * 60 * 1000
        };

        return new Date(now.getTime() - (units[timeframe] || units['30d']));
    }

    getGrowthPeriods(timeframe) {
        const periods = [];
        const now = new Date();
        const unit = timeframe.endsWith('d') ? 'days' : timeframe.endsWith('h') ? 'hours' : 'months';
        const count = parseInt(timeframe.replace(/\D/g, ''));

        for (let i = count - 1; i >= 0; i--) {
            const date = new Date(now);
            if (unit === 'days') {
                date.setDate(date.getDate() - i);
                date.setHours(0, 0, 0, 0);
            } else if (unit === 'hours') {
                date.setHours(date.getHours() - i);
            } else {
                date.setMonth(date.getMonth() - i);
            }

            const endDate = new Date(date);
            if (unit === 'days') {
                endDate.setDate(endDate.getDate() + 1);
            } else if (unit === 'hours') {
                endDate.setHours(endDate.getHours() + 1);
            } else {
                endDate.setMonth(endDate.getMonth() + 1);
            }

            periods.push({
                start: date,
                end: endDate,
                label: this.formatPeriodLabel(date, unit)
            });
        }

        return periods;
    }

    formatPeriodLabel(date, unit) {
        if (unit === 'hours') {
            return date.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit'
            });
        } else if (unit === 'days') {
            return date.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric'
            });
        } else {
            return date.toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short'
            });
        }
    }

    async calculateAvgSessionDuration(timeframe) {
        // This would typically come from session tracking
        // For now, return a mock calculation
        return 15 * 60 * 1000; // 15 minutes in milliseconds
    }

    async getTotalSessions(startDate) {
        // This would typically come from session tracking
        return await User.countDocuments({ lastLogin: { $gte: startDate } });
    }

    async getPageViews(startDate) {
        // This would typically come from page view tracking
        return 0;
    }

    async getBounceRate(startDate) {
        // This would typically come from session tracking
        return 0;
    }
}

module.exports = new AnalyticsService();