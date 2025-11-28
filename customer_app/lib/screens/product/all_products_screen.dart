import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product/product_card_modern.dart';
import '../../providers/cart_provider.dart';
import '../product/product_detail_screen.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/enhanced_states.dart';

/// All Products Screen with filtering and sorting
class AllProductsScreen extends ConsumerStatefulWidget {
  final String? initialSort;
  final String? initialFilter;

  const AllProductsScreen({
    super.key,
    this.initialSort,
    this.initialFilter,
  });

  @override
  ConsumerState<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends ConsumerState<AllProductsScreen>
    with SingleTickerProviderStateMixin {
  String _sortBy = 'newest';
  bool _showGrid = true;
  bool _showScrollToTop = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    if (widget.initialSort != null) {
      _sortBy = widget.initialSort!;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);
    Future.microtask(
        () => ref.read(productProvider.notifier).refreshProducts());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >= 400 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset < 400 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productState = ref.watch(productProvider);

    // Sort products based on selected criteria
    final sortedProducts = _sortProducts(productState.products);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('All Products'),
        elevation: 0,
        actions: [
          // Toggle Grid/List View with Animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              key: ValueKey(_showGrid),
              icon: Icon(_showGrid ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() => _showGrid = !_showGrid);
                _animationController.forward(from: 0);
              },
            ),
          ),
          // Sort Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem(
                value: 'name_az',
                child: Text('Name: A to Z'),
              ),
              const PopupMenuItem(
                value: 'name_za',
                child: Text('Name: Z to A'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productProvider.notifier).refreshProducts(),
        child: productState.isLoading && productState.products.isEmpty
            ? _buildLoadingState()
            : productState.error != null
                ? _buildErrorView(context, productState.error!)
                : sortedProducts.isEmpty
                    ? _buildEmptyView(context)
                    : _buildProductsView(context, sortedProducts),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _showScrollToTop ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showScrollToTop ? 1.0 : 0.0,
          child: FloatingActionButton.small(
            onPressed: _scrollToTop,
            child: const Icon(Icons.keyboard_arrow_up),
          ),
        ),
      ),
    );
  }

  // Shimmer Loading State
  Widget _buildLoadingState() {
    return _showGrid
        ? const ShimmerLoadingGrid(itemCount: 6)
        : const ShimmerLoadingList(itemCount: 5);
  }

  // Enhanced Products View with Staggered Animation
  Widget _buildProductsView(BuildContext context, List<dynamic> products) {
    if (_showGrid) {
      return GridView.builder(
        controller: _scrollController,
        padding: AppConstants.paddingAll16,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          // Staggered animation
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: ProductCardModern(
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
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              onToggleWishlist: () async {
                final wishlistNotifier = ref.read(wishlistProvider.notifier);
                final wishlistState = ref.read(wishlistProvider);
                final isInWishlist = wishlistState.isInWishlist(product.id);

                final success = await wishlistNotifier.toggleWishlist(
                  product.id,
                  product,
                );

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isInWishlist
                            ? 'Removed from wishlist'
                            : 'Added to wishlist',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          );
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        padding: AppConstants.paddingAll16,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          // Staggered animation for list
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: _buildProductListItem(context, product),
          );
        },
      );
    }
  }

  Widget _buildProductListItem(BuildContext context, dynamic product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstants.paddingAll12,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: AppConstants.borderRadiusMedium,
        child: Row(
          children: [
            // Product Image
            Hero(
              tag: 'product-${product.id}',
              child: ClipRRect(
                borderRadius: AppConstants.borderRadiusSmall,
                child: Container(
                  width: 100,
                  height: 100,
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  child: product.image != null && product.image!.isNotEmpty
                      ? Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_outlined);
                          },
                        )
                      : const Icon(Icons.inventory_2_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? 'Product',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.description != null)
                    Text(
                      product.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Rs ${product.price?.toStringAsFixed(2) ?? '0.00'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () async {
                            final success =
                                await ref.read(cartProvider.notifier).addToCart(
                                      productId: product.id,
                                      quantity: 1,
                                    );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${product.title} added to cart'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.add_shopping_cart,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Error View
  Widget _buildErrorView(BuildContext context, String error) {
    return EnhancedErrorState(
      message: error,
      technicalDetails:
          'Failed to load products. Please check your connection.',
      onRetry: () => ref.read(productProvider.notifier).refreshProducts(),
      isLoading: ref.watch(productProvider).isLoading,
    );
  }

  // Enhanced Empty View
  Widget _buildEmptyView(BuildContext context) {
    return EnhancedEmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'No Products Found',
      message: 'We couldn\'t find any products matching your criteria.',
      actionText: 'Browse All Categories',
      onAction: () => Navigator.pop(context),
      iconColor: AppColors.primaryBlue,
    );
  }

  List<dynamic> _sortProducts(List<dynamic> products) {
    final sorted = List.from(products);

    switch (_sortBy) {
      case 'price_low':
        sorted.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'price_high':
        sorted.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'name_az':
        sorted.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
        break;
      case 'name_za':
        sorted.sort((a, b) => (b.title ?? '').compareTo(a.title ?? ''));
        break;
      case 'newest':
      default:
        // Assuming products are already sorted by newest
        break;
    }

    return sorted;
  }
}
