import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

import '../../../models/order.dart';
import '../../../services/api_service.dart';

/// 📋 Supplier Order Detail Screen
class SupplierOrderDetailScreen extends StatefulWidget {
  final Order order;

  const SupplierOrderDetailScreen({super.key, required this.order});

  @override
  State<SupplierOrderDetailScreen> createState() =>
      _SupplierOrderDetailScreenState();
}

class _SupplierOrderDetailScreenState extends State<SupplierOrderDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isUpdating = false;

  Future<void> _updateStatus(OrderStatus newStatus) async {
    setState(() => _isUpdating = true);

    try {
      final response = await _apiService.put(
        '/api/orders/${widget.order.id}/status',
        body: {'status': newStatus.value},
      );

      if (response.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${newStatus.displayName}')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(response.message ?? 'Failed to update');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
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
              onPressed: _isUpdating
                  ? null
                  : () => _updateStatus(OrderStatus.processing),
              child: const Text('Start Processing'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isUpdating
                  ? null
                  : () => _updateStatus(OrderStatus.cancelled),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Cancel Order'),
            ),
          ] else if (order.status == OrderStatus.processing) ...[
            ElevatedButton(
              onPressed:
                  _isUpdating ? null : () => _updateStatus(OrderStatus.shipped),
              child: const Text('Mark as Shipped'),
            ),
          ] else if (order.status == OrderStatus.shipped) ...[
            ElevatedButton(
              onPressed: _isUpdating
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
