const Product = require('../models/Product');
const Order = require('../models/Order');
const User = require('../models/User'); // Added User import
const Notification = require('../models/Notification'); // Added Notification import

const Cart = require('../models/Cart');

// ==================== PRODUCT MANAGEMENT ====================

// Get supplier's own products
const getMyProducts = async (req, res) => {
    try {
        const products = await Product.find({ supplier: req.user._id })
            .populate('category', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            message: 'Products retrieved successfully',
            count: products.length,
            data: products
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error retrieving products',
            error: error.message
        });
    }
};

// Create new product
const createProduct = async (req, res) => {
    try {
        const productData = {
            ...req.body,
            supplier: req.user._id,
            images: req.files ? req.files.map((file, index) => ({
                url: `/uploads/products/${file.filename}`,
                alt: req.body.title || 'Product Image',
                isPrimary: index === 0
            })) : []
        };

        const product = await Product.create(productData);

        // Notify customers about new product
        const supplierName = req.user.businessName || `${req.user.firstName} ${req.user.lastName}`;
        const productTitle = product.title || product.name || 'New Product';

        // 1. Real-time socket notification
        try {
            if (req.app.get('webSocketService')) {
                const webSocketService = req.app.get('webSocketService');

                webSocketService.notifyRole('customer', 'product_updated', {
                    operation: 'created',
                    productName: productTitle,
                    productId: product._id,
                    message: `New product added by ${supplierName}`,
                    timestamp: new Date()
                });
            }
        } catch (socketError) {
            console.error('Socket notification error:', socketError);
        }

        // 2. Database notification (for notification screen)
        try {
            await Notification.create({
                title: 'New Product Available',
                body: `${supplierName} has added "${productTitle}" to the store.`,
                type: 'product_available',
                targetRole: 'customer',
                sentBy: req.user._id,
                data: {
                    productId: product._id,
                    productTitle: productTitle,
                    supplierId: req.user._id,
                    supplierName: supplierName
                }
            });
        } catch (notificationError) {
            console.error('Database notification error:', notificationError);
        }

        res.status(201).json({
            success: true,
            message: 'Product created successfully',
            data: product
        });
    } catch (error) {
        console.error('❌ Product creation error:', error);
        res.status(500).json({
            success: false,
            message: 'Error creating product',
            error: error.message
        });
    }
};

// Update product
const updateProduct = async (req, res) => {
    try {
        const product = await Product.findOne({
            _id: req.params.id,
            supplier: req.user._id
        });

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found or not owned by supplier'
            });
        }

        const newImages = req.files ? req.files.map(file => ({
            url: `/uploads/products/${file.filename}`,
            alt: req.body.title || 'Product Image',
            isPrimary: false
        })) : [];

        const updateData = {
            ...req.body,
            // Append new images to existing ones instead of replacing
            images: newImages.length > 0 ? [...product.images, ...newImages] : product.images
        };

        const updatedProduct = await Product.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true, runValidators: true }
        );

        res.status(200).json({
            success: true,
            message: 'Product updated successfully',
            data: updatedProduct
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating product',
            error: error.message
        });
    }
};

// Delete product
const deleteProduct = async (req, res) => {
    try {
        const product = await Product.findOneAndDelete({
            _id: req.params.id,
            supplier: req.user._id
        });

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found or not owned by supplier'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Product deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error deleting product',
            error: error.message
        });
    }
};

// Get items in active carts for this supplier
const getActiveCartItems = async (req, res) => {
    try {
        const supplierId = req.user._id;

        // Find products owned by this supplier
        const supplierProducts = await Product.find({ supplier: supplierId }).select('_id');
        const supplierProductIds = supplierProducts.map(p => p._id);

        // Find carts that have items from this supplier
        const carts = await Cart.find({ 'items.product': { $in: supplierProductIds } })
            .populate('items.product', 'title price images supplier');

        let totalItems = 0;
        let potentialRevenue = 0;
        const productStats = {};

        carts.forEach(cart => {
            cart.items.forEach(item => {
                if (item.product && item.product.supplier.toString() === supplierId.toString()) {
                    totalItems += item.quantity;
                    // Use item.price (price at time of adding to cart) or current price?
                    // item.price is stored in cart itemSchema
                    potentialRevenue += item.quantity * item.price;

                    const pid = item.product._id.toString();
                    if (!productStats[pid]) {
                        productStats[pid] = {
                            title: item.product.title,
                            image: item.product.images[0]?.url,
                            count: 0,
                            revenue: 0
                        };
                    }
                    productStats[pid].count += item.quantity;
                    productStats[pid].revenue += item.quantity * item.price;
                }
            });
        });

        const topProducts = Object.values(productStats)
            .sort((a, b) => b.count - a.count)
            .slice(0, 5);

        res.status(200).json({
            success: true,
            message: 'Active cart items retrieved successfully',
            data: {
                totalItems,
                potentialRevenue,
                uniqueCarts: carts.length,
                topProducts
            }
        });
    } catch (error) {
        console.error('Active Cart Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error retrieving active cart items',
            error: error.message
        });
    }
};

