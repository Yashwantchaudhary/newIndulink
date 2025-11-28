import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/order.dart';
import '../../routes.dart';

/// Order success screen
class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppConstants.paddingPage,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 80,
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .then()
                  .shake(),

              const SizedBox(height: AppConstants.spacing32),

              // Success Title
              Text(
                'Order Placed Successfully!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: AppConstants.spacing16),

              // Order Number
              Text(
                'Order #${order.orderNumber}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: AppConstants.spacing32),

              // Order Summary Card
              Card(
                child: Padding(
                  padding: AppConstants.paddingAll16,
                  child: Column(
                    children: [
                      _buildRow('Items', '${order.itemCount}', theme),
                      const SizedBox(height: 8),
                      _buildRow('Total Amount',
                          currencyFormat.format(order.total), theme),
                      const SizedBox(height: 8),
                      _buildRow('Payment Method',
                          order.paymentMethod.displayName, theme),
                      const SizedBox(height: 8),
                      _buildRow('Status', _getStatusText(order.status), theme,
                          color: AppColors.warning),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: AppConstants.spacing24),

              // Delivery Address
              Card(
                child: Padding(
                  padding: AppConstants.paddingAll16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery Address',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.shippingAddress.fullName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(order.shippingAddress.addressLine1),
                      if (order.shippingAddress.addressLine2 != null)
                        Text(order.shippingAddress.addressLine2!),
                      Text(
                        '${order.shippingAddress.city}, ${order.shippingAddress.state} ${order.shippingAddress.postalCode}',
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

              const Spacer(),

              // Buttons
              Column(
                children: [
                  // View Order Details
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        AppRoutes.navigateTo(context, AppRoutes.orderDetail,
                            arguments: order.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('View Order Details'),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing12),

                  // Continue Shopping
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        AppRoutes.navigateToAndRemoveUntil(
                            context, AppRoutes.home);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme,
      {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }
}
