import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

/// Admin Service for all admin operations
class AdminService {
  final AuthService _authService;

  AdminService(this._authService);

  // Helper to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== USER MANAGEMENT ====================

  /// Get all users with pagination and filters
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? role,
    bool? isActive,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (role != null) 'role': role,
      if (isActive != null) 'isActive': isActive.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  /// Get user details by ID
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/users/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user details: ${response.body}');
    }
  }

  /// Create new user
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/users'),
      headers: await _getHeaders(),
      body: json.encode(userData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  /// Update user
  Future<Map<String, dynamic>> updateUser(
      String userId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/users/$userId'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  /// Delete user (soft delete)
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/users/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  /// Toggle user active status
  Future<Map<String, dynamic>> toggleUserStatus(String userId) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/users/$userId/toggle-status'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to toggle user status: ${response.body}');
    }
  }

  // ==================== PRODUCT MANAGEMENT ====================

  /// Get all products with admin filters
  Future<Map<String, dynamic>> getAllProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? supplier,
    String? status,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (category != null) 'category': category,
      if (supplier != null) 'supplier': supplier,
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/products')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }

  /// Approve product
  Future<Map<String, dynamic>> approveProduct(String productId) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/products/$productId/approve'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to approve product: ${response.body}');
    }
  }

  /// Feature/unfeature product
  Future<Map<String, dynamic>> featureProduct(
      String productId, bool isFeatured) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/products/$productId/feature'),
      headers: await _getHeaders(),
      body: json.encode({'isFeatured': isFeatured}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to feature product: ${response.body}');
    }
  }

  /// Bulk product update
  Future<Map<String, dynamic>> bulkProductUpdate(
    List<String> productIds,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/products/bulk-update'),
      headers: await _getHeaders(),
      body: json.encode({
        'productIds': productIds,
        'updates': updates,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to bulk update products: ${response.body}');
    }
  }

  // ==================== ORDER MANAGEMENT ====================

  /// Get all orders
  Future<Map<String, dynamic>> getAllOrders({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/orders')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load orders: ${response.body}');
    }
  }

  /// Get order analytics
  Future<Map<String, dynamic>> getOrderAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = {
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/orders/analytics')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load order analytics: ${response.body}');
    }
  }

  /// Update order status
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status, {
    String? note,
  }) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/orders/$orderId/status'),
      headers: await _getHeaders(),
      body: json.encode({
        'status': status,
        if (note != null) 'note': note,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update order status: ${response.body}');
    }
  }

  // ==================== SUPPLIER MANAGEMENT ====================

  /// Get all suppliers with metrics
  Future<Map<String, dynamic>> getAllSuppliers({
    int page = 1,
    int limit = 20,
    bool? isActive,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (isActive != null) 'isActive': isActive.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/suppliers')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load suppliers: ${response.body}');
    }
  }

  /// Approve supplier
  Future<Map<String, dynamic>> approveSupplier(String supplierId) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/suppliers/$supplierId/approve'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to approve supplier: ${response.body}');
    }
  }

  /// Suspend supplier
  Future<Map<String, dynamic>> suspendSupplier(String supplierId) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/suppliers/$supplierId/suspend'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to suspend supplier: ${response.body}');
    }
  }

  // ==================== SYSTEM STATS ====================

  /// Get system statistics
  Future<Map<String, dynamic>> getSystemStats() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/admin/stats'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load system stats: ${response.body}');
    }
  }
}
