const Review = require('../models/Review');
const Product = require('../models/Product');
const Order = require('../models/Order');

// @desc    Get product reviews
// @route   GET /api/products/:productId/reviews
// @access  Public
exports.getProductReviews = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const filter = {
            product: req.params.productId,
            status: 'approved',
        };

        const reviews = await Review.find(filter)
            .populate('customer', 'firstName lastName profileImage')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        const total = await Review.countDocuments(filter);

        res.status(200).json({
            success: true,
            count: reviews.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            data: reviews,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Create review
// @route   POST /api/reviews
// @access  Private (Customer)
exports.createReview = async (req, res, next) => {
    try {
        const { product, order, rating, title, comment } = req.body;

        // Check if product exists
        const productDoc = await Product.findById(product);

        if (!productDoc) {
            return res.status(404).json({
                success: false,
                message: 'Product not found',
            });
        }

        // Check if user has purchased this product
        let isVerifiedPurchase = false;
        if (order) {
            const orderDoc = await Order.findOne({
                _id: order,
                customer: req.user.id,
                'items.product': product,
                status: 'delivered',
            });

            if (orderDoc) {
                isVerifiedPurchase = true;
            }
        }

        // Check if user already reviewed this product
        const existingReview = await Review.findOne({
            product,
            customer: req.user.id,
        });

        if (existingReview) {
            return res.status(400).json({
                success: false,
                message: 'You have already reviewed this product',
            });
        }

        // Handle uploaded images
        let images = [];
        if (req.files && req.files.length > 0) {
            images = req.files.map((file) => ({
                url: `/uploads/reviews/${file.filename}`,
                alt: 'Review image',
            }));
        }

        const review = await Review.create({
            product,
            customer: req.user.id,
            order,
            rating,
            title,
            comment,
            images,
            isVerifiedPurchase,
        });

        await review.populate('customer', 'firstName lastName profileImage');

        res.status(201).json({
            success: true,
            message: 'Review submitted successfully',
            data: review,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update review
// @route   PUT /api/reviews/:id
// @access  Private (Customer - own reviews)
exports.updateReview = async (req, res, next) => {
    try {
        let review = await Review.findById(req.params.id);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found',
            });
        }

        // Check ownership
        if (review.customer.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this review',
            });
        }

        const { rating, title, comment } = req.body;

        review.rating = rating !== undefined ? rating : review.rating;
        review.title = title !== undefined ? title : review.title;
        review.comment = comment !== undefined ? comment : review.comment;

        await review.save();

        res.status(200).json({
            success: true,
            message: 'Review updated successfully',
            data: review,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete review
// @route   DELETE /api/reviews/:id
// @access  Private (Customer - own reviews)
exports.deleteReview = async (req, res, next) => {
    try {
        const review = await Review.findById(req.params.id);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found',
            });
        }

        // Check ownership
        if (review.customer.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this review',
            });
        }

        await review.remove();

        res.status(200).json({
            success: true,
            message: 'Review deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Mark review as helpful
// @route   PUT /api/reviews/:id/helpful
// @access  Private
exports.markReviewHelpful = async (req, res, next) => {
    try {
        const review = await Review.findById(req.params.id);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found',
            });
        }

        // Check if user already marked this review as helpful
        const alreadyMarked = review.helpfulBy.includes(req.user.id);

        if (alreadyMarked) {
            // Remove from helpful
            review.helpfulBy = review.helpfulBy.filter(
                (userId) => userId.toString() !== req.user.id
            );
            review.helpfulCount -= 1;
        } else {
            // Add to helpful
            review.helpfulBy.push(req.user.id);
            review.helpfulCount += 1;
        }

        await review.save();

        res.status(200).json({
            success: true,
            message: alreadyMarked ? 'Removed from helpful' : 'Marked as helpful',
            data: { helpfulCount: review.helpfulCount },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Add supplier response to review
// @route   PUT /api/reviews/:id/response
// @access  Private (Supplier)
exports.addSupplierResponse = async (req, res, next) => {
    try {
        const { comment } = req.body;

        const review = await Review.findById(req.params.id).populate('product');

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found',
            });
        }

        // Check if user is the supplier of the product
        if (review.product.supplier.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to respond to this review',
            });
        }

        review.response = {
            comment,
            respondedAt: new Date(),
        };

        await review.save();

        res.status(200).json({
            success: true,
            message: 'Response added successfully',
            data: review,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get review statistics
// @route   GET /api/reviews/stats
// @access  Public
exports.getReviewStats = async (req, res, next) => {
    try {
        const totalReviews = await Review.countDocuments();
        const approvedReviews = await Review.countDocuments({ status: 'approved' });
        const pendingReviews = await Review.countDocuments({ status: 'pending' });

        // Get average rating
        const ratingData = await Review.aggregate([
            { $group: { _id: null, averageRating: { $avg: '$rating' } } }
        ]);

        const averageRating = ratingData[0]?.averageRating || 0;

        res.status(200).json({
            success: true,
            data: {
                totalReviews,
                approvedReviews,
                pendingReviews,
                averageRating,
                count: totalReviews
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get user review statistics
// @route   GET /api/reviews/stats/user/:userId
// @access  Private
exports.getUserReviewStats = async (req, res, next) => {
    try {
        const userId = req.params.userId;

        // Check if user is authorized to access this user's data
        if (req.user.role !== 'admin' && req.user.id !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to access this user data',
            });
        }

        const totalReviews = await Review.countDocuments({ customer: userId });
        const approvedReviews = await Review.countDocuments({ customer: userId, status: 'approved' });

        // Get average rating for user
        const ratingData = await Review.aggregate([
            { $match: { customer: userId } },
            { $group: { _id: null, averageRating: { $avg: '$rating' } } }
        ]);

        const averageRating = ratingData[0]?.averageRating || 0;

        res.status(200).json({
            success: true,
            data: {
                totalReviews,
                approvedReviews,
                averageRating,
                count: totalReviews
            }
        });
    } catch (error) {
        next(error);
    }
};
