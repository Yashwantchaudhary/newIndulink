import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/product.dart';

/// Product card variants matching actual Product model
/// Grid, List, Featured, and Compact layouts

// ===== PRODUCT CARD GRID =====
class ProductCardGrid extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onWishlist;
  final bool isInWishlist;

  const ProductCardGrid({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.onWishlist,
    this.isInWishlist = false,
  });

  @override
  State<ProductCardGrid> createState() => _ProductCardGridState();
}

class _ProductCardGridState extends State<ProductCardGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppConstants.borderRadiusMedium,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.grey)
                      .withValues(alpha: _isHovered ? 0.2 : 0.08),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: Offset(0, _isHovered ? 6 : 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppConstants.radiusMedium),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: widget.product.images.isNotEmpty
                            ? Image.network(
                                widget.product.primaryImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: isDark
                                        ? AppColors.darkSurfaceVariant
                                        : AppColors.lightSurfaceVariant,
                                    child: const Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                      color: AppColors.lightTextTertiary,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.lightSurfaceVariant,
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: AppColors.lightTextTertiary,
                                ),
                              ),
                      ),
                    ),
                    // Wishlist Button
                    if (widget.onWishlist != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onWishlist,
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: widget.isInWishlist
                                    ? AppColors.error
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Discount Badge
                    if (widget.product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${widget.product.discountPercentage}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Product Info
                Expanded(
                  child: Padding(
                    padding: AppConstants.paddingAll12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          widget.product.title,
                          style: theme.textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Rating
                        if (widget.product.averageRating > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.accentYellow,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.product.averageRating.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        const Spacer(),
                        // Price & Add to Cart Button
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.product.hasDiscount)
                                    Text(
                                      'Rs ${widget.product.compareAtPrice!.toStringAsFixed(2)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.lightTextTertiary,
                                      ),
                                    ),
                                  Text(
                                    'Rs ${widget.product.price.toStringAsFixed(2)}',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onAddToCart != null)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.onAddToCart,
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
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
        ),
      ),
    );
  }
}

// ===== PRODUCT CARD LIST =====
class ProductCardList extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onWishlist;
  final bool isInWishlist;

  const ProductCardList({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.onWishlist,
    this.isInWishlist = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing16,
            vertical: AppConstants.spacing8,
          ),
          padding: AppConstants.paddingAll12,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppConstants.borderRadiusMedium,
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey)
                    .withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: AppConstants.borderRadiusSmall,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.primaryImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.lightSurfaceVariant,
                              child: const Icon(Icons.image_outlined),
                            );
                          },
                        )
                      : Container(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                          child: const Icon(Icons.inventory_2_outlined),
                        ),
                ),
              ),
              const SizedBox(width: AppConstants.spacing12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (product.averageRating > 0) ...[
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.accentYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.averageRating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (product.hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accentOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${product.discountPercentage}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.accentOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price & Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (product.hasDiscount)
                    Text(
                      'Rs ${product.compareAtPrice!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.lightTextTertiary,
                      ),
                    ),
                  Text(
                    'Rs ${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onWishlist != null)
                        IconButton(
                          onPressed: onWishlist,
                          icon: Icon(
                            isInWishlist
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isInWishlist
                                ? AppColors.error
                                : AppColors.lightTextSecondary,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (onAddToCart != null) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onAddToCart,
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== PRODUCT CARD FEATURED =====
class ProductCardFeatured extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final String? label;

  const ProductCardFeatured({
    super.key,
    required this.product,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.orangePinkGradient,
          borderRadius: AppConstants.borderRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentOrange.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppConstants.borderRadiusLarge,
          child: Stack(
            children: [
              // Background Image
              if (product.images.isNotEmpty)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.network(
                      product.primaryImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: AppConstants.paddingAll20,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (label != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.accentOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            product.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (product.hasDiscount)
                            Text(
                              '${product.discountPercentage}% OFF',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs ${product.price.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (product.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: AppConstants.borderRadiusMedium,
                        child: Image.network(
                          product.primaryImageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== PRODUCT CARD COMPACT =====
class ProductCardCompact extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCardCompact({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppConstants.spacing12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppConstants.borderRadiusMedium,
          boxShadow: [
            BoxShadow(
              color:
                  (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusMedium),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.primaryImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            child: const Icon(Icons.image_outlined),
                          );
                        },
                      )
                    : Container(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        child: const Icon(Icons.inventory_2_outlined),
                      ),
              ),
            ),
            // Product Info
            Padding(
              padding: AppConstants.paddingAll8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
