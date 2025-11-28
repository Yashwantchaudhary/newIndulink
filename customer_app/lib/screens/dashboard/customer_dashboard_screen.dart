import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/common/custom_badge.dart';
import '../../widgets/common/shimmer_widgets.dart';
import '../../widgets/common/empty_state.dart';
import '../../l10n/app_localizations.dart';
import '../../routes.dart';

/// Customer Dashboard Screen showing orders, stats, and recommendations
class CustomerDashboardScreen extends ConsumerStatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  ConsumerState<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState
    extends ConsumerState<CustomerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch dashboard data on init
    Future.microtask(() {
      ref.read(customerDashboardProvider.notifier).fetchDashboard();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(customerDashboardProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dashboardState = ref.watch(customerDashboardProvider);
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);
    final userName = authState.user?.firstName ?? l10n.customer;

    // Handle auth loading/error states
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppRoutes.navigateToAndReplace(context, AppRoutes.login);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.hello}, $userName!',
              style: theme.textTheme.titleLarge,
            ),
            Text(
              l10n.welcomeBack,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeState.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notifications feature coming soon')),
              );
            },
          ),
          const SizedBox(width: AppConstants.spacing8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: dashboardState.isLoading && dashboardState.data == null
            ? _buildLoadingState()
            : dashboardState.error != null && dashboardState.data == null
                ? _buildErrorState(dashboardState.error!)
                : _buildDashboard(context, dashboardState),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: AppConstants.paddingPage,
      children: [
        const SizedBox(height: AppConstants.spacing16),
        // Stats shimmer
        Row(
          children: [
            Expanded(child: ShimmerWidgets.statCard(context)),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(child: ShimmerWidgets.statCard(context)),
          ],
        ),
        const SizedBox(height: AppConstants.spacing12),
        Row(
          children: [
            Expanded(child: ShimmerWidgets.statCard(context)),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(child: ShimmerWidgets.statCard(context)),
          ],
        ),
        const SizedBox(height: AppConstants.spacing24),
        // Orders shimmer
        ...List.generate(3, (_) => ShimmerWidgets.orderCard(context)),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return ListView(
      padding: AppConstants.paddingPage,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Oops! Something went wrong',
          subtitle: error,
          buttonText: 'Retry',
          onButtonPressed: _onRefresh,
          iconColor: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context, CustomerDashboardState state) {
    final l10n = AppLocalizations.of(context);
    final data = state.data;
    if (data == null) {
      return _buildErrorState('No dashboard data available');
    }

    final stats = data.stats;
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');

    return ListView(
      padding: AppConstants.paddingPage,
      children: [
        const SizedBox(height: AppConstants.spacing16),

        // Statistics Cards
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.totalOrders,
                value: stats.totalOrders.toString(),
                icon: Icons.shopping_bag_outlined,
                iconColor: AppColors.primaryBlue,
                isLoading: state.isLoading,
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: StatCard(
                title: l10n.totalSpent,
                value: currencyFormat.format(stats.totalSpent),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.accentGreen,
                isLoading: state.isLoading,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacing12),

        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.delivered,
                value: stats.deliveredOrders.toString(),
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
                gradient: AppColors.successGradient,
                isLoading: state.isLoading,
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: StatCard(
                title: l10n.pending,
                value: stats.pendingOrders.toString(),
                icon: Icons.pending_outlined,
                iconColor: AppColors.warning,
                isLoading: state.isLoading,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacing32),

        // Active Orders Section
        if (data.activeOrders.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.activeOrders,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () =>
                    AppRoutes.navigateTo(context, AppRoutes.ordersList),
                child: Text(l10n.seeAll),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.activeOrders.length,
              itemBuilder: (context, index) {
                return _buildActiveOrderCard(data.activeOrders[index]);
              },
            ),
          ),
          const SizedBox(height: AppConstants.spacing32),
        ],

        // Recent Orders Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentOrders,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () =>
                  AppRoutes.navigateTo(context, AppRoutes.ordersList),
              child: Text(l10n.viewAll),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacing12),

        if (data.recentOrders.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: l10n.noData,
            subtitle: l10n.noResults,
            buttonText: l10n.browseProducts,
            onButtonPressed: () =>
                AppRoutes.navigateTo(context, AppRoutes.enhancedHome),
          )
        else
          ...data.recentOrders.map((order) => _buildOrderCard(order)),

        const SizedBox(height: AppConstants.spacing32),
      ],
    ).animate().fadeIn(duration: AppConstants.durationNormal);
  }

  Widget _buildActiveOrderCard(order) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: AppConstants.spacing12),
      child: Card(
        child: Padding(
          padding: AppConstants.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CustomBadge.status(order.status, small: true),
                ],
              ),
              const SizedBox(height: AppConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(order.total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => AppRoutes.navigateTo(
                          context, AppRoutes.orderDetail,
                          arguments: order.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.spacing8,
                        ),
                      ),
                      child: Text(l10n.trackOrder),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  Widget _buildOrderCard(order) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: InkWell(
        onTap: () => AppRoutes.navigateTo(context, AppRoutes.orderDetail,
            arguments: order.id),
        borderRadius: AppConstants.borderRadiusMedium,
        child: Padding(
          padding: AppConstants.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.orderNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  CustomBadge.status(order.status, small: true),
                ],
              ),
              const SizedBox(height: AppConstants.spacing12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
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
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
