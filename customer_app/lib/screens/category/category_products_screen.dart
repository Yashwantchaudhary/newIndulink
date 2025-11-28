import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/skeleton_widgets.dart';
import '../product/product_detail_screen.dart';

/// Category products screen
class CategoryProductsScreen extends ConsumerStatefulWidget {
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch initial products for this category
    Future.microtask(() {
      ref
          .read(productProvider.notifier)
          .fetchProductsByCategory(widget.categoryName);
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from bottom
      ref.read(productProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: productState.isLoading && productState.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: ProductGridSkeleton(itemCount: 6),
            )
          : productState.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(productProvider.notifier)
                      .fetchProductsByCategory(widget.categoryName),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: AppConstants.paddingPage,
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppConstants.spacing12,
                            mainAxisSpacing: AppConstants.spacing12,
                            childAspectRatio: 0.7,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = productState.products[index];
                              return _buildProductCard(product, index);
                            },
                            childCount: productState.products.length,
                          ),
                        ),
                      ),
                      // Loading indicator for pagination
                      if (productState.isLoading &&
                          productState.products.isNotEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      // No more data indicator
                      if (!productState.hasMore &&
                          productState.products.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No more products to load',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProductCard(product, int index) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey.shade100,
                width: double.infinity,
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.images[0],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                      )
                    : Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: AppConstants.paddingAll12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Rs ${product.price.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.durationNormal).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: AppConstants.durationNormal,
          delay: Duration(milliseconds: index * 50),
        );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppConstants.paddingPage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: AppConstants.spacing24),
            Text(
              'No Products Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              'No products available in this category yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Browse Other Categories'),
            ),
          ],
        ),
      ),
    );
  }
}
