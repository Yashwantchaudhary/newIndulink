const Wishlist = require('../models/Wishlist');
const Product = require('../models/Product');

// @desc    Get user's wishlist
// @route   GET /api/wishlist
// @access  Private
exports.getWishlist = async (req, res) => {
    try {
        const wishlist = await Wishlist.findOne({ userId: req.user._id })
            .populate({
                path: 'products.productId',
                select: 'name price images stock category supplier rating',
                populate: {
                    path: 'supplier',
                    select: 'companyName'
                }
            });

        if (!wishlist) {
            return res.status(200).json({
                success: true,
                data: { products: [] }
            });
        }

        res.status(200).json({
            success: true,
            data: wishlist
        });
    } catch (error) {
        console.error('Get Wishlist Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching wishlist',
            error: error.message
        });
    }
};

// @desc    Add product to wishlist
// @route   POST /api/wishlist/:productId
// @route   POST /api/wishlist
// @access  Private
exports.addToWishlist = async (req, res) => {
    try {
        // Get productId from either params or body
        const { productId } = req.params.productId ? req.params : req.body;

        if (!productId) {
            return res.status(400).json({
                success: false,
                message: 'Product ID is required'
            });
        }

        // Check if product exists
        const product = await Product.findById(productId);
        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        let wishlist = await Wishlist.findOne({ userId: req.user._id });

        if (!wishlist) {
            // Create new wishlist
            wishlist = await Wishlist.create({
                userId: req.user._id,
                products: [{ productId: productId }]
            });
        } else {
            // Check if product already in wishlist
            const productExists = wishlist.products.some(
                item => item.productId.toString() === productId
            );

            if (productExists) {
                return res.status(400).json({
                    success: false,
                    message: 'Product already in wishlist'
                });
            }

            wishlist.products.push({ productId: productId });
            await wishlist.save();
        }

        await wishlist.populate({
            path: 'products.productId',
            select: 'name price images stock'
        });

        res.status(200).json({
            success: true,
            message: 'Product added to wishlist',
            data: wishlist
        });
    } catch (error) {
        console.error('Add to Wishlist Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error adding to wishlist',
            error: error.message
        });
    }
};

// @desc    Remove product from wishlist
// @route   DELETE /api/wishlist/:productId
// @access  Private
exports.removeFromWishlist = async (req, res) => {
    try {
        const { productId } = req.params;

        const wishlist = await Wishlist.findOne({ userId: req.user._id });

        if (!wishlist) {
            return res.status(404).json({
                success: false,
                message: 'Wishlist not found'
            });
        }

        wishlist.products = wishlist.products.filter(
            item => item.productId.toString() !== productId
        );

        await wishlist.save();

        await wishlist.populate({
            path: 'products.productId',
            select: 'name price images stock'
        });

        res.status(200).json({
            success: true,
            message: 'Product removed from wishlist',
            data: wishlist
        });
    } catch (error) {
        console.error('Remove from Wishlist Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error removing from wishlist',
            error: error.message
        });
    }
};

// @desc    Clear entire wishlist
// @route   DELETE /api/wishlist
// @access  Private
exports.clearWishlist = async (req, res) => {
    try {
        const wishlist = await Wishlist.findOne({ userId: req.user._id });

        if (!wishlist) {
            return res.status(404).json({
                success: false,
                message: 'Wishlist not found'
            });
        }

        wishlist.products = [];
        await wishlist.save();

        res.status(200).json({
            success: true,
            message: 'Wishlist cleared successfully',
            data: wishlist
        });
    } catch (error) {
        console.error('Clear Wishlist Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error clearing wishlist',
            error: error.message
        });
    }
};

// @desc    Check if product is in wishlist
// @route   GET /api/wishlist/check/:productId
// @access  Private
exports.checkWishlist = async (req, res) => {
    try {
        const { productId } = req.params;

        const wishlist = await Wishlist.findOne({ userId: req.user._id });

        if (!wishlist) {
            return res.status(200).json({
                success: true,
                data: { inWishlist: false }
            });
        }

        const inWishlist = wishlist.products.some(
            item => item.productId.toString() === productId
        );

        res.status(200).json({
            success: true,
            data: { inWishlist }
        });
    } catch (error) {
        console.error('Check Wishlist Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error checking wishlist',
            error: error.message
        });
    }
};
