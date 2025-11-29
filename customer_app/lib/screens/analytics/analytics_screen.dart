import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/analytics/metric_card.dart';
import '../../widgets/analytics/date_range_selector.dart';
import '../../widgets/charts/sales_line_chart.dart';
import '../../widgets/charts/product_bar_chart.dart';
import '../../services/analytics_service.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAnalytics() {
    final dateRange = ref.read(dateRangeNotifierProvider);
    final startDate = AnalyticsService.formatDate(dateRange.startDate);
    final endDate = AnalyticsService.formatDate(dateRange.endDate);

    ref.read(salesTrendsNotifierProvider.notifier).fetchSalesTrends(
          startDate: startDate,
          endDate: endDate,
          interval: 'day',
        );

    ref.read(productPerformanceNotifierProvider.notifier).fetchProductPerformance();
    
    final user = ref.read(authProvider).user;
    if (user?.role == 'supplier') {
      ref.read(customerBehaviorNotifierProvider.notifier).fetchCustomerBehavior();
      ref.read(supplierPerformanceNotifierProvider.notifier).fetchSupplierPerformance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateRange = ref.watch(dateRangeNotifierProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Range Selector
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: DateRangeSelector(
              startDate: dateRange.startDate,
              endDate: dateRange.endDate,
              selectedPreset: dateRange.preset,
              onRangeSelected: (start, end, preset) {
                ref.read(dateRangeNotifierProvider.notifier).setDateRange(
                      start,
                      end,
                      preset: preset,
                    );
                _loadAnalytics();
              },
            ),
          ),

          const Divider(height: 1),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSalesTab(),
                _buildProductsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final salesTrendsAsync = ref.watch(salesTrendsNotifierProvider);
    final productPerformanceAsync = ref.watch(productPerformanceNotifierProvider);

    return salesTrendsAsync.when(
      data: (salesTrends) {
        if (salesTrends == null) {
          return const Center(child: Text('No data available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Text(
                'Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Metric Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  MetricCard(
                    label: 'Total Revenue',
                    value: _formatCurrency(salesTrends.totals.totalRevenue),
                    changePercentage: salesTrends.comparison.revenueGrowth,
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                  MetricCard(
                    label: 'Total Orders',
                    value: salesTrends.totals.totalOrders.toString(),
                    changePercentage: salesTrends.comparison.ordersGrowth,
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                  ),
                  MetricCard(
                    label: 'Avg Order Value',
                    value: _formatCurrency(salesTrends.totals.averageOrderValue),
                    changePercentage: salesTrends.comparison.avgOrderValueGrowth,
                    icon: Icons.trending_up,
                    color: Colors.orange,
                  ),
                  MetricCard(
                    label: 'Products Sold',
                    value: productPerformanceAsync.when(
                      data: (perf) => perf?.topProducts.length.toString() ?? '-',
                      loading: () => '-',
                      error: (_, __) => '-',
                    ),
                    icon: Icons.inventory,
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Revenue Trend Chart
              Text(
                'Revenue Trend',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: salesTrends.trends.isEmpty
                    ? const Center(child: Text('No trend data available'))
                    : SalesLineChart(data: salesTrends.trends),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading analytics'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTab() {
    final salesTrendsAsync = ref.watch(salesTrendsNotifierProvider);
    final comparativeAsync = ref.watch(comparativeAnalysisNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          salesTrendsAsync.when(
            data: (salesTrends) {
              if (salesTrends == null) {
                return const Text('No sales data available');
              }

              return Column(
                children: [
                  // Sales Chart
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: SalesLineChart(data: salesTrends.trends),
                  ),

                  const SizedBox(height: 24),

                  // Detailed Metrics
                  _buildDetailedMetrics(salesTrends),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final productPerformanceAsync = ref.watch(productPerformanceNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          productPerformanceAsync.when(
            data: (performance) {
              if (performance == null || performance.topProducts.isEmpty) {
                return const Center(child: Text('No product data available'));
              }

              return Column(
                children: [
                  // Top Products Chart
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ProductBarChart(products: performance.topProducts),
                  ),

                  const SizedBox(height: 24),

                  // Top Products List
                  _buildTopProductsList(performance.topProducts),

                  // Stock Analysis (if available)
                  if (performance.stockAnalysis != null) ...[
                    const SizedBox(height: 24),
                    _buildStockAnalysis(performance.stockAnalysis!),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics(salesTrends) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Period Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildMetricRow(
              'Total Revenue',
              _formatCurrency(salesTrends.totals.totalRevenue),
              salesTrends.comparison.revenueGrowth,
            ),
            _buildMetricRow(
              'Total Orders',
              salesTrends.totals.totalOrders.toString(),
              salesTrends.comparison.ordersGrowth,
            ),
            _buildMetricRow(
              'Average Order Value',
              _formatCurrency(salesTrends.totals.averageOrderValue),
              salesTrends.comparison.avgOrderValueGrowth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double change) {
    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsList(topProducts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Selling Products',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.take(5).length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final product = topProducts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    product.product.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('${product.totalQuantity} units sold'),
                  trailing: Text(
                    _formatCurrency(product.totalRevenue),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockAnalysis(stockAnalysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStockCard(
                    'Total Products',
                    stockAnalysis.totalProducts.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStockCard(
                    'Low Stock',
                    stockAnalysis.lowStock.toString(),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStockCard(
                    'Out of Stock',
                    stockAnalysis.outOfStock.toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(value);
  }

  void _showExportDialog() {
    final dateRange = ref.read(dateRangeNotifierProvider);
    final startDate = AnalyticsService.formatDate(dateRange.startDate);
    final endDate = AnalyticsService.formatDate(dateRange.endDate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose export format and type:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildExportOption(
                    'CSV',
                    'Spreadsheet format',
                    Icons.table_chart,
                    () => _exportData('csv', 'sales', startDate, endDate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportOption(
                    'PDF',
                    'Document format',
                    Icons.picture_as_pdf,
                    () => _exportData('pdf', 'sales', startDate, endDate),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(String format, String type, String startDate, String endDate) async {
    Navigator.of(context).pop(); // Close dialog

    try {
      if (format == 'csv') {
        await ref.read(exportNotifierProvider.notifier).exportCSV(
          reportType: type,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        // PDF export
        await ref.read(analyticsServiceProvider).exportPDF(
          reportType: type,
          startDate: startDate,
          endDate: endDate,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export completed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${e.toString()}')),
      );
    }
  }

  // Placeholder methods for new tabs - will be implemented with full functionality
  Widget _buildPredictionsTab() {
    return const Center(
      child: Text('Predictions tab - Coming soon with AI insights'),
    );
  }

  Widget _buildSegmentsTab() {
    return const Center(
      child: Text('Customer segments tab - Coming soon'),
    );
  }
}
