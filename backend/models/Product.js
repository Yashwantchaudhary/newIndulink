const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Product title is required'],
            trim: true,
            maxlength: [200, 'Title cannot exceed 200 characters'],
        },
        description: {
            type: String,
            required: [true, 'Product description is required'],
            maxlength: [2000, 'Description cannot exceed 2000 characters'],
        },
        price: {
            type: Number,
            required: [true, 'Product price is required'],
            min: [0, 'Price cannot be negative'],
        },
        compareAtPrice: {
            type: Number,
            min: [0, 'Compare price cannot be negative'],
            default: null,
        },
        images: [
            {
                url: {
                    type: String,
                    required: true,
                },
                alt: String,
                isPrimary: {
                    type: Boolean,
                    default: false,
                },
            },
        ],
        category: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Category',
            required: [true, 'Product category is required'],
        },
        supplier: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Product supplier is required'],
        },
        stock: {
            type: Number,
            required: [true, 'Stock quantity is required'],
            min: [0, 'Stock cannot be negative'],
            default: 0,
        },
        sku: {
            type: String,
            unique: true,
            sparse: true,
            trim: true,
        },
        weight: {
            value: Number,
            unit: {
                type: String,
                enum: ['kg', 'g', 'lb'],
                default: 'kg',
            },
        },
        dimensions: {
            length: Number,
            width: Number,
            height: Number,
            unit: {
                type: String,
                enum: ['cm', 'in'],
                default: 'cm',
            },
        },
        tags: [String],
        // Ratings
        averageRating: {
            type: Number,
            default: 0,
            min: 0,
            max: 5,
        },
        totalReviews: {
            type: Number,
            default: 0,
        },
        // Product status
        status: {
            type: String,
            enum: ['active', 'inactive', 'out_of_stock', 'discontinued'],
            default: 'active',
        },
        isFeatured: {
            type: Boolean,
            default: false,
        },
        // SEO fields
        metaTitle: String,
        metaDescription: String,
        // Analytics
        viewCount: {
            type: Number,
            default: 0,
        },
        purchaseCount: {
            type: Number,
            default: 0,
        },
    },
    {
        timestamps: true,
    }
);

// ===== PERFORMANCE INDEXES =====
// Compound index for category filtering with featured/active products
productSchema.index({ category: 1, isFeatured: 1, status: 1, createdAt: -1 });

// Compound index for supplier's products listing
productSchema.index({ supplier: 1, status: 1, createdAt: -1 });

// Text index for product search (title, description, tags)
productSchema.index({ title: 'text', description: 'text', tags: 'text' });

// Index for price range queries
productSchema.index({ price: 1, status: 1 });

// Index for stock availability
productSchema.index({ stock: 1, status: 1 });

// Index for featured products
productSchema.index({ isFeatured: 1, status: 1, createdAt: -1 });

// ===== VIRTUALS =====
// Discount percentage
productSchema.virtual('discountPercentage').get(function () {
    if (this.compareAtPrice && this.compareAtPrice > this.price) {
        return Math.round(((this.compareAtPrice - this.price) / this.compareAtPrice) * 100);
    }
    return 0;
});

// In stock status
productSchema.virtual('inStock').get(function () {
    return this.stock > 0;
});

// Update stock status when stock changes
productSchema.pre('save', function (next) {
    if (this.stock === 0 && this.status === 'active') {
        this.status = 'out_of_stock';
    }
    next();
});

// Ensure virtuals are included in JSON
productSchema.set('toJSON', { virtuals: true });
productSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Product', productSchema);
