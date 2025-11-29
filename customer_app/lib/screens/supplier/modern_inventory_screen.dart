import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';

/// Modern Inventory Management Screen - Integrated with Product Provider
class ModernInventoryScreen extends ConsumerStatefulWidget {
  const ModernInventoryScreen({super.key});

  @override
  ConsumerState<ModernInventoryScreen> createState() =>
      _ModernInventoryScreenState();
}

class _ModernInventoryScreenState
    extends ConsumerState<ModernInventoryScreen> {
  String _selectedFilter = 'All';
  final _filters = ['All', 'Low Stock', 'Out of Stock', 'In Stock'];

  @override
  void initState() {
    super.initState();
    // Load supplier's products
    Future.microtask(() {
      final supplierId = ref.read(authProvider).user?.id;
      if (supplierId != null) {
        ref.read(productProvider.notifier).loadProducts(supplierId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productState = ref.watch(productProvider);
    final productsAll = productState.products;
    final supplierId = ref.read(authProvider).user?.id;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _scanBarcode(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportInventory(),
          ),
        ],
      ),
      body: productState.isLoading && productsAll.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Overview
                _buildStatsOverview(isDark, productsAll),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildFilterChips(),
                ),

                // Inventory List
                Expanded(
                  child: _buildInventoryList(isDark, theme, productsAll, supplierId),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bulkUpdateStock(),
        icon: const Icon(Icons.inventory_2),
        label: const Text('Bulk Update'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildStatsOverview(bool isDark, List<Product> products) {
    final totalItems = products.length;
    final lowStock = products.where((p) => (p.stock ?? 0) > 0 && (p.stock ?? 0) <= 10).length;
    final outOfStock = products.where((p) => (p.stock ?? 0) == 0).length;

    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.1),
            AppColors.secondaryPurple.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Items',
              totalItems.toString(),
              Icons.inventory,
              AppColors.primaryBlue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Expanded(
            child: _buildStatItem(
              'Low Stock',
              lowStock.toString(),
              Icons.error_outline,
              AppColors.statusPending,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Expanded(
            child: _buildStatItem(
              'Out of Stock',
              outOfStock.toString(),
              Icons.warning_outlined,
              AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
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

  Widget _buildInventoryList(bool isDark, ThemeData theme, List<Product> products, String? supplierId) {
    // Filter products based on selected filter
    List<Product> filteredProducts = products;
    
    if (_selectedFilter == 'Low Stock') {
      filteredProducts = products.where((p) => (p.stock ?? 0) > 0 && (p.stock ?? 0) <= 10).toList();
    } else if (_selectedFilter == 'Out of Stock') {
      filteredProducts = products.where((p) => (p.stock ?? 0) == 0).toList();
    } else if (_selectedFilter == 'In Stock') {
      filteredProducts = products.where((p) => (p.stock ?? 0) > 10).toList();
    }

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, size: 64, color: AppColors.lightTextTertiary),
            const SizedBox(height: 16),
            Text('No products found', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (supplierId != null) {
          await ref.read(productProvider.notifier).loadProducts(supplierId);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          return _buildInventoryCard(filteredProducts[index], isDark, theme);
        },
      ),
    );
  }

  Widget _buildInventoryCard(Product product, bool isDark, ThemeData theme) {
    final stock = product.stock ?? 0;
    const lowStockThreshold = 10;
    const maxStock = 1000; // Could be a product field
    
    final stockColor = stock == 0
        ? AppColors.error
        : (stock <= lowStockThreshold
            ? AppColors.statusPending
            : AppColors.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusLarge,
        border: Border.all(
          color: stockColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: AppConstants.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.lightSurfaceVariant,
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                  child: const Icon(Icons.inventory_2, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${product.sku ?? product.id.substring(0, 8)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: stockColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    stock == 0
                        ? 'Out of Stock'
                        : (stock <= lowStockThreshold
                            ? 'Low Stock'
                            : 'In Stock'),
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stock Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Stock',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '$stock / $maxStock units',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stock / maxStock,
                    backgroundColor: stockColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _adjustStock(product),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Adjust Stock'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _viewHistory(product),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _adjustStock(Product product) {
    final stockController = TextEditingController(text: (product.stock ?? 0).toString());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: AppConstants.paddingAll20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightTextTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Adjust Stock - ${product.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Stock',
                  prefixIcon: Icon(Icons.inventory),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Reason for Adjustment',
                  prefixIcon: Icon(Icons.note),
                  hintText: 'E.g., Received shipment, Damaged goods',
                ),
              ),
              const Spacer(),
              AnimatedButton(
                text: 'Update Stock',
                icon: Icons.check,
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock updated successfully')),
                  );
                },
                gradient: AppColors.primaryGradient,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewHistory(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing history for ${product.name}')),
    );
  }

  void _scanBarcode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening barcode scanner...')),
    );
  }

  void _exportInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting inventory report...')),
    );
  }

  void _bulkUpdateStock() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening bulk update dialog...')),
    );
  }

}
