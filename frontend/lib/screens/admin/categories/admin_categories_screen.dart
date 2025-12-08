import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_config.dart';
import '../../../services/api_service.dart';
import '../widgets/admin_layout.dart';

/// 📂 Admin Categories Screen
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(AppConfig.categoriesEndpoint);
      if (response.isSuccess && response.data != null) {
        setState(() {
          final dataMap = response.data as Map<String, dynamic>;
          final actualData = dataMap.containsKey('data')
              ? Map<String, dynamic>.from(dataMap['data'] as Map)
              : dataMap;
          _categories =
              List<Map<String, dynamic>>.from(actualData['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Categories',
      currentIndex: 3,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.category,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category['name'] ?? 'Category',
                                  style: AppTypography.labelLarge),
                              Text(
                                '${category['productCount'] ?? 0} products',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.edit),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
