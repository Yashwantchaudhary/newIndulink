import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widgets.dart';

import '../../../models/order.dart';
import '../../../providers/order_provider.dart';

/// 📋 Supplier Order Detail Screen
class SupplierOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const SupplierOrderDetailScreen({super.key, required this.orderId});

  @override
  State<SupplierOrderDetailScreen> createState() =>
      _SupplierOrderDetailScreenState();
}

class _SupplierOrderDetailScreenState extends State<SupplierOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrderDetails(widget.orderId);
    });
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    final provider = context.read<OrderProvider>();
    final success = await provider.updateOrderStatus(widget.orderId, newStatus);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${newStatus.displayName}')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to update status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingSpinner());
          }

          if (provider.errorMessage != null) {
            return ErrorStateWidget(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchOrderDetails(widget.orderId),
            );
          }

          final order = provider.selectedOrder;

          if (order == null) {
            return const ErrorStateWidget(message: 'Order not found');
          }

          return _buildOrderContent(order, provider.isLoading);
        },
      ),
    );
  }

  Widget _buildOrderContent(Order order, bool isUpdating) {
    final userName = order.user?.fullName ?? 'Customer';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.orderNumber}'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(order.status),
                  _getStatusColor(order.status).withValues(alpha: 0.7)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(_getStatusIcon(order.status),
                    color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  order.status.displayName.toUpperCase(),
                  style: AppTypography.h5.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Customer Info
          _buildCard(
            'Customer',
            Column(
              children: [
                _buildRow(Icons.person, 'Name', userName),
                const Divider(),
                _buildRow(Icons.email, 'Email', order.user?.email ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shipping Address
          _buildCard(
            'Shipping Address',
            Text(
              '${order.shippingAddress.addressLine1}, ${order.shippingAddress.city}',
              style: AppTypography.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),

          // Items
          _buildCard(
            'Items (${order.items.length})',
            Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shopping_bag),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: AppTypography.labelLarge),
                                  Text('Qty: ${item.quantity} × ₹${item.price}',
                                      style: AppTypography.bodySmall),
                                ],
                              ),
                            ),
                            Text('₹${item.subtotal}',
                                style: AppTypography.labelLarge
                                    .copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Summary
          _buildCard(
            'Summary',
            Column(
              children: [
                _buildSummaryRow('Subtotal', order.subtotal),
                _buildSummaryRow('Tax', order.tax),
                _buildSummaryRow('Shipping', order.shippingFee),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: AppTypography.h6
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text('₹${order.total}',
                        style: AppTypography.h5.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          if (order.status == OrderStatus.pending) ...[
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () => _updateStatus(OrderStatus.processing),
              child: const Text('Start Processing'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isUpdating
                  ? null
                  : () => _updateStatus(OrderStatus.cancelled),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Cancel Order'),
            ),
          ] else if (order.status == OrderStatus.processing) ...[
            ElevatedButton(
              onPressed:
                  isUpdating ? null : () => _updateStatus(OrderStatus.shipped),
              child: const Text('Mark as Shipped'),
            ),
          ] else if (order.status == OrderStatus.shipped) ...[
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () => _updateStatus(OrderStatus.delivered),
              child: const Text('Mark as Delivered'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.labelLarge
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              Text(value, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text('₹$value', style: AppTypography.labelLarge),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.shipped:
        return AppColors.statusShipped;
      case OrderStatus.processing:
        return AppColors.statusProcessing;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
      default:
        return AppColors.statusPending;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.processing:
        return Icons.autorenew;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }
}
