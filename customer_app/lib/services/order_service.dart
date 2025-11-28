import 'package:dio/dio.dart';
import '../models/order.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Order service for API communication
class OrderService {
  final Dio _dio;
  final Ref _ref;

  OrderService(this._ref)
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  /// Get authentication token
  String? _getToken() {
    final authState = _ref.read(authProvider);
    return authState.token;
  }

  /// Create order from cart
  Future<Order> createOrder({
    required ShippingAddress shippingAddress,
    required PaymentMethod paymentMethod,
    String? customerNote,
  }) async {
    try {
      final token = _getToken();

      final response = await _dio.post(
        '/orders',
        data: {
          'shippingAddress': shippingAddress.toJson(),
          'paymentMethod': paymentMethod.toServerString(),
          if (customerNote != null) 'customerNote': customerNote,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Order.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to create order');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all orders for current user
  Future<List<Order>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final token = _getToken();

      final response = await _dio.get(
        '/orders',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final orders = (response.data['data'] as List)
            .map((json) => Order.fromJson(json))
            .toList();
        return orders;
      } else {
        throw Exception('Failed to load orders');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single order by ID
  Future<Order> getOrder(String orderId) async {
    try {
      final token = _getToken();

      final response = await _dio.get(
        '/orders/$orderId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Order.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to load order');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel order
  Future<Order> cancelOrder(String orderId, String reason) async {
    try {
      final token = _getToken();

      final response = await _dio.patch(
        '/orders/$orderId/cancel',
        data: {'cancellationReason': reason},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Order.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to cancel order');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get supplier orders
  Future<List<Order>> getSupplierOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final token = _getToken();

      final response = await _dio.get(
        '/orders/supplier',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final orders = (response.data['data'] as List)
            .map((json) => Order.fromJson(json))
            .toList();
        return orders;
      } else {
        throw Exception('Failed to load supplier orders');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update order status (supplier)
  Future<Order> updateOrderStatus(
    String orderId,
    String status, {
    String? trackingNumber,
    String? supplierNote,
  }) async {
    try {
      final token = _getToken();

      final response = await _dio.put(
        '/orders/$orderId/status',
        data: {
          'status': status,
          if (trackingNumber != null) 'trackingNumber': trackingNumber,
          if (supplierNote != null) 'supplierNote': supplierNote,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Order.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to update order status');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle errors
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Server error: ${error.response!.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please try again.';
    } else if (error.type == DioExceptionType.unknown) {
      return 'Network error. Please check your connection.';
    }
    return 'An unexpected error occurred';
  }
}
