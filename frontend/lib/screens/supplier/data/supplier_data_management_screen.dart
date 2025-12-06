import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';

/// 📊 Supplier Data Management Screen
/// Allows suppliers to manage their business data collections
class SupplierDataManagementScreen extends StatefulWidget {
  const SupplierDataManagementScreen({super.key});

  @override
  State<SupplierDataManagementScreen> createState() =>
      _SupplierDataManagementScreenState();
}

class _SupplierDataManagementScreenState
    extends State<SupplierDataManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDataStats();
  }

  Future<void> _loadDataStats() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) return;

      // Load stats for supplier collections
      final responses = await Future.wait([
        _apiService.get('/products/stats/supplier/$userId'),
        _apiService.get('/orders/stats/supplier/$userId'),
        _apiService.get('/rfq/stats/supplier/$userId'),
      ]);

      setState(() {
        _stats = {
          'products': responses[0].isSuccess
              ? responses[0].data
              : {'count': 0, 'totalValue': 0},
          'orders': responses[1].isSuccess
              ? responses[1].data
              : {'count': 0, 'totalRevenue': 0},
          'rfqs': responses[2].isSuccess ? responses[2].data : {'count': 0},
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Data'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDataStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildDataCollectionsGrid(),
                    const SizedBox(height: 24),
                    _buildAnalyticsSummary(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Data Hub',
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your business data',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard('Total Revenue',
                  '₹${_stats['orders']?['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
              const SizedBox(width: 16),
              _buildStatCard(
                  'Active Products', '${_stats['products']?['count'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCollectionsGrid() {
    final collections = [
      {
        'title': 'My Products',
        'icon': Icons.inventory,
        'color': AppColors.primary,
        'route': AppRoutes.supplierDataProducts,
        'stats': _stats['products'],
        'description': 'Manage product catalog',
        'subtitle':
            '${_stats['products']?['count'] ?? 0} products • ₹${_stats['products']?['totalValue']?.toStringAsFixed(2) ?? '0.00'} value',
      },
      {
        'title': 'Customer Orders',
        'icon': Icons.receipt_long,
        'color': AppColors.success,
        'route': AppRoutes.supplierDataOrders,
        'stats': _stats['orders'],
        'description': 'Manage customer orders',
        'subtitle':
            '${_stats['orders']?['count'] ?? 0} orders • ₹${_stats['orders']?['totalRevenue']?.toStringAsFixed(2) ?? '0.00'} revenue',
      },
      {
        'title': 'Quote Requests',
        'icon': Icons.assignment,
        'color': AppColors.warning,
        'route': AppRoutes.supplierDataRfqs,
        'stats': _stats['rfqs'],
        'description': 'Respond to RFQs',
        'subtitle': '${_stats['rfqs']?['count'] ?? 0} pending requests',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Data Collections',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            return _buildCollectionCard(collection);
          },
        ),
      ],
    );
  }

  Widget _buildCollectionCard(Map<String, dynamic> collection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: collection['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              collection['icon'],
              color: collection['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection['title'],
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  collection['description'],
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  collection['subtitle'],
                  style: AppTypography.caption.copyWith(
                    color: collection['color'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, collection['route']),
            icon: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Business Analytics',
                style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Monthly Revenue',
                  '₹${_calculateMonthlyRevenue()}',
                  AppColors.success,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Active RFQs',
                  '${_stats['rfqs']?['count'] ?? 0}',
                  AppColors.warning,
                  Icons.pending_actions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Products',
                  '${_stats['products']?['count'] ?? 0}',
                  AppColors.primary,
                  Icons.inventory,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Order Rate',
                  '${_calculateOrderRate()}%',
                  AppColors.secondary,
                  Icons.percent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Add Product',
                Icons.add_box,
                AppColors.primary,
                () =>
                    Navigator.pushNamed(context, AppRoutes.supplierProductAdd),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'View Analytics',
                Icons.bar_chart,
                AppColors.secondary,
                () => Navigator.pushNamed(context, AppRoutes.supplierAnalytics),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Export Data',
                Icons.download,
                AppColors.success,
                () => _exportData(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Business Report',
                Icons.description,
                AppColors.warning,
                () => _generateReport(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).asGestureDetector(onTap: onTap);
  }

  String _calculateMonthlyRevenue() {
    // TODO: Calculate actual monthly revenue
    final totalRevenue = _stats['orders']?['totalRevenue'] ?? 0.0;
    return (totalRevenue / 12).toStringAsFixed(2); // Placeholder calculation
  }

  String _calculateOrderRate() {
    // TODO: Calculate actual order conversion rate
    final totalProducts = _stats['products']?['count'] ?? 0;
    final totalOrders = _stats['orders']?['count'] ?? 0;
    if (totalProducts == 0) return '0';
    return ((totalOrders / totalProducts) * 100).toStringAsFixed(1);
  }

  void _exportData() {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export functionality coming soon')),
    );
  }

  void _generateReport() {
    // TODO: Implement report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Business report functionality coming soon')),
    );
  }
}

extension GestureDetectorExtension on Widget {
  Widget asGestureDetector({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: this,
    );
  }
}
