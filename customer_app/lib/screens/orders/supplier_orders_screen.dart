import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';

/// Supplier Orders Management Screen
class SupplierOrdersScreen extends ConsumerStatefulWidget {
  const SupplierOrdersScreen({super.key});

  @override
  ConsumerState<SupplierOrdersScreen> createState() => _SupplierOrdersScreenState();
}

class _SupplierOrdersScreenState extends ConsumerState<SupplierOrdersScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(supplierOrderProvider.notifier).fetchOrders();
    });
  }

  String? _getStatusFromFilter() {
    return _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Orders Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),

          // Orders List
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              selectedColor: AppColors.primaryBlue,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    // Mock data for demonstration
    final orders = [
      _mockOrder('ORD-001', 'John Doe', 'Pending', 2500.0, 2),
      _mockOrder('ORD-002', 'Jane Smith', 'Processing', 1800.0, 1),
      _mockOrder('ORD-003', 'Bob Johnson', 'Shipped', 3200.0, 3),
    ];

    if (orders.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: 'No Orders Yet',
        message: 'Orders from customers will appear here',
      );
    }

    return ListView.builder(
      padding: AppConstants.paddingAll16,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildOrderCard(_MockOrder order) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: AppConstants.borderRadiusSmall,
                ),
                child: const Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.customerName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.itemCount} item${order.itemCount > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Rs ${order.total.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewOrderDetails(order),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 8),
              if (order.status == 'Pending')
                ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(order, 'Processing'),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = AppColors.statusPending;
        break;
      case 'processing':
        color = AppColors.statusProcessing;
        break;
      case 'shipped':
        color = AppColors.statusShipped;
        break;
      case 'delivered':
        color = AppColors.statusDelivered;
        break;
      default:
        color = AppColors.lightTextSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Orders'),
              onTap: () {
                setState(() => _selectedFilter = 'All');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Pending'),
              onTap: () {
                setState(() => _selectedFilter = 'Pending');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Processing'),
              onTap: () {
                setState(() => _selectedFilter = 'Processing');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewOrderDetails(_MockOrder order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for ${order.orderNumber}')),
    );
  }

  void _updateOrderStatus(_MockOrder order, String newStatus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order.orderNumber} status updated to $newStatus')),
    );
  }

  _MockOrder _mockOrder(String orderNumber, String customerName, String status, double total, int itemCount) {
    return _MockOrder(
      orderNumber: orderNumber,
      customerName: customerName,
      status: status,
      total: total,
      itemCount: itemCount,
    );
  }
}

class _MockOrder {
  final String orderNumber;
  final String customerName;
  final String status;
  final double total;
  final int itemCount;

  _MockOrder({
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.total,
    required this.itemCount,
  });
}