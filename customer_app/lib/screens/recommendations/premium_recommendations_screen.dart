import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';

/// Premium AI-Powered Recommendations Screen
class PremiumRecommendationsScreen extends ConsumerStatefulWidget {
  const PremiumRecommendationsScreen({super.key});

  @override
  ConsumerState<PremiumRecommendationsScreen> createState() =>
      _PremiumRecommendationsScreenState();
}

class _PremiumRecommendationsScreenState
    extends ConsumerState<PremiumRecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667eea),
                        Color(0xFF764ba2),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: AppConstants.paddingAll20,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'AI Powered',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Smart Recommendations',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Curated just for you',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'For You'),
                  Tab(text: 'Trending'),
                  Tab(text: 'Similar'),
                  Tab(text: 'Complete'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPersonalizedTab(isDark, theme),
            _buildTrendingTab(isDark, theme),
            _buildSimilarTab(isDark, theme),
            _buildCompleteTab(isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: AppConstants.paddingAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Insight Card
          Container(
            padding: AppConstants.paddingAll16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.1),
                  AppColors.accentOrange.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: AppConstants.borderRadiusLarge,
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Based on your recent activity',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You\'ve been viewing construction materials',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recommended Products
          SectionHeader(
            title: 'Perfect for Your Project',
            icon: Icons.stars,
            actionText: 'See All',
            onSeeAll: () {},
          ),
          const SizedBox(height: 12),
          _buildProductGrid(),
          const SizedBox(height: 24),

          // Because You Viewed
          const SectionHeader(
            title: 'Because You Viewed Cement',
            icon: Icons.remove_red_eye_outlined,
          ),
          const SizedBox(height: 12),
          _buildHorizontalProductList(),
          const SizedBox(height: 24),

          // Frequently Bought Together
          const SectionHeader(
            title: 'Frequently Bought Together',
            icon: Icons.shopping_basket,
          ),
          const SizedBox(height: 12),
          _buildBundleCard(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildTrendingTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: AppConstants.paddingAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Hot Right Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildProductGrid(),
        ],
      ),
    );
  }

  Widget _buildSimilarTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: AppConstants.paddingAll16,
      child: Column(
        children: [
          const SectionHeader(title: 'Similar to Your Favorites'),
          const SizedBox(height: 12),
          _buildProductGrid(),
        ],
      ),
    );
  }

  Widget _buildCompleteTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: AppConstants.paddingAll16,
      child: Column(
        children: [
          const SectionHeader(title: 'Complete the Look'),
          const SizedBox(height: 12),
          _buildBundleCard(isDark, theme),
          const SizedBox(height: 16),
          _buildBundleCard(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    // Mock product grid - replace with actual ProductCardGrid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius: AppConstants.borderRadiusLarge,
          ),
          child: const Center(child: Text('Product Card')),
        );
      },
    );
  }

  Widget _buildHorizontalProductList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              borderRadius: AppConstants.borderRadiusMedium,
            ),
            child: const Center(child: Text('Product')),
          );
        },
      ),
    );
  }

  Widget _buildBundleCard(bool isDark, ThemeData theme) {
    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryPurple.withValues(alpha: 0.1),
            AppColors.primaryBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppConstants.borderRadiusLarge,
        border: Border.all(
          color: AppColors.secondaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SAVE 15%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Bundle Deal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBundleItem('Cement 50kg'),
              const SizedBox(width: 8),
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 8),
              _buildBundleItem('Sand 1 ton'),
              const SizedBox(width: 8),
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 8),
              _buildBundleItem('Bricks'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bundle Price',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Text(
                    'Rs 8,500',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const Text(
                    'Rs 10,000',
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add Bundle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBundleItem(String name) {
    return Expanded(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            name,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
