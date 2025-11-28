import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Quantity selector widget with increment/decrement buttons
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;
  final double? size;

  const QuantitySelector({
    super.key,
    required this.quantity,
    this.maxQuantity = 999,
    required this.onChanged,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonSize = size ?? 36.0;
    final fontSize = (size ?? 36.0) * 0.4;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
        borderRadius: AppConstants.borderRadiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          _buildButton(
            icon: Icons.remove,
            onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
            size: buttonSize,
          ),

          // Quantity display
          Container(
            constraints: BoxConstraints(minWidth: buttonSize * 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              quantity.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Increment button
          _buildButton(
            icon: Icons.add,
            onTap:
                quantity < maxQuantity ? () => onChanged(quantity + 1) : null,
            size: buttonSize,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onTap,
    required double size,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size * 0.5,
          color: onTap != null ? AppColors.primaryBlue : Colors.grey,
        ),
      ),
    );
  }
}
