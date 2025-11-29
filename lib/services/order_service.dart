import '../core/constants/app_config.dart';
import '../models/order.dart';
import '../models/user.dart';
import 'api_service.dart';

/// 📦 Order Service
/// Handles order management operations
class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final ApiService _api = ApiService();

  // =================== Order Operations ====================

  /// Create new order
  Future<OrderResult> createOrder({
    required Address shippingAddress,
    required String paymentMethod,
    String? notes,
    String? couponCode,
  }) async {
    try {
      final response = await _api.post(
        AppConfig.createOrderEndpoint,
        body: {
          'shippingAddress': shippingAddress.toJson(),
          'paymentMethod': paymentMethod,
          if (notes != null) 'notes': notes,
          if (couponCode != null) 'couponCode': couponCode,
        },
      );

      if (response.isSuccess && response.data != null) {
        final order = Order.fromJson(response.data);

        return OrderResult(
          success: true,
          order: order,
          message: 'Order placed successfully',
        );
      } else {
        return OrderResult(
          success: false,
          message: response.message ?? 'Failed to create order',
        );
      }
    } catch (e) {
      return OrderResult(
        success: false,
        message: 'An error occurred while creating order',
      );
    }
  }

  /// Get all orders for current user
  Future<OrderListResult> getOrders({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        params['status'] = status.value;
      }

      final response = await _api.get(
        AppConfig.ordersEndpoint,
        params: params,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final ordersJson = data['orders'] ?? data['data'] ?? [];
        final orders =
            (ordersJson as List).map((json) => Order.fromJson(json)).toList();

        return OrderListResult(
          success: true,
          orders: orders,
          total: data['total'] ?? orders.length,
        );
      } else {
        return OrderListResult(
          success: false,
          message: response.message ?? 'Failed to fetch orders',
        );
      }
    } catch (e) {
      return OrderListResult(
        success: false,
        message: 'An error occurred while fetching orders',
      );
    }
  }

  /// Get order details by ID
  Future<OrderResult> getOrderDetails(String orderId) async {
    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.orderDetailsEndpoint,
        {'id': orderId},
      );

      final response = await _api.get(endpoint);

      if (response.isSuccess && response.data != null) {
        final order = Order.fromJson(response.data);

        return OrderResult(
          success: true,
          order: order,
        );
      } else {
        return OrderResult(
          success: false,
          message: response.message ?? 'Order not found',
        );
      }
    } catch (e) {
      return OrderResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Cancel order
  Future<OrderResult> cancelOrder(String orderId) async {
    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.cancelOrderEndpoint,
        {'id': orderId},
      );

      final response = await _api.put(endpoint);

      if (response.isSuccess) {
        final order =
            response.data != null ? Order.fromJson(response.data) : null;

        return OrderResult(
          success: true,
          order: order,
          message: 'Order cancelled successfully',
        );
      } else {
        return OrderResult(
          success: false,
          message: response.message ?? 'Failed to cancel order',
        );
      }
    } catch (e) {
      return OrderResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Track order
  Future<OrderTrackingResult> trackOrder(String orderId) async {
    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.trackOrderEndpoint,
        {'id': orderId},
      );

      final response = await _api.get(endpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data;

        return OrderTrackingResult(
          success: true,
          status: OrderStatus.fromString(data['status'] ?? 'pending'),
          statusHistory: data['statusHistory'] != null
              ? (data['statusHistory'] as List)
                  .map((e) => OrderStatusHistory.fromJson(e))
                  .toList()
              : [],
          trackingNumber: data['trackingNumber'],
          estimatedDelivery: data['estimatedDelivery'] != null
              ? DateTime.parse(data['estimatedDelivery'])
              : null,
        );
      } else {
        return OrderTrackingResult(
          success: false,
          message: response.message ?? 'Failed to track order',
        );
      }
    } catch (e) {
      return OrderTrackingResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  // ==================== Supplier Order Management ====================

  /// Get orders for supplier (supplier role only)
  Future<OrderListResult> getSupplierOrders({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        params['status'] = status.value;
      }

      final response = await _api.get(
        AppConfig.supplierOrdersEndpoint,
        params: params,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final ordersJson = data['orders'] ?? [];
        final orders =
            (ordersJson as List).map((json) => Order.fromJson(json)).toList();

        return OrderListResult(
          success: true,
          orders: orders,
          total: data['total'] ?? orders.length,
        );
      } else {
        return OrderListResult(
          success: false,
          message: response.message ?? 'Failed to fetch orders',
        );
      }
    } catch (e) {
      return OrderListResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Update order status (supplier/admin only)
  Future<OrderResult> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? notes,
  }) async {
    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.updateOrderStatusEndpoint,
        {'id': orderId},
      );

      final response = await _api.put(
        endpoint,
        body: {
          'status': status.value,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.isSuccess) {
        final order =
            response.data != null ? Order.fromJson(response.data) : null;

        return OrderResult(
          success: true,
          order: order,
          message: 'Order status updated',
        );
      } else {
        return OrderResult(
          success: false,
          message: response.message ?? 'Failed to update order status',
        );
      }
    } catch (e) {
      return OrderResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }
}

/// 📋 Order Result Model
class OrderResult {
  final bool success;
  final String? message;
  final Order? order;

  OrderResult({
    required this.success,
    this.message,
    this.order,
  });
}

/// 📋 Order List Result
class OrderListResult {
  final bool success;
  final String? message;
  final List<Order> orders;
  final int? total;

  OrderListResult({
    required this.success,
    this.message,
    this.orders = const [],
    this.total,
  });
}

/// 📋 Order Tracking Result
class OrderTrackingResult {
  final bool success;
  final String? message;
  final OrderStatus? status;
  final List<OrderStatusHistory> statusHistory;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;

  OrderTrackingResult({
    required this.success,
    this.message,
    this.status,
    this.statusHistory = const [],
    this.trackingNumber,
    this.estimatedDelivery,
  });
}
