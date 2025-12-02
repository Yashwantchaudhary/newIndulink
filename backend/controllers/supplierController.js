const Product = require('../models/Product');
const Order = require('../models/Order');
const User = require('../models/User');

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
            images: req.files ? req.files.map(file => `/uploads/${file.filename}`) : []
        };

        const product = await Product.create(productData);

        res.status(201).json({
            success: true,
            message: 'Product created successfully',
            data: product
        });
    } catch (error) {
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

        const updateData = {
            ...req.body,
            images: req.files ? req.files.map(file => `/uploads/${file.filename}`) : product.images
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

// ==================== ORDER MANAGEMENT ====================

// Get supplier's orders (orders containing supplier's products)
const getSupplierOrders = async (req, res) => {
    try {
        // Find orders that contain products from this supplier
        const orders = await Order.find({
            'items.product': {
                $in: await Product.find({ supplier: req.user._id }).distinct('_id')
            }
        })
        .populate('user', 'firstName lastName email')
        .populate('items.product', 'name price images')
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
            .populate('user', 'firstName lastName email phone')
            .populate('items.product', 'name price images sku')
            .populate('shippingAddress');

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        // Check if order contains supplier's products
        const hasSupplierProducts = order.items.some(item =>
            item.product && item.product.supplier && item.product.supplier.toString() === req.user._id.toString()
        );

        if (!hasSupplierProducts) {
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

        // Check if order contains supplier's products
        const hasSupplierProducts = order.items.some(item =>
            item.product && item.product.supplier && item.product.supplier.toString() === req.user._id.toString()
        );

        if (!hasSupplierProducts) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this order'
            });
        }

        order.status = status;
        await order.save();

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

        // Product statistics
        const totalProducts = await Product.countDocuments({ supplier: supplierId });
        const activeProducts = await Product.countDocuments({
            supplier: supplierId,
            isActive: true
        });

        // Order statistics
        const totalOrders = await Order.countDocuments({
            'items.product': {
                $in: await Product.find({ supplier: supplierId }).distinct('_id')
            }
        });

        // Revenue calculation
        const orders = await Order.find({
            'items.product': {
                $in: await Product.find({ supplier: supplierId }).distinct('_id')
            },
            status: { $in: ['delivered', 'shipped'] }
        });

        let totalRevenue = 0;
        orders.forEach(order => {
            order.items.forEach(item => {
                if (item.product && item.product.supplier && item.product.supplier.toString() === supplierId.toString()) {
                    totalRevenue += item.price * item.quantity;
                }
            });
        });

        res.status(200).json({
            success: true,
            message: 'Supplier analytics retrieved successfully',
            data: {
                products: {
                    total: totalProducts,
                    active: activeProducts
                },
                orders: {
                    total: totalOrders
                },
                revenue: {
                    total: totalRevenue
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error retrieving analytics',
            error: error.message
        });
    }
};

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
    getSupplierOrders,
    updateOrderStatus,
    getOrderDetails,
    getSupplierAnalytics,
    getSalesReport,
    updateSupplierProfile
};