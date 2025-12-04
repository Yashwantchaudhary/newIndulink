import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/widgets/product_card_widget.dart';
import '../../../models/product.dart';
import '../../../services/api_service.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';

/// ❤️ Customer Wishlist Screen
/// Manage saved products with grid view and quick add to cart
class CustomerWishlistScreen extends StatefulWidget {
  const CustomerWishlistScreen({super.key});

  static Route route() {
    return MaterialPageRoute(builder: (_) => const CustomerWishlistScreen());
  }

  @override
  State<CustomerWishlistScreen> createState() => _CustomerWishlistScreenState();
}

class _CustomerWishlistScreenState extends State<CustomerWishlistScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Product> _wishlistProducts = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(AppConfig.wishlistEndpoint);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> productsJson = response.data is List
            ? response.data
            : response.data['products'] ?? response.data['wishlist'] ?? [];

        setState(() {
          _wishlistProducts = productsJson
              .map((json) => Product.fromJson(Map<String, dynamic>.from(
                  json is Map
                      ? json
                      : {'_id': json}))) // Handle different response formats
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load wishlist';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading wishlist: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    try {
      final response = await _apiService.delete('${AppConfig.wishlistEndpoint}/$productId');

      if (response.isSuccess) {
        setState(() {
          _wishlistProducts.removeWhere((p) => p.id == productId);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from wishlist'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to remove item'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      final success = await context.read<CartProvider>().addToCart(
            product,
            quantity: 1,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} added to cart'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to cart
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _clearAllWishlist() async {
    try {
      final success = await context.read<WishlistProvider>().clearWishlist();

      if (success && mounted) {
        setState(() {
          _wishlistProducts.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wishlist cleared successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<WishlistProvider>().errorMessage ?? 'Failed to clear wishlist'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing wishlist: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wishlist'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_wishlistProducts.isNotEmpty)
            TextButton(
              onPressed: _showClearConfirmation,
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWishlist,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWishlist,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_wishlistProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primaryLightest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 80,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your wishlist is empty',
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save products you love for later',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Continue Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _wishlistProducts.length,
      itemBuilder: (context, index) {
        return _buildWishlistItem(_wishlistProducts[index]);
      },
    );
  }

  Widget _buildWishlistItem(Product product) {
    return Stack(
      children: [
        ProductCard(
          product: product,
          width: double.infinity,
        ),

        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _removeFromWishlist(product.id),
              icon: const Icon(Icons.favorite, color: AppColors.error),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ),

        // Add to cart button
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: product.inStock ? () => _addToCart(product) : null,
              icon: const Icon(Icons.shopping_cart, size: 16),
              label: Text(
                product.inStock ? 'Add to Cart' : 'Out of Stock',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    product.inStock ? AppColors.primary : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showClearConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wishlist'),
        content: const Text(
            'Are you sure you want to remove all items from your wishlist?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearAllWishlist();
    }
  }
}
