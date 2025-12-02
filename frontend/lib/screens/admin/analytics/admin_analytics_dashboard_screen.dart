import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/admin_layout.dart';

/// 📊 Admin Analytics Dashboard Screen
/// Comprehensive analytics and reporting dashboard
class AdminAnalyticsDashboardScreen extends StatefulWidget {
  const AdminAnalyticsDashboardScreen({super.key});

  @override
  State<AdminAnalyticsDashboardScreen> createState() => _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState extends State<AdminAnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load analytics data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
      analyticsProvider.loadDashboardAnalytics();
      analyticsProvider.loadAnalyticsConfig();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return AdminLayout(
      title: 'Analytics Dashboard',
      currentIndex: 0, // Custom index for analytics
      child: Column(
        children: [
          // Timeframe Selector
          _buildTimeframeSelector(analyticsProvider),

          // Tab Bar
          Container(
            margin: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textPrimary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard),
                  text: 'Overview',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'Users',
                ),
                Tab(
                  icon: Icon(Icons.trending_up),
                  text: 'Sales',
                ),
                Tab(
                  icon: Icon(Icons.inventory),
                  text: 'Products',
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                _buildOverviewTab(analyticsProvider),

                // Users Tab
                _buildUsersTab(analyticsProvider),

                // Sales Tab
                _buildSalesTab(analyticsProvider),

                // Products Tab
                _buildProductsTab(analyticsProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(AnalyticsProvider provider) {
    final timeframes = ['1h', '24h', '7d', '30d', '90d', '1y'];
    final labels = ['1 Hour', '24 Hours', '7 Days', '30 Days', '90 Days', '1 Year'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Timeframe:',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: timeframes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final timeframe = entry.value;
                  final isSelected = provider.selectedTimeframe == timeframe;

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(labels[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          provider.updateTimeframe(timeframe);
                          provider.loadDashboardAnalytics(timeframe: timeframe);
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AnalyticsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: AppTypography.h6.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.loadDashboardAnalytics(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final metrics = provider.getKeyMetrics();
    final trends = provider.getTrendIndicators();

    return RefreshIndicator(
      onRefresh: () => provider.loadDashboardAnalytics(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics Cards
            _buildMetricsGrid(metrics, trends),

            const SizedBox(height: 24),

            // Charts Section
            Text(
              'Performance Charts',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Revenue Trend Chart
            _buildChartCard(
              'Revenue Trend',
              Icons.trending_up,
              AppColors.success,
              _buildRevenueChart(provider),
            ),

            const SizedBox(height: 16),

            // User Growth Chart
            _buildChartCard(
              'User Growth',
              Icons.people,
              AppColors.primary,
              _buildUserGrowthChart(provider),
            ),

            const SizedBox(height: 16),

            // Top Products
            _buildTopProductsCard(provider),

            const SizedBox(height: 16),

            // Recent Activity
            _buildRecentActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(AnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Analytics',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (provider.userAnalytics != null) ...[
            // User Metrics
            _buildUserMetricsCards(provider.userAnalytics!),

            const SizedBox(height: 24),

            // User Demographics
            _buildUserDemographicsChart(provider.userAnalytics!),

            const SizedBox(height: 24),

            // User Engagement
            _buildUserEngagementCard(provider.userAnalytics!),
          ] else ...[
            const Center(child: Text('No user analytics data available')),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesTab(AnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Analytics',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (provider.salesAnalytics != null) ...[
            // Sales Metrics
            _buildSalesMetricsCards(provider.salesAnalytics!),

            const SizedBox(height: 24),

            // Sales Trend
            _buildSalesTrendChart(provider.salesAnalytics!),

            const SizedBox(height: 24),

            // Sales by Category
            _buildSalesByCategoryChart(provider.salesAnalytics!),
          ] else ...[
            const Center(child: Text('No sales analytics data available')),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsTab(AnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Analytics',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (provider.productAnalytics != null) ...[
            // Product Metrics
            _buildProductMetricsCards(provider.productAnalytics!),

            const SizedBox(height: 24),

            // Product Performance
            _buildProductPerformanceChart(provider.productAnalytics!),

            const SizedBox(height: 24),

            // Inventory Status
            _buildInventoryStatusCard(provider.productAnalytics!),
          ] else ...[
            const Center(child: Text('No product analytics data available')),
          ],
        ],
      ),
    );
  }

  // Helper Methods for Building UI Components

  Widget _buildMetricsGrid(Map<String, dynamic> metrics, Map<String, dynamic> trends) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Users',
          metrics['totalUsers'].toString(),
          Icons.people,
          AppColors.primary,
          trends['userGrowth'],
        ),
        _buildMetricCard(
          'Total Revenue',
          '₹${metrics['totalRevenue']}',
          Icons.attach_money,
          AppColors.success,
          trends['salesGrowth'],
        ),
        _buildMetricCard(
          'Total Orders',
          metrics['totalOrders'].toString(),
          Icons.shopping_cart,
          AppColors.warning,
          trends['orderGrowth'],
        ),
        _buildMetricCard(
          'Active Products',
          metrics['totalProducts'].toString(),
          Icons.inventory,
          AppColors.info,
          0, // No trend data for products
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, double trend) {
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
              Icon(icon, color: color, size: 24),
              const Spacer(),
              if (trend != 0) ...[
                Icon(
                  trend > 0 ? Icons.trending_up : Icons.trending_down,
                  color: trend > 0 ? AppColors.success : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trend.abs().toStringAsFixed(1)}%',
                  style: AppTypography.caption.copyWith(
                    color: trend > 0 ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, IconData icon, Color color, Widget chart) {
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
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
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

  Widget _buildRevenueChart(AnalyticsProvider provider) {
    final data = provider.getFormattedChartData('sales_trend');
    return _buildSimpleChart(data['labels'], data['values'], AppColors.success);
  }

  Widget _buildUserGrowthChart(AnalyticsProvider provider) {
    final data = provider.getFormattedChartData('user_growth');
    return _buildSimpleChart(data['labels'], data['values'], AppColors.primary);
  }

  Widget _buildSimpleChart(List<String> labels, List<dynamic> values, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: SimpleBarChartPainter(labels, values, color),
        child: Container(),
      ),
    );
  }

  Widget _buildTopProductsCard(AnalyticsProvider provider) {
    final topProducts = provider.salesAnalytics?['topProducts'] ?? [];

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
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (topProducts.isEmpty) ...[
            const Center(child: Text('No product data available')),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              itemBuilder: (context, index) {
                final product = topProducts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(product['name'] ?? 'Unknown Product'),
                  subtitle: Text('₹${product['revenue'] ?? 0} revenue'),
                  trailing: Text('${product['quantitySold'] ?? 0} sold'),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
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
            'Recent Activity',
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Activity feed coming soon...')),
        ],
      ),
    );
  }

  // Placeholder methods for other tabs
  Widget _buildUserMetricsCards(Map<String, dynamic> data) {
    return const Center(child: Text('User metrics cards coming soon...'));
  }

  Widget _buildUserDemographicsChart(Map<String, dynamic> data) {
    return const Center(child: Text('User demographics chart coming soon...'));
  }

  Widget _buildUserEngagementCard(Map<String, dynamic> data) {
    return const Center(child: Text('User engagement card coming soon...'));
  }

  Widget _buildSalesMetricsCards(Map<String, dynamic> data) {
    return const Center(child: Text('Sales metrics cards coming soon...'));
  }

  Widget _buildSalesTrendChart(Map<String, dynamic> data) {
    return const Center(child: Text('Sales trend chart coming soon...'));
  }

  Widget _buildSalesByCategoryChart(Map<String, dynamic> data) {
    return const Center(child: Text('Sales by category chart coming soon...'));
  }

  Widget _buildProductMetricsCards(Map<String, dynamic> data) {
    return const Center(child: Text('Product metrics cards coming soon...'));
  }

  Widget _buildProductPerformanceChart(Map<String, dynamic> data) {
    return const Center(child: Text('Product performance chart coming soon...'));
  }

  Widget _buildInventoryStatusCard(Map<String, dynamic> data) {
    return const Center(child: Text('Inventory status card coming soon...'));
  }
}

// Simple Bar Chart Painter
class SimpleBarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<dynamic> values;
  final Color color;

  SimpleBarChartPainter(this.labels, this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final maxValue = values.map((v) => v as num).reduce((a, b) => a > b ? a : b);
    final barWidth = size.width / values.length * 0.8;
    final spacing = size.width / values.length * 0.2;

    for (int i = 0; i < values.length; i++) {
      final barHeight = (values[i] / maxValue) * size.height * 0.8;
      final left = i * (barWidth + spacing) + spacing / 2;
      final top = size.height - barHeight - 20;

      canvas.drawRect(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}