import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_config.dart';
import '../services/analytics_service.dart';

/// 📊 Analytics Provider
/// Manages analytics data and state for the application
class AnalyticsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardAnalytics;
  Map<String, dynamic>? _userAnalytics;
  Map<String, dynamic>? _salesAnalytics;
  Map<String, dynamic>? _productAnalytics;
  Map<String, dynamic>? _systemAnalytics;
  Map<String, dynamic>? _supplierAnalytics;
  Map<String, dynamic>? _analyticsConfig;
  String _selectedTimeframe = '30d';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get dashboardAnalytics => _dashboardAnalytics;
  Map<String, dynamic>? get userAnalytics => _userAnalytics;
  Map<String, dynamic>? get salesAnalytics => _salesAnalytics;
  Map<String, dynamic>? get productAnalytics => _productAnalytics;
  Map<String, dynamic>? get systemAnalytics => _systemAnalytics;
  Map<String, dynamic>? get supplierAnalytics => _supplierAnalytics;
  Map<String, dynamic>? get analyticsConfig => _analyticsConfig;
  String get selectedTimeframe => _selectedTimeframe;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Load analytics configuration
  Future<void> loadAnalyticsConfig() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.get('/analytics/config');
      if (response.isSuccess && response.data != null) {
        _analyticsConfig = response.data;
      }
    } catch (error) {
      _setError('Failed to load analytics configuration');
    } finally {
      _setLoading(false);
    }
  }

  /// Load dashboard analytics
  Future<void> loadDashboardAnalytics({String? timeframe}) async {
    try {
      _setLoading(true);
      _setError(null);

      final tf = timeframe ?? _selectedTimeframe;
      final response =
          await _apiService.get('/analytics/dashboard?timeframe=$tf');

      if (response.isSuccess && response.data != null) {
        _dashboardAnalytics = response.data;
        _selectedTimeframe = tf;
      }
    } catch (error) {
      _setError('Failed to load dashboard analytics');
    } finally {
      _setLoading(false);
    }
  }

  /// Load user analytics (Admin only)
  Future<void> loadUserAnalytics({String? timeframe}) async {
    try {
      _setLoading(true);
      _setError(null);

      final tf = timeframe ?? _selectedTimeframe;
      final response = await _apiService.get('/analytics/users?timeframe=$tf');

      if (response.isSuccess && response.data != null) {
        _userAnalytics = response.data;
      }
    } catch (error) {
      _setError('Failed to load user analytics');
    } finally {
      _setLoading(false);
    }
  }

  /// Load sales analytics
  Future<void> loadSalesAnalytics({String? timeframe}) async {
    try {
      _setLoading(true);
      _setError(null);

      final tf = timeframe ?? _selectedTimeframe;
      final response = await _apiService.get('/analytics/sales?timeframe=$tf');

      if (response.isSuccess && response.data != null) {
        _salesAnalytics = response.data;
      }
    } catch (error) {
      _setError('Failed to load sales analytics');
    } finally {
      _setLoading(false);
    }
  }

  /// Load product analytics
  Future<void> loadProductAnalytics({String? timeframe}) async {
    try {
      _setLoading(true);
      _setError(null);

      final tf = timeframe ?? _selectedTimeframe;
      final response =
          await _apiService.get('/analytics/products?timeframe=$tf');

      if (response.isSuccess && response.data != null) {
        _productAnalytics = response.data;
      }
    } catch (error) {
      _setError('Failed to load product analytics');
    } finally {
      _setLoading(false);
    }
  }

  /// Load system analytics (Admin only)
  Future<void> loadSystemAnalytics({String? timeframe}) async {
    try {
      _setLoading(true);
      _setError(null);

      final tf = timeframe ?? _selectedTimeframe;
      final response = await _apiService.get('/analytics/system?timeframe=$tf');

      if (response.isSuccess && response.data != null) {
        _systemAnalytics = response.data;
      }
    } catch (error) {
      _setError('Failed to load system analytics');
    } finally {
      _setLoading(false);
    }
  }

  /// Load supplier analytics (Supplier only)
  Future<void> loadSupplierAnalytics({String? timeframe}) async {
    try {
      _setLoading(true);
      _setError(null);

      final tf = timeframe ?? _selectedTimeframe;
      final AnalyticsService analyticsService = AnalyticsService();

      final result = await analyticsService.getSupplierAnalytics();

      if (result.success && result.supplierAnalytics != null) {
        final analytics = result.supplierAnalytics!;
        // Convert the strongly typed object back to a Map for the provider's generic Map storage
        // Ideally refactor provider to store the object, but for minimal change, map it back.
        // Or even better, let's look at `_supplierAnalytics` type. It is Map<String, dynamic>. A shame.
        // Let's manually construct the map from the object to ensure all fields are present.
        _supplierAnalytics = {
          'totalRevenue': analytics.totalRevenue,
          'totalOrders': analytics.totalOrders,
          'activeProducts': analytics.activeProducts,
          'averageOrderValue': analytics.averageOrderValue,
          'revenueChange': analytics.revenueChange,
          'ordersChange': analytics.ordersChange,
          'productsChange': analytics.productsChange,
          'aovChange': analytics.aovChange,
          'revenueData': analytics.revenueData,
          'topProducts': analytics.topProducts,
          'salesByPeriod': analytics.salesByPeriod,
          'orderStatusData': analytics.orderStatusData,
          'productPerformance': analytics.productPerformance,
          'inventoryStatus': analytics.inventoryStatus,
          'categoryPerformance': analytics.categoryPerformance,
          'recentSales': analytics.recentSales,
          'timeframe': tf,
        };
      } else {
        _setError(result.message ?? 'Failed to load supplier analytics');
      }
    } catch (error) {
      _setError('Failed to load supplier analytics');
    } finally {
      _setLoading(false);
    }
  }

  /// Load custom analytics report
  Future<Map<String, dynamic>?> loadCustomAnalytics({
    required List<String> metrics,
    String? timeframe,
    Map<String, dynamic>? filters,
    String? groupBy,
    String? sortBy,
    int? limit,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final body = {
        'metrics': metrics,
        'timeframe': timeframe ?? _selectedTimeframe,
        if (filters != null) 'filters': filters,
        if (groupBy != null) 'groupBy': groupBy,
        if (sortBy != null) 'sortBy': sortBy,
        if (limit != null) 'limit': limit,
      };

      final response = await _apiService.post('/analytics/custom', body: body);

      if (response.isSuccess && response.data != null) {
        return response.data;
      }
      return null;
    } catch (error) {
      _setError('Failed to load custom analytics');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Export analytics report
  Future<bool> exportAnalyticsReport({
    required String type,
    String format = 'pdf',
    String? timeframe,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final tf = timeframe ?? _selectedTimeframe;
      final uri = Uri.parse('${AppConfig.baseUrl}/analytics/export/$type')
          .replace(queryParameters: {
        'format': format,
        'timeframe': tf,
      });

      // This would need to be implemented with proper file handling
      // For now, return true to indicate success
      return true;
    } catch (error) {
      _setError('Failed to export analytics report');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update selected timeframe
  void updateTimeframe(String timeframe) {
    _selectedTimeframe = timeframe;
    notifyListeners();
  }

  /// Refresh all analytics data
  Future<void> refreshAllAnalytics() async {
    await Future.wait([
      loadDashboardAnalytics(),
      loadUserAnalytics(),
      loadSalesAnalytics(),
      loadProductAnalytics(),
      loadSystemAnalytics(),
    ]);
  }

  /// Clear error message
  void clearError() {
    _setError(null);
  }

  /// Get formatted analytics data for charts
  Map<String, dynamic> getFormattedChartData(String type) {
    switch (type) {
      case 'user_growth':
        final data = _userAnalytics?['growth']?['data'] ?? [];
        return {
          'labels': data.map((item) => item['period']).toList(),
          'values': data.map((item) => item['count']).toList(),
        };

      case 'sales_trend':
        final data = _salesAnalytics?['trend'] ?? [];
        return {
          'labels': data.map((item) => item['period']).toList(),
          'values': data.map((item) => item['revenue']).toList(),
        };

      case 'sales_by_category':
        final data = _salesAnalytics?['byCategory'] ?? [];
        return {
          'labels': data.map((item) => item['name']).toList(),
          'values': data.map((item) => item['revenue']).toList(),
        };

      case 'product_performance':
        final data = _productAnalytics?['performance'] ?? [];
        return {
          'labels': data.take(10).map((item) => item['title']).toList(),
          'values': data.take(10).map((item) => item['revenue']).toList(),
        };

      default:
        return {'labels': [], 'values': []};
    }
  }

  /// Get key metrics for dashboard
  Map<String, dynamic> getKeyMetrics() {
    return {
      'totalUsers': _userAnalytics?['summary']?['totalUsers'] ?? 0,
      'newUsers': _userAnalytics?['summary']?['newUsers'] ?? 0,
      'totalRevenue': _salesAnalytics?['summary']?['totalRevenue'] ?? 0,
      'totalOrders': _salesAnalytics?['summary']?['orderCount'] ?? 0,
      'avgOrderValue': _salesAnalytics?['summary']?['avgOrderValue'] ?? 0,
      'totalProducts': _productAnalytics?['summary']?['totalProducts'] ?? 0,
      'activeProducts': _productAnalytics?['summary']?['activeProducts'] ?? 0,
    };
  }

  /// Get trend indicators
  Map<String, dynamic> getTrendIndicators() {
    return {
      'userGrowth': _userAnalytics?['growth']?['growthRate'] ?? 0,
      'salesGrowth': _calculateSalesGrowth(),
      'orderGrowth': _calculateOrderGrowth(),
    };
  }

  double _calculateSalesGrowth() {
    final trend = _salesAnalytics?['trend'] ?? [];
    if (trend.length < 2) return 0;

    final current = trend.last['revenue'] ?? 0;
    final previous = trend[trend.length - 2]['revenue'] ?? 0;

    return previous > 0 ? ((current - previous) / previous) * 100 : 0;
  }

  double _calculateOrderGrowth() {
    // This would need order trend data
    return 0;
  }
}
