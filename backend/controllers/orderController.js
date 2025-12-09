const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Product = require('../models/Product');
const { sendOrderStatusNotification } = require('../services/notificationService');

// @desc    Create order from cart
// @route   POST /api/orders
// @access  Private (Customer)
exports.createOrder = async (req, res, next) => {
    try {
        const { shippingAddress, paymentMethod, customerNote } = req.body;

        // Get cart
        const cart = await Cart.findOne({ user: req.user.id }).populate('items.product');

        if (!cart || cart.items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Cart is empty',
            });
        }

        // Group items by supplier
        const ordersBySupplier = {};

        for (const item of cart.items) {
            // Check if product still exists
            if (!item.product) {
                return res.status(400).json({
                    success: false,
                    message: 'One or more products in your cart are no longer available',
                });
            }

            const supplierId = item.product.supplier.toString();

            if (!ordersBySupplier[supplierId]) {
                ordersBySupplier[supplierId] = [];
            }

            // Check stock
            if (item.product.stock < item.quantity) {
                return res.status(400).json({
                    success: false,
                    message: `Insufficient stock for ${item.product.title}`,
                });
            }

            ordersBySupplier[supplierId].push(item);
        }

        // Create separate order for each supplier
        const createdOrders = [];

        for (const [supplierId, items] of Object.entries(ordersBySupplier)) {
            const orderItems = items.map((item) => ({
                product: item.product._id,
                productSnapshot: {
                    title: item.product.title,
                    image: item.product.images && item.product.images.length > 0 ? item.product.images[0].url : null,
                    sku: item.product.sku,
                },
                quantity: item.quantity,
                price: item.price,
                subtotal: item.price * item.quantity,
            }));

            const subtotal = orderItems.reduce((sum, item) => sum + item.subtotal, 0);
            const tax = subtotal * 0.13;
            const shippingCost = subtotal > 1000 ? 0 : 100;
            const total = subtotal + tax + shippingCost;

            // Generate order number manually
            const orderCount = await Order.countDocuments();
            const orderNumber = `IND${Date.now()}${String(orderCount + 1).padStart(4, '0')}`;

            const order = await Order.create({
                orderNumber,
                customer: req.user.id,
                supplier: supplierId,
                items: orderItems,
                subtotal,
                tax,
                shippingCost,
                total,
                shippingAddress,
                paymentMethod: paymentMethod || 'cash_on_delivery',
                customerNote,
            });

            // Update product stock and purchase count
            for (const item of items) {
                await Product.findByIdAndUpdate(item.product._id, {
                    $inc: {
                        stock: -item.quantity,
                        purchaseCount: item.quantity,
                    },
                });
            }

            createdOrders.push(order);

            // Send notification and Socket event to supplier
            try {
                // Socket.io emission
                if (req.io) {
                    req.io.to(`user_${supplierId}`).emit('order:new', {
                        message: 'New order received',
                        orderId: order._id,
                        orderNumber: order.orderNumber
                    });
                }

                await sendOrderStatusNotification(supplierId, order._id.toString(), 'pending_approval');
            } catch (notificationError) {
                console.error('Failed to send new order notification/socket to supplier:', notificationError);
            }
        }

        // Notify customer via Socket
        if (req.io) {
            req.io.to(`user_${req.user.id}`).emit('order:created', {
                message: 'Order created successfully',
                orders: createdOrders.map(o => o._id)
            });
        }

        // Clear cart
        cart.items = [];
        await cart.save();

        // Populate orders
        const populatedOrders = await Order.find({
            _id: { $in: createdOrders.map((o) => o._id) },
        })
            .populate('supplier', 'firstName lastName businessName')
            .populate('items.product', 'title images');

        res.status(201).json({
            success: true,
            message: 'Order(s) created successfully',
            data: populatedOrders,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get customer orders
// @route   GET /api/orders
// @access  Private (Customer)
exports.getCustomerOrders = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const filter = { customer: req.user.id };

        if (req.query.status) {
            filter.status = req.query.status;
        }

        const orders = await Order.find(filter)
            .populate('supplier', 'firstName lastName businessName')
            .populate('items.product', 'title images')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        const total = await Order.countDocuments(filter);

        res.status(200).json({
            success: true,
            count: orders.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            data: orders,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get supplier orders
// @route   GET /api/orders/supplier
// @access  Private (Supplier)
exports.getSupplierOrders = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const filter = { supplier: req.user.id };

        if (req.query.status) {
            filter.status = req.query.status;
        }

        const orders = await Order.find(filter)
            .populate('customer', 'firstName lastName phone')
            .populate('items.product', 'title images')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        const total = await Order.countDocuments(filter);

        res.status(200).json({
            success: true,
            count: orders.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            data: orders,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get order by ID
// @route   GET /api/orders/:id
// @access  Private
exports.getOrder = async (req, res, next) => {
    try {
        const order = await Order.findById(req.params.id)
            .populate('customer', 'firstName lastName email phone')
            .populate('supplier', 'firstName lastName businessName phone')
            .populate('items.product', 'title images sku');

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Check authorization
        const isCustomer = order.customer._id.toString() === req.user.id;
        const isSupplier = order.supplier._id.toString() === req.user.id;
        const isAdmin = req.user.role === 'admin';

        if (!isCustomer && !isSupplier && !isAdmin) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to view this order',
            });
        }

        res.status(200).json({
            success: true,
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update order status
// @route   PUT /api/orders/:id/status
// @access  Private (Supplier)
exports.updateOrderStatus = async (req, res, next) => {
    try {
        const { status, trackingNumber, supplierNote } = req.body;

        const order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Check authorization
        if (order.supplier.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this order',
            });
        }

        // Update order
        order.status = status;
        if (trackingNumber) order.trackingNumber = trackingNumber;
        if (supplierNote) order.supplierNote = supplierNote;

        // Set estimated delivery for shipped orders
        if (status === 'shipped' && !order.estimatedDelivery) {
            const estimatedDate = new Date();
            estimatedDate.setDate(estimatedDate.getDate() + 7); // 7 days from now
            order.estimatedDelivery = estimatedDate;
        }

        await order.save();

        // Send push notification to customer about status update
        try {
            await sendOrderStatusNotification(order.customer.toString(), order._id.toString(), status, {
                trackingNumber: trackingNumber,
                supplierNote: supplierNote,
            });
        } catch (notificationError) {
            // Don't fail the request if notification fails
        }

        // Socket.io event to customer
        if (req.io) {
            req.io.to(`user_${order.customer.toString()}`).emit('order:updated', {
                orderId: order._id,
                status: status,
                orderNumber: order.orderNumber,
                message: `Order #${order.orderNumber} status updated to ${status}`
            });
        }

        res.status(200).json({
            success: true,
            message: 'Order status updated',
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Approve order
// @route   PUT /api/orders/:id/approve
// @access  Private (Supplier)
exports.approveOrder = async (req, res, next) => {
    try {
        const { supplierNote } = req.body;

        const order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Check authorization
        if (order.supplier.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to approve this order',
            });
        }

        // Can only approve pending_approval orders
        if (order.status !== 'pending_approval') {
            return res.status(400).json({
                success: false,
                message: 'Order is not pending approval',
            });
        }

        order.status = 'pending';
        if (supplierNote) order.supplierNote = supplierNote;
        await order.save();

        // Send notification to customer
        try {
            await sendOrderStatusNotification(order.customer.toString(), order._id.toString(), 'approved', {
                supplierNote: supplierNote,
            });
        } catch (notificationError) {
            console.error('Failed to send order approval notification:', notificationError);
        }

        res.status(200).json({
            success: true,
            message: 'Order approved successfully',
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Reject order
// @route   PUT /api/orders/:id/reject
// @access  Private (Supplier)
exports.rejectOrder = async (req, res, next) => {
    try {
        const { supplierNote, rejectionReason } = req.body;

        const order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Check authorization
        if (order.supplier.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to reject this order',
            });
        }

        // Can only reject pending_approval orders
        if (order.status !== 'pending_approval') {
            return res.status(400).json({
                success: false,
                message: 'Order is not pending approval',
            });
        }

        // Restore product stock
        for (const item of order.items) {
            await Product.findByIdAndUpdate(item.product, {
                $inc: {
                    stock: item.quantity,
                    purchaseCount: -item.quantity,
                },
            });
        }

        order.status = 'cancelled';
        order.rejectedAt = new Date();
        if (supplierNote) order.supplierNote = supplierNote;
        if (rejectionReason) order.cancellationReason = rejectionReason;
        await order.save();

        // Send notification to customer
        try {
            await sendOrderStatusNotification(order.customer.toString(), order._id.toString(), 'rejected', {
                supplierNote: supplierNote,
                rejectionReason: rejectionReason,
            });
        } catch (notificationError) {
            console.error('Failed to send order rejection notification:', notificationError);
        }

        res.status(200).json({
            success: true,
            message: 'Order rejected successfully',
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Cancel order
// @route   PUT /api/orders/:id/cancel
// @access  Private (Customer)
exports.cancelOrder = async (req, res, next) => {
    try {
        const { cancellationReason } = req.body;

        const order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Check authorization
        if (order.customer.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to cancel this order',
            });
        }

        // Can only cancel pending_approval, pending or confirmed orders
        if (!['pending_approval', 'pending', 'confirmed'].includes(order.status)) {
            return res.status(400).json({
                success: false,
                message: 'Cannot cancel order at this stage',
            });
        }

        // Restore product stock
        for (const item of order.items) {
            await Product.findByIdAndUpdate(item.product, {
                $inc: {
                    stock: item.quantity,
                    purchaseCount: -item.quantity,
                },
            });
        }

        order.status = 'cancelled';
        order.cancellationReason = cancellationReason;
        await order.save();

        res.status(200).json({
            success: true,
            message: 'Order cancelled successfully',
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get order statistics
// @route   GET /api/orders/stats
// @access  Private (Admin)
exports.getOrderStats = async (req, res, next) => {
    try {
        const totalOrders = await Order.countDocuments();
        const pendingOrders = await Order.countDocuments({ status: 'pending' });
        const completedOrders = await Order.countDocuments({ status: 'delivered' });
        const cancelledOrders = await Order.countDocuments({ status: 'cancelled' });

        // Get total revenue
        const revenueData = await Order.aggregate([
            { $match: { status: 'delivered' } },
            { $group: { _id: null, totalRevenue: { $sum: '$total' } } }
        ]);

        const totalRevenue = revenueData[0]?.totalRevenue || 0;

        res.status(200).json({
            success: true,
            data: {
                totalOrders,
                pendingOrders,
                completedOrders,
                cancelledOrders,
                totalRevenue,
                count: totalOrders
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get supplier order statistics
// @route   GET /api/orders/stats/supplier/:supplierId
// @access  Private (Supplier or Admin)
exports.getSupplierOrderStats = async (req, res, next) => {
    try {
        const supplierId = req.params.supplierId;

        // Check if user is authorized to access this supplier's data
        if (req.user.role !== 'admin' && req.user.id !== supplierId) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to access this supplier data',
            });
        }

        const totalOrders = await Order.countDocuments({ supplier: supplierId });
        const pendingOrders = await Order.countDocuments({ supplier: supplierId, status: 'pending' });
        const completedOrders = await Order.countDocuments({ supplier: supplierId, status: 'delivered' });
        const cancelledOrders = await Order.countDocuments({ supplier: supplierId, status: 'cancelled' });

        // Get total revenue for supplier
        const revenueData = await Order.aggregate([
            { $match: { supplier: new mongoose.Types.ObjectId(supplierId), status: 'delivered' } },
            { $group: { _id: null, totalRevenue: { $sum: '$total' } } }
        ]);

        const totalRevenue = revenueData[0]?.totalRevenue || 0;

        res.status(200).json({
            success: true,
            data: {
                totalOrders,
                pendingOrders,
                completedOrders,
                cancelledOrders,
                totalRevenue,
                count: totalOrders
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Search orders
// @route   GET /api/orders/search
// @access  Private (Admin)
exports.searchOrders = async (req, res, next) => {
    try {
        const { query, status, customerId, supplierId, startDate, endDate, page = 1, limit = 20 } = req.query;
        const skip = (page - 1) * limit;

        const filter = {};

        if (query) {
            filter.$or = [
                { orderNumber: { $regex: query, $options: 'i' } },
                { 'shippingAddress.fullName': { $regex: query, $options: 'i' } },
                { 'shippingAddress.phone': { $regex: query, $options: 'i' } }
            ];
        }

        if (status) filter.status = status;
        if (customerId) filter.customer = customerId;
        if (supplierId) filter.supplier = supplierId;

        if (startDate || endDate) {
            filter.createdAt = {};
            if (startDate) filter.createdAt.$gte = new Date(startDate);
            if (endDate) filter.createdAt.$lte = new Date(endDate);
        }

        const orders = await Order.find(filter)
            .populate('customer', 'firstName lastName email')
            .populate('supplier', 'firstName lastName businessName')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(parseInt(limit));

        const total = await Order.countDocuments(filter);

        res.status(200).json({
            success: true,
            count: orders.length,
            total,
            page: parseInt(page),
            pages: Math.ceil(total / limit),
            data: orders,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Bulk update order status
// @route   PUT /api/orders/bulk/status
// @access  Private (Admin)
exports.bulkUpdateOrderStatus = async (req, res, next) => {
    try {
        const { orderIds, status, trackingNumbers = [], supplierNotes = [] } = req.body;

        if (!Array.isArray(orderIds) || orderIds.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Order IDs array is required',
            });
        }

        if (!status) {
            return res.status(400).json({
                success: false,
                message: 'Status is required',
            });
        }

        const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid status value',
            });
        }

        // Update orders in bulk
        const result = await Order.updateMany(
            { _id: { $in: orderIds } },
            {
                $set: {
                    status: status,
                    ...(status === 'shipped' && { shippedAt: new Date() }),
                    ...(status === 'delivered' && { deliveredAt: new Date(), paymentStatus: 'paid' }),
                    ...(status === 'cancelled' && { cancelledAt: new Date() })
                }
            }
        );

        // Update tracking numbers if provided
        if (trackingNumbers.length > 0 && orderIds.length === trackingNumbers.length) {
            for (let i = 0; i < orderIds.length; i++) {
                await Order.findByIdAndUpdate(orderIds[i], {
                    trackingNumber: trackingNumbers[i]
                });
            }
        }

        // Update supplier notes if provided
        if (supplierNotes.length > 0 && orderIds.length === supplierNotes.length) {
            for (let i = 0; i < orderIds.length; i++) {
                await Order.findByIdAndUpdate(orderIds[i], {
                    supplierNote: supplierNotes[i]
                });
            }
        }

        res.status(200).json({
            success: true,
            message: 'Bulk order status update completed',
            modifiedCount: result.modifiedCount,
            matchedCount: result.matchedCount,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Export orders data
// @route   GET /api/orders/export
// @access  Private (Admin)
exports.exportOrders = async (req, res, next) => {
    try {
        const { status, startDate, endDate, format = 'csv' } = req.query;

        const filter = {};

        if (status) filter.status = status;
        if (startDate || endDate) {
            filter.createdAt = {};
            if (startDate) filter.createdAt.$gte = new Date(startDate);
            if (endDate) filter.createdAt.$lte = new Date(endDate);
        }

        const orders = await Order.find(filter)
            .populate('customer', 'firstName lastName email phone')
            .populate('supplier', 'firstName lastName businessName phone')
            .sort({ createdAt: -1 });

        if (format === 'csv') {
            // Generate CSV format
            const csvHeader = 'Order Number,Customer,Supplier,Status,Total,Date,Payment Method,Tracking Number\n';
            const csvRows = orders.map(order =>
                `"${order.orderNumber}","${order.customer?.firstName} ${order.customer?.lastName}","${order.supplier?.businessName || order.supplier?.firstName}","${order.status}","${order.total}","${order.createdAt}","${order.paymentMethod}","${order.trackingNumber || ''}"`
            ).join('\n');

            const csvData = csvHeader + csvRows;

            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=orders_export.csv');
            res.status(200).send(csvData);
        } else {
            // JSON format
            res.status(200).json({
                success: true,
                data: orders,
            });
        }
    } catch (error) {
        next(error);
    }
};

// @desc    Update order tracking information
// @route   PUT /api/orders/:id/tracking
// @access  Private (Supplier)
exports.updateOrderTracking = async (req, res, next) => {
    try {
        const { trackingNumber, carrier, estimatedDelivery, trackingUrl } = req.body;

        const order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Check authorization
        if (order.supplier.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update tracking for this order',
            });
        }

        // Update tracking information
        if (trackingNumber) order.trackingNumber = trackingNumber;
        if (carrier) order.carrier = carrier;
        if (estimatedDelivery) order.estimatedDelivery = new Date(estimatedDelivery);
        if (trackingUrl) order.trackingUrl = trackingUrl;

        // If order was not shipped yet, update status to shipped
        if (order.status !== 'shipped' && order.status !== 'delivered') {
            order.status = 'shipped';
            order.shippedAt = new Date();
        }

        await order.save();

        // Send notification to customer about tracking update
        try {
            await sendOrderStatusNotification(order.customer.toString(), order._id.toString(), 'tracking_updated', {
                trackingNumber: trackingNumber,
                carrier: carrier,
                estimatedDelivery: estimatedDelivery,
                trackingUrl: trackingUrl,
            });
        } catch (notificationError) {
            console.error('Failed to send tracking update notification:', notificationError);
        }

        res.status(200).json({
            success: true,
            message: 'Order tracking information updated',
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Process order refund
// @route   PUT /api/orders/:id/refund
// @access  Private (Admin)
exports.processRefund = async (req, res, next) => {
    try {
        const { refundAmount, refundReason, refundMethod } = req.body;

        const order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Only delivered orders can be refunded
        if (order.status !== 'delivered') {
            return res.status(400).json({
                success: false,
                message: 'Only delivered orders can be refunded',
            });
        }

        // Update order status and refund information
        order.status = 'refunded';
        order.refundedAt = new Date();
        order.paymentStatus = 'refunded';
        order.refundAmount = refundAmount || order.total;
        order.refundReason = refundReason;
        order.refundMethod = refundMethod;

        await order.save();

        // Send notifications
        try {
            // Notify customer
            await sendOrderStatusNotification(order.customer.toString(), order._id.toString(), 'refunded', {
                refundAmount: refundAmount,
                refundReason: refundReason,
                refundMethod: refundMethod,
            });

            // Notify supplier
            await sendOrderStatusNotification(order.supplier.toString(), order._id.toString(), 'order_refunded', {
                refundAmount: refundAmount,
                refundReason: refundReason,
            });
        } catch (notificationError) {
            console.error('Failed to send refund notification:', notificationError);
        }

        res.status(200).json({
            success: true,
            message: 'Order refund processed successfully',
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get comprehensive order analytics
// @route   GET /api/orders/analytics
// @access  Private (Admin)
exports.getOrderAnalytics = async (req, res, next) => {
    try {
        const { timeRange = '30days', supplierId } = req.query;

        const filter = {};
        if (supplierId) filter.supplier = supplierId;

        // Set date range filter
        const now = new Date();
        let startDate;

        switch (timeRange) {
            case '7days':
                startDate = new Date(now.setDate(now.getDate() - 7));
                break;
            case '30days':
                startDate = new Date(now.setDate(now.getDate() - 30));
                break;
            case '90days':
                startDate = new Date(now.setDate(now.getDate() - 90));
                break;
            case 'year':
                startDate = new Date(now.setFullYear(now.getFullYear() - 1));
                break;
            default:
                startDate = new Date(now.setDate(now.getDate() - 30));
        }

        filter.createdAt = { $gte: startDate };

        // Get analytics data
        const [statusDistribution, revenueByDay, averageOrderValue, topCustomers, topProducts] = await Promise.all([
            // Status distribution
            Order.aggregate([
                { $match: filter },
                { $group: { _id: '$status', count: { $sum: 1 } } },
                { $sort: { count: -1 } }
            ]),

            // Revenue by day
            Order.aggregate([
                { $match: { ...filter, status: 'delivered' } },
                {
                    $group: {
                        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
                        totalRevenue: { $sum: '$total' },
                        orderCount: { $sum: 1 }
                    }
                },
                { $sort: { _id: 1 } }
            ]),

            // Average order value
            Order.aggregate([
                { $match: { ...filter, status: 'delivered' } },
                { $group: { _id: null, avgOrderValue: { $avg: '$total' }, totalOrders: { $sum: 1 } } }
            ]),

            // Top customers
            Order.aggregate([
                { $match: filter },
                { $group: { _id: '$customer', count: { $sum: 1 }, totalSpent: { $sum: '$total' } } },
                { $sort: { totalSpent: -1 } },
                { $limit: 5 },
                {
                    $lookup: {
                        from: 'users',
                        localField: '_id',
                        foreignField: '_id',
                        as: 'customer'
                    }
                },
                { $unwind: '$customer' }
            ]),

            // Top products
            Order.aggregate([
                { $match: filter },
                { $unwind: '$items' },
                { $group: { _id: '$items.product', count: { $sum: 1 }, totalQuantity: { $sum: '$items.quantity' } } },
                { $sort: { totalQuantity: -1 } },
                { $limit: 5 },
                {
                    $lookup: {
                        from: 'products',
                        localField: '_id',
                        foreignField: '_id',
                        as: 'product'
                    }
                },
                { $unwind: '$product' }
            ])
        ]);

        res.status(200).json({
            success: true,
            data: {
                statusDistribution: statusDistribution || [],
                revenueByDay: revenueByDay || [],
                averageOrderValue: averageOrderValue[0]?.avgOrderValue || 0,
                totalOrders: averageOrderValue[0]?.totalOrders || 0,
                topCustomers: topCustomers || [],
                topProducts: topProducts || [],
                timeRange: timeRange,
                startDate: startDate.toISOString(),
                endDate: new Date().toISOString()
            }
        });
    } catch (error) {
        next(error);
    }
};

// ==================== ADMIN ORDER MANAGEMENT ====================

// @desc    Get order by ID (Admin)
// @route   GET /api/admin/orders/:id
// @access  Private (Admin)
exports.getOrderById = async (req, res, next) => {
    try {
        const order = await Order.findById(req.params.id)
            .populate('customer', 'firstName lastName email phone')
            .populate('items.product', 'title images price')
            .populate('items.supplier', 'firstName lastName businessName email');

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        res.status(200).json({
            success: true,
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete/Cancel order (Admin)
// @route   DELETE /api/admin/orders/:id
// @access  Private (Admin)
exports.deleteOrder = async (req, res, next) => {
    try {
        const order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Only allow deletion of pending or cancelled orders
        if (!['pending', 'cancelled'].includes(order.status)) {
            return res.status(400).json({
                success: false,
                message: 'Cannot delete order with status: ' + order.status,
            });
        }

        // Restore product stock if order is being deleted
        for (const item of order.items) {
            await Product.findByIdAndUpdate(item.product, {
                $inc: { stock: item.quantity }
            });
        }

        await order.remove();

        res.status(200).json({
            success: true,
            message: 'Order deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};
