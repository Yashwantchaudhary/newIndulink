import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import 'premium_widgets.dart';

/// Enhanced Empty State Widget with Animation
class EnhancedEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EnhancedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.iconColor,
  });

  @override
  State<EnhancedEmptyState> createState() => _EnhancedEmptyStateState();
}

class _EnhancedEmptyStateState extends State<EnhancedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: AppConstants.paddingAll24,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (widget.iconColor ?? AppColors.primaryBlue)
                                  .withValues(alpha: 0.1),
                              (widget.iconColor ?? AppColors.secondaryPurple)
                                  .withValues(alpha: 0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 80,
                          color: widget.iconColor ?? AppColors.primaryBlue,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  widget.message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.actionText != null && widget.onAction != null) ...[
                  const SizedBox(height: 32),
                  AnimatedButton(
                    text: widget.actionText!,
                    onPressed: widget.onAction!,
                    gradient: AppColors.primaryGradient,
                    icon: Icons.arrow_forward,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced Error State Widget with Retry
class EnhancedErrorState extends StatefulWidget {
  final String title;
  final String message;
  final String? technicalDetails;
  final VoidCallback onRetry;
  final bool isLoading;

  const EnhancedErrorState({
    super.key,
    this.title = 'Oops! Something went wrong',
    required this.message,
    this.technicalDetails,
    required this.onRetry,
    this.isLoading = false,
  });

  @override
  State<EnhancedErrorState> createState() => _EnhancedErrorStateState();
}

class _EnhancedErrorStateState extends State<EnhancedErrorState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            // Error Icon with Shake Animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withValues(alpha: 0.1),
                      AppColors.error.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 80,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              widget.message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            // Technical Details (Expandable)
            if (widget.technicalDetails != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() => _showDetails = !_showDetails);
                },
                icon: Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(_showDetails ? 'Hide Details' : 'Show Details'),
              ),
              if (_showDetails)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: AppConstants.paddingAll12,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    borderRadius: AppConstants.borderRadiusSmall,
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    widget.technicalDetails!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 32),
            // Retry Button
            AnimatedButton(
              text: 'Retry',
              onPressed: widget.isLoading ? () {} : widget.onRetry,
              icon: widget.isLoading ? null : Icons.refresh,
              gradient: AppColors.primaryGradient,
              isLoading: widget.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
