import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Premium gradient button with smooth animations and haptic feedback
/// Supports multiple variants: filled, outlined, text
class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final PremiumButtonVariant variant;
  final LinearGradient? gradient;
  final Color? color;
  final Color? textColor;
  final double? height;
  final EdgeInsets? padding;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.variant = PremiumButtonVariant.filled,
    this.gradient,
    this.color,
    this.textColor,
    this.height,
    this.padding,
  });

  /// Primary gradient button
  factory PremiumButton.primary({
    required String text,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return PremiumButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      gradient: AppColors.primaryGradient,
    );
  }

  /// Secondary outlined button
  factory PremiumButton.secondary({
    required String text,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return PremiumButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      variant: PremiumButtonVariant.outlined,
      color: AppColors.primaryBlue,
    );
  }

  /// Text-only button
  factory PremiumButton.text({
    required String text,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
  }) {
    return PremiumButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      variant: PremiumButtonVariant.text,
      color: AppColors.primaryBlue,
    );
  }

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppConstants.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: AppConstants.curveStandard,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: AppConstants.durationNormal,
          curve: AppConstants.curveStandard,
          height: widget.height ?? AppConstants.buttonHeightMedium,
          width: widget.isFullWidth ? double.infinity : null,
          padding: widget.padding ??
              (widget.variant == PremiumButtonVariant.text
                  ? AppConstants.paddingH16
                  : AppConstants.paddingH24),
          decoration: _buildDecoration(isDark),
          child: _buildContent(theme),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDark) {
    switch (widget.variant) {
      case PremiumButtonVariant.filled:
        return BoxDecoration(
          gradient: widget.gradient ??
              LinearGradient(
                colors: [
                  widget.color ?? AppColors.primaryBlue,
                  widget.color ?? AppColors.primaryBlue,
                ],
              ),
          borderRadius: AppConstants.borderRadiusMedium,
          boxShadow: widget.onPressed == null || widget.isLoading
              ? null
              : [
                  BoxShadow(
                    color: (widget.gradient?.colors.first ??
                            widget.color ??
                            AppColors.primaryBlue)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        );

      case PremiumButtonVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppConstants.borderRadiusMedium,
          border: Border.all(
            color: widget.onPressed == null || widget.isLoading
                ? (isDark ? AppColors.neutral600 : AppColors.neutral400)
                : (widget.color ?? AppColors.primaryBlue),
            width: 1.5,
          ),
        );

      case PremiumButtonVariant.text:
        return BoxDecoration(
          color: _isPressed
              ? (isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant)
              : Colors.transparent,
          borderRadius: AppConstants.borderRadiusSmall,
        );
    }
  }

  Widget _buildContent(ThemeData theme) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final contentColor = _getContentColor(theme.brightness == Brightness.dark);

    return Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null && !widget.isLoading) ...[
          IconTheme(
            data: IconThemeData(
              color: contentColor,
              size: AppConstants.iconSizeSmall,
            ),
            child: widget.icon!,
          ),
          const SizedBox(width: AppConstants.spacing8),
        ],
        if (widget.isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(contentColor),
            ),
          )
        else
          Text(
            widget.text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: contentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Color _getContentColor(bool isDark) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    if (isDisabled) {
      return isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    }

    switch (widget.variant) {
      case PremiumButtonVariant.filled:
        return widget.textColor ?? AppColors.neutral100;
      case PremiumButtonVariant.outlined:
      case PremiumButtonVariant.text:
        return widget.textColor ?? widget.color ?? AppColors.primaryBlue;
    }
  }
}

enum PremiumButtonVariant {
  filled,
  outlined,
  text,
}
