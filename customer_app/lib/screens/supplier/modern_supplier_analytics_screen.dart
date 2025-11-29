import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../widgets/dashboard/chart_widgets.dart';

/// Modern Supplier Analytics Dashboard Screen
class ModernSupplierAnalyticsScreen extends ConsumerStatefulWidget {
  const ModernSupplierAnalyticsScreen({super.key});

  @override
  ConsumerState<ModernSupplierAnalyticsScreen> createState() =>
      _ModernSupplierAnalyticsScreenState();
}

class _ModernSupplierAnalyticsScreenState
    extends ConsumerState<ModernSupplierAnalyticsScreen> {
  String _selectedPeriod = '30 Days';
  final _periods = ['7 Days', '30 Days', '3 Months', 'Year'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: AppConstants.paddingAll20,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analytics & Insights',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your business performance',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _exportReport(),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: AppConstants.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),

                  // Revenue Overview
                  const SectionHeader(title: 'Revenue Overview', icon: Icons.trending_up),
                  const SizedBox(height: 12),
                  _buildRevenueOverview(isDark),
                  const SizedBox(height: 24),

                  // Revenue Chart
                  _buildRevenueChart(),
                  const SizedBox(height: 24),

                  // Top Products
                  const SectionHeader(title: 'Top Performing Products'),
                  const SizedBox(height: 12),
                  _buildTopProducts(isDark, theme),
                  const SizedBox(height: 24),

                  // Category Distribution
                  const SectionHeader(title: 'Sales by Category'),
                  const SizedBox(height: 12),
                  _buildCategoryChart(),
                  const SizedBox(height: 24),

                  // Customer Insights
                  const SectionHeader(title: 'Customer Insights'),
                  const SizedBox(height: 12),
                  _buildCustomerInsights(isDark),
                  const SizedBox(height: 24),

                  // Performance Metrics
                  const SectionHeader(title: 'Performance Metrics'),
                  const SizedBox(height: 12),
                  _buildPerformanceMetrics(isDark, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = _selectedPeriod == period;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedPeriod = period);
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

  Widget _buildRevenueOverview(bool isDark) {
    return const Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Total Revenue',
            value: 'Rs 245,000',
            icon: Icons.payments,
            iconColor: AppColors.primaryBlue,
            trend: '+12.5%',
            isPositiveTrend: true,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            title: 'Total Orders',
            value: '156',
            icon: Icons.shopping_bag,
            iconColor: AppColors.accentOrange,
            trend: '+8.3%',
            isPositiveTrend: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 280,
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusLarge,
      ),
      child: const RevenueChart(
        title: 'Weekly Revenue',
        data: [
          FlSpot(0, 35000),
          FlSpot(1, 42000),
          FlSpot(2, 38000),
          FlSpot(3, 45000),
          FlSpot(4, 52000),
          FlSpot(5, 48000),
          FlSpot(6, 40000),
        ],
        maxY: 55000,
        bottomTitles: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      ),
    );
  }

  Widget _buildTopProducts(bool isDark, ThemeData theme) {
    final products = [
      {'name': 'Portland Cement 50kg', 'sales': 'Rs 85,000', 'units': '850'},
      {'name': 'TMT Steel Bars', 'sales': 'Rs 62,000', 'units': '420'},
      {'name': 'Red Bricks (1000pcs)', 'sales': 'Rs 45,000', 'units': '180'},
      {'name': 'White Paint 20L', 'sales': 'Rs 32,000', 'units': '320'},
    ];

    return Column(
      children: products.map((product) {
        final index = products.indexOf(product);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: AppConstants.paddingAll16,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppConstants.borderRadiusMedium,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: _getRankGradient(index),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name']!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${product['units']} units sold',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                product['sales']!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChart() {
    return Container(
      height: 280,
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusLarge,
      ),
      child: CategoryPieChart(
        title: 'Sales by Category',
        data: [
          PieChartSectionData(
            value: 35,
            title: 'Cement',
            color: AppColors.primaryBlue,
          ),
          PieChartSectionData(
            value: 25,
            title: 'Steel',
            color: AppColors.accentOrange,
          ),
          PieChartSectionData(
            value: 18,
            title: 'Bricks',
            color: AppColors.success,
          ),
          PieChartSectionData(
            value: 13,
            title: 'Paint',
            color: AppColors.accentYellow,
          ),
          PieChartSectionData(
            value: 9,
            title: 'Others',
            color: AppColors.lightTextSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInsights(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'New Customers',
                '24',
                Icons.person_add,
                AppColors.success,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                'Repeat Rate',
                '68%',
                Icons.refresh,
                AppColors.primaryBlue,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Avg Order Value',
                'Rs 1,570',
                Icons.shopping_cart,
                AppColors.accentOrange,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                'Customer Satisfaction',
                '4.8',
                Icons.star,
                AppColors.accentYellow,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(bool isDark, ThemeData theme) {
    final metrics = [
      {'label': 'Conversion Rate', 'value': '3.2%', 'change': '+0.5%'},
      {'label': 'Average Response Time', 'value': '2.3h', 'change': '-0.8h'},
      {'label': 'Product Views', 'value': '12,450', 'change': '+15%'},
      {'label': 'Cart Abandonment', 'value': '28%', 'change': '-4%'},
    ];

    return Column(
      children: metrics.map((metric) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: AppConstants.paddingAll16,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  metric['label']!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                metric['value']!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: metric['change']!.startsWith('-')
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  metric['change']!,
                  style: TextStyle(
                    color: metric['change']!.startsWith('-')
                        ? AppColors.error
                        : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  LinearGradient _getRankGradient(int index) {
    switch (index) {
      case 0:
        return AppColors.primaryGradient;
      case 1:
        return AppColors.accentGradient;
      case 2:
        return AppColors.secondaryGradient;
      default:
        return AppColors.successGradient;
    }
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting analytics report...')),
    );
  }
}
