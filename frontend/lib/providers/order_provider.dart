import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/order_service.dart';

/// 📦 Order Provider
/// Manages order state
class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  // State
  List<Order> _orders = [];
  Order? _selectedOrder;
  OrderStatus? _filterStatus;

  bool _isLoading = false;
  bool _isCreatingOrder = false;
  String? _errorMessage;

  // Getters
  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  OrderStatus? get filterStatus => _filterStatus;
  bool get isLoading => _isLoading;
  bool get isCreatingOrder => _isCreatingOrder;
  String? get errorMessage => _errorMessage;

  /// Get filtered orders
  List<Order> get filteredOrders {
    if (_filterStatus == null) {
      return _orders;
    }
    return _orders.where((order) => order.status == _filterStatus).toList();
  }

  /// Get pending orders count
  int get pendingOrdersCount {
    return _orders.where((order) => order.status == OrderStatus.pending).length;
  }

  /// Fetch all orders
  Future<void> fetchOrders({OrderStatus? status}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _orderService.getOrders(status: status);

      if (result.success) {
        _orders = result.orders;
      } else {
        _setError(result.message ?? 'Failed to load orders');
      }
    } catch (e) {
      _setError('An error occurred');
    }

    _setLoading(false);
  }

  /// Create new order
  Future<Order?> createOrder({
    required Address shippingAddress,
    required String paymentMethod,
    String? notes,
    String? couponCode,
  }) async {
    _isCreatingOrder = true;
    _clearError();
    notifyListeners();

    try {
      final result = await _orderService.createOrder(
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        notes: notes,
        couponCode: couponCode,
      );

      if (result.success && result.order != null) {
        _orders.insert(0, result.order!);
        _isCreatingOrder = false;
        notifyListeners();
        return result.order;
      } else {
        _setError(result.message ?? 'Failed to create order');
        _isCreatingOrder = false;
        return null;
      }
    } catch (e) {
      _setError('An error occurred');
      _isCreatingOrder = false;
      return null;
    }
  }

  /// Get order details
  Future<void> fetchOrderDetails(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _orderService.getOrderDetails(orderId);

      if (result.success && result.order != null) {
        _selectedOrder = result.order;
      } else {
        _setError(result.message ?? 'Order not found');
      }
    } catch (e) {
      _setError('An error occurred');
    }

    _setLoading(false);
  }

  /// Update order status (supplier/admin only)
  Future<bool> updateOrderStatus(String orderId, OrderStatus status, {String? notes}) async {
    _clearError();

    try {
      final result = await _orderService.updateOrderStatus(
        orderId: orderId,
        status: status,
        notes: notes,
      );

      if (result.success) {
        // Update local state
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1 && result.order != null) {
          _orders[index] = result.order!;
        }

        if (_selectedOrder?.id == orderId && result.order != null) {
          _selectedOrder = result.order;
        }

        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Failed to update order status');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      return false;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId) async {
    _clearError();

    try {
      final result = await _orderService.cancelOrder(orderId);

      if (result.success) {
        // Update local state
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1 && result.order != null) {
          _orders[index] = result.order!;
        }

        if (_selectedOrder?.id == orderId && result.order != null) {
          _selectedOrder = result.order;
        }

        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Failed to cancel order');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      return false;
    }
  }

  /// Track order
  Future<OrderTrackingResult?> trackOrder(String orderId) async {
    _clearError();

    try {
      final result = await _orderService.trackOrder(orderId);

      if (result.success) {
        return result;
      } else {
        _setError(result.message ?? 'Failed to track order');
        return null;
      }
    } catch (e) {
      _setError('An error occurred');
      return null;
    }
  }

  /// Set filter status
  void setFilterStatus(OrderStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  /// Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  /// Refresh orders
  Future<void> refresh() async {
    await fetchOrders(status: _filterStatus);
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
