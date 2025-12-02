/// 📊 Analytics Controller
/// Handles analytics and reporting API endpoints

const analyticsService = require('../services/analyticsService');

// @desc    Get user analytics
// @route   GET /api/analytics/users
// @access  Private (Admin only)
exports.getUserAnalytics = async (req, res, next) => {
    try {
        const timeframe = req.query.timeframe || '30d';
        const data = await analyticsService.getUserAnalytics(timeframe);

        res.status(200).json({
            success: true,
            data
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get sales analytics
// @route   GET /api/analytics/sales
// @access  Private (Admin and Supplier)
exports.getSalesAnalytics = async (req, res, next) => {
    try {
        const timeframe = req.query.timeframe || '30d';
        const data = await analyticsService.getSalesAnalytics(timeframe);

        // For suppliers, filter data to only show their products
        if (req.user.role === 'supplier') {
            data.bySupplier = data.bySupplier.filter(
                supplier => supplier._id.toString() === req.user.id
            );
            data.topProducts = await analyticsService.getTopProducts(
                analyticsService.getStartDate(timeframe),
                10,
                req.user.id
            );
        }

        res.status(200).json({
            success: true,
            data
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get product analytics
// @route   GET /api/analytics/products
// @access  Private (Admin and Supplier)
exports.getProductAnalytics = async (req, res, next) => {
    try {
        const timeframe = req.query.timeframe || '30d';
        const data = await analyticsService.getProductAnalytics(timeframe);

        // For suppliers, filter data to only show their products
        if (req.user.role === 'supplier') {
            data.performance = data.performance.filter(
                product => product.supplier?.toString() === req.user.id
            );
        }

        res.status(200).json({
            success: true,
            data
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get system analytics
// @route   GET /api/analytics/system
// @access  Private (Admin only)
exports.getSystemAnalytics = async (req, res, next) => {
    try {
        const timeframe = req.query.timeframe || '24h';
        const data = await analyticsService.getSystemAnalytics(timeframe);

        res.status(200).json({
            success: true,
            data
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get comprehensive dashboard analytics
// @route   GET /api/analytics/dashboard
// @access  Private (Role-based access)
exports.getDashboardAnalytics = async (req, res, next) => {
    try {
        const timeframe = req.query.timeframe || '30d';

        const [
            userAnalytics,
            salesAnalytics,
            productAnalytics,
            systemAnalytics
        ] = await Promise.all([
            req.user.role === 'admin' ? analyticsService.getUserAnalytics(timeframe) : null,
            analyticsService.getSalesAnalytics(timeframe),
            analyticsService.getProductAnalytics(timeframe),
            req.user.role === 'admin' ? analyticsService.getSystemAnalytics('24h') : null
        ]);

        // Filter data based on user role
        if (req.user.role === 'supplier') {
            salesAnalytics.bySupplier = salesAnalytics.bySupplier.filter(
                supplier => supplier._id.toString() === req.user.id
            );
            productAnalytics.performance = productAnalytics.performance.filter(
                product => product.supplier?.toString() === req.user.id
            );
        }

        const dashboard = {
            user: userAnalytics,
            sales: salesAnalytics,
            product: productAnalytics,
            system: systemAnalytics,
            timeframe,
            generatedAt: new Date().toISOString()
        };

        res.status(200).json({
            success: true,
            data: dashboard
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get custom analytics report
// @route   POST /api/analytics/custom
// @access  Private (Admin only)
exports.getCustomAnalytics = async (req, res, next) => {
    try {
        const {
            metrics = [],
            timeframe = '30d',
            filters = {},
            groupBy = null,
            sortBy = null,
            limit = 100
        } = req.body;

        const startDate = analyticsService.getStartDate(timeframe);
        const results = {};

        // Process each requested metric
        for (const metric of metrics) {
            switch (metric) {
                case 'user_growth':
                    results.userGrowth = await analyticsService.getUserGrowth(timeframe);
                    break;
                case 'sales_trend':
                    results.salesTrend = await analyticsService.getSalesTrend(timeframe);
                    break;
                case 'top_products':
                    results.topProducts = await analyticsService.getTopProducts(startDate, limit);
                    break;
                case 'sales_by_category':
                    results.salesByCategory = await analyticsService.getSalesByCategory(startDate);
                    break;
                case 'sales_by_supplier':
                    results.salesBySupplier = await analyticsService.getSalesBySupplier(startDate);
                    break;
                case 'product_performance':
                    results.productPerformance = await analyticsService.getProductPerformance(startDate);
                    break;
                case 'inventory_status':
                    results.inventoryStatus = await analyticsService.getInventoryStatus();
                    break;
                default:
                    // Handle custom metrics
                    break;
            }
        }

        // Apply filters if provided
        if (Object.keys(filters).length > 0) {
            results.filters = filters;
            // Apply filtering logic here
        }

        // Apply grouping if requested
        if (groupBy) {
            results.groupBy = groupBy;
            // Apply grouping logic here
        }

        // Apply sorting if requested
        if (sortBy) {
            results.sortBy = sortBy;
            // Apply sorting logic here
        }

        res.status(200).json({
            success: true,
            data: {
                results,
                metadata: {
                    timeframe,
                    startDate,
                    requestedMetrics: metrics,
                    generatedAt: new Date().toISOString()
                }
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Export analytics report
// @route   GET /api/analytics/export/:type
// @access  Private (Admin only)
exports.exportAnalyticsReport = async (req, res, next) => {
    try {
        const { type } = req.params;
        const format = req.query.format || 'pdf';
        const timeframe = req.query.timeframe || '30d';

        let data;
        let title;

        switch (type) {
            case 'users':
                data = await analyticsService.getUserAnalytics(timeframe);
                title = 'User Analytics Report';
                break;
            case 'sales':
                data = await analyticsService.getSalesAnalytics(timeframe);
                title = 'Sales Analytics Report';
                break;
            case 'products':
                data = await analyticsService.getProductAnalytics(timeframe);
                title = 'Product Analytics Report';
                break;
            case 'system':
                data = await analyticsService.getSystemAnalytics(timeframe);
                title = 'System Analytics Report';
                break;
            case 'dashboard':
                data = await analyticsService.getDashboardAnalytics(timeframe);
                title = 'Dashboard Analytics Report';
                break;
            default:
                return res.status(400).json({
                    success: false,
                    message: 'Invalid report type'
                });
        }

        const exportService = require('../services/dataExportService');
        let result;

        switch (format.toLowerCase()) {
            case 'pdf':
                result = await exportService.exportToPDF([data], `${type}_analytics_${Date.now()}`, {
                    title: title
                });
                break;
            default:
                result = await exportService.exportToJSON(data, `${type}_analytics_${Date.now()}`);
        }

        // Set appropriate headers
        const mimeTypes = {
            json: 'application/json',
            pdf: 'application/pdf'
        };

        res.setHeader('Content-Type', mimeTypes[format] || 'application/octet-stream');
        res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);

        // Stream the file
        const fs = require('fs');
        const fileStream = fs.createReadStream(result.filePath);
        fileStream.pipe(res);

        // Clean up
        fileStream.on('end', () => {
            setTimeout(() => {
                try {
                    fs.unlinkSync(result.filePath);
                } catch (error) {
                    console.error('Error cleaning up analytics export file:', error);
                }
            }, 5000);
        });

    } catch (error) {
        next(error);
    }
};

// @desc    Get analytics configuration
// @route   GET /api/analytics/config
// @access  Public
exports.getAnalyticsConfig = async (req, res, next) => {
    res.status(200).json({
        success: true,
        data: {
            timeframes: ['1h', '24h', '7d', '30d', '90d', '1y'],
            metrics: {
                user: ['totalUsers', 'newUsers', 'activeUsers', 'growthRate', 'engagementRate'],
                sales: ['totalRevenue', 'orderCount', 'avgOrderValue', 'conversionRate'],
                product: ['totalProducts', 'activeProducts', 'lowStockProducts'],
                system: ['totalRequests', 'avgResponseTime', 'errorRate', 'uptime']
            },
            exportFormats: ['json', 'pdf'],
            reportTypes: ['users', 'sales', 'products', 'system', 'dashboard']
        }
    });
};
