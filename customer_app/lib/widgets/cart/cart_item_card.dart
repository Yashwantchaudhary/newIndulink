import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/cart.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product/quantity_selector.dart';
import 'package:intl/intl.dart';

/// Cart item card widget
class CartItemCard extends ConsumerWidget {
  final CartItem item;
  final VoidCallback? onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing8,
      ),
      child: Padding(
        padding: AppConstants.paddingAll12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: AppConstants.borderRadiusSmall,
              child: Container(
                width: 80,
                height: 80,
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                child: item.product.image != null
                    ? CachedNetworkImage(
                        imageUrl: item.product.image!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image,
                          size: 32,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        size: 32,
                        color: Colors.grey,
                      ),
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.product.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Text(
                    currencyFormat.format(item.price),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quantity & Remove
                  Row(
                    children: [
                      // Quantity Selector
                      QuantitySelector(
                        quantity: item.quantity,
                        maxQuantity: item.product.stock,
                        onChanged: (newQty) => _updateQuantity(ref, newQty),
                        size: 32,
                      ),
                      const Spacer(),

                      // Subtotal
                      Text(
                        currencyFormat.format(item.subtotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              onPressed: () => _showRemoveDialog(context, ref),
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateQuantity(WidgetRef ref, int newQty) async {
    if (item.id == null) return;

    final success = await ref.read(cartProvider.notifier).updateQuantity(
          itemId: item.id!,
          quantity: newQty,
        );

    if (!success) {
      // Show error - quantity update failed
    }
  }

  Future<void> _showRemoveDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.product.title}" from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (item.id != null) {
        final success =
            await ref.read(cartProvider.notifier).removeFromCart(item.id!);

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.product.title} removed from cart'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      onRemove?.call();
    }
  }
}
