import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/category.dart';

/// Category card widget
class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Image
            Expanded(
              flex: 3,
              child: Container(
                color: AppColors.lightSurfaceVariant,
                child: category.image != null
                    ? CachedNetworkImage(
                        imageUrl: category.image!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.category,
                          size: 48,
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        ),
                      )
                    : Icon(
                        Icons.category,
                        size: 48,
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      ),
              ),
            ),

            // Category Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: AppConstants.paddingAll12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${category.productCount} ${category.productCount == 1 ? "product" : "products"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
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
}
