import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../widgets/product/product_cards.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';

/// Production-level Enhanced Product Detail Screen
class EnhancedProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const EnhancedProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<EnhancedProductDetailScreen> createState() =>
      _EnhancedProductDetailScreenState();
}

class _EnhancedProductDetailScreenState
    extends ConsumerState<EnhancedProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mock product - replace with actual provider
    final product = _getMockProduct();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(product),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
            ],
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: AppConstants.paddingAll20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title & Rating
                    Text(
                      product.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (product.averageRating > 0) ...[
                          const Icon(
                            Icons.star,
                            color: AppColors.accentYellow,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.averageRating.toStringAsFixed(1),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${product.totalReviews} reviews)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        const Spacer(),
                        StatusBadge(
                          status:
                              product.isInStock ? 'in_stock' : 'out_of_stock',
                          isSmall: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Price Section
                    if (product.hasDiscount)
                      Text(
                        'Rs ${product.compareAtPrice!.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.lightTextTertiary,
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rs ${product.price.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${product.discountPercentage}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const SectionHeader(title: 'Description'),
                    const SizedBox(height: 12),
                    Text(
                      product.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Specifications
                    const SectionHeader(title: 'Specifications'),
                    const SizedBox(height: 12),
                    _buildSpecRow('SKU', product.sku ?? 'N/A', theme),
                    _buildSpecRow('Stock', '${product.stock} units', theme),
                    _buildSpecRow(
                        'Category', product.category?.name ?? 'N/A', theme),
                    _buildSpecRow('Supplier',
                        product.supplier?.displayName ?? 'N/A', theme),
                    const SizedBox(height: 24),

                    // Quantity Selector
                    const SectionHeader(title: 'Quantity'),
                    const SizedBox(height: 12),
                    Container(
                      padding: AppConstants.paddingAll12,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        borderRadius: AppConstants.borderRadiusMedium,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              '$_quantity',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_quantity < product.stock) {
                                setState(() => _quantity++);
                              }
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Related Products
                    SectionHeader(
                      title: 'Related Products',
                      actionText: 'See All',
                      onSeeAll: () {},
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return ProductCardCompact(
                            product: product,
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Bottom Action Bar
      bottomNavigationBar: _buildBottomBar(context, ref, product, isDark),
    );
  }

  Widget _buildImageGallery(Product product) {
    final images = product.images.isNotEmpty
        ? product.images.map((img) => img.url).toList()
        : [''];

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
          itemBuilder: (context, index) {
            return images[index].isNotEmpty
                ? Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.lightSurfaceVariant,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: AppColors.lightTextTertiary,
                        ),
                      );
                    },
                  )
                : Container(
                    color: AppColors.lightSurfaceVariant,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: AppColors.lightTextTertiary,
                    ),
                  );
          },
        ),
        // Image Indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    Product product,
    bool isDark,
  ) {
    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add to Wishlist Button
            AnimatedButton(
              text: '',
              icon: Icons.favorite_border,
              onPressed: () {},
              isOutlined: true,
              backgroundColor: AppColors.primaryBlue,
            ),
            const SizedBox(width: 12),
            // Add to Cart Button
            Expanded(
              child: AnimatedButton(
                text: 'Add to Cart',
                icon: Icons.shopping_cart,
                onPressed: () async {
                  final success =
                      await ref.read(cartProvider.notifier).addToCart(
                            productId: product.id,
                            quantity: _quantity,
                          );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Added $_quantity ${product.title} to cart'),
                        action: SnackBarAction(
                          label: 'View Cart',
                          onPressed: () {
                            // Navigate to cart
                          },
                        ),
                      ),
                    );
                  }
                },
                gradient: AppColors.primaryGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Product _getMockProduct() {
    return Product(
      id: widget.productId,
      title: 'Premium Portland Cement 50kg',
      description:
          'High-quality Portland cement suitable for all construction needs. Manufactured to international standards with consistent strength and durability. Perfect for residential and commercial projects.',
      price: 650.0,
      compareAtPrice: 800.0,
      images: [],
      categoryId: 'cat_1',
      supplierId: 'sup_1',
      stock: 150,
      sku: 'CEMENT-50KG-001',
      averageRating: 4.5,
      totalReviews: 128,
      createdAt: DateTime.now(),
    );
  }
}
