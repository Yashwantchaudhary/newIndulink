import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import 'category_products_screen.dart';

/// Production-level Enhanced Categories Screen
class EnhancedCategoriesScreen extends ConsumerStatefulWidget {
  const EnhancedCategoriesScreen({super.key});

  @override
  ConsumerState<EnhancedCategoriesScreen> createState() =>
      _EnhancedCategoriesScreenState();
}

class _EnhancedCategoriesScreenState
    extends ConsumerState<EnhancedCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedCategory = 'All';
  final bool _isLoading = false;

  final _categories = [
    _CategoryData(
      'Building Materials',
      Icons.construction,
      AppColors.primaryGradient,
      324,
    ),
    _CategoryData(
      'Cement & Concrete',
      Icons.layers,
      AppColors.secondaryGradient,
      156,
    ),
    _CategoryData(
      'Steel & Iron',
      Icons.straighten,
      AppColors.cyanBlueGradient,
      89,
    ),
    _CategoryData(
      'Bricks & Blocks',
      Icons.view_module,
      AppColors.accentGradient,
      234,
    ),
    _CategoryData(
      'Wood & Timber',
      Icons.park,
      AppColors.successGradient,
      145,
    ),
    _CategoryData(
      'Paints & Coatings',
      Icons.palette,
      AppColors.purpleGradient,
      98,
    ),
    _CategoryData(
      'Tools & Equipment',
      Icons.handyman,
      AppColors.orangePinkGradient,
      167,
    ),
    _CategoryData(
      'Electrical',
      Icons.electric_bolt,
      AppColors.primaryGradient,
      203,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with Search
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Browse Categories',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          const SliverToBoxAdapter(
            child: Padding(
              padding: AppConstants.paddingAll16,
              child: SearchBarWidget(
                hintText: 'Search categories or products...',
                showVoiceIcon: false,
              ),
            ),
          ),

          // Category Grid
          SliverPadding(
            padding: AppConstants.paddingAll16,
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildCategoryCard(_categories[index]);
                },
                childCount: _categories.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_CategoryData category) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          // Navigate to category products with animation
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  CategoryProductsScreen(categoryName: category.name),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: category.gradient.colors.map((c) => c.withValues(alpha: 0.15)).toList(),
              begin: category.gradient.begin,
              end: category.gradient.end,
            ),
            borderRadius: AppConstants.borderRadiusLarge,
            border: Border.all(
              color: category.gradient.colors.first.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Count Badge
              Positioned(
                top: 12,
                right: 12,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${category.count}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: category.gradient.colors.first.withValues(alpha: 1.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: AppConstants.paddingAll16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: category.gradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: category.gradient.colors.first.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          category.icon,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

class _CategoryData {
  final String name;
  final IconData icon;
  final LinearGradient gradient;
  final int count;

  _CategoryData(this.name, this.icon, this.gradient, this.count);
}
