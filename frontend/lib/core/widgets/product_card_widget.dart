import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../screens/customer/products/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final double? width;
  final bool showAddButton;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: SizedBox(
        height: width == double.infinity
            ? 160
            : null, // Constrain height for list view
        child: Container(
          width: width ?? 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Section with Premium Styling
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.grey.shade50,
                              Colors.grey.shade100,
                            ],
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: product.primaryImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.shade100,
                                  Colors.grey.shade200,
                                ],
                              ),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.grey.shade100,
                                  Colors.grey.shade200,
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.construction,
                                  color: AppColors.primary.withOpacity(0.4),
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No Image',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Subtle gradient overlay on image for depth
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.03),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Discount Badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercentage}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlist, child) {
                        final isInWishlist = wishlist.isInWishlist(product.id);
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                            ),
                            color: isInWishlist
                                ? AppColors.error
                                : AppColors.textSecondary,
                            onPressed: () async {
                              final success =
                                  await wishlist.toggleWishlist(product);
                              if (success && context.mounted) {
                                final action =
                                    isInWishlist ? 'removed from' : 'added to';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${product.title} $action wishlist'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(wishlist.errorMessage ??
                                        'Failed to update wishlist'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Details Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10), // Reduced from 12 to 10
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max, // Changed from min to max
                    children: [
                      // Category
                      if (product.categoryName != null)
                        Text(
                          product.categoryName!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 9, // Reduced from 10
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (product.categoryName != null)
                        const SizedBox(height: 2), // Reduced from 4

                      // Title
                      Text(
                        product.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13, // Slightly reduced
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Reduced from 4

                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12, // Reduced from 14
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 2), // Reduced from 4
                          Text(
                            product.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11, // Reduced from 12
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2), // Reduced from 4
                          Text(
                            '(${product.totalReviews})',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10, // Reduced from 12
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Price and Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Rs. ${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15, // Slightly reduced from 16
                                  ),
                                ),
                                if (product.hasDiscount)
                                  Text(
                                    'Rs. ${product.compareAtPrice!.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 11, // Reduced from 12
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (showAddButton)
                            InkWell(
                              onTap: () async {
                                final success = await context
                                    .read<CartProvider>()
                                    .addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? '${product.title} added to cart'
                                        : 'Failed to add ${product.title} to cart'),
                                    duration: const Duration(seconds: 1),
                                    action: success
                                        ? SnackBarAction(
                                            label: 'VIEW CART',
                                            onPressed: () {
                                              // Navigate to cart
                                            },
                                          )
                                        : null,
                                  ),
                                );
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.all(7), // Reduced from 8
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.white,
                                  size: 16, // Reduced from 18
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ), // Close SizedBox
    );
  }
}
