import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_constants.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order/order_card.dart';
import 'order_detail_screen.dart';

/// Orders list screen
class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch orders on init
    Future.microtask(() => ref.read(orderProvider.notifier).fetchOrders());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderState = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: orderState.isLoading && orderState.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : orderState.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => ref.read(orderProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppConstants.spacing16,
                      bottom: AppConstants.spacing16,
                    ),
                    itemCount:
                        orderState.orders.length + (orderState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == orderState.orders.length) {
                        // Load more indicator
                        if (!orderState.isLoading) {
                          Future.microtask(() =>
                              ref.read(orderProvider.notifier).loadMore());
                        }
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final order = orderState.orders[index];
                      return OrderCard(
                        order: order,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailScreen(orderId: order.id),
                            ),
                          );
                        },
                      )
                          .animate()
                          .fadeIn(duration: AppConstants.durationNormal)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: AppConstants.durationNormal,
                            delay: Duration(milliseconds: index * 50),
                          );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppConstants.paddingPage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: AppConstants.spacing24),
            Text(
              'No Orders Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              'Your order history will appear here',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}
