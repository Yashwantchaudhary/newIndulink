import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Enhanced Skeleton Loaders for Modern Screens
class SkeletonLoaders {
  /// Product Card Grid Skeleton
  static Widget productCardGridSkeleton({bool isDark = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusLarge,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          _SkeletonBox(
            height: 180,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          Padding(
            padding: AppConstants.paddingAll12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 16),
                SizedBox(height: 8),
                _SkeletonBox(width: 120, height: 14),
                SizedBox(height: 12),
                Row(
                  children: [
                    _SkeletonBox(width: 80, height: 20),
                    Spacer(),
                    _SkeletonBox(width: 32, height: 32, isCircle: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Product List Skeleton
  static Widget productListSkeleton({bool isDark = false}) {
    return Container(
      padding: AppConstants.paddingAll12,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
      ),
      child: const Row(
        children: [
          _SkeletonBox(width: 100, height: 100),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 16),
                SizedBox(height: 8),
                _SkeletonBox(width: 150, height: 14),
                SizedBox(height: 8),
                _SkeletonBox(width: 100, height: 14),
                SizedBox(height: 12),
                Row(
                  children: [
                    _SkeletonBox(width: 80, height: 24),
                    Spacer(),
                    _SkeletonBox(width: 100, height: 32),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Order Card Skeleton
  static Widget orderCardSkeleton({bool isDark = false}) {
    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusLarge,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 40, height: 40),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 150, height: 16),
                    SizedBox(height: 4),
                    _SkeletonBox(width: 100, height: 14),
                  ],
                ),
              ),
              _SkeletonBox(width: 80, height: 24),
            ],
          ),
          SizedBox(height: 16),
          _SkeletonBox(width: double.infinity, height: 60),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SkeletonBox(width: double.infinity, height: 40)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  /// Chat Message Skeleton
  static Widget chatMessageSkeleton({
    bool isMe = false,
    bool isDark = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const _SkeletonBox(width: 32, height: 32, isCircle: true),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 200, height: 14),
                  SizedBox(height: 4),
                  _SkeletonBox(width: 150, height: 14),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Stats Card Skeleton
  static Widget statsCardSkeleton({bool isDark = false}) {
    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusLarge,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 40, height: 40, isCircle: true),
              Spacer(),
              _SkeletonBox(width: 60, height: 24),
            ],
          ),
          SizedBox(height: 16),
          _SkeletonBox(width: 100, height: 32),
          SizedBox(height: 8),
          _SkeletonBox(width: 80, height: 14),
        ],
      ),
    );
  }

  /// Notification Card Skeleton
  static Widget notificationSkeleton({bool isDark = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
      ),
      child: const Row(
        children: [
          _SkeletonBox(width: 48, height: 48),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 16),
                SizedBox(height: 4),
                _SkeletonBox(width: 200, height: 14),
                SizedBox(height: 4),
                _SkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grid Skeleton (for products, categories, etc.)
  static Widget gridSkeleton({
    required int itemCount,
    bool isDark = false,
  }) {
    return GridView.builder(
      padding: AppConstants.paddingAll16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => productCardGridSkeleton(isDark: isDark),
    );
  }

  /// List Skeleton
  static Widget listSkeleton({
    required int itemCount,
    required Widget Function(bool isDark) itemBuilder,
    bool isDark = false,
  }) {
    return ListView.separated(
      padding: AppConstants.paddingAll16,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => itemBuilder(isDark),
    );
  }
}

/// Animated Skeleton Box
class _SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const _SkeletonBox({
    this.width,
    required this.height,
    this.borderRadius,
    this.isCircle = false,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;
    final highlightColor = isDark
        ? AppColors.darkSurfaceVariant.withOpacity(0.5)
        : Colors.white.withOpacity(0.3);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: widget.isCircle
                ? null
                : (widget.borderRadius ?? AppConstants.borderRadiusSmall),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                highlightColor.withOpacity(0.0),
                highlightColor,
                highlightColor.withOpacity(0.0),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Full Page Skeleton Loading Screens
class SkeletonLoadingScreens {
  /// Products Grid Loading
  static Widget productsGridLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Products')),
      body: SkeletonLoaders.gridSkeleton(itemCount: 6, isDark: isDark),
    );
  }

  /// Orders List Loading
  static Widget ordersListLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Orders')),
      body: SkeletonLoaders.listSkeleton(
        itemCount: 5,
        itemBuilder: (isDark) => SkeletonLoaders.orderCardSkeleton(isDark: isDark),
        isDark: isDark,
      ),
    );
  }

  /// Notifications Loading
  static Widget notificationsLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Notifications')),
      body: SkeletonLoaders.listSkeleton(
        itemCount: 8,
        itemBuilder: (isDark) => SkeletonLoaders.notificationSkeleton(isDark: isDark),
        isDark: isDark,
      ),
    );
  }

  /// Chat Messages Loading
  static Widget chatLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Chat')),
      body: ListView(
        padding: AppConstants.paddingAll16,
        children: [
          SkeletonLoaders.chatMessageSkeleton(isMe: false, isDark: isDark),
          SkeletonLoaders.chatMessageSkeleton(isMe: true, isDark: isDark),
          SkeletonLoaders.chatMessageSkeleton(isMe: false, isDark: isDark),
          SkeletonLoaders.chatMessageSkeleton(isMe: true, isDark: isDark),
          SkeletonLoaders.chatMessageSkeleton(isMe: false, isDark: isDark),
        ],
      ),
    );
  }
}
