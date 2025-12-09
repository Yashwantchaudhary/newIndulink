import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_config.dart';

import '../../../services/api_service.dart';
import '../products/product_list_screen.dart';

/// 📂 Customer Categories Screen
/// Browse product categories with counts and navigation
class CustomerCategoriesScreen extends StatefulWidget {
  const CustomerCategoriesScreen({super.key});

  static Route route() {
    return MaterialPageRoute(builder: (_) => const CustomerCategoriesScreen());
  }

  @override
  State<CustomerCategoriesScreen> createState() =>
      _CustomerCategoriesScreenState();
}

class _CustomerCategoriesScreenState extends State<CustomerCategoriesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(AppConfig.categoriesEndpoint);

      if (response.isSuccess && response.data != null) {
        // Backend returns: { success: true, count: X, data: [categories] }
        final List<dynamic> categoriesJson = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data['categories'] ?? []);

        setState(() {
          _categories =
              categoriesJson.map((json) => Category.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load categories';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading categories: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'No categories available',
              style: AppTypography.h4.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new categories',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
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
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(_categories[index]);
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(
              initialCategory: category.name,
              title: category.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCategoryColor(category.name),
              _getCategoryColor(category.name).withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: _getCategoryColor(category.name).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    _getCategoryIcon(category.name),
                    size: 120,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    _getCategoryIcon(category.name),
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.name,
                    style: AppTypography.h5.copyWith(
                      color: Colors.white,
                      fontWeight: AppTypography.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.productCount ?? 0} products',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('cement')) return AppColors.categoryCement;
    if (lowerName.contains('steel')) return AppColors.categorySteel;
    if (lowerName.contains('brick')) return AppColors.categoryBricks;
    if (lowerName.contains('sand')) return AppColors.categorySand;
    if (lowerName.contains('paint')) return AppColors.categoryPaint;
    if (lowerName.contains('tool')) return AppColors.categoryTools;
    if (lowerName.contains('electric')) return AppColors.categoryElectrical;
    if (lowerName.contains('plumb')) return AppColors.categoryPlumbing;
    return AppColors.primary;
  }

  IconData _getCategoryIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('cement')) return Icons.construction;
    if (lowerName.contains('brick')) return Icons.square;
    if (lowerName.contains('steel')) return Icons.carpenter;
    if (lowerName.contains('paint')) return Icons.format_paint;
    if (lowerName.contains('tool')) return Icons.handyman;
    if (lowerName.contains('electric')) return Icons.electric_bolt;
    if (lowerName.contains('plumb')) return Icons.plumbing;
    if (lowerName.contains('sand')) return Icons.category;
    return Icons.category;
  }
}

/// 📁 Category Model
class Category {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int? productCount;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.productCount,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      imageUrl: json['imageUrl'] ?? json['image'],
      productCount: json['productCount'] ?? json['count'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'productCount': productCount,
      'isActive': isActive,
    };
  }
}
