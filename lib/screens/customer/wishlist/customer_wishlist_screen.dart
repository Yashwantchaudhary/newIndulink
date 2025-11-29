import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/product_card_widget.dart';
import '../../../models/product.dart';
import '../../../services/api_service.dart';
import '../../../providers/cart_provider.dart';

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
      final response = await _apiService.get('/api/wishlist');

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
      final response = await _apiService.delete('/api/wishlist/$productId');

      if (response.isSuccess) {
        setState(() {
          _wishlistProducts.removeWhere((p) => p.id == productId);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to remove item')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      final success = await context.read<CartProvider>().addToCart(
            product: product,
            quantity: 1,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} added to cart'),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              // Navigate to cart
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          if (_wishlistProducts.isNotEmpty)
            TextButton(
              onPressed: _showClearConfirmation,
              child: const Text('Clear All'),
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
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
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'Your wishlist is empty',
              style: AppTypography.h4.copyWith(
                fontWeight: AppTypography.bold,
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
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Continue Shopping'),
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
                  color: Colors.black.withValues(alpha: 0.1),
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
          bottom: 8,
          left: 8,
          right: 8,
          child: ElevatedButton.icon(
            onPressed: product.inStock ? () => _addToCart(product) : null,
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: Text(
              product.inStock ? 'Add to Cart' : 'Out of Stock',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // TODO: Implement clear all API call
    setState(() {
      _wishlistProducts.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wishlist cleared')),
    );
  }
}
