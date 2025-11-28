import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:badges/badges.dart' as badges;
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/deals/deals_banner.dart';
import '../../widgets/product/product_card_modern.dart';
import '../cart/cart_screen.dart';
import '../product/product_detail_screen.dart';
import '../customer/wishlist_screen.dart';
import '../notifications/modern_notifications_screen.dart';
import '../search/modern_search_screen.dart';
import '../category/categories_screen.dart';
import '../order/orders_list_screen.dart';
import '../../widgets/search/voice_search_dialog.dart';
import '../scanner/barcode_scanner_screen.dart';

class EnhancedHomeScreen extends ConsumerStatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  ConsumerState<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends ConsumerState<EnhancedHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();

    // Fetch products on init
    Future.microtask(
        () => ref.read(productProvider.notifier).refreshProducts());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final productState = ref.watch(productProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(productProvider.notifier).refreshProducts(),
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(
                  context, cartItemCount, authState.user?.firstName ?? 'Guest'),

              // Search Bar Section
              _buildSearchSection(context),

              // Quick Actions
              _buildQuickActions(context),

              // Deals Banner
              _buildDealsBanner(context),

              // Categories
              _buildCategoriesSection(context),

              // Featured Products
              _buildFeaturedProducts(context, productState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, int cartItemCount, String userName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      floating: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      toolbarHeight: 70,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $userName! 👋',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'What are you looking for today?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
        ],
      ),
      actions: [
        // Notifications
        IconButton(
          icon: const badges.Badge(
            badgeContent: Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Icon(Icons.notifications_outlined),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ModernNotificationsScreen()),
            );
          },
        ),
        // Cart
        IconButton(
          icon: cartItemCount > 0
              ? badges.Badge(
                  badgeContent: Text(
                    cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined),
                )
              : const Icon(Icons.shopping_cart_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing20,
          vertical: AppConstants.spacing16,
        ),
        child: SearchBarWidget(
          readOnly: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ModernSearchScreen()),
            );
          },
          onVoiceSearch: () {
            showDialog(
              context: context,
              builder: (context) => VoiceSearchDialog(
                onSearchQuery: (query) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModernSearchScreen(),
                    ),
                  );
                },
              ),
            );
          },
          onScan: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BarcodeScannerScreen(),
              ),
            );
          },
        ),
      )
          .animate()
          .fadeIn(duration: AppConstants.durationNormal)
          .slideY(begin: -0.2, end: 0, curve: AppConstants.curveEmphasized),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionButton(
              context: context,
              icon: Icons.local_offer_rounded,
              label: 'Deals',
              gradient: AppColors.accentGradient,
              onTap: () {
                Navigator.pushNamed(context, '/deals');
              },
            ),
            _buildQuickActionButton(
              context: context,
              icon: Icons.favorite_rounded,
              label: 'Wishlist',
              gradient: const LinearGradient(
                colors: [AppColors.accentPink, AppColors.secondaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WishlistScreen()),
                );
              },
            ),
            _buildQuickActionButton(
              context: context,
              icon: Icons.history_rounded,
              label: 'Recent',
              gradient: const LinearGradient(
                colors: [AppColors.accentCyan, AppColors.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrdersListScreen()),
                );
              },
            ),
            _buildQuickActionButton(
              context: context,
              icon: Icons.category_rounded,
              label: 'All Categories',
              gradient: AppColors.successGradient,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CategoriesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsBanner(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: DealsBanner(
          banners: [
            BannerItem(
              title: 'Flash Sale! 🔥',
              subtitle: 'Up to 60% OFF on Electronics',
              badge: 'LIMITED TIME',
              icon: Icons.bolt_rounded,
              gradient: AppColors.primaryGradient,
              onTap: () {
                Navigator.pushNamed(context, '/deals');
              },
            ),
            BannerItem(
              title: 'New Arrivals',
              subtitle: 'Check out the latest products',
              badge: 'NEW',
              icon: Icons.new_releases_rounded,
              gradient: AppColors.secondaryGradient,
              onTap: () {
                Navigator.pushNamed(context, '/all-products');
              },
            ),
            BannerItem(
              title: 'Free Shipping',
              subtitle: 'On orders above Rs 5000',
              badge: 'TODAY ONLY',
              icon: Icons.local_shipping_rounded,
              gradient: AppColors.successGradient,
              onTap: () {
                // TODO: Navigate to shipping info
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shop by Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CategoriesScreen()),
                    );
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryCard(
                  context: context,
                  title: 'Electronics',
                  icon: Icons.devices_rounded,
                  gradient: AppColors.primaryGradient,
                  count: 245,
                ),
                _buildCategoryCard(
                  context: context,
                  title: 'Fashion',
                  icon: Icons.checkroom_rounded,
                  gradient: AppColors.secondaryGradient,
                  count: 189,
                ),
                _buildCategoryCard(
                  context: context,
                  title: 'Home & Garden',
                  icon: Icons.home_rounded,
                  gradient: AppColors.successGradient,
                  count: 156,
                ),
                _buildCategoryCard(
                  context: context,
                  title: 'Industrial',
                  icon: Icons.factory_rounded,
                  gradient: AppColors.accentGradient,
                  count: 324,
                ),
                _buildCategoryCard(
                  context: context,
                  title: 'Sports',
                  icon: Icons.sports_basketball_rounded,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentCyan, AppColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  count: 98,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required int count,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: gradient.begin,
          end: gradient.end,
          colors:
              gradient.colors.map((c) => c.withValues(alpha: 0.15)).toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient.colors.first.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoriesScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts(BuildContext context, productState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing20,
              vertical: AppConstants.spacing16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Products',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/all-products');
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

          // Loading State
          if (productState.isLoading && productState.products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          // Error State
          else if (productState.error != null)
            ErrorStateWidget.server(
              onRetry: () =>
                  ref.read(productProvider.notifier).refreshProducts(),
            )
          // Empty State
          else if (productState.products.isEmpty)
            EmptyState.noItems(
              title: 'No Products Yet',
              subtitle: 'Check back soon for amazing products!',
            )
          // Products Grid
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: productState.products.length > 10
                    ? 10
                    : productState.products.length,
                itemBuilder: (context, index) {
                  final product = productState.products[index];
                  return ProductCardModern(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(productId: product.id),
                        ),
                      );
                    },
                    onAddToCart: () async {
                      final success =
                          await ref.read(cartProvider.notifier).addToCart(
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
                    onToggleWishlist: () async {
                      final wishlistNotifier =
                          ref.read(wishlistProvider.notifier);
                      final wishlistState = ref.read(wishlistProvider);
                      final isInWishlist =
                          wishlistState.isInWishlist(product.id);

                      final success = await wishlistNotifier.toggleWishlist(
                        product.id,
                        product,
                      );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isInWishlist
                                  ? '${product.title} removed from wishlist'
                                  : '${product.title} added to wishlist',
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 300 + (index * 50)),
                        duration: AppConstants.durationNormal,
                      )
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        curve: AppConstants.curveEmphasized,
                      );
                },
              ),
            ),
          const SizedBox(height: AppConstants.spacing24),
        ],
      ),
    );
  }
}
