const Order = require('../models/Order');
const Product = require('../models/Product');
const User = require('../models/User');
const PDFDocument = require('pdfkit');

// Helper: Generate CSV from data
const generateCSV = (headers, rows) => {
    const csvRows = [headers.join(',')];
    for (const row of rows) {
        csvRows.push(row.join(','));
    }
    return csvRows.join('\n');
};

// Helper: Calculate percentage change
const calculatePercentageChange = (current, previous) => {
    if (previous === 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
};

// @desc    Get sales trends analysis
// @route   GET /api/analytics/sales-trends?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&interval=day|week|month
// @access  Private (Supplier)
exports.getSalesTrends = async (req, res, next) => {
    try {
        const { startDate, endDate, interval = 'day' } = req.query;
        const userId = req.user.id;
        const userRole = req.user.role;

        // Validate dates
        if (!startDate || !endDate) {
            return res.status(400).json({
                success: false,
                message: 'Start date and end date are required',
            });
        }

        const start = new Date(startDate);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        // Build match query based on role
        const matchQuery = {
            createdAt: { $gte: start, $lte: end },
            status: { $in: ['delivered', 'shipped', 'processing'] },
        };

        if (userRole === 'supplier') {
            matchQuery.supplier = req.user._id;
        } else if (userRole === 'customer') {
            matchQuery.customer = req.user._id;
        }

        // Determine date format based on interval
        let dateFormat;
        if (interval === 'week') {
            dateFormat = '%Y-W%V'; // Year-Week
        } else if (interval === 'month') {
            dateFormat = '%Y-%m'; // Year-Month
        } else {
            dateFormat = '%Y-%m-%d'; // Year-Month-Day
        }

        // Aggregate sales data
        const salesTrends = await Order.aggregate([
            { $match: matchQuery },
            {
                $group: {
                    _id: {
                        $dateToString: { format: dateFormat, date: '$createdAt' },
                    },
                    revenue: { $sum: '$total' },
                    orders: { $sum: 1 },
                    averageOrderValue: { $avg: '$total' },
                },
            },
            { $sort: { _id: 1 } },
        ]);

        // Calculate totals
        const totals = {
            totalRevenue: salesTrends.reduce((sum, item) => sum + item.revenue, 0),
            totalOrders: salesTrends.reduce((sum, item) => sum + item.orders, 0),
            averageOrderValue: salesTrends.length > 0
                ? salesTrends.reduce((sum, item) => sum + item.averageOrderValue, 0) / salesTrends.length
                : 0,
        };

        // Calculate previous period for comparison
        const periodDuration = end - start;
        const prevStart = new Date(start.getTime() - periodDuration);
        const prevEnd = new Date(start.getTime() - 1);

        const prevMatchQuery = { ...matchQuery, createdAt: { $gte: prevStart, $lte: prevEnd } };

        const prevPeriodData = await Order.aggregate([
            { $match: prevMatchQuery },
            {
                $group: {
                    _id: null,
                    totalRevenue: { $sum: '$total' },
                    totalOrders: { $sum: 1 },
                    averageOrderValue: { $avg: '$total' },
                },
            },
        ]);

        const prevTotals = prevPeriodData[0] || {
            totalRevenue: 0,
            totalOrders: 0,
            averageOrderValue: 0,
        };

        // Calculate growth percentages
        const comparison = {
            revenueGrowth: calculatePercentageChange(totals.totalRevenue, prevTotals.totalRevenue),
            ordersGrowth: calculatePercentageChange(totals.totalOrders, prevTotals.totalOrders),
            avgOrderValueGrowth: calculatePercentageChange(totals.averageOrderValue, prevTotals.averageOrderValue),
        };

        res.status(200).json({
            success: true,
            data: {
                trends: salesTrends,
                totals,
                comparison,
                period: {
                    start: startDate,
                    end: endDate,
                    interval,
                },
            },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get product performance metrics
// @route   GET /api/analytics/product-performance?limit=20
// @access  Private (Supplier)
exports.getProductPerformance = async (req, res, next) => {
    try {
        const { limit = 20 } = req.query;
        const userId = req.user.id;
        const userRole = req.user.role;

        // Build match query
        const matchQuery = { status: 'delivered' };
        if (userRole === 'supplier') {
            matchQuery.supplier = req.user._id;
        }

        // Top products by revenue
        const topProducts = await Order.aggregate([
            { $match: matchQuery },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.product',
                    totalRevenue: { $sum: '$items.subtotal' },
                    totalQuantity: { $sum: '$items.quantity' },
                    orderCount: { $sum: 1 },
                },
            },
            { $sort: { totalRevenue: -1 } },
            { $limit: parseInt(limit) },
        ]);

        // Populate product details
        await Product.populate(topProducts, {
            path: '_id',
            select: 'title images price category stock',
        });

        // Bottom products (need improvement)
        const bottomProducts = await Order.aggregate([
            { $match: matchQuery },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.product',
                    totalRevenue: { $sum: '$items.subtotal' },
                    totalQuantity: { $sum: '$items.quantity' },
                },
            },
            { $sort: { totalRevenue: 1 } },
            { $limit: 10 },
        ]);

        await Product.populate(bottomProducts, {
            path: '_id',
            select: 'title images price',
        });

        // Category performance
        const categoryPerformance = await Order.aggregate([
            { $match: matchQuery },
            { $unwind: '$items' },
            {
                $lookup: {
                    from: 'products',
                    localField: 'items.product',
                    foreignField: '_id',
                    as: 'productInfo',
                },
            },
            { $unwind: '$productInfo' },
            {
                $group: {
                    _id: '$productInfo.category',
                    revenue: { $sum: '$items.subtotal' },
                    quantity: { $sum: '$items.quantity' },
                },
            },
            { $sort: { revenue: -1 } },
        ]);

        // Get all products for stock analysis (supplier only)
        let stockAnalysis = null;
        if (userRole === 'supplier') {
            const products = await Product.find({ supplier: req.user._id });
            const lowStock = products.filter(p => p.stock > 0 && p.stock < 10);
            const outOfStock = products.filter(p => p.stock === 0);

            stockAnalysis = {
                totalProducts: products.length,
                lowStock: lowStock.length,
                outOfStock: outOfStock.length,
                lowStockProducts: lowStock.slice(0, 5).map(p => ({
                    id: p._id,
                    title: p.title,
                    stock: p.stock,
                    image: p.images[0],
                })),
            };
        }

        res.status(200).json({
            success: true,
            data: {
                topProducts,
                bottomProducts,
                categoryPerformance,
                stockAnalysis,
            },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get customer behavior analytics
// @route   GET /api/analytics/customer-behavior
// @access  Private (Supplier/Admin)
exports.getCustomerBehavior = async (req, res, next) => {
    try {
        if (req.user.role !== 'supplier' && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Supplier or admin role required.',
            });
        }

        const supplierId = req.user.role === 'supplier' ? req.user._id : null;
        const matchQuery = supplierId ? { supplier: supplierId } : {};

        // New vs returning customers
        const customerAnalysis = await Order.aggregate([
            { $match: matchQuery },
            {
                $group: {
                    _id: '$customer',
                    orderCount: { $sum: 1 },
                    totalSpent: { $sum: '$total' },
                    firstOrder: { $min: '$createdAt' },
                    lastOrder: { $max: '$createdAt' },
                },
            },
        ]);

        const newCustomers = customerAnalysis.filter(c => c.orderCount === 1).length;
        const returningCustomers = customerAnalysis.filter(c => c.orderCount > 1).length;

        // Average customer lifetime value
        const avgLifetimeValue = customerAnalysis.length > 0
            ? customerAnalysis.reduce((sum, c) => sum + c.totalSpent, 0) / customerAnalysis.length
            : 0;

        // Purchase frequency
        const avgOrdersPerCustomer = customerAnalysis.length > 0
            ? customerAnalysis.reduce((sum, c) => sum + c.orderCount, 0) / customerAnalysis.length
            : 0;

        // Top customers
        const topCustomers = customerAnalysis
            .sort((a, b) => b.totalSpent - a.totalSpent)
            .slice(0, 10);

        await User.populate(topCustomers, {
            path: '_id',
            select: 'firstName lastName email',
        });

        res.status(200).json({
            success: true,
            data: {
                summary: {
                    totalCustomers: customerAnalysis.length,
                    newCustomers,
                    returningCustomers,
                    avgLifetimeValue,
                    avgOrdersPerCustomer,
                },
                topCustomers,
            },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get supplier performance KPIs
// @route   GET /api/analytics/supplier-performance
// @access  Private (Supplier)
exports.getSupplierPerformance = async (req, res, next) => {
    try {
        const supplierId = req.user._id;

        // Order fulfillment metrics
        const orderMetrics = await Order.aggregate([
            { $match: { supplier: supplierId } },
            {
                $group: {
                    _id: null,
                    totalOrders: { $sum: 1 },
                    delivered: {
                        $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] },
                    },
                    cancelled: {
                        $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] },
                    },
                    processing: {
                        $sum: { $cond: [{ $eq: ['$status', 'processing'] }, 1, 0] },
                    },
                },
            },
        ]);

        const metrics = orderMetrics[0] || {
            totalOrders: 0,
            delivered: 0,
            cancelled: 0,
            processing: 0,
        };

        const fulfillmentRate = metrics.totalOrders > 0
            ? (metrics.delivered / metrics.totalOrders) * 100
            : 0;

        // Average delivery time (for delivered orders)
        const deliveryTimeData = await Order.aggregate([
            {
                $match: {
                    supplier: supplierId,
                    status: 'delivered',
                    deliveredAt: { $exists: true },
                },
            },
            {
                $project: {
                    deliveryTime: {
                        $divide: [
                            { $subtract: ['$deliveredAt', '$createdAt'] },
                            1000 * 60 * 60 * 24, // Convert to days
                        ],
                    },
                },
            },
            {
                $group: {
                    _id: null,
                    avgDeliveryTime: { $avg: '$deliveryTime' },
                },
            },
        ]);

        const avgDeliveryTime = deliveryTimeData[0]?.avgDeliveryTime || 0;

        // Product catalog stats
        const productStats = await Product.aggregate([
            { $match: { supplier: supplierId } },
            {
                $group: {
                    _id: null,
                    totalProducts: { $sum: 1 },
                    activeProducts: {
                        $sum: { $cond: [{ $eq: ['$status', 'active'] }, 1, 0] },
                    },
                },
            },
        ]);

        const products = productStats[0] || { totalProducts: 0, activeProducts: 0 };

        res.status(200).json({
            success: true,
            data: {
                orderMetrics: metrics,
                fulfillmentRate: fulfillmentRate.toFixed(2),
                avgDeliveryTime: avgDeliveryTime.toFixed(1),
                productStats: products,
            },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get comparative analysis (period-over-period)
// @route   GET /api/analytics/compare?period=week|month|quarter|year
// @access  Private
exports.getComparativeAnalysis = async (req, res, next) => {
    try {
        const { period = 'month' } = req.query;
        const userId = req.user.id;
        const userRole = req.user.role;

        // Calculate date ranges
        const now = new Date();
        let currentStart, currentEnd, previousStart, previousEnd;

        if (period === 'week') {
            currentEnd = new Date(now);
            currentStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            previousEnd = new Date(currentStart.getTime() - 1);
            previousStart = new Date(previousEnd.getTime() - 7 * 24 * 60 * 60 * 1000);
        } else if (period === 'month') {
            currentEnd = new Date(now);
            currentStart = new Date(now.getFullYear(), now.getMonth(), 1);
            previousEnd = new Date(currentStart.getTime() - 1);
            previousStart = new Date(previousEnd.getFullYear(), previousEnd.getMonth(), 1);
        } else if (period === 'quarter') {
            const currentQuarter = Math.floor(now.getMonth() / 3);
            currentStart = new Date(now.getFullYear(), currentQuarter * 3, 1);
            currentEnd = new Date(now);
            previousEnd = new Date(currentStart.getTime() - 1);
            const prevQuarter = Math.floor(previousEnd.getMonth() / 3);
            previousStart = new Date(previousEnd.getFullYear(), prevQuarter * 3, 1);
        } else {
            // year
            currentStart = new Date(now.getFullYear(), 0, 1);
            currentEnd = new Date(now);
            previousStart = new Date(now.getFullYear() - 1, 0, 1);
            previousEnd = new Date(now.getFullYear() - 1, 11, 31);
        }

        // Build match query
        const baseMatch = { status: { $in: ['delivered', 'shipped', 'processing'] } };
        if (userRole === 'supplier') {
            baseMatch.supplier = req.user._id;
        } else if (userRole === 'customer') {
            baseMatch.customer = req.user._id;
        }

        // Current period data
        const currentData = await Order.aggregate([
            {
                $match: {
                    ...baseMatch,
                    createdAt: { $gte: currentStart, $lte: currentEnd },
                },
            },
            {
                $group: {
                    _id: null,
                    revenue: { $sum: '$total' },
                    orders: { $sum: 1 },
                    avgOrderValue: { $avg: '$total' },
                },
            },
        ]);

        // Previous period data
        const previousData = await Order.aggregate([
            {
                $match: {
                    ...baseMatch,
                    createdAt: { $gte: previousStart, $lte: previousEnd },
                },
            },
            {
                $group: {
                    _id: null,
                    revenue: { $sum: '$total' },
                    orders: { $sum: 1 },
                    avgOrderValue: { $avg: '$total' },
                },
            },
        ]);

        const current = currentData[0] || { revenue: 0, orders: 0, avgOrderValue: 0 };
        const previous = previousData[0] || { revenue: 0, orders: 0, avgOrderValue: 0 };

        // Calculate changes
        const comparison = {
            revenue: {
                current: current.revenue,
                previous: previous.revenue,
                change: calculatePercentageChange(current.revenue, previous.revenue),
                trend: current.revenue >= previous.revenue ? 'up' : 'down',
            },
            orders: {
                current: current.orders,
                previous: previous.orders,
                change: calculatePercentageChange(current.orders, previous.orders),
                trend: current.orders >= previous.orders ? 'up' : 'down',
            },
            avgOrderValue: {
                current: current.avgOrderValue,
                previous: previous.avgOrderValue,
                change: calculatePercentageChange(current.avgOrderValue, previous.avgOrderValue),
                trend: current.avgOrderValue >= previous.avgOrderValue ? 'up' : 'down',
            },
        };

        res.status(200).json({
            success: true,
            data: {
                period,
                currentPeriod: {
                    start: currentStart,
                    end: currentEnd,
                },
                previousPeriod: {
                    start: previousStart,
                    end: previousEnd,
                },
                comparison,
            },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Export analytics as CSV
// @route   GET /api/analytics/export/csv?reportType=sales|products|customers&startDate=XXX&endDate=XXX
// @access  Private
exports.exportCSV = async (req, res, next) => {
    try {
        const { reportType, startDate, endDate } = req.query;

        if (!reportType) {
            return res.status(400).json({
                success: false,
                message: 'Report type is required',
            });
        }

        const start = startDate ? new Date(startDate) : new Date(new Date().getTime() - 30 * 24 * 60 * 60 * 1000);
        const end = endDate ? new Date(endDate) : new Date();
        end.setHours(23, 59, 59, 999);

        const matchQuery = {
            createdAt: { $gte: start, $lte: end },
        };

        if (req.user.role === 'supplier') {
            matchQuery.supplier = req.user._id;
        } else if (req.user.role === 'customer') {
            matchQuery.customer = req.user._id;
        }

        let csvData;
        let filename;

        if (reportType === 'sales') {
            const orders = await Order.find(matchQuery)
                .populate('customer', 'firstName lastName email')
                .sort({ createdAt: -1 });

            const headers = ['Order ID', 'Date', 'Customer', 'Status', 'Total', 'Items'];
            const rows = orders.map(order => [
                order._id.toString(),
                order.createdAt.toISOString().split('T')[0],
                order.customer ? `${order.customer.firstName} ${order.customer.lastName}` : 'N/A',
                order.status,
                order.total.toFixed(2),
                order.items.length,
            ]);

            csvData = generateCSV(headers, rows);
            filename = `sales_report_${start.toISOString().split('T')[0]}_to_${end.toISOString().split('T')[0]}.csv`;
        } else if (reportType === 'products') {
            const productMatch = req.user.role === 'supplier' ? { supplier: req.user._id } : {};
            const products = await Product.find(productMatch).populate('category', 'name');

            const headers = ['Product ID', 'Title', 'Category', 'Price', 'Stock', 'Status'];
            const rows = products.map(product => [
                product._id.toString(),
                product.title,
                product.category?.name || 'N/A',
                product.price.toFixed(2),
                product.stock,
                product.status,
            ]);

            csvData = generateCSV(headers, rows);
            filename = `products_report_${new Date().toISOString().split('T')[0]}.csv`;
        } else {
            return res.status(400).json({
                success: false,
                message: 'Invalid report type',
            });
        }

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
        res.status(200).send(csvData);
    } catch (error) {
        next(error);
    }
};

// @desc    Export analytics as PDF
// @route   GET /api/analytics/export/pdf?reportType=sales|products|customers&startDate=XXX&endDate=XXX
// @access  Private
exports.exportPDF = async (req, res, next) => {
    try {
        const { reportType, startDate, endDate } = req.query;

        if (!reportType) {
            return res.status(400).json({
                success: false,
                message: 'Report type is required',
            });
        }

        const start = startDate ? new Date(startDate) : new Date(new Date().getTime() - 30 * 24 * 60 * 60 * 1000);
        const end = endDate ? new Date(endDate) : new Date();
        end.setHours(23, 59, 59, 999);

        const matchQuery = {
            createdAt: { $gte: start, $lte: end },
        };

        if (req.user.role === 'supplier') {
            matchQuery.supplier = req.user._id;
        } else if (req.user.role === 'customer') {
            matchQuery.customer = req.user._id;
        }

        // Create PDF document
        const doc = new PDFDocument({
            margin: 50,
            size: 'A4',
        });

        // Set response headers
        const filename = `${reportType}_report_${start.toISOString().split('T')[0]}_to_${end.toISOString().split('T')[0]}.pdf`;
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

        // Pipe PDF to response
        doc.pipe(res);

        // Add header
        doc.fontSize(20).text('Analytics Report', { align: 'center' });
        doc.moveDown();
        doc.fontSize(12).text(`Report Type: ${reportType.charAt(0).toUpperCase() + reportType.slice(1)}`, { align: 'center' });
        doc.text(`Period: ${start.toISOString().split('T')[0]} to ${end.toISOString().split('T')[0]}`, { align: 'center' });
        doc.text(`Generated: ${new Date().toISOString().split('T')[0]}`, { align: 'center' });
        doc.moveDown(2);

        if (reportType === 'sales') {
            await generateSalesPDF(doc, matchQuery, req.user);
        } else if (reportType === 'products') {
            await generateProductsPDF(doc, matchQuery, req.user);
        } else if (reportType === 'customers') {
            await generateCustomersPDF(doc, matchQuery, req.user);
        } else {
            doc.fontSize(14).text('Invalid report type', { align: 'center' });
        }

        // Add footer
        doc.moveDown(2);
        doc.fontSize(10).text('Generated by InduLink Analytics System', {
            align: 'center',
            color: 'gray'
        });

        doc.end();
    } catch (error) {
        next(error);
    }
};

// Helper: Generate sales report PDF
async function generateSalesPDF(doc, matchQuery, user) {
    doc.fontSize(16).text('Sales Summary', { underline: true });
    doc.moveDown();

    // Get sales data
    const orders = await Order.find(matchQuery)
        .populate('customer', 'firstName lastName email')
        .sort({ createdAt: -1 });

    // Summary statistics
    const totalRevenue = orders.reduce((sum, order) => sum + order.total, 0);
    const totalOrders = orders.length;
    const avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    doc.fontSize(12);
    doc.text(`Total Orders: ${totalOrders}`);
    doc.text(`Total Revenue: \$${totalRevenue.toFixed(2)}`);
    doc.text(`Average Order Value: \$${avgOrderValue.toFixed(2)}`);
    doc.moveDown();

    // Orders table
    if (orders.length > 0) {
        doc.fontSize(14).text('Order Details', { underline: true });
        doc.moveDown(0.5);

        // Table headers
        const tableTop = doc.y;
        doc.fontSize(10);
        doc.text('Date', 50, tableTop);
        doc.text('Order ID', 120, tableTop);
        doc.text('Customer', 220, tableTop);
        doc.text('Status', 350, tableTop);
        doc.text('Total', 420, tableTop);

        // Draw header line
        doc.moveTo(50, tableTop + 15).lineTo(500, tableTop + 15).stroke();

        let yPosition = tableTop + 25;
        orders.slice(0, 50).forEach(order => { // Limit to 50 orders for PDF
            if (yPosition > 700) { // New page if needed
                doc.addPage();
                yPosition = 50;
            }

            const date = order.createdAt.toISOString().split('T')[0];
            const customerName = order.customer
                ? `${order.customer.firstName} ${order.customer.lastName}`
                : 'N/A';

            doc.text(date, 50, yPosition);
            doc.text(order._id.toString().substring(0, 8) + '...', 120, yPosition);
            doc.text(customerName.substring(0, 20), 220, yPosition);
            doc.text(order.status, 350, yPosition);
            doc.text(`\$${order.total.toFixed(2)}`, 420, yPosition);

            yPosition += 15;
        });
    }
};

// @desc    Get predictive insights and trend analysis
// @route   GET /api/analytics/predictive-insights?period=30
// @access  Private
exports.getPredictiveInsights = async (req, res, next) => {
    try {
        const { period = 30 } = req.query;
        const userId = req.user.id;
        const userRole = req.user.role;

        // Get historical data for the last N days
        const endDate = new Date();
        const startDate = new Date(endDate.getTime() - period * 24 * 60 * 60 * 1000);

        const matchQuery = {
            createdAt: { $gte: startDate, $lte: endDate },
            status: { $in: ['delivered', 'shipped', 'processing'] },
        };

        if (userRole === 'supplier') {
            matchQuery.supplier = req.user._id;
        } else if (userRole === 'customer') {
            matchQuery.customer = req.user._id;
        }

        // Get daily sales data
        const dailyData = await Order.aggregate([
            { $match: matchQuery },
            {
                $group: {
                    _id: {
                        $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
                    },
                    revenue: { $sum: '$total' },
                    orders: { $sum: 1 },
                },
            },
            { $sort: { '_id': 1 } },
        ]);

        // Calculate trend analysis
        const trendAnalysis = calculateTrendAnalysis(dailyData);

        // Generate forecasts
        const revenueForecast = generateSimpleForecast(dailyData, 'revenue', 7);
        const ordersForecast = generateSimpleForecast(dailyData, 'orders', 7);

        // Calculate growth rates and predictions
        const insights = {
            trendAnalysis,
            forecasts: {
                revenue: revenueForecast,
                orders: ordersForecast,
            },
            predictions: {
                nextWeekRevenue: calculatePredictedValue(dailyData, 'revenue'),
                nextWeekOrders: calculatePredictedValue(dailyData, 'orders'),
                growthRate: trendAnalysis.growthRate,
                confidence: calculateConfidence(dailyData),
            },
            recommendations: generateRecommendations(trendAnalysis, dailyData),
        };

        res.status(200).json({
            success: true,
            data: insights,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get user segmentation analytics
// @route   GET /api/analytics/user-segmentation
// @access  Private (Supplier/Admin)
exports.getUserSegmentation = async (req, res, next) => {
    try {
        if (req.user.role !== 'supplier' && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Supplier or admin role required.',
            });
        }

        const supplierId = req.user.role === 'supplier' ? req.user._id : null;
        const matchQuery = supplierId ? { supplier: supplierId } : {};

        // Get customer segments based on spending and order frequency
        const customerSegments = await Order.aggregate([
            { $match: matchQuery },
            {
                $group: {
                    _id: '$customer',
                    totalSpent: { $sum: '$total' },
                    orderCount: { $sum: 1 },
                    avgOrderValue: { $avg: '$total' },
                    firstOrder: { $min: '$createdAt' },
                    lastOrder: { $max: '$createdAt' },
                },
            },
        ]);

        // Populate customer details
        await User.populate(customerSegments, {
            path: '_id',
            select: 'firstName lastName email createdAt',
        });

        // Calculate segments
        const segments = {
            vip: [],
            regular: [],
            occasional: [],
            new: [],
        };

        const now = new Date();
        customerSegments.forEach(customer => {
            if (!customer._id) return;

            const daysSinceFirstOrder = Math.floor(
                (now - customer.firstOrder) / (1000 * 60 * 60 * 24)
            );
            const daysSinceLastOrder = Math.floor(
                (now - customer.lastOrder) / (1000 * 60 * 60 * 24)
            );

            // VIP: High spenders with frequent orders
            if (customer.totalSpent > 1000 && customer.orderCount > 5) {
                segments.vip.push(customer);
            }
            // Regular: Moderate spenders with consistent orders
            else if (customer.totalSpent > 500 && customer.orderCount > 2) {
                segments.regular.push(customer);
            }
            // Occasional: Low frequency, low spend
            else if (customer.orderCount <= 2) {
                segments.occasional.push(customer);
            }

            // New customers (joined in last 30 days)
            if (daysSinceFirstOrder <= 30) {
                segments.new.push(customer);
            }
        });

        // Calculate segment statistics
        const segmentStats = {};
        Object.keys(segments).forEach(segment => {
            const customers = segments[segment];
            segmentStats[segment] = {
                count: customers.length,
                totalRevenue: customers.reduce((sum, c) => sum + c.totalSpent, 0),
                avgOrderValue: customers.length > 0
                    ? customers.reduce((sum, c) => sum + c.avgOrderValue, 0) / customers.length
                    : 0,
                avgOrdersPerCustomer: customers.length > 0
                    ? customers.reduce((sum, c) => sum + c.orderCount, 0) / customers.length
                    : 0,
            };
        });

        res.status(200).json({
            success: true,
            data: {
                segments,
                statistics: segmentStats,
                totalCustomers: customerSegments.length,
            },
        });
    } catch (error) {
        next(error);
    }
};

// Helper: Calculate trend analysis
function calculateTrendAnalysis(dailyData) {
    if (dailyData.length < 2) {
        return {
            direction: 'insufficient_data',
            growthRate: 0,
            volatility: 0,
            trendStrength: 0,
        };
    }

    const revenues = dailyData.map(d => d.revenue);
    const n = revenues.length;

    // Calculate linear regression for trend
    const x = Array.from({ length: n }, (_, i) => i);
    const y = revenues;

    const sumX = x.reduce((a, b) => a + b, 0);
    const sumY = y.reduce((a, b) => a + b, 0);
    const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
    const sumXX = x.reduce((sum, xi) => sum + xi * xi, 0);

    const slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    const intercept = (sumY - slope * sumX) / n;

    // Calculate growth rate (percentage change over period)
    const firstHalf = revenues.slice(0, Math.floor(n / 2));
    const secondHalf = revenues.slice(Math.floor(n / 2));

    const firstHalfAvg = firstHalf.reduce((a, b) => a + b, 0) / firstHalf.length;
    const secondHalfAvg = secondHalf.reduce((a, b) => a + b, 0) / secondHalf.length;

    const growthRate = firstHalfAvg > 0
        ? ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100
        : 0;

    // Calculate volatility (coefficient of variation)
    const mean = sumY / n;
    const variance = y.reduce((sum, yi) => sum + Math.pow(yi - mean, 2), 0) / n;
    const volatility = mean > 0 ? Math.sqrt(variance) / mean : 0;

    return {
        direction: slope > 0 ? 'increasing' : slope < 0 ? 'decreasing' : 'stable',
        growthRate: Math.round(growthRate * 100) / 100,
        slope: slope,
        volatility: Math.round(volatility * 100) / 100,
        trendStrength: Math.min(Math.abs(slope) / (mean / n) * 100, 100), // Normalized trend strength
        dataPoints: n,
    };
}

// Helper: Generate simple forecast using moving average
function generateSimpleForecast(data, field, days) {
    if (data.length < 3) return [];

    const values = data.map(d => d[field]);
    const forecasts = [];

    // Use simple moving average of last 3 days
    for (let i = 0; i < days; i++) {
        const recentValues = values.slice(-3);
        const forecast = recentValues.reduce((a, b) => a + b, 0) / recentValues.length;

        forecasts.push({
            date: new Date(Date.now() + (i + 1) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
            predicted: Math.round(forecast * 100) / 100,
        });
    }

    return forecasts;
}

// Helper: Calculate predicted value for next period
function calculatePredictedValue(data, field) {
    if (data.length < 2) return 0;

    const values = data.map(d => d[field]);
    const recent = values.slice(-3);
    return recent.reduce((a, b) => a + b, 0) / recent.length;
}

// Helper: Calculate confidence in predictions
function calculateConfidence(data) {
    if (data.length < 5) return 'low';

    // Simple confidence based on data consistency
    const values = data.map(d => d.revenue);
    const mean = values.reduce((a, b) => a + b, 0) / values.length;
    const variance = values.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / values.length;
    const cv = Math.sqrt(variance) / mean; // Coefficient of variation

    if (cv < 0.2) return 'high';
    if (cv < 0.5) return 'medium';
    return 'low';
}

// Helper: Generate recommendations based on trends
function generateRecommendations(trendAnalysis, data) {
    const recommendations = [];

    if (trendAnalysis.direction === 'decreasing') {
        recommendations.push({
            type: 'warning',
            message: 'Revenue is trending downward. Consider promotional campaigns or product improvements.',
            priority: 'high',
        });
    } else if (trendAnalysis.direction === 'increasing') {
        recommendations.push({
            type: 'success',
            message: 'Revenue is growing steadily. Consider scaling successful strategies.',
            priority: 'medium',
        });
    }

    if (trendAnalysis.volatility > 0.5) {
        recommendations.push({
            type: 'warning',
            message: 'High revenue volatility detected. Focus on stabilizing sales channels.',
            priority: 'medium',
        });
    }

    if (data.length < 7) {
        recommendations.push({
            type: 'info',
            message: 'More data needed for accurate predictions. Continue monitoring for at least 7 days.',
            priority: 'low',
        });
    }

    return recommendations;
}

// Helper: Generate products report PDF
async function generateProductsPDF(doc, matchQuery, user) {
    doc.fontSize(16).text('Product Performance', { underline: true });
    doc.moveDown();

    const productMatch = user.role === 'supplier' ? { supplier: user._id } : {};
    const products = await Product.find(productMatch).populate('category', 'name');

    doc.fontSize(12).text(`Total Products: ${products.length}`);
    doc.moveDown();

    if (products.length > 0) {
        // Table headers
        const tableTop = doc.y;
        doc.fontSize(10);
        doc.text('Product Name', 50, tableTop);
        doc.text('Category', 250, tableTop);
        doc.text('Price', 350, tableTop);
        doc.text('Stock', 420, tableTop);
        doc.text('Status', 470, tableTop);

        // Draw header line
        doc.moveTo(50, tableTop + 15).lineTo(520, tableTop + 15).stroke();

        let yPosition = tableTop + 25;
        products.slice(0, 100).forEach(product => { // Limit to 100 products
            if (yPosition > 700) {
                doc.addPage();
                yPosition = 50;
            }

            doc.text(product.title.substring(0, 25), 50, yPosition);
            doc.text(product.category?.name || 'N/A', 250, yPosition);
            doc.text(`\$${product.price.toFixed(2)}`, 350, yPosition);
            doc.text(product.stock.toString(), 420, yPosition);
            doc.text(product.status, 470, yPosition);

            yPosition += 15;
        });
    }
}

// Helper: Generate customers report PDF
async function generateCustomersPDF(doc, matchQuery, user) {
    if (user.role !== 'supplier' && user.role !== 'admin') {
        doc.fontSize(14).text('Access denied. Supplier or admin role required.');
        return;
    }

    doc.fontSize(16).text('Customer Analytics', { underline: true });
    doc.moveDown();

    const supplierId = user.role === 'supplier' ? user._id : null;
    const customerMatch = supplierId ? { supplier: supplierId } : {};

    const customerAnalysis = await Order.aggregate([
        { $match: customerMatch },
        {
            $group: {
                _id: '$customer',
                orderCount: { $sum: 1 },
                totalSpent: { $sum: '$total' },
                firstOrder: { $min: '$createdAt' },
                lastOrder: { $max: '$createdAt' },
            },
        },
        { $sort: { totalSpent: -1 } },
        { $limit: 50 },
    ]);

    await User.populate(customerAnalysis, {
        path: '_id',
        select: 'firstName lastName email',
    });

    doc.fontSize(12);
    doc.text(`Total Customers: ${customerAnalysis.length}`);
    doc.moveDown();

    if (customerAnalysis.length > 0) {
        // Table headers
        const tableTop = doc.y;
        doc.fontSize(10);
        doc.text('Customer Name', 50, tableTop);
        doc.text('Email', 200, tableTop);
        doc.text('Orders', 350, tableTop);
        doc.text('Total Spent', 420, tableTop);

        // Draw header line
        doc.moveTo(50, tableTop + 15).lineTo(500, tableTop + 15).stroke();

        let yPosition = tableTop + 25;
        customerAnalysis.forEach(customer => {
            if (yPosition > 700) {
                doc.addPage();
                yPosition = 50;
            }

            const customerName = customer._id
                ? `${customer._id.firstName} ${customer._id.lastName}`
                : 'N/A';

            doc.text(customerName, 50, yPosition);
            doc.text(customer._id?.email || 'N/A', 200, yPosition);
            doc.text(customer.orderCount.toString(), 350, yPosition);
            doc.text(`\$${customer.totalSpent.toFixed(2)}`, 420, yPosition);

            yPosition += 15;
        });
    }
}
