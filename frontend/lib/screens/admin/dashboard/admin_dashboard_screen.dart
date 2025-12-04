import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_config.dart';
import '../../../routes/app_routes.dart';
import '../analytics/admin_analytics_dashboard_screen.dart';
import '../../../services/api_service.dart';
import '../../../models/dashboard.dart';
import '../widgets/admin_layout.dart';

/// 👨‍💼 Admin Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  AdminDashboardData? _data;

  @override
  void initState() {
    super.initState();
    // Start loading data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Add timeout to prevent infinite loading
      final response =
          await _apiService.get(AppConfig.adminDashboardEndpoint).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          // Backend wraps response in {success, message, data: {...}}
          // But response.data already contains the unwrapped data
          final Map<String, dynamic> dataMap = response.data is Map
              ? Map<String, dynamic>.from(response.data as Map)
              : <String, dynamic>{};

          // Check if data is already unwrapped or needs unwrapping
          final Map<String, dynamic> actualData =
              dataMap.containsKey('data') && dataMap['data'] is Map
                  ? Map<String, dynamic>.from(dataMap['data'] as Map)
                  : dataMap;

          _data = AdminDashboardData.fromJson(actualData);
          _isLoading = false;
        });
      } else {
        // Handle non-success response
        _handleLoadError(response.message ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      _handleLoadError(e.toString());
    }
  }

  void _handleLoadError(String error) {
    setState(() {
      _isLoading = false;
      _data = AdminDashboardData(
        totalUsers: 0,
        totalSuppliers: 0,
        totalCustomers: 0,
        totalProducts: 0,
        totalOrders: 0,
        totalRevenue: 0.0,
        platformCommission: 0.0,
        recentUsers: [],
      );
    });

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load dashboard: $error'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Admin Dashboard',
      currentIndex: 0,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Loading indicator at top
            if (_isLoading)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading dashboard data...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

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
                    Icons.people, AppColors.primary, _isLoading),
                _buildStatCard('Suppliers', '${_data?.totalSuppliers ?? 0}',
                    Icons.store, AppColors.secondary, _isLoading),
                _buildStatCard('Products', '${_data?.totalProducts ?? 0}',
                    Icons.inventory, AppColors.warning, _isLoading),
                _buildStatCard('Orders', '${_data?.totalOrders ?? 0}',
                    Icons.shopping_bag, AppColors.success, _isLoading),
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
              _isLoading,
            ),
            const SizedBox(height: 16),

            // Recent Users
            if (_data?.recentUsers != null && _data!.recentUsers.isNotEmpty)
              _buildCard(
                'Recent Users',
                Column(
                  children: _data!.recentUsers.take(5).map((user) {
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text((user['name'] ?? 'U')[0].toUpperCase()),
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
                          style:
                              TextStyle(color: AppColors.primary, fontSize: 12),
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
                _isLoading,
              ),
            const SizedBox(height: 16),

            // Data Management Access
            _buildCard(
              'System Management',
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pushNamed(
                            context, AppRoutes.adminDataManagement),
                    icon: const Icon(Icons.storage),
                    label: const Text('Data Management Hub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage all system data collections, users, products, orders, and more',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isLoading) {
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
          Text(isLoading ? '...' : value,
              style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold)),
          Text(title,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCard(String title, Widget child, bool isLoading) {
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
