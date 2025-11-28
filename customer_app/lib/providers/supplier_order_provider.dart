import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_provider.dart';

/// Supplier Order state
class SupplierOrderState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  SupplierOrderState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  SupplierOrderState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return SupplierOrderState(
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

/// Supplier Order notifier
class SupplierOrderNotifier extends StateNotifier<SupplierOrderState> {
  final OrderService _orderService;

  SupplierOrderNotifier(this._orderService) : super(SupplierOrderState());

  /// Fetch supplier orders
  Future<void> fetchOrders({bool loadMore = false, String? status}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = loadMore ? state.currentPage + 1 : 1;
      final newOrders = await _orderService.getSupplierOrders(
        page: page,
        status: status,
      );

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
  Future<void> refresh({String? status}) async {
    state = SupplierOrderState();
    await fetchOrders(status: status);
  }

  /// Load more orders
  Future<void> loadMore({String? status}) async {
    if (!state.hasMore || state.isLoading) return;
    await fetchOrders(loadMore: true, status: status);
  }

  /// Update order status
  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? trackingNumber,
    String? supplierNote,
  }) async {
    try {
      final updatedOrder = await _orderService.updateOrderStatus(
        orderId,
        status,
        trackingNumber: trackingNumber,
        supplierNote: supplierNote,
      );

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

/// Supplier Order provider
final supplierOrderProvider =
    StateNotifierProvider<SupplierOrderNotifier, SupplierOrderState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return SupplierOrderNotifier(orderService);
});
