/// Dashboard data models for customer and supplier analytics
library;

class CustomerDashboardData {
  final CustomerStats stats;
  final List<OrderSummary> recentOrders;
  final List<OrderSummary> activeOrders;

  CustomerDashboardData({
    required this.stats,
    required this.recentOrders,
    required this.activeOrders,
  });

  factory CustomerDashboardData.fromJson(Map<String, dynamic> json) {
    return CustomerDashboardData(
      stats: CustomerStats.fromJson(json['stats'] ?? {}),
      recentOrders: (json['recentOrders'] as List<dynamic>?)
              ?.map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activeOrders: (json['activeOrders'] as List<dynamic>?)
              ?.map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stats': stats.toJson(),
      'recentOrders': recentOrders.map((e) => e.toJson()).toList(),
      'activeOrders': activeOrders.map((e) => e.toJson()).toList(),
    };
  }
}

class CustomerStats {
  final int totalOrders;
  final double totalSpent;
  final int deliveredOrders;
  final int pendingOrders;

  CustomerStats({
    required this.totalOrders,
    required this.totalSpent,
    required this.deliveredOrders,
    this.pendingOrders = 0,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      deliveredOrders: (json['deliveredOrders'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'deliveredOrders': deliveredOrders,
      'pendingOrders': pendingOrders,
    };
  }
}

class SupplierDashboardData {
  final RevenueData revenue;
  final List<OrderStatusData> ordersByStatus;
  final List<TopProduct> topProducts;
  final List<RevenueOverTime> revenueOverTime;
  final ProductStats productStats;
  final List<OrderSummary> recentOrders;

  SupplierDashboardData({
    required this.revenue,
    required this.ordersByStatus,
    required this.topProducts,
    required this.revenueOverTime,
    required this.productStats,
    required this.recentOrders,
  });

  factory SupplierDashboardData.fromJson(Map<String, dynamic> json) {
    return SupplierDashboardData(
      revenue: RevenueData.fromJson(json['revenue'] ?? {}),
      ordersByStatus: (json['ordersByStatus'] as List<dynamic>?)
              ?.map((e) => OrderStatusData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topProducts: (json['topProducts'] as List<dynamic>?)
              ?.map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      revenueOverTime: (json['revenueOverTime'] as List<dynamic>?)
              ?.map((e) => RevenueOverTime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      productStats: ProductStats.fromJson(json['productStats'] ?? {}),
      recentOrders: (json['recentOrders'] as List<dynamic>?)
              ?.map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revenue': revenue.toJson(),
      'ordersByStatus': ordersByStatus.map((e) => e.toJson()).toList(),
      'topProducts': topProducts.map((e) => e.toJson()).toList(),
      'revenueOverTime': revenueOverTime.map((e) => e.toJson()).toList(),
      'productStats': productStats.toJson(),
      'recentOrders': recentOrders.map((e) => e.toJson()).toList(),
    };
  }
}

class RevenueData {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final double growthPercentage;

  RevenueData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    this.growthPercentage = 0.0,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      growthPercentage: (json['growthPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'growthPercentage': growthPercentage,
    };
  }
}

class OrderStatusData {
  final String status;
  final int count;

  OrderStatusData({
    required this.status,
    required this.count,
  });

  factory OrderStatusData.fromJson(Map<String, dynamic> json) {
    return OrderStatusData(
      status: json['_id'] as String? ?? json['status'] as String? ?? 'unknown',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': status,
      'count': count,
    };
  }
}

class TopProduct {
  final String productId;
  final String title;
  final String? image;
  final double price;
  final int totalQuantity;
  final double totalRevenue;

  TopProduct({
    required this.productId,
    required this.title,
    this.image,
    required this.price,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    final productData = json['_id'] as Map<String, dynamic>?;
    final images = productData?['images'] as List<dynamic>?;
    final firstImage = images?.isNotEmpty == true ? images![0] : null;

    return TopProduct(
      productId: (productData?['_id'] as String?) ?? '',
      title: (productData?['title'] as String?) ?? 'Unknown Product',
      image: firstImage is Map ? firstImage['url'] as String? : null,
      price: (productData?['price'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': {
        '_id': productId,
        'title': title,
        'images': image != null
            ? [
                {'url': image}
              ]
            : [],
        'price': price,
      },
      'totalQuantity': totalQuantity,
      'totalRevenue': totalRevenue,
    };
  }
}

class RevenueOverTime {
  final String date;
  final double revenue;
  final int orders;

  RevenueOverTime({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  factory RevenueOverTime.fromJson(Map<String, dynamic> json) {
    return RevenueOverTime(
      date: json['_id'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': date,
      'revenue': revenue,
      'orders': orders,
    };
  }
}

class ProductStats {
  final int totalProducts;
  final int activeProducts;
  final int outOfStock;
  final int totalStock;
  final int lowStock;

  ProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.outOfStock,
    required this.totalStock,
    this.lowStock = 0,
  });

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      activeProducts: (json['activeProducts'] as num?)?.toInt() ?? 0,
      outOfStock: (json['outOfStock'] as num?)?.toInt() ?? 0,
      totalStock: (json['totalStock'] as num?)?.toInt() ?? 0,
      lowStock: (json['lowStock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'outOfStock': outOfStock,
      'totalStock': totalStock,
      'lowStock': lowStock,
    };
  }
}

class OrderSummary {
  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final DateTime createdAt;
  final String? customerName;
  final String? supplierName;
  final String? businessName;
  final List<OrderItem> items;

  OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.createdAt,
    this.customerName,
    this.supplierName,
    this.businessName,
    this.items = const [],
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final customerData = json['customer'] as Map<String, dynamic>?;
    final supplierData = json['supplier'] as Map<String, dynamic>?;

    return OrderSummary(
      id: json['_id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      customerName: customerData != null
          ? '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'
              .trim()
          : null,
      supplierName: supplierData != null
          ? '${supplierData['firstName'] ?? ''} ${supplierData['lastName'] ?? ''}'
              .trim()
          : null,
      businessName: supplierData?['businessName'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderNumber': orderNumber,
      'status': status,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'customer': customerName != null
          ? {'firstName': customerName!.split(' ').first}
          : null,
      'supplier': {
        'firstName': supplierName?.split(' ').first,
        'businessName': businessName,
      },
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderItem {
  final String productId;
  final String? title;
  final String? image;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    required this.productId,
    this.title,
    this.image,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final productData = json['product'] as Map<String, dynamic>?;
    final snapshotData = json['productSnapshot'] as Map<String, dynamic>?;
    final images = productData?['images'] as List<dynamic>?;
    final firstImage = images?.isNotEmpty == true ? images![0] : null;

    return OrderItem(
      productId:
          (productData?['_id'] as String?) ?? json['product'] as String? ?? '',
      title: (productData?['title'] as String?) ??
          snapshotData?['title'] as String?,
      image: firstImage is Map
          ? firstImage['url'] as String?
          : snapshotData?['image'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'productSnapshot': {
        'title': title,
        'image': image,
      },
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}

// ===== ADMIN/HOST DASHBOARD MODELS =====

class AdminDashboardData {
  final PlatformAnalytics platformAnalytics;
  final AdminMetrics adminMetrics;
  final List<UserSummary> recentUsers;
  final List<OrderSummary> recentOrders;
  final SystemHealth systemHealth;

  AdminDashboardData({
    required this.platformAnalytics,
    required this.adminMetrics,
    required this.recentUsers,
    required this.recentOrders,
    required this.systemHealth,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      platformAnalytics:
          PlatformAnalytics.fromJson(json['platformAnalytics'] ?? {}),
      adminMetrics: AdminMetrics.fromJson(json['adminMetrics'] ?? {}),
      recentUsers: (json['recentUsers'] as List<dynamic>?)
              ?.map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentOrders: (json['recentOrders'] as List<dynamic>?)
              ?.map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      systemHealth: SystemHealth.fromJson(json['systemHealth'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platformAnalytics': platformAnalytics.toJson(),
      'adminMetrics': adminMetrics.toJson(),
      'recentUsers': recentUsers.map((e) => e.toJson()).toList(),
      'recentOrders': recentOrders.map((e) => e.toJson()).toList(),
      'systemHealth': systemHealth.toJson(),
    };
  }
}

class PlatformAnalytics {
  final double totalPlatformRevenue;
  final int totalActiveUsers;
  final int totalOrders;
  final double averageOrderValue;
  final double platformGrowthRate;

  PlatformAnalytics({
    required this.totalPlatformRevenue,
    required this.totalActiveUsers,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.platformGrowthRate,
  });

  factory PlatformAnalytics.fromJson(Map<String, dynamic> json) {
    return PlatformAnalytics(
      totalPlatformRevenue:
          (json['totalPlatformRevenue'] as num?)?.toDouble() ?? 0.0,
      totalActiveUsers: (json['totalActiveUsers'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      platformGrowthRate:
          (json['platformGrowthRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPlatformRevenue': totalPlatformRevenue,
      'totalActiveUsers': totalActiveUsers,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'platformGrowthRate': platformGrowthRate,
    };
  }
}

class AdminMetrics {
  final double totalCommissions;
  final double platformFees;
  final UserGrowthMetrics userGrowth;
  final RevenueBreakdown revenueBreakdown;

  AdminMetrics({
    required this.totalCommissions,
    required this.platformFees,
    required this.userGrowth,
    required this.revenueBreakdown,
  });

  factory AdminMetrics.fromJson(Map<String, dynamic> json) {
    return AdminMetrics(
      totalCommissions: (json['totalCommissions'] as num?)?.toDouble() ?? 0.0,
      platformFees: (json['platformFees'] as num?)?.toDouble() ?? 0.0,
      userGrowth: UserGrowthMetrics.fromJson(json['userGrowth'] ?? {}),
      revenueBreakdown:
          RevenueBreakdown.fromJson(json['revenueBreakdown'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCommissions': totalCommissions,
      'platformFees': platformFees,
      'userGrowth': userGrowth.toJson(),
      'revenueBreakdown': revenueBreakdown.toJson(),
    };
  }
}

class UserGrowthMetrics {
  final int newUsersThisMonth;
  final int newUsersLastMonth;
  final double growthRate;
  final int totalSuppliers;
  final int totalCustomers;

  UserGrowthMetrics({
    required this.newUsersThisMonth,
    required this.newUsersLastMonth,
    required this.growthRate,
    required this.totalSuppliers,
    required this.totalCustomers,
  });

  factory UserGrowthMetrics.fromJson(Map<String, dynamic> json) {
    return UserGrowthMetrics(
      newUsersThisMonth: (json['newUsersThisMonth'] as num?)?.toInt() ?? 0,
      newUsersLastMonth: (json['newUsersLastMonth'] as num?)?.toInt() ?? 0,
      growthRate: (json['growthRate'] as num?)?.toDouble() ?? 0.0,
      totalSuppliers: (json['totalSuppliers'] as num?)?.toInt() ?? 0,
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newUsersThisMonth': newUsersThisMonth,
      'newUsersLastMonth': newUsersLastMonth,
      'growthRate': growthRate,
      'totalSuppliers': totalSuppliers,
      'totalCustomers': totalCustomers,
    };
  }
}

class RevenueBreakdown {
  final double supplierRevenue;
  final double platformRevenue;
  final double commissionRevenue;
  final double feeRevenue;

  RevenueBreakdown({
    required this.supplierRevenue,
    required this.platformRevenue,
    required this.commissionRevenue,
    required this.feeRevenue,
  });

  factory RevenueBreakdown.fromJson(Map<String, dynamic> json) {
    return RevenueBreakdown(
      supplierRevenue: (json['supplierRevenue'] as num?)?.toDouble() ?? 0.0,
      platformRevenue: (json['platformRevenue'] as num?)?.toDouble() ?? 0.0,
      commissionRevenue: (json['commissionRevenue'] as num?)?.toDouble() ?? 0.0,
      feeRevenue: (json['feeRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierRevenue': supplierRevenue,
      'platformRevenue': platformRevenue,
      'commissionRevenue': commissionRevenue,
      'feeRevenue': feeRevenue,
    };
  }
}

class UserSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final DateTime createdAt;
  final bool isActive;

  UserSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.isActive,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['_id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  String get fullName => '$firstName $lastName';
}

class SystemHealth {
  final String status;
  final double uptime;
  final int activeConnections;
  final Map<String, ServiceStatus> services;

  SystemHealth({
    required this.status,
    required this.uptime,
    required this.activeConnections,
    required this.services,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    final servicesMap = <String, ServiceStatus>{};
    if (json['services'] is Map) {
      (json['services'] as Map<String, dynamic>).forEach((key, value) {
        servicesMap[key] =
            ServiceStatus.fromJson(value as Map<String, dynamic>);
      });
    }

    return SystemHealth(
      status: json['status'] as String? ?? 'unknown',
      uptime: (json['uptime'] as num?)?.toDouble() ?? 0.0,
      activeConnections: (json['activeConnections'] as num?)?.toInt() ?? 0,
      services: servicesMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'uptime': uptime,
      'activeConnections': activeConnections,
      'services': services.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class ServiceStatus {
  final String name;
  final String status;
  final String? message;
  final DateTime? lastChecked;

  ServiceStatus({
    required this.name,
    required this.status,
    this.message,
    this.lastChecked,
  });

  factory ServiceStatus.fromJson(Map<String, dynamic> json) {
    return ServiceStatus(
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String?,
      lastChecked: json['lastChecked'] != null
          ? DateTime.parse(json['lastChecked'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'message': message,
      'lastChecked': lastChecked?.toIso8601String(),
    };
  }
}