// ==================== ORDER MANAGEMENT ====================

// Get supplier's orders
const getSupplierOrders = async (req, res) => {
    try {
        // Orders are split by supplier at creation, so we can directly filter by supplier field
        // This is more efficient than searching through product items
        const orders = await Order.find({ supplier: req.user._id })
            .populate('customer', 'firstName lastName email phone') // Fixed: populate 'customer', not 'user'
            .populate('items.product', 'title price images') // consistent with other controllers
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            message: 'Orders retrieved successfully',
            count: orders.length,
            data: orders
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error retrieving orders',
            error: error.message
        });
    }
};

// Get order details
const getOrderDetails = async (req, res) => {
    try {
        const order = await Order.findById(req.params.id)
            .populate('customer', 'firstName lastName email phone') // Fixed: populate 'customer'
            .populate('items.product', 'title price images sku')
            .populate('shippingAddress');

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        // Check if order belongs to supplier
        // Since orders are split by supplier, direct check is sufficient
        if (order.supplier.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to view this order'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Order details retrieved successfully',
            data: order
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error retrieving order details',
            error: error.message
        });
    }
};

// Update order status
const updateOrderStatus = async (req, res) => {
    try {
        const { status } = req.body;
        const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid status. Must be one of: ' + validStatuses.join(', ')
            });
        }

        const order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        // Check if order belongs to supplier
        if (order.supplier.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this order'
            });
        }

        order.status = status;
        await order.save();

        // Notify Customer about status update
        await Notification.create({
            targetUsers: [order.user], // Notify the customer
            type: 'order_status',
            title: `Order #${order.orderNumber} Updated`,
            body: `Your order status has been updated to ${status}`,
            data: { orderId: order._id }
        });

        res.status(200).json({
            success: true,
            message: 'Order status updated successfully',
            data: order
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating order status',
            error: error.message
        });
    }
};

// ==================== ANALYTICS & REPORTS ====================

