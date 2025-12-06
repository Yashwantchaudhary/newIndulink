import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/product_card_widget.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../models/product.dart';
import '../cart/cart_screen.dart';
import '../products/product_list_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../wishlist/customer_wishlist_screen.dart';
import '../categories/customer_categories_screen.dart';
import '../notifications/customer_notifications_screen.dart';

/// 🏠 **WORLD-CLASS Customer Home Screen**
/// Production-level modern UI/UX with premium animations
/// Designed like top e-commerce apps (Amazon, Flipkart, Shopify)
class CustomerHomeScreenRedesigned extends StatefulWidget {
  const CustomerHomeScreenRedesigned({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => const CustomerHomeScreenRedesigned(),
    );
  }

  @override
  State<CustomerHomeScreenRedesigned> createState() =>
      _CustomerHomeScreenRedesignedState();
}

class _CustomerHomeScreenRedesignedState
    extends State<CustomerHomeScreenRedesigned> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _bannerController;
  late Timer _bannerTimer;
  int _currentBannerIndex = 0;
  late AnimationController _heroAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _categoryAnimationController;

  // Flash Deal Timer
  Duration _flashDealTimeLeft = const Duration(hours: 2, minutes: 30);
  late Timer _flashDealTimer;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _heroAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _categoryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Auto-scroll banners
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentBannerIndex < 2) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      _bannerController.animateToPage(
        _currentBannerIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });

    // Flash deal countdown
    _flashDealTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_flashDealTimeLeft.inSeconds > 0) {
            _flashDealTimeLeft -= const Duration(seconds: 1);
          }
        });
      }
    });

    // Fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer.cancel();
    _flashDealTimer.cancel();
    _heroAnimationController.dispose();
    _pulseAnimationController.dispose();
    _categoryAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    Widget? screen;
    switch (index) {
      case 0:
        return; // Already on home
      case 1:
        screen = const CustomerCategoriesScreen();
        break;
      case 2:
        screen = const CartScreen();
        break;
      case 3:
        screen = const CustomerWishlistScreen();
        break;
      case 4:
        screen = const ProfileScreen();
        break;
    }

    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen!),
      ).then((_) => setState(() => _selectedIndex = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium App Bar
            _buildPremiumAppBar(),

            // Search Bar with Animation
            SliverToBoxAdapter(
              child: _buildAnimatedSearchBar(),
            ),

            // Animated Banner Carousel
            SliverToBoxAdapter(
              child: _buildPremiumBannerSection(),
            ),

            // Quick Action Chips
            SliverToBoxAdapter(
              child: _buildQuickActionChips(),
            ),

            // Categories with Animation
            SliverToBoxAdapter(
              child: _buildPremiumCategoriesSection(),
            ),

            // Flash Deals with Timer
            SliverToBoxAdapter(
              child: _buildFlashDealsSection(),
            ),

            // Featured Products
            SliverToBoxAdapter(
              child: _buildFeaturedProductsSection(),
            ),

            // Best Sellers Grid
            SliverToBoxAdapter(
              child: _buildBestSellersSection(),
            ),

            // Bottom Spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),

      // Premium Bottom Navigation
      bottomNavigationBar: _buildPremiumBottomNavigation(),

      // Floating Action Button for Quick Cart Access
      floatingActionButton: _buildFloatingCartButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ==================== Premium App Bar ====================
  Widget _buildPremiumAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Animated Logo
                    AnimatedBuilder(
                      animation: _heroAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_heroAnimationController.value * 0.05),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.construction,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INDULINK',
                            style: AppTypography.h5.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Building Materials Marketplace',
                            style: AppTypography.caption.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.9),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notifications
                    _buildNotificationButton(),
                    const SizedBox(width: 8),
                    // Cart
                    _buildCartButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Pulsing effect
            Positioned.fill(
              child: Transform.scale(
                scale: 1.0 + (_pulseAnimationController.value * 0.3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(
                          (1 - _pulseAnimationController.value) * 0.3,
                        ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerNotificationsScreen(),
                  ),
                );
              },
              icon: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 26,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).colorScheme.onPrimary,
                            width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartButton() {
    return Consumer<CartProvider>(
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
              Icon(
                Icons.shopping_cart_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 26,
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary,
                          width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      cart.itemCount > 9 ? '9+' : cart.itemCount.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================== Animated Search Bar ====================
  Widget _buildAnimatedSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Hero(
        tag: 'search_bar',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Search building materials...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Premium Banner Section ====================
  Widget _buildPremiumBannerSection() {
    final banners = [
      {
        'title': 'MEGA SALE',
        'subtitle': 'Up to 50% OFF',
        'description': 'On cement, steel & more',
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B6B), Color(0xFFFF3838)],
        ),
        'icon': Icons.local_fire_department,
      },
      {
        'title': 'NEW ARRIVALS',
        'subtitle': 'Latest Products',
        'description': 'Premium quality materials',
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        ),
        'icon': Icons.new_releases,
      },
      {
        'title': 'FREE SHIPPING',
        'subtitle': 'On orders ₹5000+',
        'description': 'Limited time offer',
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
        ),
        'icon': Icons.local_shipping,
      },
    ];

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildBannerCard(banners[index]);
            },
          ),
          // Page Indicators
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentBannerIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: banner['gradient'] as LinearGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (banner['gradient'] as LinearGradient)
                .colors
                .first
                .withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated Background Pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _heroAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BannerPatternPainter(
                    animation: _heroAnimationController.value,
                  ),
                );
              },
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        banner['icon'] as IconData,
                        color: Colors.white.withOpacity(0.9),
                        size: 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner['title'] as String,
                        style: AppTypography.h6.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        banner['subtitle'] as String,
                        style: AppTypography.h4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        banner['description'] as String,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.95),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductListScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              (banner['gradient'] as LinearGradient)
                                  .colors
                                  .first,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Shop Now',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Quick Action Chips ====================
  Widget _buildQuickActionChips() {
    final actions = [
      {
        'label': 'Best Deals',
        'icon': Icons.local_offer,
        'color': AppColors.secondary
      },
      {
        'label': 'New Arrival',
        'icon': Icons.fiber_new,
        'color': AppColors.success
      },
      {'label': 'Top Rated', 'icon': Icons.star, 'color': AppColors.warning},
      {
        'label': 'Fast Delivery',
        'icon': Icons.bolt,
        'color': AppColors.primary
      },
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(
                        title: action['label'] as String,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: (action['color'] as Color).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        action['label'] as String,
                        style: AppTypography.labelLarge.copyWith(
                          color: action['color'] as Color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== Premium Categories Section ====================
  Widget _buildPremiumCategoriesSection() {
    final categories = [
      {
        'name': 'Cement',
        'icon': Icons.construction,
        'color': AppColors.categoryCement,
        'count': '1.2k+'
      },
      {
        'name': 'Bricks',
        'icon': Icons.square,
        'color': AppColors.categoryBricks,
        'count': '850+'
      },
      {
        'name': 'Steel',
        'icon': Icons.carpenter,
        'color': AppColors.categorySteel,
        'count': '650+'
      },
      {
        'name': 'Paint',
        'icon': Icons.format_paint,
        'color': AppColors.categoryPaint,
        'count': '920+'
      },
      {
        'name': 'Tools',
        'icon': Icons.handyman,
        'color': AppColors.categoryTools,
        'count': '1.5k+'
      },
      {
        'name': 'Electrical',
        'icon': Icons.electric_bolt,
        'color': AppColors.categoryElectrical,
        'count': '780+'
      },
      {
        'name': 'Plumbing',
        'icon': Icons.plumbing,
        'color': AppColors.categoryPlumbing,
        'count': '540+'
      },
      {
        'name': 'More',
        'icon': Icons.apps,
        'color': AppColors.primary,
        'count': '2k+'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop by Category',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find what you need',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerCategoriesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('See All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: AnimatedBuilder(
            animation: _categoryAnimationController,
            builder: (context, child) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final delay = index * 0.1;
                  final animation = Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _categoryAnimationController,
                      curve: Interval(
                        delay,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: _buildCategoryCard(categories[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListScreen(
                  initialCategory: category['name'] as String,
                  title: category['name'] as String,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (category['color'] as Color).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (category['color'] as Color).withOpacity(0.8),
                        category['color'] as Color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (category['color'] as Color).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  category['name'] as String,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  category['count'] as String,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Flash Deals Section ====================
  Widget _buildFlashDealsSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.products.isEmpty) return const SizedBox.shrink();

        final flashDeals = provider.products
            .where((p) => p.hasDiscount && p.discountPercentage >= 20)
            .take(6)
            .toList();

        if (flashDeals.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF3838)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚡ Flash Deals',
                            style: AppTypography.h5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Limited time offers',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Countdown Timer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_flashDealTimeLeft),
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: flashDeals.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildFlashDealCard(flashDeals[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashDealCard(Product product) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          // Navigate to product details
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with discount badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      color: AppColors.background,
                      child: product.primaryImageUrl.isNotEmpty
                          ? Image.network(
                              product.primaryImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.construction,
                                  size: 48,
                                  color: AppColors.textTertiary,
                                );
                              },
                            )
                          : const Icon(
                              Icons.construction,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                    ),
                  ),
                  // Discount Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.badgeSale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.discountPercentage}% OFF',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Product Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.compareAtPrice != null)
                                  Text(
                                    '₹${product.compareAtPrice!.toStringAsFixed(0)}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textTertiary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  '₹${product.price.toStringAsFixed(0)}',
                                  style: AppTypography.h6.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLightest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: AppColors.primary,
                              size: 18,
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
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // ==================== Featured Products Section ====================
  Widget _buildFeaturedProductsSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.products.isEmpty) return const SizedBox.shrink();

        final featured =
            provider.products.where((p) => p.isFeatured).take(10).toList();

        if (featured.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.warning,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Featured Products',
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hand-picked for you',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductListScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 330,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: featured.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 16),
                      child: ProductCard(
                        product: featured[index],
                        width: 200,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== Best Sellers Section ====================
  Widget _buildBestSellersSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.products.isEmpty) return const SizedBox.shrink();

        final bestSellers = provider.products.take(6).toList();

        return Container(
          margin: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: AppColors.success,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Best Sellers',
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Most popular products',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductListScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: bestSellers.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: bestSellers[index],
                      width: double.infinity,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== Premium Bottom Navigation ====================
  Widget _buildPremiumBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.category, 'Categories', 1),
              _buildNavItem(Icons.shopping_cart, 'Cart', 2),
              _buildNavItem(Icons.favorite, 'Wishlist', 3),
              _buildNavItem(Icons.person, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: isSelected ? 24 : 22,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Floating Cart Button ====================
  Widget _buildFloatingCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.itemCount == 0) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _pulseAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseAnimationController.value * 0.05),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
                backgroundColor: AppColors.secondary,
                elevation: 8,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                  '${cart.itemCount} items',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== Custom Painter for Banner Pattern ====================
class _BannerPatternPainter extends CustomPainter {
  final double animation;

  _BannerPatternPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final spacing = 40.0;
    final offset = animation * spacing;

    for (var i = -1; i < (size.width / spacing) + 1; i++) {
      final x = i * spacing + offset;
      canvas.drawCircle(
        Offset(x, size.height * 0.3),
        20,
        paint,
      );
      canvas.drawCircle(
        Offset(x + spacing / 2, size.height * 0.7),
        15,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BannerPatternPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
