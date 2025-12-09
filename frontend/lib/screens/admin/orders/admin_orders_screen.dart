import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_config.dart';
import '../../../services/api_service.dart';
import '../widgets/admin_layout.dart';

/// 📦 Admin Orders Screen
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(AppConfig.adminOrdersEndpoint);
      if (response.isSuccess && response.data != null) {
        setState(() {
          final dataMap = response.data as Map<String, dynamic>;
          final actualData = dataMap.containsKey('data')
              ? Map<String, dynamic>.from(dataMap['data'] as Map)
              : dataMap;
          _orders = List<Map<String, dynamic>>.from(actualData['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Orders',
      currentIndex: 4,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order #${order['orderNumber'] ?? order['id']}',
                                style: AppTypography.labelLarge
                                    .copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                        order['status'] ?? 'pending')
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                order['status'] ?? 'pending',
                                style: TextStyle(
                                  color: _getStatusColor(
                                      order['status'] ?? 'pending'),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                () {
                                  final customer =
                                      order['customer'] ?? order['user'];
                                  if (customer == null) return 'Customer';
                                  if (customer['fullName'] != null) {
                                    return customer['fullName'];
                                  }
                                  final name =
                                      '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'
                                          .trim();
                                  return name.isNotEmpty ? name : 'Customer';
                                }(),
                                style: AppTypography.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'shipped':
        return AppColors.warning;
      case 'processing':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
