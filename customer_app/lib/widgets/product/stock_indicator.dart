import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

/// Stock indicator widget
class StockIndicator extends StatelessWidget {
  final int stock;
  final int lowStockThreshold;

  const StockIndicator({
    super.key,
    required this.stock,
    this.lowStockThreshold = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (stock == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              'Out of Stock',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (stock <= lowStockThreshold) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              'Only $stock left',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          size: 16,
          color: AppColors.success,
        ),
        const SizedBox(width: 4),
        Text(
          'In Stock',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
