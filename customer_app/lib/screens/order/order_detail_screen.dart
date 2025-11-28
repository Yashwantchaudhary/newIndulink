import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order/order_status_timeline.dart';
import '../../widgets/order/order_item_card.dart';

/// Order detail screen
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Order not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          return _buildOrderDetail(order, theme, ref, context);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(orderDetailProvider(orderId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetail(
      Order order, ThemeData theme, WidgetRef ref, BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');
    final canCancel = order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed;

    return ListView(
      padding: AppConstants.paddingPage,
      children: [
        // Order Header
        Text(
          'Order #${order.orderNumber}',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Placed on ${DateFormat('MMM dd, yyyy').format(order.createdAt)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: AppConstants.spacing24),

        // Status Timeline
        if (order.status != OrderStatus.cancelled &&
            order.status != OrderStatus.refunded)
          OrderStatusTimeline(order: order),

        const SizedBox(height: AppConstants.spacing24),

        // Items
        Text(
          'Items',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacing12),
        ...order.items.map((item) => OrderItemCard(item: item)),

        const SizedBox(height: AppConstants.spacing24),

        // Price Summary
        Card(
          child: Padding(
            padding: AppConstants.paddingAll16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRow(
                    'Subtotal', currencyFormat.format(order.subtotal), theme),
                const SizedBox(height: 8),
                _buildRow('Tax', currencyFormat.format(order.tax), theme),
                const SizedBox(height: 8),
                _buildRow('Shipping', currencyFormat.format(order.shippingCost),
                    theme),
                const Divider(height: 24),
                _buildRow('Total', currencyFormat.format(order.total), theme,
                    isBold: true),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spacing24),

        // Shipping Address
        Card(
          child: Padding(
            padding: AppConstants.paddingAll16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Shipping Address',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  order.shippingAddress.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(order.shippingAddress.phone),
                const SizedBox(height: 4),
                Text(order.shippingAddress.addressLine1),
                if (order.shippingAddress.addressLine2 != null)
                  Text(order.shippingAddress.addressLine2!),
                Text(
                  '${order.shippingAddress.city}, ${order.shippingAddress.state} ${order.shippingAddress.postalCode}',
                ),
                Text(order.shippingAddress.country),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spacing24),

        // Payment Info
        Card(
          child: Padding(
            padding: AppConstants.paddingAll16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payment, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRow(
                    'Payment Method', order.paymentMethod.displayName, theme),
                const SizedBox(height: 8),
                _buildRow('Status',
                    order.paymentStatus?.toUpperCase() ?? 'PENDING', theme),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spacing24),

        // Cancel Button
        if (canCancel)
          OutlinedButton(
            onPressed: () => _showCancelDialog(context, ref, order),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel Order'),
          ),

        const SizedBox(height: AppConstants.spacing16),
      ],
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

  Future<void> _showCancelDialog(
      BuildContext context, WidgetRef ref, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(orderProvider.notifier)
          .cancelOrder(order.id, 'Cancelled by customer');

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh order details
        ref.refresh(orderDetailProvider(order.id));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
