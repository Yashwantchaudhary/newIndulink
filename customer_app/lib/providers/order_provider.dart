import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/order_service.dart';

/// Order state
class OrderState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  OrderState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isEmpty => orders.isEmpty;
  bool get hasOrders => orders.isNotEmpty;
}

/// Order notifier
class OrderNotifier extends StateNotifier<OrderState> {
  final OrderService _orderService;

  OrderNotifier(this._orderService) : super(OrderState());

  /// Fetch orders
  Future<void> fetchOrders({bool loadMore = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = loadMore ? state.currentPage + 1 : 1;
      final newOrders = await _orderService.getOrders(page: page);

      state = state.copyWith(
        orders: loadMore ? [...state.orders, ...newOrders] : newOrders,
        isLoading: false,
        currentPage: page,
        hasMore: newOrders.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh orders
  Future<void> refresh() async {
    state = OrderState();
    await fetchOrders();
  }

  /// Load more orders
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await fetchOrders(loadMore: true);
  }

  /// Create order
  Future<Order?> createOrder({
    required ShippingAddress shippingAddress,
    required PaymentMethod paymentMethod,
    String? customerNote,
  }) async {
    try {
      final order = await _orderService.createOrder(
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        customerNote: customerNote,
      );

      // Add to list
      state = state.copyWith(
        orders: [order, ...state.orders],
      );

      return order;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final updatedOrder = await _orderService.cancelOrder(orderId, reason);

      // Update in list
      final updatedOrders = state.orders.map((order) {
        return order.id == orderId ? updatedOrder : order;
      }).toList();

      state = state.copyWith(orders: updatedOrders);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Order service provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref);
});

/// Order provider
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return OrderNotifier(orderService);
});

/// Single order provider
final orderDetailProvider =
    FutureProvider.family<Order?, String>((ref, orderId) async {
  try {
    final orderService = ref.watch(orderServiceProvider);
    return await orderService.getOrder(orderId);
  } catch (e) {
    return null;
  }
});
