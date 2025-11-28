import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/cart/cart_item_card.dart';
import '../../widgets/cart/cart_summary_card.dart';
import '../checkout/checkout_address_screen.dart';

/// Shopping Cart Screen
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (cartState.hasItems)
            IconButton(
              onPressed: () => _showClearCartDialog(context, ref),
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: cartState.isLoading && cartState.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cartState.isEmpty
              ? _buildEmptyCart(context)
              : _buildCartContent(context, ref, cartState),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return EmptyState.noItems(
      title: 'Your Cart is Empty',
      subtitle: 'Add items to your cart to get started',
      buttonText: 'Continue Shopping',
      onButtonPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildCartContent(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(cartProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppConstants.spacing8,
                bottom: AppConstants.spacing8,
              ),
              itemCount: cartState.cart.items.length,
              itemBuilder: (context, index) {
                final item = cartState.cart.items[index];
                return CartItemCard(item: item)
                    .animate()
                    .fadeIn(duration: AppConstants.durationNormal)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: AppConstants.durationNormal,
                      delay: Duration(milliseconds: index * 50),
                    );
              },
            ),
          ),
        ),

        // Cart Summary (Sticky Bottom)
        CartSummaryCard(
          cart: cartState.cart,
          onCheckout: () => _handleCheckout(context),
        ),
      ],
    );
  }

  Future<void> _showClearCartDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(cartProvider.notifier).clearCart();

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart cleared'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _handleCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutAddressScreen(),
      ),
    );
  }
}
