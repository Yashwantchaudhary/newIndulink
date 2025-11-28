import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Advanced chip component with selection states and animations
class AdvancedChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? icon;
  final Color? selectedColor;
  final Color? unselectedColor;
  final LinearGradient? selectedGradient;

  const AdvancedChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
    this.selectedGradient,
  });

  /// Filter chip variant
  factory AdvancedChip.filter({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? icon,
  }) {
    return AdvancedChip(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      icon: icon,
    );
  }

  /// Choice chip variant
  factory AdvancedChip.choice({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AdvancedChip(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  /// Gradient chip variant
  factory AdvancedChip.gradient({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required LinearGradient gradient,
  }) {
    return AdvancedChip(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      selectedGradient: gradient,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: AppConstants.durationNormal,
      curve: AppConstants.curveStandard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppConstants.borderRadiusSmall,
          child: AnimatedContainer(
            duration: AppConstants.durationFast,
            curve: AppConstants.curveStandard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing16,
              vertical: AppConstants.spacing8,
            ),
            decoration: _buildDecoration(isDark),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      color: _getContentColor(isDark),
                      size: AppConstants.iconSizeSmall,
                    ),
                    child: icon!,
                  ),
                  const SizedBox(width: AppConstants.spacing8),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _getContentColor(isDark),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: AppConstants.spacing8),
                  Icon(
                    Icons.check_circle,
                    size: AppConstants.iconSizeSmall,
                    color: _getContentColor(isDark),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDark) {
    if (isSelected) {
      if (selectedGradient != null) {
        return BoxDecoration(
          gradient: selectedGradient,
          borderRadius: AppConstants.borderRadiusSmall,
          boxShadow: [
            BoxShadow(
              color: (selectedGradient!.colors.first).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
      }
      return BoxDecoration(
        color: selectedColor ?? AppColors.primaryBlue,
        borderRadius: AppConstants.borderRadiusSmall,
        boxShadow: [
          BoxShadow(
            color:
                (selectedColor ?? AppColors.primaryBlue).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: unselectedColor ??
          (isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant),
      borderRadius: AppConstants.borderRadiusSmall,
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        width: 1,
      ),
    );
  }

  Color _getContentColor(bool isDark) {
    if (isSelected) {
      return selectedGradient != null || selectedColor != null
          ? Colors.white
          : Colors.white;
    }
    return isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  }
}

/// Chip group for managing multiple chips
class ChipGroup extends StatelessWidget {
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onSelected;
  final bool allowMultiSelect;
  final List<String>? selectedItems;
  final ValueChanged<List<String>>? onMultiSelect;
  final Axis direction;
  final double spacing;

  const ChipGroup({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onSelected,
    this.allowMultiSelect = false,
    this.selectedItems,
    this.onMultiSelect,
    this.direction = Axis.horizontal,
    this.spacing = AppConstants.spacing8,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: items.map((item) {
          final isSelected = allowMultiSelect
              ? (selectedItems?.contains(item) ?? false)
              : item == selectedItem;

          return AdvancedChip(
            label: item,
            isSelected: isSelected,
            onTap: () {
              if (allowMultiSelect && onMultiSelect != null) {
                final newSelection = List<String>.from(selectedItems ?? []);
                if (isSelected) {
                  newSelection.remove(item);
                } else {
                  newSelection.add(item);
                }
                onMultiSelect!(newSelection);
              } else {
                onSelected(item);
              }
            },
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final isSelected = allowMultiSelect
            ? (selectedItems?.contains(item) ?? false)
            : item == selectedItem;

        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: AdvancedChip(
            label: item,
            isSelected: isSelected,
            onTap: () {
              if (allowMultiSelect && onMultiSelect != null) {
                final newSelection = List<String>.from(selectedItems ?? []);
                if (isSelected) {
                  newSelection.remove(item);
                } else {
                  newSelection.add(item);
                }
                onMultiSelect!(newSelection);
              } else {
                onSelected(item);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
