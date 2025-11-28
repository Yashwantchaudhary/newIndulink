import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Skeleton widget for product card grid layout
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade300,
      highlightColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      child: Container(
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
            // Image placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusMedium),
                  ),
                ),
              ),
            ),
            // Content placeholder
            Expanded(
              flex: 2,
              child: Padding(
                padding: AppConstants.paddingAll12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title placeholder
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 100,
                      color: Colors.white,
                    ),
                    const Spacer(),
                    // Price placeholder
                    Container(
                      height: 20,
                      width: 80,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton widget for product card list layout
class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade300,
      highlightColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
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
              color:
                  (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppConstants.borderRadiusSmall,
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            // Content placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  // Description placeholder
                  Container(
                    height: 14,
                    width: 200,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  // Rating and discount placeholder
                  Container(
                    height: 12,
                    width: 120,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            // Price and actions placeholder
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: 16,
                  width: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton grid for loading multiple product cards
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.spacing12,
        mainAxisSpacing: AppConstants.spacing12,
        childAspectRatio: 0.7,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

/// Skeleton list for loading multiple product list items
class ProductListSkeletonGrid extends StatelessWidget {
  final int itemCount;

  const ProductListSkeletonGrid({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ProductListSkeleton(),
    );
  }
}

/// Category skeleton for loading category grids
class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade300,
      highlightColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: 80,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic shimmer wrapper for any widget
class ShimmerWrapper extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerWrapper({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBaseColor =
        isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade300;
    final defaultHighlightColor =
        isDark ? AppColors.darkSurface : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBaseColor,
      highlightColor: highlightColor ?? defaultHighlightColor,
      child: child,
    );
  }
}
