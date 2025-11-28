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
                    image: item.product.images[0]?.url,
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

            const order = await Order.create({
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

            // Send notification to supplier about new order pending approval
            try {
                await sendOrderStatusNotification(supplierId, order._id.toString(), 'pending_approval');
            } catch (notificationError) {
                console.error('Failed to send new order notification to supplier:', notificationError);
            }
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
            console.error('Failed to send order status notification:', notificationError);
            // Don't fail the request if notification fails
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
