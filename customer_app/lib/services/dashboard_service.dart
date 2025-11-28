import 'dart:developer' as developer;
import '../models/dashboard_models.dart';
import 'api_service.dart';

/// Dashboard API service for fetching analytics and stats
/// Uses ApiService which automatically handles JWT token injection
class DashboardService {
  final ApiService _apiService;

  DashboardService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get customer dashboard data
  Future<CustomerDashboardData> getCustomerDashboard() async {
    try {
      developer.log('Fetching customer dashboard data...',
          name: 'DashboardService');

      final response = await _apiService.get('/dashboard/customer');

      if (response.statusCode == 200 && response.data['success'] == true) {
        developer.log('Customer dashboard data fetched successfully',
            name: 'DashboardService');
        return CustomerDashboardData.fromJson(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      developer.log('Exception in getCustomerDashboard: $e',
          name: 'DashboardService', error: e);
      rethrow;
    }
  }

  /// Get supplier dashboard data
  Future<SupplierDashboardData> getSupplierDashboard({
    int days = 30,
  }) async {
    try {
      developer.log('Fetching supplier dashboard data for $days days...',
          name: 'DashboardService');

      final response = await _apiService.get(
        '/dashboard/supplier',
        queryParameters: {'days': days},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        developer.log('Supplier dashboard data fetched successfully',
            name: 'DashboardService');
        return SupplierDashboardData.fromJson(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      developer.log('Exception in getSupplierDashboard: $e',
          name: 'DashboardService', error: e);
      rethrow;
    }
  }

  /// Get admin/host dashboard data
  Future<AdminDashboardData> getAdminDashboard() async {
    try {
      developer.log('Fetching admin dashboard data...',
          name: 'DashboardService');

      final response = await _apiService.get('/dashboard/admin');

      if (response.statusCode == 200 && response.data['success'] == true) {
        developer.log('Admin dashboard data fetched successfully',
            name: 'DashboardService');
        return AdminDashboardData.fromJson(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load admin dashboard data');
      }
    } catch (e) {
      developer.log('Exception in getAdminDashboard: $e',
          name: 'DashboardService', error: e);
      rethrow;
    }
  }
}
