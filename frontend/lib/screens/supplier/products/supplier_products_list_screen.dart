import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/product.dart';
import '../../../services/product_service.dart';
import 'supplier_product_add_edit_screen.dart';

/// 📦 Supplier Products List Screen
/// Manage products with grid/list view, search, and filters
class SupplierProductsListScreen extends StatefulWidget {
  const SupplierProductsListScreen({super.key});

  static Route route() {
    return MaterialPageRoute(
        builder: (_) => const SupplierProductsListScreen());
  }

  @override
  State<SupplierProductsListScreen> createState() =>
      _SupplierProductsListScreenState();
}

class _SupplierProductsListScreenState
    extends State<SupplierProductsListScreen> {
  final ProductService _productService = ProductService();
  bool _isLoading = true;
  String? _error;
  List<Product> _products = [];
  bool _isGridView = true;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _productService.getSupplierProducts();

      if (mounted) {
        setState(() {
          if (result.success) {
            _products = result.products;
          } else {
            _error = result.message ?? 'Failed to load products';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading products: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _productService.deleteProduct(productId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
          _loadProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete product')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<Product> get _filteredProducts {
    return _products.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final lowercaseQuery = _searchQuery.toLowerCase();
        if (!product.title.toLowerCase().contains(lowercaseQuery) &&
            !product.description.toLowerCase().contains(lowercaseQuery)) {
          return false;
        }
      }

      // Status filter
      if (_filterStatus != 'all') {
        switch (_filterStatus) {
          case 'active':
            return product.status == ProductStatus.active;
          case 'inactive':
            return product.status == ProductStatus.inactive;
          case 'low_stock':
            return product.isLowStock;
          case 'out_of_stock':
            return product.isOutOfStock;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Active', 'active'),
                      _buildFilterChip('Inactive', 'inactive'),
                      _buildFilterChip('Low Stock', 'low_stock'),
                      _buildFilterChip('Out of Stock', 'out_of_stock'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Products List
          Expanded(
            child: _buildProductsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SupplierProductAddEditScreen(),
            ),
          );

          if (result == true) {
            _loadProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
          });
        },
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProductsList() {
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
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredProducts = _filteredProducts;

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterStatus != 'all'
                  ? 'No products found'
                  : 'No products yet',
              style: AppTypography.h5.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterStatus != 'all'
                  ? 'Try adjusting your filters'
                  : 'Tap + to add your first product',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55, // Calc: Width 160 / Height 290 = 0.55
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          return _buildProductGridItem(filteredProducts[index]);
        },
      );
    } else {
      return ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
        itemCount: filteredProducts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildProductListItem(filteredProducts[index]);
        },
      );
    }
  }

  Widget _buildProductGridItem(Product product) {
    return GestureDetector(
      onTap: () => _editProduct(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusM),
                    ),
                    image: product.primaryImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(product.primaryImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.primaryImageUrl.isEmpty
                      ? const Center(
                          child: Icon(Icons.image,
                              size: 48, color: AppColors.textTertiary),
                        )
                      : null,
                ),
                // Stock Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.getStockColor(product.stock)
                          .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.stockStatusText,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10,
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
                      style: AppTypography.labelLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '₹${product.price.toStringAsFixed(2)}',
                      style: AppTypography.h6.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => _editProduct(product),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Edit',
                              style: TextStyle(fontSize: 12)),
                        ),
                        IconButton(
                          onPressed: () => _deleteProduct(product.id),
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: AppColors.error,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
    );
  }

  Widget _buildProductListItem(Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              image: product.primaryImageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.primaryImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.primaryImageUrl.isEmpty
                ? const Center(
                    child: Icon(Icons.image, color: AppColors.textTertiary),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: AppTypography.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  style: AppTypography.h6.copyWith(
                    color: AppColors.primary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.getStockColor(product.stock)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.stockStatusText,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.getStockColor(product.stock),
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              IconButton(
                onPressed: () => _editProduct(product),
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.primary,
              ),
              IconButton(
                onPressed: () => _deleteProduct(product.id),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierProductAddEditScreen(product: product),
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }
}
