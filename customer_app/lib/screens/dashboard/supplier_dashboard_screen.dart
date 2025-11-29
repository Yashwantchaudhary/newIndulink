import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../widgets/dashboard/chart_widgets.dart';
import 'package:fl_chart/fl_chart.dart';

/// Redesigned Production-Level Supplier Dashboard
/// Features: Analytics, stats, charts, quick actions, recent orders
class SupplierDashboardScreenNew extends ConsumerStatefulWidget {
  const SupplierDashboardScreenNew({super.key});

  @override
  ConsumerState<SupplierDashboardScreenNew> createState() =>
      _SupplierDashboardScreenNewState();
}

class _SupplierDashboardScreenNewState
    extends ConsumerState<SupplierDashboardScreenNew> {
  final String _selectedPeriod = '7Days';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(supplierDashboardProvider.notifier).fetchDashboard();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(supplierDashboardProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dashboardState = ref.watch(supplierDashboardProvider);
    final authState = ref.watch(authProvider);
    final businessName = authState.user?.businessName ?? 'Your Business';
    final userName = authState.user?.firstName ?? 'Supplier';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // App Bar with Gradient
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Text(
                                  userName[0].toUpperCase(),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacing12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, $userName',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    Text(
                                      businessName,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverList(
              delegate: SliverChildListDelegate([
                if (dashboardState.isLoading && dashboardState.data == null)
                  _buildLoadingState()
                else if (dashboardState.data != null)
                  _buildDashboardContent(dashboardState.data!)
                else if (dashboardState.error != null)
                  _buildErrorState(dashboardState.error!),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: AppConstants.paddingAll16,
      child: Column(
        children: [
          Row(
            children: List.generate(
              2,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == 0 ? AppConstants.spacing12 : 0,
                  ),
                  child: const LoadingShimmer(
                    width: double.infinity,
                    height: AppConstants.statCardHeight,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacing12),
          Row(
            children: List.generate(
              2,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == 0 ? AppConstants.spacing12 : 0,
                  ),
                  child: const LoadingShimmer(
                    width: double.infinity,
                    height: AppConstants.statCardHeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Error Loading Dashboard',
      message: error,
      actionText: 'Retry',
      onAction: _onRefresh,
    );
  }

  Widget _buildDashboardContent(dynamic data) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');
    final revenue = data.revenue;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Stats Cards
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Total Revenue',
                  value: currencyFormat.format(revenue.totalRevenue),
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.accentGreen,
                  trend: revenue.growthPercentage != null
                      ? '${revenue.growthPercentage!.toStringAsFixed(1)}%'
                      : null,
                  isPositiveTrend: revenue.growthPercentage != null && revenue.growthPercentage! > 0,
                  subtitle: 'This month',
                ),
              ),
              const SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: StatsCard(
                  title: 'Total Orders',
                  value: revenue.totalOrders.toString(),
                  icon: Icons.shopping_bag_rounded,
                  iconColor: AppColors.primaryBlue,
                  subtitle: '${_getOrderCountByStatus(data.ordersByStatus, 'pending')} pending',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacing12),

          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Avg Order Value',
                  value: currencyFormat.format(revenue.averageOrderValue),
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.secondaryPurple,
                ),
              ),
              const SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: StatsCard(
                  title: 'Total Products',
                  value: data.productStats.totalProducts.toString(),
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppColors.accentOrange,
                  subtitle: '${data.productStats.activeProducts} active',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacing24),

          // Quick Actions
          const SectionHeader(
            title: 'Quick Actions',
            icon: Icons.bolt,
          ),
          const SizedBox(height: AppConstants.spacing12),
          _buildQuickActions(),

          const SizedBox(height: AppConstants.spacing24),

          // Revenue Chart
          const SectionHeader(
            title: 'Sales Analytics',
            subtitle: 'Last 7 days performance',
          ),
          const SizedBox(height: AppConstants.spacing12),
          RevenueChart(
            data: _convertRevenueData(data.revenueOverTime),
            title: '',
            maxY: _calculateMaxY(data.revenueOverTime),
            bottomTitles: _getBottomTitles(data.revenueOverTime),
          ),

          const SizedBox(height: AppConstants.spacing24),

          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInventoryStatus(data.productStats),
              ),
              const SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: _buildOrderStatusCard(data.ordersByStatus),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacing24),

          // Recent Orders
          SectionHeader(
            title: 'Recent Orders',
            actionText: 'View All',
            onSeeAll: () {
              // Navigate to orders screen
            },
          ),
          const SizedBox(height: AppConstants.spacing12),

          if (data.recentOrders.isEmpty)
            const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No Orders Yet',
              message: 'Orders will appear here when customers place them',
            )
          else
            ...data.recentOrders
                .take(5)
                .map((order) => _buildRecentOrderCard(order))
                .toList(),

          const SizedBox(height: AppConstants.spacing32),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.add_business,
        label: 'Add Product',
        color: AppColors.primaryBlue,
        gradient: AppColors.primaryGradient,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Product screen coming soon')),
          );
        },
      ),
      _QuickAction(
        icon: Icons.shopping_bag_outlined,
        label: 'View Orders',
        color: AppColors.secondaryPurple,
        gradient: AppColors.secondaryGradient,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.inventory,
        label: 'Manage Inventory',
        color: AppColors.accentOrange,
        gradient: AppColors.accentGradient,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.analytics,
        label: 'Analytics',
        color: AppColors.accentCyan,
        gradient: AppColors.cyanBlueGradient,
        onTap: () {
          Navigator.of(context).pushNamed('/analytics');
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.spacing12,
        mainAxisSpacing: AppConstants.spacing12,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GradientCard(
          gradient: action.gradient,
          onTap: action.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: AppConstants.spacing8),
              Text(
                action.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryStatus(dynamic productStats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacing16),
          _buildInventoryRow(
            'In Stock',
            productStats.activeProducts,
            Icons.check_circle,
            AppColors.success,
          ),
          const SizedBox(height: AppConstants.spacing12),
          _buildInventoryRow(
            'Low Stock',
            productStats.lowStock,
            Icons.warning,
            AppColors.warning,
          ),
          const SizedBox(height: AppConstants.spacing12),
          _buildInventoryRow(
            'Out of Stock',
            productStats.outOfStock,
            Icons.cancel,
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(String label, int value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppConstants.borderRadiusSmall,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusCard(List<dynamic> ordersByStatus) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get order counts by status
    final pending = _getOrderCountByStatus(ordersByStatus, 'pending');
    final processing = _getOrderCountByStatus(ordersByStatus, 'processing');
    final delivered = _getOrderCountByStatus(ordersByStatus, 'delivered');

    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacing16),
          _buildInventoryRow(
            'Pending',
            pending,
            Icons.pending_actions,
            AppColors.statusPending,
          ),
          const SizedBox(height: AppConstants.spacing12),
          _buildInventoryRow(
            'Processing',
            processing,
            Icons.loop,
            AppColors.statusProcessing,
          ),
          const SizedBox(height: AppConstants.spacing12),
          _buildInventoryRow(
            'Delivered',
            delivered,
            Icons.check_circle,
            AppColors.statusDelivered,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrderCard(dynamic order) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');
    final dateFormat = DateFormat('MMM dd, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
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
              const SizedBox(width: AppConstants.spacing12),
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
                      order.customerName ?? 'Customer',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: order.status, isSmall: true),
            ],
          ),
          const SizedBox(height: AppConstants.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                dateFormat.format(order.createdAt),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                currencyFormat.format(order.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<FlSpot> _convertRevenueData(List<dynamic> revenueOverTime) {
    return revenueOverTime
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              (entry.value['revenue'] as num).toDouble(),
            ))
        .toList();
  }

  double _calculateMaxY(List<dynamic> revenueOverTime) {
    if (revenueOverTime.isEmpty) return 100;
    final maxRevenue = revenueOverTime
        .map((e) => (e['revenue'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return (maxRevenue * 1.2).ceilToDouble();
  }

  List<String> _getBottomTitles(List<dynamic> revenueOverTime) {
    return revenueOverTime
        .map((e) {
          final date = DateTime.parse(e['date'] as String);
          return DateFormat('MMM dd').format(date);
        })
        .toList();
  }

  /// Safely parse dynamic value to integer
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// Get order count by status from the list
  int _getOrderCountByStatus(List<dynamic> ordersByStatus, String status) {
    try {
      final statusData = ordersByStatus.firstWhere(
        (element) => element.status == status,
        orElse: () => null,
      );
      return statusData?.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildNavigationDrawer(String userRole) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      userName[0].toUpperCase(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    businessName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.inventory,
                  title: 'My Products',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupplierProductsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag,
                  title: 'Orders',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupplierOrdersScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory_2,
                  title: 'Inventory',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to inventory screen
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModernSupplierAnalyticsScreen(),
                      ),
                    );
                  },
                ),
                if (userRole == 'admin') ...[
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings,
                    title: 'User Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserManagementScreen(),
                        ),
                      );
                    },
                  ),
                ],
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to settings
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to help
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    // Handle logout
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primaryBlue,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isDark ? Colors.white : AppColors.darkText,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final LinearGradient gradient;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.onTap,
  });
}
