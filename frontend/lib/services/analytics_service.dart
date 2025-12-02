import '../core/constants/app_config.dart';
import '../models/analytics.dart';
import 'api_service.dart';

/// 📊 Analytics Service
/// Handles analytics data fetching and processing
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final ApiService _api = ApiService();

  /// Get supplier analytics
  Future<AnalyticsResult> getSupplierAnalytics() async {
    try {
      final response = await _api.get(AppConfig.supplierAnalyticsEndpoint);

      if (response.isSuccess && response.data != null) {
        final analytics = SupplierAnalytics.fromJson(response.data);
        return AnalyticsResult(
          success: true,
          supplierAnalytics: analytics,
        );
      } else {
        return AnalyticsResult(
          success: false,
          message: response.message ?? 'Failed to load supplier analytics',
        );
      }
    } catch (e) {
      return AnalyticsResult(
        success: false,
        message: 'An error occurred while fetching analytics',
      );
    }
  }

  /// Get admin analytics
  Future<AnalyticsResult> getAdminAnalytics() async {
    try {
      final response = await _api.get(AppConfig.adminAnalyticsEndpoint);

      if (response.isSuccess && response.data != null) {
        final analytics = AdminAnalytics.fromJson(response.data);
        return AnalyticsResult(
          success: true,
          adminAnalytics: analytics,
        );
      } else {
        return AnalyticsResult(
          success: false,
          message: response.message ?? 'Failed to load admin analytics',
        );
      }
    } catch (e) {
      return AnalyticsResult(
        success: false,
        message: 'An error occurred while fetching analytics',
      );
    }
  }

  /// Get analytics for specific date range
  Future<AnalyticsResult> getAnalyticsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    bool isSupplier = true,
  }) async {
    try {
      final params = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final endpoint = isSupplier
          ? AppConfig.supplierAnalyticsEndpoint
          : AppConfig.adminAnalyticsEndpoint;

      final response = await _api.get(endpoint, params: params);

      if (response.isSuccess && response.data != null) {
        if (isSupplier) {
          final analytics = SupplierAnalytics.fromJson(response.data);
          return AnalyticsResult(
            success: true,
            supplierAnalytics: analytics,
          );
        } else {
          final analytics = AdminAnalytics.fromJson(response.data);
          return AnalyticsResult(
            success: true,
            adminAnalytics: analytics,
          );
        }
      } else {
        return AnalyticsResult(
          success: false,
          message: response.message ?? 'Failed to load analytics for date range',
        );
      }
    } catch (e) {
      return AnalyticsResult(
        success: false,
        message: 'An error occurred while fetching analytics',
      );
    }
  }

  /// Export analytics data
  Future<AnalyticsServiceResult> exportAnalytics({
    required String format, // 'csv', 'pdf', 'excel'
    bool isSupplier = true,
  }) async {
    try {
      final params = {'format': format};
      final endpoint = isSupplier
          ? AppConfig.supplierAnalyticsEndpoint
          : AppConfig.adminAnalyticsEndpoint;

      final response = await _api.get('$endpoint/export', params: params);

      if (response.isSuccess) {
        return AnalyticsServiceResult(
          success: true,
          data: response.data,
          message: 'Analytics exported successfully',
        );
      } else {
        return AnalyticsServiceResult(
          success: false,
          message: response.message ?? 'Failed to export analytics',
        );
      }
    } catch (e) {
      return AnalyticsServiceResult(
        success: false,
        message: 'An error occurred while exporting analytics',
      );
    }
  }
}