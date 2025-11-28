import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../order/order_success_screen.dart';

/// Checkout payment screen
class CheckoutPaymentScreen extends ConsumerStatefulWidget {
  final ShippingAddress shippingAddress;

  const CheckoutPaymentScreen({
    super.key,
    required this.shippingAddress,
  });

  @override
  ConsumerState<CheckoutPaymentScreen> createState() =>
      _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends ConsumerState<CheckoutPaymentScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cashOnDelivery;
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartState = ref.watch(cartProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: AppConstants.paddingPage,
              children: [
                // Order Summary
                Text(
                  'Order Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing16),

                Card(
                  child: Padding(
                    padding: AppConstants.paddingAll16,
                    child: Column(
                      children: [
                        _buildRow(
                          'Items (${cartState.cart.itemCount})',
                          currencyFormat.format(cartState.cart.subtotal),
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Tax (13%)',
                          currencyFormat.format(cartState.cart.tax),
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Shipping',
                          cartState.cart.subtotal >= 1000 ? 'FREE' : 'Rs 100',
                          theme,
                        ),
                        const Divider(height: 24),
                        _buildRow(
                          'Total',
                          currencyFormat.format(cartState.cart.total),
                          theme,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacing24),

                // Payment Methods
                Text(
                  'Select Payment Method',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing16),

                // Cash on Delivery
                _buildPaymentOption(
                  PaymentMethod.cashOnDelivery,
                  Icons.money,
                  'Cash on Delivery',
                  'Pay when you receive the product',
                  true,
                ),

                const SizedBox(height: AppConstants.spacing12),

                // Online Payment (Coming Soon)
                _buildPaymentOption(
                  PaymentMethod.online,
                  Icons.credit_card,
                  'Online Payment',
                  'Coming soon',
                  false,
                ),

                const SizedBox(height: AppConstants.spacing12),

                // Wallet (Coming Soon)
                _buildPaymentOption(
                  PaymentMethod.wallet,
                  Icons.account_balance_wallet,
                  'Wallet',
                  'Coming soon',
                  false,
                ),

                const SizedBox(height: AppConstants.spacing24),

                // Shipping Address
                Text(
                  'Shipping Address',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing16),

                Card(
                  child: Padding(
                    padding: AppConstants.paddingAll16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shippingAddress.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.shippingAddress.phone),
                        const SizedBox(height: 8),
                        Text(widget.shippingAddress.addressLine1),
                        if (widget.shippingAddress.addressLine2 != null)
                          Text(widget.shippingAddress.addressLine2!),
                        Text(
                          '${widget.shippingAddress.city}, ${widget.shippingAddress.state} ${widget.shippingAddress.postalCode}',
                        ),
                        Text(widget.shippingAddress.country),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Place Order Button
          Container(
            padding: AppConstants.paddingAll16,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Place Order',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : null,
            color: isBold ? AppColors.primaryBlue : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    IconData icon,
    String title,
    String subtitle,
    bool isEnabled,
  ) {
    return InkWell(
      onTap: isEnabled
          ? () => setState(() => _selectedPaymentMethod = method)
          : null,
      borderRadius: AppConstants.borderRadiusMedium,
      child: Container(
        padding: AppConstants.paddingAll16,
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == method && isEnabled
                ? AppColors.primaryBlue
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: AppConstants.borderRadiusMedium,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isEnabled ? AppColors.primaryBlue : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? null : Colors.grey,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            if (isEnabled)
              Radio<PaymentMethod>(
                value: method,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
              )
            else
              const Icon(Icons.lock_outline, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    setState(() => _isPlacingOrder = true);

    try {
      final order = await ref.read(orderProvider.notifier).createOrder(
            shippingAddress: widget.shippingAddress,
            paymentMethod: _selectedPaymentMethod,
          );

      if (!mounted) return;

      if (order != null) {
        // Clear cart after successful order
        await ref.read(cartProvider.notifier).clearCart();

        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(order: order),
          ),
        );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place order. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }
}