// Get supplier analytics
const getSupplierAnalytics = async (req, res) => {
    try {
        const supplierId = req.user._id;

        // 1. Basic Counts
        const totalProducts = await Product.countDocuments({ supplier: supplierId });
        const activeProducts = await Product.countDocuments({ supplier: supplierId, status: 'active' });

        // Product IDs for filtering orders
        const supplierProducts = await Product.find({ supplier: supplierId }).select('_id title price images');
        const supplierProductIds = supplierProducts.map(p => p._id);

        // Orders involving this supplier
        const orders = await Order.find({ supplier: supplierId });

        const totalOrders = orders.length;

        // 2. Revenue Calculation
        let totalRevenue = 0;
        // Filter delivered orders for revenue
        const deliveredOrders = orders.filter(o => o.status === 'delivered');

        // Calculate revenue only from this supplier's items in the orders
        // Note: In the new 'split order' model, order.total is already specific to the supplier
        deliveredOrders.forEach(order => {
            totalRevenue += order.total;
        });

        const averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

        // 3. Revenue Trend (Last 6 months)
        const revenueData = await getRevenueTrend(supplierId);

        // 4. Order Status Distribution
        const orderStatusData = await Order.aggregate([
            { $match: { supplier: supplierId } },
            { $group: { _id: '$status', count: { $sum: 1 } } },
            { $project: { status: '$_id', count: 1, _id: 0 } }
        ]);

        // 5. Top Products
        // Calculate sales count per product
        const productSales = {};
        orders.forEach(order => {
            order.items.forEach(item => {
                const pid = item.product.toString();
                // Since this order is specific to supplier, all items are theirs
                if (!productSales[pid]) {
                    productSales[pid] = {
                        name: item.productSnapshot?.title || 'Unknown',
                        sold: 0,
                        revenue: 0
                    };
                }
                productSales[pid].sold += item.quantity;
                productSales[pid].revenue += item.subtotal;
            });
        });

        const topProducts = Object.values(productSales)
            .sort((a, b) => b.revenue - a.revenue)
            .slice(0, 5);

        // 6. Recent Sales
        const recentSales = await Order.find({ supplier: supplierId })
            .sort({ createdAt: -1 })
            .limit(5)
            .populate('customer', 'firstName lastName')
            .lean();

        const formattedRecentSales = recentSales.map(order => ({
            orderNumber: order.orderNumber,
            customerName: order.customer ? `${order.customer.firstName} ${order.customer.lastName}` : 'Guest',
            amount: order.total,
            date: order.createdAt
        }));

        // 7. Inventory Status
        const inventoryStatus = await Product.find({ supplier: supplierId })
            .select('title stock')
            .sort({ stock: 1 })
            .limit(10)
            .lean()
            .then(products => products.map(p => ({
                name: p.title,
                stock: p.stock
            })));

        // 8. Category Performance
        const categoryPerformance = await Product.aggregate([
            { $match: { supplier: supplierId } },
            { $group: { _id: '$category', count: { $sum: 1 } } },
            { $lookup: { from: 'categories', localField: '_id', foreignField: '_id', as: 'categoryInfo' } },
            { $unwind: '$categoryInfo' },
            { $project: { name: '$categoryInfo.name', products: '$count', percentage: { $multiply: [{ $divide: ['$count', totalProducts] }, 100] } } }
        ]);

        const formattedCategoryPerformance = categoryPerformance.map(c => ({
            name: c.name,
            products: c.products,
            percentage: Math.round(c.percentage)
        }));

        res.status(200).json({
            success: true,
            message: 'Supplier analytics retrieved successfully',
            data: {
                totalRevenue,
                totalOrders,
                activeProducts,
                averageOrderValue,
                revenueChange: 0,
                ordersChange: 0,
                productsChange: 0,
                aovChange: 0,
                revenueData,
                topProducts,
                salesByPeriod: revenueData.map((val, index) => ({ period: index + 1, sales: val })), // Format for frontend
                orderStatusData,
                productPerformance: topProducts,
                inventoryStatus,
                categoryPerformance: formattedCategoryPerformance,
                recentSales: formattedRecentSales
            }
        });
    } catch (error) {
        console.error('Analytics Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error retrieving analytics',
            error: error.message
        });
    }
};

// Helper for Revenue Trend (Last 6 months)
async function getRevenueTrend(supplierId) {
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const result = await Order.aggregate([
        {
            $match: {
                supplier: supplierId,
                status: 'delivered',
                createdAt: { $gte: sixMonthsAgo }
            }
        },
        {
            $group: {
                _id: { $month: '$createdAt' },
                total: { $sum: '$total' }
            }
        },
        { $sort: { _id: 1 } }
    ]);

    // Map to simple array of values (simplified for this use case)
    // Ideally we should map to specific months, but for the chart we just return values
    return result.map(r => r.total);
}

// Get sales report
const getSalesReport = async (req, res) => {
    try {
        const supplierId = req.user._id;
        const { startDate, endDate } = req.query;

        let dateFilter = {};
        if (startDate && endDate) {
            dateFilter.createdAt = {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            };
        }

        const orders = await Order.find({
            ...dateFilter,
            'items.product': {
                $in: await Product.find({ supplier: supplierId }).distinct('_id')
            },
            status: { $in: ['delivered', 'shipped'] }
        })
            .populate('items.product', 'name sku')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            message: 'Sales report generated successfully',
            data: orders
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error generating sales report',
            error: error.message
        });
    }
};

// ==================== PROFILE MANAGEMENT ====================

// Update supplier profile
const updateSupplierProfile = async (req, res) => {
    try {
        const updateData = { ...req.body };

        // Handle logo upload
        if (req.file) {
            updateData.logo = `/uploads/${req.file.filename}`;
        }

        const updatedUser = await User.findByIdAndUpdate(
            req.user._id,
            updateData,
            { new: true, runValidators: true }
        ).select('-password -refreshToken');

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully',
            data: updatedUser
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating profile',
            error: error.message
        });
    }
};

module.exports = {
    getMyProducts,
    createProduct,
    updateProduct,
    deleteProduct,
    getActiveCartItems,
    getSupplierOrders,
    updateOrderStatus,
    getOrderDetails,
    getSupplierAnalytics,
    getSalesReport,
    updateSupplierProfile
};