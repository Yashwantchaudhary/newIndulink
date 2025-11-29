import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../models/product.dart';
import 'modern_add_edit_product_screen.dart';

/// Production-level Supplier Products Management Screen
class SupplierProductsScreen extends ConsumerStatefulWidget {
  const SupplierProductsScreen({super.key});

  @override
  ConsumerState<SupplierProductsScreen> createState() =>
      _SupplierProductsScreenState();
}

class _SupplierProductsScreenState
    extends ConsumerState<SupplierProductsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Row
          _buildStatsRow(),

          // Filter Chips
          _buildFilterChips(),

          // Products List
          Expanded(
            child: _buildProductsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernAddEditProductScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: AppConstants.paddingAll16,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              '48',
              Icons.inventory_2,
              AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              'In Stock',
              '42',
              Icons.check_circle,
              AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              'Low Stock',
              '4',
              Icons.warning,
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              'Out',
              '2',
              Icons.cancel,
              AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: AppConstants.paddingAll12,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Active', 'Inactive', 'Low Stock', 'Out of Stock'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              selectedColor: AppColors.primaryBlue,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList() {
    return Consumer(
      builder: (context, ref, child) {
        final supplierProductsState = ref.watch(supplierProductProvider);
        final supplierProductsNotifier = ref.read(supplierProductProvider.notifier);

        // Initialize products on first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (supplierProductsState.products.isEmpty && !supplierProductsState.isLoading) {
            supplierProductsNotifier.fetchMyProducts();
          }
        });

        if (supplierProductsState.isLoading && supplierProductsState.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (supplierProductsState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${supplierProductsState.error}'),
                ElevatedButton(
                  onPressed: () => supplierProductsNotifier.fetchMyProducts(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (supplierProductsState.products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        return RefreshIndicator(
          onRefresh: () async => supplierProductsNotifier.refreshProducts(),
          child: ListView.builder(
            padding: AppConstants.paddingAll16,
            itemCount: supplierProductsState.products.length +
                (supplierProductsState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == supplierProductsState.products.length) {
                // Load more indicator
                supplierProductsNotifier.loadMore();
                return const Center(child: CircularProgressIndicator());
              }
              return _buildProductCard(supplierProductsState.products[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(_MockProduct product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLowStock = product.stock > 0 && product.stock <= 10;
    final isOutOfStock = product.stock == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to product detail/edit
        },
        borderRadius: AppConstants.borderRadiusMedium,
        child: Padding(
          padding: AppConstants.paddingAll12,
          child: Row(
            children: [
              // Product Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  borderRadius: AppConstants.borderRadiusSmall,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 32,
                  color: AppColors.lightTextTertiary,
                ),
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Rs ${product.price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? AppColors.error.withValues(alpha: 0.1)
                                : isLowStock
                                    ? AppColors.warning.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOutOfStock
                                ? 'Out of Stock'
                                : 'Stock: ${product.stock}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isOutOfStock
                                  ? AppColors.error
                                  : isLowStock
                                      ? AppColors.warning
                                      : AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  Switch(
                    value: product.isActive,
                    onChanged: (value) {
                      // Toggle active status
                    },
                    activeThumbColor: AppColors.success,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModernAddEditProductScreen(
                                productId: product
                                    .name, // Replace with actual product ID
                              ),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: AppColors.error,
                        onPressed: () {
                          _showDeleteConfirmation(context, product);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppConstants.paddingAll20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Products',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Sort by Price (Low to High)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Sort by Price (High to Low)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Sort by Stock'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Sort by Name'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, _MockProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product deleted')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockProduct {
  final String name;
  final String category;
  final double price;
  final int stock;
  final bool isActive;
  final String? image;

  _MockProduct({
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.isActive,
  });
}
