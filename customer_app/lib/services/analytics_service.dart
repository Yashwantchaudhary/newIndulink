import 'dart:io';
import '../config/api_client.dart';
import '../models/analytics_models.dart';

class AnalyticsService {
  final ApiClient _apiClient;

  AnalyticsService(this._apiClient);

  /// Get sales trends analysis
  /// [startDate] and [endDate] in format 'YYYY-MM-DD'
  /// [interval] can be 'day', 'week', or 'month'
  Future<SalesTrends> getSalesTrends({
    required String startDate,
    required String endDate,
    String interval = 'day',
  }) async {
    final response = await _apiClient.get(
      '/dashboard/analytics/sales-trends',
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
        'interval': interval,
      },
    );

    return SalesTrends.fromJson(response['data']);
  }

  /// Get product performance metrics
  /// [limit] - number of top products to fetch (default 20)
  Future<ProductPerformance> getProductPerformance({int limit = 20}) async {
    final response = await _apiClient.get(
      '/dashboard/analytics/product-performance',
      queryParameters: {'limit': limit.toString()},
    );

    return ProductPerformance.fromJson(response['data']);
  }

  /// Get customer behavior analytics
  /// Only available for suppliers and admins
  Future<CustomerBehavior> getCustomerBehavior() async {
    final response = await _apiClient.get(
      '/dashboard/analytics/customer-behavior',
    );

    return CustomerBehavior.fromJson(response['data']);
  }

  /// Get supplier performance KPIs
  /// Only available for suppliers
  Future<SupplierPerformance> getSupplierPerformance() async {
    final response = await _apiClient.get(
      '/dashboard/analytics/supplier-performance',
    );

    return SupplierPerformance.fromJson(response['data']);
  }

  /// Get comparative analysis (period-over-period)
  /// [period] can be 'week', 'month', 'quarter', or 'year'
  Future<ComparativeAnalysis> getComparative({String period = 'month'}) async {
    final response = await _apiClient.get(
      '/dashboard/analytics/compare',
      queryParameters: {'period': period},
    );

    return ComparativeAnalysis.fromJson(response['data']);
  }

  /// Export analytics data as CSV
  /// [reportType] can be 'sales' or 'products'
  /// [startDate] and [endDate] in format 'YYYY-MM-DD'
  /// Returns the downloaded file path
  Future<File> exportCSV({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.downloadFile(
      '/dashboard/analytics/export/csv',
      queryParameters: {
        'reportType': reportType,
        'startDate': startDate,
        'endDate': endDate,
      },
    );

    return response;
  }

  /// Get predictive insights and trend analysis
  /// [period] - number of days to analyze (default 30)
  Future<PredictiveInsights> getPredictiveInsights({int period = 30}) async {
    final response = await _apiClient.get(
      '/dashboard/analytics/predictive-insights',
      queryParameters: {'period': period.toString()},
    );

    return PredictiveInsights.fromJson(response['data']);
  }

  /// Get user segmentation analytics
  /// Only available for suppliers and admins
  Future<UserSegmentation> getUserSegmentation() async {
    final response = await _apiClient.get(
      '/dashboard/analytics/user-segmentation',
    );

    return UserSegmentation.fromJson(response['data']);
  }

  /// Export analytics data as PDF
  /// [reportType] can be 'sales', 'products', or 'customers'
  /// [startDate] and [endDate] in format 'YYYY-MM-DD'
  /// Returns the downloaded file path
  Future<File> exportPDF({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _apiClient.downloadFile(
      '/dashboard/analytics/export/pdf',
      queryParameters: {
        'reportType': reportType,
        'startDate': startDate,
        'endDate': endDate,
      },
    );

    return response;
  }

  /// Helper: Get date string in YYYY-MM-DD format
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Helper: Get date range for common presets
  static DateRange getPresetRange(String preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (preset) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'yesterday':
        start = DateTime(now.year, now.month, now.day - 1);
        end = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        break;
      case 'week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'quarter':
        start = now.subtract(const Duration(days: 90));
        break;
      case 'year':
        start = now.subtract(const Duration(days: 365));
        break;
      default:
        start = now.subtract(const Duration(days: 30));
    }

    return DateRange(start: start, end: end);
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  String get startFormatted => AnalyticsService.formatDate(start);
  String get endFormatted => AnalyticsService.formatDate(end);
}
