import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Modern input field with floating labels, icons, and smooth validation animations
class ModernTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;

  const ModernTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.inputFormatters,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasError = widget.errorText != null;

    final borderColor = _getBorderColor(isDark, hasError);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text field with animated border
        AnimatedContainer(
          duration: AppConstants.durationNormal,
          curve: AppConstants.curveStandard,
          decoration: BoxDecoration(
            color: widget.enabled
                ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                : (isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant),
            borderRadius: AppConstants.borderRadiusMedium,
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _internalFocusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            autofocus: widget.autofocus,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: _getLabelColor(theme, isDark, hasError),
                fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w400,
              ),
              hintText: widget.hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing16,
              ),
              isDense: true,
              counterText: '', // Hide counter
            ),
          ),
        ),

        // Helper or error text
        if (widget.helperText != null || hasError)
          Padding(
            padding: const EdgeInsets.only(
              top: AppConstants.spacing8,
              left: AppConstants.spacing16,
            ),
            child: AnimatedSwitcher(
              duration: AppConstants.durationNormal,
              child: Text(
                hasError ? widget.errorText! : widget.helperText!,
                key: ValueKey(hasError),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasError
                      ? AppColors.error
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getBorderColor(bool isDark, bool hasError) {
    if (!widget.enabled) {
      return isDark ? AppColors.darkBorder : AppColors.lightBorder;
    }
    if (hasError) {
      return AppColors.error;
    }
    if (_isFocused) {
      return AppColors.primaryBlue;
    }
    return isDark ? AppColors.darkBorder : AppColors.lightBorder;
  }

  Color _getLabelColor(ThemeData theme, bool isDark, bool hasError) {
    if (!widget.enabled) {
      return isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    }
    if (hasError) {
      return AppColors.error;
    }
    if (_isFocused) {
      return AppColors.primaryBlue;
    }
    return isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  }
}
