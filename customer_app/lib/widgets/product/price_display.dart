import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Price display widget with optional discount badge
class PriceDisplay extends StatelessWidget {
  final double price;
  final double? compareAtPrice;
  final TextStyle? priceStyle;
  final TextStyle? compareStyle;
  final bool showCurrency;
  final String currencySymbol;

  const PriceDisplay({
    super.key,
    required this.price,
    this.compareAtPrice,
    this.priceStyle,
    this.compareStyle,
    this.showCurrency = true,
    this.currencySymbol = 'Rs ',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = compareAtPrice != null && compareAtPrice! > price;
    final discountPercent = hasDiscount
        ? (((compareAtPrice! - price) / compareAtPrice!) * 100).round()
        : 0;

    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Current price
        Text(
          currencyFormat.format(price),
          style: priceStyle ??
              theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
        ),

        if (hasDiscount) ...[
          const SizedBox(width: AppConstants.spacing8),

          // Compare at price (strikethrough)
          Text(
            currencyFormat.format(compareAtPrice),
            style: compareStyle ??
                theme.textTheme.titleMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                  decoration: TextDecoration.lineThrough,
                ),
          ),

          const SizedBox(width: AppConstants.spacing8),

          // Discount badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Text(
              '$discountPercent% OFF',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
