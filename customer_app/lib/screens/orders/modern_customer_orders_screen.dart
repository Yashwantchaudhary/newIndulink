import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';

/// Modern Customer Orders Screen with enhanced UI
class ModernCustomerOrdersScreen extends ConsumerStatefulWidget {
  const ModernCustomerOrdersScreen({super.key});

  @override
  ConsumerState<ModernCustomerOrdersScreen> createState() =>
      _ModernCustomerOrdersScreenState();
}

class _ModernCustomerOrdersScreenState
    extends ConsumerState<ModernCustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
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
                            'My Orders',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track and manage your orders',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersList('all'),
            _buildOrdersList('active'),
            _buildOrdersList('completed'),
            _buildOrdersList('cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(String filter) {
    // Mock data
    final orders = List.generate(
      10,
      (index) => _MockOrder(
        id: 'ORD-${2000 + index}',
        status: ['pending', 'processing', 'shipped', 'delivered'][index % 4],
        items: 2 + (index % 3),
        total: 5000 + (index * 750),
        date: DateTime.now().subtract(Duration(days: index * 2)),
        estimatedDelivery: DateTime.now().add(Duration(days: 3 + (index % 5))),
      ),
    );

    if (orders.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.shopping_bag_outlined,
        title: 'No Orders Found',
        message: 'You haven\'t placed any orders yet',
        actionText: 'Browse Products',
        onAction: () {},
      );
    }

    return ListView.builder(
      padding: AppConstants.paddingAll16,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildModernOrderCard(orders[index]);
      },
    );
  }

  Widget _buildModernOrderCard(_MockOrder order) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkSurface,
                  AppColors.darkSurface.withValues(alpha: 0.95),
                ]
              : [
                  AppColors.lightSurface,
                  AppColors.lightSurface.withValues(alpha: 0.98),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppConstants.borderRadiusLarge,
        border: Border.all(
          color: _getStatusColor(order.status).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(order.status).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(order),
          borderRadius: AppConstants.borderRadiusLarge,
          child: Padding(
            padding: AppConstants.paddingAll16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(order.status),
                            _getStatusColor(order.status)
                                .withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: AppConstants.borderRadiusSmall,
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(order.status)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.id,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormat.format(order.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: order.status, isSmall: false),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Indicator
                if (order.status != 'cancelled' && order.status != 'delivered')
                  Container(
                    padding: AppConstants.paddingAll12,
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(order.status).withValues(alpha: 0.1),
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: _getStatusColor(order.status),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Estimated delivery: ${dateFormat.format(order.estimatedDelivery)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Order Info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.inventory_2_outlined,
                        '${order.items} items',
                        theme,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.payments_outlined,
                        'Rs ${order.total.toStringAsFixed(0)}',
                        theme,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showOrderDetails(order),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (order.status == 'delivered')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.rate_review, size: 18),
                          label: const Text('Review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        borderRadius: AppConstants.borderRadiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.statusPending;
      case 'processing':
        return AppColors.statusProcessing;
      case 'shipped':
        return AppColors.statusShipped;
      case 'delivered':
        return AppColors.statusDelivered;
      case 'cancelled':
        return AppColors.statusCancelled;
      default:
        return AppColors.primaryBlue;
    }
  }

  void _showOrderDetails(_MockOrder order) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightTextTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: AppConstants.paddingH20,
              child: Row(
                children: [
                  Text(
                    'Order Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Order Tracking Timeline
            Expanded(
              child: SingleChildScrollView(
                padding: AppConstants.paddingAll20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildOrderTimeline(order, theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline(_MockOrder order, ThemeData theme) {
    final stages = [
      _TimelineStage('Order Placed', 'Your order has been confirmed', true),
      _TimelineStage(
          'Processing', 'Preparing your items', order.status != 'pending'),
      _TimelineStage('Shipped', 'Order is on the way',
          order.status == 'shipped' || order.status == 'delivered'),
      _TimelineStage('Delivered', 'Order delivered successfully',
          order.status == 'delivered'),
    ];

    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isLast = index == stages.length - 1;

        return TimelineTile(
          isFirst: index == 0,
          isLast: isLast,
          beforeLineStyle: LineStyle(
            color: stage.isCompleted
                ? AppColors.success
                : AppColors.lightTextTertiary,
            thickness: 2,
          ),
          indicatorStyle: IndicatorStyle(
            width: 40,
            height: 40,
            indicator: Container(
              decoration: BoxDecoration(
                color: stage.isCompleted ? AppColors.success : Colors.grey,
                shape: BoxShape.circle,
                boxShadow: stage.isCompleted
                    ? [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                stage.isCompleted ? Icons.check : Icons.circle,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          endChild: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        stage.isCompleted ? null : AppColors.lightTextTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MockOrder {
  final String id;
  final String status;
  final int items;
  final double total;
  final DateTime date;
  final DateTime estimatedDelivery;

  _MockOrder({
    required this.id,
    required this.status,
    required this.items,
    required this.total,
    required this.date,
    required this.estimatedDelivery,
  });
}

class _TimelineStage {
  final String title;
  final String description;
  final bool isCompleted;

  _TimelineStage(this.title, this.description, this.isCompleted);
}
