/// 📊 Dashboard Data Models
/// Data models for supplier, customer, and admin dashboards
library;

class SupplierDashboardData {
  final double totalRevenue;
  final int totalOrders;
  final int totalProducts;
  final int lowStockCount;
  final int unreadNotifications;
  final double? revenueTrend;
  final double? ordersTrend;
  final double? productsTrend;
  final List<double> revenueData;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> topProducts;

  SupplierDashboardData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalProducts,
    this.lowStockCount = 0,
    this.unreadNotifications = 0,
    this.revenueTrend,
    this.ordersTrend,
    this.productsTrend,
    this.revenueData = const [],
    this.recentOrders = const [],
    this.topProducts = const [],
  });

  factory SupplierDashboardData.fromJson(Map<String, dynamic> json) {
    return SupplierDashboardData(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      lowStockCount: json['lowStockCount'] ?? 0,
      unreadNotifications: json['unreadNotifications'] ?? 0,
      revenueTrend: json['revenueTrend'] != null
          ? (json['revenueTrend'] as num).toDouble()
          : null,
      ordersTrend: json['ordersTrend'] != null
          ? (json['ordersTrend'] as num).toDouble()
          : null,
      productsTrend: json['productsTrend'] != null
          ? (json['productsTrend'] as num).toDouble()
          : null,
      revenueData: json['revenueData'] != null
          ? (json['revenueData'] as List)
              .map((e) => (e as num).toDouble())
              .toList()
          : [],
      recentOrders: json['recentOrders'] != null
          ? List<Map<String, dynamic>>.from(json['recentOrders'])
          : [],
      topProducts: json['topProducts'] != null
          ? List<Map<String, dynamic>>.from(json['topProducts'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'totalProducts': totalProducts,
      'lowStockCount': lowStockCount,
      'unreadNotifications': unreadNotifications,
      'revenueTrend': revenueTrend,
      'ordersTrend': ordersTrend,
      'productsTrend': productsTrend,
      'revenueData': revenueData,
      'recentOrders': recentOrders,
      'topProducts': topProducts,
    };
  }
}

class CustomerDashboardData {
  final int totalOrders;
  final int pendingOrders;
  final double totalSpent;
  final int wishlistCount;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> recommendedProducts;

  CustomerDashboardData({
    required this.totalOrders,
    this.pendingOrders = 0,
    this.totalSpent = 0.0,
    this.wishlistCount = 0,
    this.recentOrders = const [],
    this.recommendedProducts = const [],
  });

  factory CustomerDashboardData.fromJson(Map<String, dynamic> json) {
    return CustomerDashboardData(
      totalOrders: json['totalOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      wishlistCount: json['wishlistCount'] ?? 0,
      recentOrders: json['recentOrders'] != null
          ? List<Map<String, dynamic>>.from(json['recentOrders'])
          : [],
      recommendedProducts: json['recommendedProducts'] != null
          ? List<Map<String, dynamic>>.from(json['recommendedProducts'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'pendingOrders': pendingOrders,
      'totalSpent': totalSpent,
      'wishlistCount': wishlistCount,
      'recentOrders': recentOrders,
      'recommendedProducts': recommendedProducts,
    };
  }
}

class AdminDashboardData {
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

  AdminDashboardData({
    required this.totalUsers,
    required this.totalSuppliers,
    required this.totalCustomers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    this.platformCommission = 0.0,
    this.revenueData = const [],
    this.recentUsers = const [],
    this.topSuppliers = const [],
    this.usersByRole = const {},
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    // Extract from usersByRole array
    final usersByRoleArray = json['usersByRole'] as List<dynamic>? ?? [];
    final usersByRole = <String, int>{};
    for (final role in usersByRoleArray) {
      usersByRole[role['_id']] = role['count'];
    }

    return AdminDashboardData(
      totalUsers: json['totalUsers'] ?? 0,
      totalSuppliers: json['totalSuppliers'] ?? usersByRole['supplier'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? usersByRole['customer'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      platformCommission: (json['platformCommission'] ?? 0).toDouble(),
      revenueData: json['revenueData'] != null
          ? (json['revenueData'] as List)
              .map((e) => (e as num).toDouble())
              .toList()
          : [],
      recentUsers: json['recentUsers'] != null
          ? (json['recentUsers'] as List).map((e) {
              final userMap = Map<String, dynamic>.from(e);
              // Combine first and last name if name is missing but parts exist
              if (userMap['name'] == null &&
                  userMap['firstName'] != null &&
                  userMap['lastName'] != null) {
                userMap['name'] =
                    '${userMap['firstName']} ${userMap['lastName']}';
              }
              return userMap;
            }).toList()
          : [],
      topSuppliers: json['topSuppliers'] != null
          ? List<Map<String, dynamic>>.from(json['topSuppliers'])
          : [],
      usersByRole: usersByRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalSuppliers': totalSuppliers,
      'totalCustomers': totalCustomers,
      'totalProducts': totalProducts,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'platformCommission': platformCommission,
      'revenueData': revenueData,
      'recentUsers': recentUsers,
      'topSuppliers': topSuppliers,
      'usersByRole': usersByRole,
    };
  }
}
