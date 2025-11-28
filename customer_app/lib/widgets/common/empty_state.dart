import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import 'premium_button.dart';

/// Enhanced empty state widget with illustration, title, subtitle, and action
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
  });

  /// No items in list
  factory EmptyState.noItems({
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return EmptyState(
      icon: Icons.inbox_rounded,
      title: title,
      subtitle: subtitle ?? 'There are no items to display',
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      iconColor: AppColors.neutral600,
    );
  }

  /// No search results
  factory EmptyState.noResults({
    String? query,
    VoidCallback? onClear,
  }) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No Results Found',
      subtitle: query != null
          ? 'No results for "$query". Try different keywords.'
          : 'Try adjusting your search or filters',
      buttonText: onClear != null ? 'Clear Search' : null,
      onButtonPressed: onClear,
      iconColor: AppColors.neutral600,
    );
  }

  /// No internet connection
  factory EmptyState.noInternet({
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'No Internet Connection',
      subtitle: 'Please check your connection and try again',
      buttonText: 'Retry',
      onButtonPressed: onRetry,
      iconColor: AppColors.warning,
    );
  }

  /// No data available
  factory EmptyState.noData({
    required String message,
    VoidCallback? onRefresh,
  }) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'No Data Available',
      subtitle: message,
      buttonText: onRefresh != null ? 'Refresh' : null,
      onButtonPressed: onRefresh,
      iconColor: AppColors.neutral600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppConstants.paddingAll24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with circle background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color:
                    (iconColor ?? AppColors.primaryBlue).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? AppColors.primaryBlue,
              ),
            ).animate().scale(
                  duration: AppConstants.durationSlow,
                  curve: AppConstants.curveBounce,
                ),

            const SizedBox(height: AppConstants.spacing32),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppConstants.spacing12),

            // Subtitle
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppConstants.spacing32),
              PremiumButton.primary(
                text: buttonText!,
                onPressed: onButtonPressed,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.durationNormal);
  }
}
