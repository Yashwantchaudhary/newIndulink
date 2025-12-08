import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widgets.dart';
import '../../../models/order.dart';
import '../../../providers/order_provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrderDetails(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrackingHeader(order),
                const SizedBox(height: 24),
                if (order.status == OrderStatus.cancelled)
                  _buildCancelledStatus(order)
                else
                  _buildTimeline(order),
                const SizedBox(height: 24),
                if (order.trackingNumber != null || order.carrier != null)
                  _buildTrackingDetails(order),
                const SizedBox(height: 24),
                _buildOrderItemsPreview(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackingHeader(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${order.orderNumber}',
            style: AppTypography.h6.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Placed on ${DateFormat('MMM dd, yyyy').format(order.createdAt)}',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (order.estimatedDelivery != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Estimated Delivery',
              style: AppTypography.caption.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMM dd').format(order.estimatedDelivery!),
              style: AppTypography.h5.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelledStatus(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.error, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: AppTypography.h6.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (order.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.notes!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Order order) {
    final steps = [
      {
        'status': OrderStatus.pending,
        'title': 'Order Placed',
        'icon': Icons.shopping_cart
      },
      {
        'status': OrderStatus.processing,
        'title': 'Processing',
        'icon': Icons.settings
      },
      {
        'status': OrderStatus.shipped,
        'title': 'Shipped',
        'icon': Icons.local_shipping
      },
      {
        'status': OrderStatus.delivered,
        'title': 'Delivered',
        'icon': Icons.check_circle
      },
    ];

    int currentStepIndex =
        steps.indexWhere((step) => step['status'] == order.status);
    if (currentStepIndex == -1) currentStepIndex = 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isCompleted = index <= currentStepIndex;
              final isLast = index == steps.length - 1;
              final isActive = index == currentStepIndex;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isActive ? (step['icon'] as IconData) : Icons.check,
                          color:
                              isCompleted ? Colors.white : Colors.grey.shade400,
                          size: 16,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: index < currentStepIndex
                              ? AppColors.primary
                              : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: isCompleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCompleted
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                        if (isActive &&
                            order.statusHistory != null &&
                            order.statusHistory!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, hh:mm a')
                                .format(order.updatedAt),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingDetails(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking Information',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (order.carrier != null) _buildDetailRow('Carrier', order.carrier!),
          if (order.trackingNumber != null)
            _buildDetailRow('Tracking Number', order.trackingNumber!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style:
                AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsPreview(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style:
                AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '${order.totalItems} items',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
