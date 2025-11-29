import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product/product_card_modern.dart';
import '../../providers/cart_provider.dart';
import '../product/product_detail_screen.dart';

/// Deals and Flash Sale Screen
class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() => ref.read(productProvider.notifier).refreshProducts());
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
    final productState = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Deals & Offers'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Flash Sale 🔥'),
            Tab(text: 'Daily Deals'),
            Tab(text: 'Clearance'),
            Tab(text: 'New Arrivals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlashSaleTab(context, productState, isDark),
          _buildDailyDealsTab(context, productState, isDark),
          _buildClearanceTab(context, productState, isDark),
          _buildNewArrivalsTab(context, productState, isDark),
        ],
      ),
    );
  }

  Widget _buildFlashSaleTab(BuildContext context, productState, bool isDark) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => ref.read(productProvider.notifier).refreshProducts(),
      child: CustomScrollView(
        slivers: [
          // Flash Sale Banner
          SliverToBoxAdapter(
            child: Container(
              margin: AppConstants.paddingAll16,
              padding: AppConstants.paddingAll20,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppConstants.borderRadiusMedium,
              ),
              child: Column(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Flash Sale',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Up to 60% OFF - Limited Time Only!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCountdownTimer(),
                ],
              ),
            ),
          ),
          // Products Grid
          _buildProductsGrid(context, productState),
        ],
      ),
    );
  }

  Widget _buildDailyDealsTab(BuildContext context, productState, bool isDark) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => ref.read(productProvider.notifier).refreshProducts(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: AppConstants.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Best Deals',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Handpicked deals updated daily',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildProductsGrid(context, productState),
        ],
      ),
    );
  }

  Widget _buildClearanceTab(BuildContext context, productState, bool isDark) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => ref.read(productProvider.notifier).refreshProducts(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: AppConstants.paddingAll16,
              padding: AppConstants.paddingAll20,
              decoration: const BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: AppConstants.borderRadiusMedium,
              ),
              child: Column(
                children: [
                  const Icon(Icons.local_offer_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Clearance Sale',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Massive discounts on selected items',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildProductsGrid(context, productState),
        ],
      ),
    );
  }

  Widget _buildNewArrivalsTab(BuildContext context, productState, bool isDark) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => ref.read(productProvider.notifier).refreshProducts(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: AppConstants.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.new_releases_rounded, color: AppColors.accentOrange),
                      const SizedBox(width: 8),
                      Text(
                        'New Arrivals',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fresh products just added',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildProductsGrid(context, productState),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext context, productState) {
    if (productState.isLoading && productState.products.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (productState.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${productState.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(productProvider.notifier).refreshProducts(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (productState.products.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No deals available at the moment')),
      );
    }

    return SliverPadding(
      padding: AppConstants.paddingAll16,
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = productState.products[index];
            return ProductCardModern(
              product: product,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(productId: product.id),
                  ),
                );
              },
              onAddToCart: () async {
                final success = await ref.read(cartProvider.notifier).addToCart(
                      productId: product.id,
                      quantity: 1,
                    );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.title} added to cart'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              onToggleWishlist: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wishlist feature coming soon!')),
                );
              },
            );
          },
          childCount: productState.products.length,
        ),
      ),
    );
  }

  Widget _buildCountdownTimer() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'Ends in 23:45:32',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
