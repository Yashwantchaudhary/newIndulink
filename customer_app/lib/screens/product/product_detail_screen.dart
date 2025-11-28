import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/common/beautiful_card.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/product/image_carousel.dart';
import '../../widgets/product/quantity_selector.dart';
import '../../widgets/product/price_display.dart';
import '../../widgets/product/rating_display.dart';
import '../../widgets/product/stock_indicator.dart';

/// Product Detail Screen
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedQuantity = 1;
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return ErrorStateWidget.notFound(
              message: 'This product no longer exists',
              onAction: () => Navigator.pop(context),
            );
          }
          return _buildProductDetail(product, isDark, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateWidget.server(
          onRetry: () => ref.refresh(productDetailProvider(widget.productId)),
        ),
      ),
      // Sticky Add to Cart button
      bottomNavigationBar: productAsync.when(
        data: (product) {
          if (product == null) return const SizedBox.shrink();
          return _buildAddToCartBar(product, theme, isDark);
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildProductDetail(Product product, bool isDark, ThemeData theme) {
    final imageUrls = product.images.map((img) => img.url).toList();

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 400,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: ImageCarousel(
              imageUrls: imageUrls,
              height: 400,
            ),
          ),
        ),

        // Product Info
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusLarge),
              ),
            ),
            child: Padding(
              padding: AppConstants.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stock indicator
                  StockIndicator(stock: product.stock),
                  const SizedBox(height: AppConstants.spacing12),

                  // Product title
                  Text(
                    product.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),

                  // Rating
                  RatingDisplay(
                    rating: product.averageRating,
                    reviewCount: product.totalReviews,
                  ),
                  const SizedBox(height: AppConstants.spacing16),

                  // Price
                  PriceDisplay(
                    price: product.price,
                    compareAtPrice: product.compareAtPrice,
                  ),
                  const SizedBox(height: AppConstants.spacing24),

                  // Quantity Selector
                  Row(
                    children: [
                      Text(
                        'Quantity:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacing12),
                      QuantitySelector(
                        quantity: _selectedQuantity,
                        maxQuantity: product.stock,
                        onChanged: (qty) =>
                            setState(() => _selectedQuantity = qty),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacing24),

                  // Divider
                  Divider(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  const SizedBox(height: AppConstants.spacing16),

                  // Description
                  _buildDescriptionSection(product, theme),
                  const SizedBox(height: AppConstants.spacing24),

                  // Supplier Info (if available)
                  if (product.supplier != null) ...[
                    _buildSupplierInfo(product.supplier!, theme, isDark),
                    const SizedBox(height: AppConstants.spacing24),
                  ],

                  // Category (if available)
                  if (product.category != null) ...[
                    _buildCategoryInfo(product.category!, theme, isDark),
                    const SizedBox(height: AppConstants.spacing24),
                  ],

                  // Additional spacing for bottom button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ).animate().fadeIn(duration: AppConstants.durationNormal),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(Product product, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacing8),
        AnimatedCrossFade(
          firstChild: Text(
            product.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          secondChild: Text(
            product.description,
            style: theme.textTheme.bodyMedium,
          ),
          crossFadeState: _isDescriptionExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (product.description.length > 150)
          TextButton(
            onPressed: () {
              setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
            },
            child: Text(_isDescriptionExpanded ? 'Show Less' : 'Read More'),
          ),
      ],
    );
  }

  Widget _buildSupplierInfo(Supplier supplier, ThemeData theme, bool isDark) {
    return BeautifulCard.elevated(
      onTap: () {
        // TODO: Navigate to supplier profile
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            child: const Icon(Icons.store, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sold by',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
                Text(
                  supplier.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 300))
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildCategoryInfo(Category category, ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: AppConstants.borderRadiusSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.category,
                size: 16,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 4),
              Text(
                category.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartBar(Product product, ThemeData theme, bool isDark) {
    final cartState = ref.watch(cartProvider);
    final isAdding = cartState.isLoading;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: AppConstants.shadowMedium,
      ),
      child: SafeArea(
        child: PremiumButton.primary(
          text: product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
          onPressed: product.stock > 0 && !isAdding
              ? () => _handleAddToCart(product)
              : null,
          isLoading: isAdding,
          isFullWidth: true,
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(Product product) async {
    final success = await ref.read(cartProvider.notifier).addToCart(
          productId: product.id,
          quantity: _selectedQuantity,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} added to cart'),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              // TODO: Navigate to cart screen
            },
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add item to cart'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
