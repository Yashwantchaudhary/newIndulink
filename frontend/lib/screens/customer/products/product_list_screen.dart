import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/loading_widgets.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/product_card_widget.dart';
import '../../../providers/product_provider.dart';

class ProductListScreen extends StatefulWidget {
  final String? initialCategory;
  final String? title;

  const ProductListScreen({
    super.key,
    this.initialCategory,
    this.title,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.clearFilters(); // Reset filters first
      if (widget.initialCategory != null) {
        provider.setCategory(widget.initialCategory);
      } else {
        provider.fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadMoreProducts();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ProductFilterSheet(),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ProductSortSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Products',
          style: AppTypography.h6.copyWith(fontWeight: AppTypography.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to search
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSortSheet,
                    icon: const Icon(Icons.sort, size: 18),
                    label: const Text('Sort'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterSheet,
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.products.isEmpty) {
                  return _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: AppDimensions.space16,
                            mainAxisSpacing: AppDimensions.space16,
                          ),
                          itemCount: 6,
                          itemBuilder: (_, __) => const ProductCardShimmer(),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          itemCount: 6,
                          itemBuilder: (_, __) => const ListItemShimmer(),
                        );
                }

                if (provider.errorMessage != null &&
                    provider.products.isEmpty) {
                  return ErrorStateWidget(
                    message: provider.errorMessage!,
                    onRetry: () => provider.fetchProducts(),
                  );
                }

                if (provider.products.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Products Found',
                    message: 'Try adjusting your filters or search query',
                    icon: Icons.search_off,
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: _isGridView
                      ? GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: AppDimensions.space16,
                            mainAxisSpacing: AppDimensions.space16,
                          ),
                          itemCount: provider.products.length +
                              (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.products.length) {
                              return const Center(
                                  child: LoadingSpinner(size: 24));
                            }
                            return ProductCard(
                              product: provider.products[index],
                              width: double.infinity,
                            );
                          },
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          itemCount: provider.products.length +
                              (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.products.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: LoadingSpinner(size: 24)),
                              );
                            }
                            // TODO: Create a List View version of ProductCard
                            // For now using the grid card with adjusted width
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ProductCard(
                                product: provider.products[index],
                                width: double.infinity,
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductSortSheet extends StatelessWidget {
  const ProductSortSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: AppTypography.h6.copyWith(fontWeight: AppTypography.bold),
          ),
          const SizedBox(height: 16),
          _buildSortOption(context, provider, 'Newest', 'newest'),
          _buildSortOption(
              context, provider, 'Price: Low to High', 'price_asc'),
          _buildSortOption(
              context, provider, 'Price: High to Low', 'price_desc'),
          _buildSortOption(context, provider, 'Top Rated', 'rating'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    ProductProvider provider,
    String label,
    String value,
  ) {
    final isSelected = provider.sortBy == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        provider.setSortBy(value);
        Navigator.pop(context);
      },
    );
  }
}

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({super.key});

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  RangeValues _priceRange = const RangeValues(0, 10000);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style:
                    AppTypography.h6.copyWith(fontWeight: AppTypography.bold),
              ),
              TextButton(
                onPressed: () {
                  context.read<ProductProvider>().clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const Divider(),

          // Price Range
          Text(
            'Price Range',
            style: AppTypography.bodyLarge
                .copyWith(fontWeight: AppTypography.bold),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              'Rs. ${_priceRange.start.round()}',
              'Rs. ${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rs. ${_priceRange.start.round()}'),
              Text('Rs. ${_priceRange.end.round()}'),
            ],
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<ProductProvider>().setPriceRange(
                      _priceRange.start,
                      _priceRange.end,
                    );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
