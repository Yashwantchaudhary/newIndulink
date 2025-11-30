import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../services/api_service.dart';
import '../../../models/dashboard.dart';

/// 👨‍💼 Admin Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  AdminDashboardData? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/api/dashboard/admin');
      if (response.isSuccess && response.data != null) {
        setState(() {
          _data = AdminDashboardData.fromJson(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard('Total Users', '${_data?.totalUsers ?? 0}',
                          Icons.people, AppColors.primary),
                      _buildStatCard(
                          'Suppliers',
                          '${_data?.totalSuppliers ?? 0}',
                          Icons.store,
                          AppColors.secondary),
                      _buildStatCard('Products', '${_data?.totalProducts ?? 0}',
                          Icons.inventory, AppColors.warning),
                      _buildStatCard('Orders', '${_data?.totalOrders ?? 0}',
                          Icons.shopping_bag, AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Revenue Card
                  _buildCard(
                    'Platform Revenue',
                    Column(
                      children: [
                        Text(
                          '₹${_data?.totalRevenue.toStringAsFixed(2) ?? '0.00'}',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commission: ₹${_data?.platformCommission.toStringAsFixed(2) ?? '0.00'}',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recent Users
                  if (_data?.recentUsers != null &&
                      _data!.recentUsers.isNotEmpty)
                    _buildCard(
                      'Recent Users',
                      Column(
                        children: _data!.recentUsers.take(5).map((user) {
                          return ListTile(
                            leading: CircleAvatar(
                              child:
                                  Text((user['name'] ?? 'U')[0].toUpperCase()),
                            ),
                            title: Text(user['name'] ?? 'User'),
                            subtitle: Text(user['email'] ?? ''),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user['role'] ?? 'customer',
                                style: TextStyle(
                                    color: AppColors.primary, fontSize: 12),
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 32),
          const Spacer(),
          Text(value,
              style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold)),
          Text(title,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
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
}
