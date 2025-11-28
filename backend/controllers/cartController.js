const Cart = require('../models/Cart');
const Product = require('../models/Product');

// @desc    Get user's cart
// @route   GET /api/cart
// @access  Private (Customer)
exports.getCart = async (req, res, next) => {
    try {
        let cart = await Cart.findOne({ user: req.user.id }).populate({
            path: 'items.product',
            select: 'title price images stock status',
        });

        if (!cart) {
            cart = await Cart.create({ user: req.user.id, items: [] });
        }

        res.status(200).json({
            success: true,
            data: cart,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Add item to cart
// @route   POST /api/cart
// @access  Private (Customer)
exports.addToCart = async (req, res, next) => {
    try {
        const { productId, quantity } = req.body;

        // Validate product
        const product = await Product.findById(productId);

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found',
            });
        }

        if (product.status !== 'active') {
            return res.status(400).json({
                success: false,
                message: 'Product is not available',
            });
        }

        if (product.stock < quantity) {
            return res.status(400).json({
                success: false,
                message: 'Insufficient stock',
            });
        }

        // Get or create cart
        let cart = await Cart.findOne({ user: req.user.id });

        if (!cart) {
            cart = await Cart.create({ user: req.user.id, items: [] });
        }

        // Check if product already in cart
        const existingItemIndex = cart.items.findIndex(
            (item) => item.product.toString() === productId
        );

        if (existingItemIndex > -1) {
            // Update quantity
            cart.items[existingItemIndex].quantity += quantity;

            // Check stock again
            if (cart.items[existingItemIndex].quantity > product.stock) {
                return res.status(400).json({
                    success: false,
                    message: 'Insufficient stock',
                });
            }
        } else {
            // Add new item
            cart.items.push({
                product: productId,
                quantity,
                price: product.price,
            });
        }

        await cart.save();

        // Send notification to supplier
        try {
            const { createAndSendNotification } = require('../services/notificationService');

            // Create notification for supplier
            const notificationResult = await createAndSendNotification({
                userId: product.supplier.toString(),
                type: 'system',
                title: 'Product Added to Cart',
                message: `Your product "${product.title}" was added to a customer's cart (Quantity: ${quantity})`,
                data: {
                    cartItem: true,
                    productId: productId,
                    customerId: req.user.id,
                    quantity: quantity,
                    productName: product.title,
                },
            });

            if (notificationResult.success) {
                console.log(`Cart notification sent to supplier ${product.supplier}`);
            }
        } catch (notificationError) {
            console.error('Error sending cart notification:', notificationError);
            // Don't fail the cart operation if notification fails
        }

        // Populate and return
        cart = await Cart.findById(cart._id).populate({
            path: 'items.product',
            select: 'title price images stock status',
        });

        res.status(200).json({
            success: true,
            message: 'Item added to cart',
            data: cart,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update cart item quantity
// @route   PUT /api/cart/:itemId
// @access  Private (Customer)
exports.updateCartItem = async (req, res, next) => {
    try {
        const { quantity } = req.body;

        const cart = await Cart.findOne({ user: req.user.id });

        if (!cart) {
            return res.status(404).json({
                success: false,
                message: 'Cart not found',
            });
        }

        const item = cart.items.id(req.params.itemId);

        if (!item) {
            return res.status(404).json({
                success: false,
                message: 'Item not found in cart',
            });
        }

        // Validate stock
        const product = await Product.findById(item.product);

        if (quantity > product.stock) {
            return res.status(400).json({
                success: false,
                message: 'Insufficient stock',
            });
        }

        item.quantity = quantity;
        await cart.save();

        // Populate and return
        const updatedCart = await Cart.findById(cart._id).populate({
            path: 'items.product',
            select: 'title price images stock status',
        });

        res.status(200).json({
            success: true,
            message: 'Cart updated',
            data: updatedCart,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Remove item from cart
// @route   DELETE /api/cart/:itemId
// @access  Private (Customer)
exports.removeFromCart = async (req, res, next) => {
    try {
        const cart = await Cart.findOne({ user: req.user.id });

        if (!cart) {
            return res.status(404).json({
                success: false,
                message: 'Cart not found',
            });
        }

        cart.items.id(req.params.itemId).remove();
        await cart.save();

        // Populate and return
        const updatedCart = await Cart.findById(cart._id).populate({
            path: 'items.product',
            select: 'title price images stock status',
        });

        res.status(200).json({
            success: true,
            message: 'Item removed from cart',
            data: updatedCart,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Clear cart
// @route   DELETE /api/cart
// @access  Private (Customer)
exports.clearCart = async (req, res, next) => {
    try {
        const cart = await Cart.findOne({ user: req.user.id });

        if (!cart) {
            return res.status(404).json({
                success: false,
                message: 'Cart not found',
            });
        }

        cart.items = [];
        await cart.save();

        res.status(200).json({
            success: true,
            message: 'Cart cleared',
            data: cart,
        });
    } catch (error) {
        next(error);
    }
};
