import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_constants.dart';
import '../../providers/category_provider.dart';
import '../../widgets/category/category_card.dart';
import 'category_products_screen.dart';

/// Categories screen
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch categories on init
    Future.microtask(
        () => ref.read(categoryProvider.notifier).fetchCategories());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: categoryState.isLoading && categoryState.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : categoryState.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(categoryProvider.notifier).refresh(),
                  child: GridView.builder(
                    padding: AppConstants.paddingPage,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppConstants.spacing16,
                      mainAxisSpacing: AppConstants.spacing16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: categoryState.categories.length,
                    itemBuilder: (context, index) {
                      final category = categoryState.categories[index];
                      return CategoryCard(
                        category: category,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsScreen(
                                categoryName: category.name,
                              ),
                            ),
                          );
                        },
                      )
                          .animate()
                          .fadeIn(duration: AppConstants.durationNormal)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: AppConstants.durationNormal,
                            delay: Duration(milliseconds: index * 50),
                          );
                    },
                  ),
                ),
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
              Icons.category_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: AppConstants.spacing24),
            Text(
              'No Categories Available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              'Categories will appear here once added',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
