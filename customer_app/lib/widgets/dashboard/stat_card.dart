import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Reusable statistic card widget for dashboard metrics
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final double? trend; // Positive for increase, negative for decrease
  final VoidCallback? onTap;
  final bool isLoading;
  final Gradient? gradient;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
    this.trend,
    this.onTap,
    this.isLoading = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: AppConstants.elevationMedium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppConstants.borderRadiusMedium,
        child: Container(
          padding: AppConstants.paddingAll16,
          decoration: BoxDecoration(
            borderRadius: AppConstants.borderRadiusMedium,
            gradient: gradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and trend row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon container
                  Container(
                    padding: AppConstants.paddingAll12,
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppColors.primaryBlue).withValues(
                        alpha: gradient != null ? 0.2 : 0.1,
                      ),
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                    child: Icon(
                      icon,
                      size: AppConstants.iconSizeLarge,
                      color: gradient != null
                          ? Colors.white
                          : (iconColor ?? AppColors.primaryBlue),
                    ),
                  ),

                  // Trend indicator
                  if (trend != null && !isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing8,
                        vertical: AppConstants.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (trend! >= 0 ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.1),
                        borderRadius: AppConstants.borderRadiusSmall,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trend! >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 16,
                            color: trend! >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trend!.abs().toStringAsFixed(1)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: trend! >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppConstants.spacing12),

              // Title
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: gradient != null
                      ? Colors.white.withValues(alpha: 0.9)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppConstants.spacing4),

              // Value
              if (isLoading)
                Container(
                  height: 28,
                  width: 100,
                  decoration: BoxDecoration(
                    color: (gradient != null
                            ? Colors.white
                            : AppColors.lightBorder)
                        .withValues(alpha: 0.3),
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                )
              else
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: gradient != null
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              // Subtitle
              if (subtitle != null) ...[
                const SizedBox(height: AppConstants.spacing4),
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: gradient != null
                        ? Colors.white.withValues(alpha: 0.8)
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.durationNormal).slideY(
          begin: 0.2,
          end: 0,
          duration: AppConstants.durationNormal,
          curve: Curves.easeOutCubic,
        );
  }
}
