const Category = require('../models/Category');

// @desc    Get all categories
// @route   GET /api/categories
// @access  Public
exports.getCategories = async (req, res, next) => {
    try {
        const filter = {};

        if (req.query.parent) {
            filter.parent = req.query.parent;
        } else if (req.query.topLevel === 'true') {
            filter.parent = null;
        }

        if (req.query.active === 'true') {
            filter.isActive = true;
        }

        const categories = await Category.find(filter)
            .populate('parent', 'name')
            .sort({ order: 1, name: 1 });

        res.status(200).json({
            success: true,
            count: categories.length,
            data: categories,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get single category
// @route   GET /api/categories/:id
// @access  Public
exports.getCategory = async (req, res, next) => {
    try {
        const category = await Category.findById(req.params.id).populate('parent', 'name slug');

        if (!category) {
            return res.status(404).json({
                success: false,
                message: 'Category not found',
            });
        }

        res.status(200).json({
            success: true,
            data: category,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Create category
// @route   POST /api/categories
// @access  Private (Supplier/Admin)
exports.createCategory = async (req, res, next) => {
    try {
        const category = await Category.create(req.body);

        res.status(201).json({
            success: true,
            message: 'Category created successfully',
            data: category,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update category
// @route   PUT /api/categories/:id
// @access  Private (Admin)
exports.updateCategory = async (req, res, next) => {
    try {
        const category = await Category.findByIdAndUpdate(req.params.id, req.body, {
            new: true,
            runValidators: true,
        });

        if (!category) {
            return res.status(404).json({
                success: false,
                message: 'Category not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Category updated successfully',
            data: category,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get category statistics
// @route   GET /api/categories/stats
// @access  Public
exports.getCategoryStats = async (req, res, next) => {
    try {
        const totalCategories = await Category.countDocuments();
        const activeCategories = await Category.countDocuments({ isActive: true });

        // Get product count per category
        const categoriesWithProducts = await Category.aggregate([
            {
                $lookup: {
                    from: 'products',
                    localField: '_id',
                    foreignField: 'category',
                    as: 'products'
                }
            },
            {
                $project: {
                    name: 1,
                    productCount: { $size: '$products' }
                }
            }
        ]);

        res.status(200).json({
            success: true,
            data: {
                totalCategories,
                activeCategories,
                categoriesWithProducts,
                count: totalCategories
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete category
// @route   DELETE /api/categories/:id
// @access  Private (Admin)
exports.deleteCategory = async (req, res, next) => {
    try {
        const category = await Category.findById(req.params.id);

        if (!category) {
            return res.status(404).json({
                success: false,
                message: 'Category not found',
            });
        }

        // Check if category has products
        if (category.productCount > 0) {
            return res.status(400).json({
                success: false,
                message: 'Cannot delete category with products',
            });
        }

        await category.remove();

        res.status(200).json({
            success: true,
            message: 'Category deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};
