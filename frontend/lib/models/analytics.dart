/// 📊 Analytics Models
/// Data models for analytics and reporting

/// Supplier Analytics Data
class SupplierAnalytics {
  final double totalRevenue;
  final int totalOrders;
  final int activeProducts;
  final double averageOrderValue;
  final double revenueChange;
  final double ordersChange;
  final double productsChange;
  final double aovChange;
  final List<double> revenueData;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> salesByPeriod;
  final List<Map<String, dynamic>> orderStatusData;
  final List<Map<String, dynamic>> productPerformance;
  final List<Map<String, dynamic>> inventoryStatus;
  final List<Map<String, dynamic>> categoryPerformance;
  final List<Map<String, dynamic>> recentSales;

  SupplierAnalytics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeProducts,
    required this.averageOrderValue,
    required this.revenueChange,
    required this.ordersChange,
    required this.productsChange,
    required this.aovChange,
    required this.revenueData,
    required this.topProducts,
    required this.salesByPeriod,
    required this.orderStatusData,
    required this.productPerformance,
    required this.inventoryStatus,
    required this.categoryPerformance,
    required this.recentSales,
  });

  factory SupplierAnalytics.fromJson(Map<String, dynamic> json) {
    return SupplierAnalytics(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      activeProducts: json['activeProducts'] as int? ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      revenueChange: (json['revenueChange'] as num?)?.toDouble() ?? 0.0,
      ordersChange: (json['ordersChange'] as num?)?.toDouble() ?? 0.0,
      productsChange: (json['productsChange'] as num?)?.toDouble() ?? 0.0,
      aovChange: (json['aovChange'] as num?)?.toDouble() ?? 0.0,
      revenueData: (json['revenueData'] as List<dynamic>?)
          ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
          .toList() ?? [],
      topProducts: (json['topProducts'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      salesByPeriod: (json['salesByPeriod'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      orderStatusData: (json['orderStatusData'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      productPerformance: (json['productPerformance'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      inventoryStatus: (json['inventoryStatus'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      categoryPerformance: (json['categoryPerformance'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      recentSales: (json['recentSales'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
    );
  }
}

/// Admin Analytics Data
class AdminAnalytics {
  final int totalUsers;
  final int totalSuppliers;
  final int totalCustomers;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final double platformCommission;
  final List<double> revenueData;
  final List<Map<String, dynamic>> recentUsers;
  final List<Map<String, dynamic>> topSuppliers;
  final Map<String, int> usersByRole;
  final List<Map<String, dynamic>> systemHealth;

  AdminAnalytics({
    required this.totalUsers,
    required this.totalSuppliers,
    required this.totalCustomers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.platformCommission,
    required this.revenueData,
    required this.recentUsers,
    required this.topSuppliers,
    required this.usersByRole,
    required this.systemHealth,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      totalUsers: json['totalUsers'] as int? ?? 0,
      totalSuppliers: json['totalSuppliers'] as int? ?? 0,
      totalCustomers: json['totalCustomers'] as int? ?? 0,
      totalProducts: json['totalProducts'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      platformCommission: (json['platformCommission'] as num?)?.toDouble() ?? 0.0,
      revenueData: (json['revenueData'] as List<dynamic>?)
          ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
          .toList() ?? [],
      recentUsers: (json['recentUsers'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      topSuppliers: (json['topSuppliers'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      usersByRole: (json['usersByRole'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int? ?? 0)) ?? {},
      systemHealth: (json['systemHealth'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
    );
  }
}

/// Analytics Result Model
class AnalyticsResult {
  final bool success;
  final String? message;
  final SupplierAnalytics? supplierAnalytics;
  final AdminAnalytics? adminAnalytics;

  AnalyticsResult({
    required this.success,
    this.message,
    this.supplierAnalytics,
    this.adminAnalytics,
  });

  // Helper getter
  dynamic get analytics => supplierAnalytics ?? adminAnalytics;
}

/// Analytics Service Response
class AnalyticsServiceResult {
  final bool success;
  final String? message;
  final dynamic data;

  AnalyticsServiceResult({
    required this.success,
    this.message,
    this.data,
  });
}