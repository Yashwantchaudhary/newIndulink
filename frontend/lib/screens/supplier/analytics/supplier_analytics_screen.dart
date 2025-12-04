import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widgets.dart';

import '../../../providers/analytics_provider.dart';

/// 📊 Supplier Analytics Screen
/// Displays detailed analytics and insights for suppliers
class SupplierAnalyticsScreen extends StatefulWidget {
  const SupplierAnalyticsScreen({super.key});

  @override
  State<SupplierAnalyticsScreen> createState() => _SupplierAnalyticsScreenState();
}

class _SupplierAnalyticsScreenState extends State<SupplierAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load analytics data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadSupplierAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Products'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analyticsProvider, child) {
          if (analyticsProvider.isLoading) {
            return const Center(child: LoadingSpinner());
          }

          if (analyticsProvider.errorMessage != null) {
            return ErrorStateWidget(
              message: analyticsProvider.errorMessage!,
              onRetry: () => analyticsProvider.loadSupplierAnalytics(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(analyticsProvider),
              _buildSalesTab(analyticsProvider),
              _buildProductsTab(analyticsProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(AnalyticsProvider provider) {
    final analytics = provider.supplierAnalytics;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      children: [
        // Key Metrics Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                'Rs. ${analytics?['totalRevenue'] ?? 0}',
                Icons.attach_money,
                AppColors.success,
                analytics?['revenueChange'] ?? 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Orders',
                '${analytics?['totalOrders'] ?? 0}',
                Icons.shopping_cart,
                AppColors.primary,
                analytics?['ordersChange'] ?? 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Active Products',
                '${analytics?['activeProducts'] ?? 0}',
                Icons.inventory,
                AppColors.warning,
                analytics?['productsChange'] ?? 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg. Order Value',
                'Rs. ${analytics?['averageOrderValue'] ?? 0}',
                Icons.trending_up,
                AppColors.info,
                analytics?['aovChange'] ?? 0,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Revenue Chart
        _buildChartCard(
          'Revenue Trend',
          _buildRevenueChart(analytics?['revenueData'] ?? []),
        ),

        const SizedBox(height: 16),

        // Top Products
        _buildTopProductsCard(analytics?['topProducts'] ?? []),
      ],
    );
  }

  Widget _buildSalesTab(AnalyticsProvider provider) {
    final analytics = provider.supplierAnalytics;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      children: [
        // Sales by Period
        _buildChartCard(
          'Sales by Period',
          _buildSalesChart(analytics?['salesByPeriod'] ?? []),
        ),

        const SizedBox(height: 16),

        // Order Status Distribution
        _buildChartCard(
          'Order Status Distribution',
          _buildOrderStatusChart(analytics?['orderStatusData'] ?? []),
        ),

        const SizedBox(height: 16),

        // Recent Sales
        _buildRecentSalesCard(analytics?['recentSales'] ?? []),
      ],
    );
  }

  Widget _buildProductsTab(AnalyticsProvider provider) {
    final analytics = provider.supplierAnalytics;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      children: [
        // Product Performance
        _buildChartCard(
          'Product Performance',
          _buildProductPerformanceChart(analytics?['productPerformance'] ?? []),
        ),

        const SizedBox(height: 16),

        // Inventory Status
        _buildInventoryStatusCard(analytics?['inventoryStatus'] ?? []),

        const SizedBox(height: 16),

        // Category Performance
        _buildCategoryPerformanceCard(analytics?['categoryPerformance'] ?? []),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, double change) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (change != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: change > 0 ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
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
            title,
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: chart,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<double> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No sales data available'));
    }

    return BarChart(
      BarChartData(
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['sales'] as num?)?.toDouble() ?? 0,
                color: AppColors.primary,
                width: 16,
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(show: false),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildOrderStatusChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No order data available'));
    }

    return PieChart(
      PieChartData(
        sections: data.map((item) {
          return PieChartSectionData(
            value: (item['count'] as num?)?.toDouble() ?? 0,
            title: '${item['status']}\n${item['count']}',
            color: _getStatusColor(item['status'] as String? ?? ''),
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductPerformanceChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No product data available'));
    }

    return BarChart(
      BarChartData(
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['sales'] as num?)?.toDouble() ?? 0,
                color: AppColors.success,
                width: 12,
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(show: false),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildTopProductsCard(List<Map<String, dynamic>> products) {
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
            'Top Products',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const Center(child: Text('No product data available'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text('${index + 1}'),
                  ),
                  title: Text(product['name'] ?? 'Unknown Product'),
                  subtitle: Text('Sold: ${product['sold'] ?? 0}'),
                  trailing: Text(
                    'Rs. ${product['revenue'] ?? 0}',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesCard(List<Map<String, dynamic>> sales) {
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
            'Recent Sales',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (sales.isEmpty)
            const Center(child: Text('No recent sales'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sales.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final sale = sales[index];
                return ListTile(
                  title: Text('Order #${sale['orderNumber'] ?? ''}'),
                  subtitle: Text(sale['customerName'] ?? 'Unknown Customer'),
                  trailing: Text(
                    'Rs. ${sale['amount'] ?? 0}',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatusCard(List<Map<String, dynamic>> inventory) {
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
            'Inventory Status',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (inventory.isEmpty)
            const Center(child: Text('No inventory data available'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: inventory.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = inventory[index];
                final stock = item['stock'] as int? ?? 0;
                final statusColor = stock == 0 ? AppColors.error :
                                   stock < 10 ? AppColors.warning : AppColors.success;

                return ListTile(
                  title: Text(item['name'] ?? 'Unknown Product'),
                  subtitle: Text('Stock: $stock'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stock == 0 ? 'Out of Stock' :
                      stock < 10 ? 'Low Stock' : 'In Stock',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceCard(List<Map<String, dynamic>> categories) {
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
            'Category Performance',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Center(child: Text('No category data available'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category['name'] ?? 'Unknown Category'),
                  subtitle: Text('${category['products'] ?? 0} products'),
                  trailing: Text(
                    '${category['percentage'] ?? 0}%',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'shipped':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}