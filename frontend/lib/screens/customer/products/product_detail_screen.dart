import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widgets.dart';
import '../../../core/widgets/review_card_widget.dart';
import '../../../models/product.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../cart/cart_screen.dart';
import 'write_review_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().getProductDetails(widget.productId);
      // Load reviews for this product
      context.read<ReviewProvider>().fetchProductReviews(widget.productId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    context
        .read<CartProvider>()
        .addToCart(product, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  void _toggleWishlist(Product product) async {
    final wishlistProvider = context.read<WishlistProvider>();
    final isInWishlist = wishlistProvider.isInWishlist(product.id);

    final success = await wishlistProvider.toggleWishlist(product);

    if (success && mounted) {
      final action = isInWishlist ? 'removed from' : 'added to';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} $action wishlist'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wishlistProvider.errorMessage ?? 'Failed to update wishlist'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _shareProduct(Product product) {
    final String shareText = '''
Check out this amazing product on INDULINK!

🏗️ ${product.title}

💰 Price: Rs. ${product.price.toStringAsFixed(0)}
${product.hasDiscount ? '🔥 Special Offer: ${product.discountPercentage}% OFF!' : ''}

📦 ${product.stockStatusText}

${product.description.length > 100
        ? '${product.description.substring(0, 100)}...'
        : product.description}

Download INDULINK app to purchase: https://indulink.com/product/${product.id}
''';

    Share.share(shareText.trim(), subject: 'Check out this product on INDULINK');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingSpinner());
          }

          if (provider.errorMessage != null) {
            return ErrorStateWidget(
              message: provider.errorMessage!,
              onRetry: () => provider.getProductDetails(widget.productId),
            );
          }

          final product = provider.selectedProduct;

          if (product == null) {
            return const ErrorStateWidget(message: 'Product not found');
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(product),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(product),
                    _buildProductInfo(product),
                    const Divider(height: 1),
                    _buildDescription(product),
                    const Divider(height: 1),
                    _buildSpecifications(product),
                    const Divider(height: 1),
                    _buildSupplierInfo(product),
                    const Divider(height: 1),
                    _buildReviewsSection(product),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final product = provider.selectedProduct;
          if (product == null) return const SizedBox.shrink();
          return _buildBottomBar(product);
        },
      ),
    );
  }

  Widget _buildAppBar(Product product) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            final product = provider.selectedProduct;
            return IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
              onPressed: product != null ? () => _shareProduct(product) : null,
            );
          },
        ),
        Consumer<WishlistProvider>(
          builder: (context, wishlist, child) {
            final product = context.read<ProductProvider>().selectedProduct;
            if (product == null) return const SizedBox.shrink();

            final isInWishlist = wishlist.isInWishlist(product.id);
            return IconButton(
              icon: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: isInWishlist ? AppColors.error : AppColors.textPrimary,
              ),
              onPressed: () => _toggleWishlist(product),
            );
          },
        ),
        Consumer<CartProvider>(
          builder: (context, cart, _) {
            return IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: AppColors.textPrimary),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cart.itemCount.toString(),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageGallery(Product product) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              itemCount: product.images.isNotEmpty ? product.images.length : 1,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                if (product.images.isEmpty) {
                  return Container(
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported,
                        size: 64, color: AppColors.textTertiary),
                  );
                }
                return CachedNetworkImage(
                  imageUrl: product.images[index].url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              },
            ),
          ),
          if (product.images.length > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(product.images.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? AppColors.primary
                          : AppColors.textTertiary.withOpacity(0.3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.categoryName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product.categoryName!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            product.title,
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.warning, size: 20),
              const SizedBox(width: 4),
              Text(
                product.averageRating.toStringAsFixed(1),
                style: AppTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                '(${product.totalReviews} reviews)',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.inStock
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.stockStatusText,
                  style: TextStyle(
                    color:
                        product.inStock ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${product.price.toStringAsFixed(0)}',
                style: AppTypography.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (product.hasDiscount) ...[
                const SizedBox(width: 8),
                Text(
                  'Rs. ${product.compareAtPrice!.toStringAsFixed(0)}',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textTertiary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${product.discountPercentage}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecifications(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specifications',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (product.weight != null)
            _buildSpecRow('Weight', product.weight!.displayText),
          if (product.dimensions != null)
            _buildSpecRow('Dimensions', product.dimensions!.displayText),
          if (product.sku != null) _buildSpecRow('SKU', product.sku!),
          if (product.tags.isNotEmpty)
            _buildSpecRow('Tags', product.tags.join(', ')),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfo(Product product) {
    if (product.supplierName == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLightest,
            child: Text(
              product.supplierName![0].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sold by',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  product.supplierName!,
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              if (product.supplierId != null) {
                Navigator.pushNamed(
                  context,
                  '/customer/supplier/profile',
                  arguments: product.supplierId,
                );
              }
            },
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _quantity < product.stock
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: product.inStock ? () => _addToCart(product) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  product.inStock ? 'Add to Cart' : 'Out of Stock',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(Product product) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Row(
                  children: [
                    Text(
                      'Customer Reviews',
                      style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (reviewProvider.reviews.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          final productProvider = context.read<ProductProvider>();
                          Navigator.pushNamed(
                            context,
                            '/customer/products/reviews',
                            arguments: {
                              'productId': widget.productId,
                              'productTitle': productProvider.selectedProduct?.title ?? 'Product',
                              'productImage': productProvider.selectedProduct?.images.isNotEmpty == true
                                  ? productProvider.selectedProduct!.images.first.url
                                  : null,
                            },
                          );
                        },
                        child: Text(
                          'View All (${reviewProvider.reviews.length})',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),

              // Review Summary
              if (reviewProvider.reviews.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
                  child: ReviewSummaryWidget(
                    averageRating: product.averageRating,
                    totalReviews: product.totalReviews,
                    ratingDistribution: _calculateRatingDistribution(reviewProvider.reviews),
                  ),
                ),

              // Write Review Button
              Padding(
                 padding: const EdgeInsets.all(AppDimensions.paddingL),
                 child: SizedBox(
                   width: double.infinity,
                   child: OutlinedButton.icon(
                     onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => WriteReviewScreen(
                             productId: product.id,
                             productTitle: product.title,
                             productImage: product.images.isNotEmpty ? product.images.first.url : null,
                           ),
                         ),
                       );
                     },
                     icon: const Icon(Icons.edit_outlined),
                     label: const Text('Write a Review'),
                     style: OutlinedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       side: BorderSide(color: AppColors.primary),
                       foregroundColor: AppColors.primary,
                     ),
                   ),
                 ),
               ),

              // Reviews List
              if (reviewProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingL),
                  child: Center(child: LoadingSpinner()),
                )
              else if (reviewProvider.reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No reviews yet',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to review this product',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviewProvider.reviews.length > 3 ? 3 : reviewProvider.reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviewProvider.reviews[index];
                    return ReviewCard(review: review);
                  },
                ),

              // Show more button if there are more than 3 reviews
              if (reviewProvider.reviews.length > 3)
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        final productProvider = context.read<ProductProvider>();
                        Navigator.pushNamed(
                          context,
                          '/customer/products/reviews',
                          arguments: {
                            'productId': widget.productId,
                            'productTitle': productProvider.selectedProduct?.title ?? 'Product',
                            'productImage': productProvider.selectedProduct?.images.isNotEmpty == true
                                ? productProvider.selectedProduct!.images.first.url
                                : null,
                          },
                        );
                      },
                      child: Text(
                        'Show All Reviews (${reviewProvider.reviews.length})',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Map<int, int> _calculateRatingDistribution(List reviews) {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final review in reviews) {
      if (review is Map && review.containsKey('rating')) {
        final rating = review['rating'] as int;
        if (distribution.containsKey(rating)) {
          distribution[rating] = distribution[rating]! + 1;
        }
      }
    }

    return distribution;
  }
}
