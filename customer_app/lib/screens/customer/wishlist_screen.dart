import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../widgets/product/product_cards.dart';
import '../../models/product.dart';

/// Production-level Wishlist Screen
class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mock data - replace with actual wishlist provider
    final mockProducts = List.generate(
      8,
      (index) => Product(
        id: 'prod_$index',
        title: 'Building Material Product ${index + 1}',
        description: 'High quality construction material for your projects',
        price: 500.0 + (index * 100),
        categoryId:
            index % 3 == 0 ? 'cement' : (index % 3 == 1 ? 'steel' : 'bricks'),
        supplierId: 'supplier_$index',
        images: [],
        stock: 50 + index,
        createdAt: DateTime.now(),
      ),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              _showClearConfirmation(context);
            },
          ),
        ],
      ),
      body: mockProducts.isEmpty
          ? EmptyStateWidget(
              icon: Icons.favorite_outline,
              title: 'Your Wishlist is Empty',
              message: 'Add products you love to your wishlist',
              actionText: 'Browse Products',
              onAction: () => _showShareWishlist(context),
            )
          : Column(
              children: [
                // Stats Row
                Container(
                  padding: AppConstants.paddingAll16,
                  child: Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Total Items',
                          value: mockProducts.length.toString(),
                          icon: Icons.favorite,
                          iconColor: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Total Value',
                          value:
                              'Rs ${_calculateTotal(mockProducts).toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet,
                          iconColor: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                // Products Grid/List
                Expanded(
                  child: _isGridView
                      ? _buildGridView(mockProducts)
                      : _buildListView(mockProducts),
                ),

                // Bottom Actions
                Container(
                  padding: AppConstants.paddingAll16,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedButton(
                          text: 'Add All to Cart',
                          icon: Icons.shopping_cart,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added all items to cart'),
                              ),
                            );
                          },
                          gradient: AppColors.primaryGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedButton(
                        text: 'Share',
                        icon: Icons.share,
                        onPressed: () => _showShareWishlist(context),
                        isOutlined: true,
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGridView(List<Product> products) {
    return GridView.builder(
      padding: AppConstants.paddingAll16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCardGrid(
          product: products[index],
          onTap: () {
            // Navigate to product detail
          },
          onAddToCart: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${products[index].title} added to cart')),
            );
          },
          onWishlist: () {
            _removeFromWishlist(context, products[index]);
          },
          isInWishlist: true,
        );
      },
    );
  }

  Widget _buildListView(List<Product> products) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCardList(
          product: products[index],
          onTap: () {
            // Navigate to product detail
          },
          onAddToCart: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${products[index].title} added to cart')),
            );
          },
          onWishlist: () {
            _removeFromWishlist(context, products[index]);
          },
          isInWishlist: true,
        );
      },
    );
  }

  double _calculateTotal(List<Product> products) {
    return products.fold(0.0, (sum, product) => sum + product.price);
  }

  void _removeFromWishlist(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Wishlist'),
        content: Text('Remove "${product.title}" from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Removed from wishlist')),
              );
            },
            child:
                const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wishlist'),
        content: const Text('Remove all items from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wishlist cleared')),
              );
            },
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showShareWishlist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share wishlist feature coming soon')),
    );
  }
}
