import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Collection of shimmer loading widgets for different UI elements
class ShimmerWidgets {
  ShimmerWidgets._();

  /// Base shimmer wrapper
  static Widget _shimmer({
    required Widget child,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor:
          isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      highlightColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: child,
    );
  }

  /// Shimmer stat card
  static Widget statCard(BuildContext context) {
    return _shimmer(
      context: context,
      child: Card(
        child: SizedBox(
          height: AppConstants.statCardHeight,
          child: Padding(
            padding: AppConstants.paddingAll16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppConstants.borderRadiusSmall,
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppConstants.borderRadiusSmall,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 24,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shimmer order card
  static Widget orderCard(BuildContext context) {
    return _shimmer(
      context: context,
      child: Card(
        child: Padding(
          padding: AppConstants.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacing12),
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusCircle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer chart
  static Widget chart(BuildContext context, {double? height}) {
    return _shimmer(
      context: context,
      child: Container(
        height: height ?? AppConstants.chartHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppConstants.borderRadiusMedium,
        ),
      ),
    );
  }

  /// Shimmer list tile
  static Widget listTile(BuildContext context) {
    return _shimmer(
      context: context,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        title: Container(
          width: double.infinity,
          height: 16,
          color: Colors.white,
        ),
        subtitle: Container(
          width: 120,
          height: 12,
          color: Colors.white,
          margin: const EdgeInsets.only(top: 8),
        ),
      ),
    );
  }

  /// Shimmer product card
  static Widget productCard(BuildContext context) {
    return _shimmer(
      context: context,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
              ),
            ),
            Padding(
              padding: AppConstants.paddingAll12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 16,
                    color: Colors.white,
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
