import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../providers/cart_provider.dart';
import '../../routes.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/enhanced_states.dart';

/// Production-level Enhanced Shopping Cart Screen
class EnhancedCartScreen extends ConsumerWidget {
  const EnhancedCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Shopping Cart'),
            if (cartState.items.isNotEmpty) ...[
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cartState.items.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                _showClearCartDialog(context, ref);
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: cartState.isLoading && cartState.items.isEmpty
          ? const ShimmerLoadingList(itemCount: 3, itemHeight: 120)
          : cartState.items.isEmpty
              ? EnhancedEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your Cart is Empty',
                  message: 'Add products to your cart to see them here',
                  actionText: 'Browse Products',
                  onAction: () =>
                      AppRoutes.navigateToAndReplace(context, AppRoutes.home),
                  iconColor: AppColors.primaryBlue,
                )
              : Column(
                  children: [
                    // Cart Items List with Staggered Animation
                    Expanded(
                      child: ListView.builder(
                        padding: AppConstants.paddingAll16,
                        itemCount: cartState.items.length,
                        itemBuilder: (context, index) {
                          final item = cartState.items[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 300 + (index * 100)),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(30 * (1 - value), 0),
                                  child: child,
                                ),
                              );
                            },
                            child: Dismissible(
                              key: Key(item.id!),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.only(right: 20),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: AppConstants.borderRadiusMedium,
                                ),
                                alignment: Alignment.centerRight,
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Remove Item'),
                                      content: const Text(
                                        'Remove this item from cart?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Remove',
                                            style: TextStyle(
                                                color: AppColors.error),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) {
                                ref
                                    .read(cartProvider.notifier)
                                    .removeFromCart(item.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Removed from cart'),
                                    backgroundColor: AppColors.success,
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        // Undo logic would go here
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: _buildCartItem(context, ref, item, isDark),
                            ),
                          );
                        },
                      ),
                    ),

                    // Cart Summary
                    _buildCartSummary(context, ref, cartState, isDark),
                  ],
                ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstants.paddingAll12,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
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
              child:
                  item.product?.image != null && item.product!.image!.isNotEmpty
                      ? Image.network(
                          item.product!.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_outlined);
                          },
                        )
                      : const Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(width: 12),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.title ?? 'Product',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${item.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (item.quantity > 1) {
                            ref.read(cartProvider.notifier).updateQuantity(
                                  itemId: item.id!,
                                  quantity: item.quantity - 1,
                                );
                          }
                        },
                        icon: const Icon(Icons.remove, size: 18),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).updateQuantity(
                                itemId: item.id!,
                                quantity: item.quantity + 1,
                              );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Remove Button
          IconButton(
            onPressed: () {
              ref.read(cartProvider.notifier).removeFromCart(item.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Removed from cart')),
              );
            },
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(
    BuildContext context,
    WidgetRef ref,
    dynamic cartState,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final subtotal = cartState.subtotal;
    final tax = subtotal * 0.13; // 13% tax
    final shipping = subtotal > 5000 ? 0.0 : 150.0;
    final total = subtotal + tax + shipping;

    return Container(
      padding: AppConstants.paddingAll20,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Promo Code Section
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    contentPadding: AppConstants.paddingAll12,
                    border: OutlineInputBorder(
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedButton(
                text: 'Apply',
                onPressed: () {},
                isOutlined: true,
                backgroundColor: AppColors.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Summary Rows
          _buildSummaryRow('Subtotal', subtotal, theme),
          const SizedBox(height: 8),
          _buildSummaryRow('Tax (13%)', tax, theme),
          const SizedBox(height: 8),
          _buildSummaryRow('Shipping', shipping, theme, isFree: shipping == 0),
          const Divider(height: 24),
          _buildSummaryRow('Total', total, theme, isTotal: true),
          const SizedBox(height: 16),
          // Checkout Button
          AnimatedButton(
            text: 'Proceed to Checkout',
            icon: Icons.arrow_forward,
            onPressed: () {
              if (cartState.items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your cart is empty')),
                );
                return;
              }
              AppRoutes.navigateTo(context, AppRoutes.checkoutAddress);
            },
            gradient: AppColors.primaryGradient,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    ThemeData theme, {
    bool isTotal = false,
    bool isFree = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.bodyMedium,
        ),
        Text(
          isFree ? 'FREE' : 'Rs ${amount.toStringAsFixed(2)}',
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                )
              : theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isFree ? AppColors.success : null,
                ),
        ),
      ],
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart cleared')),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
