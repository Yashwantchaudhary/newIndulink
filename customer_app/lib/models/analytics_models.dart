// Analytics Data Models

class SalesTrends {
  final List<TrendData> trends;
  final SalesTotals totals;
  final SalesComparison comparison;
  final Period period;

  SalesTrends({
    required this.trends,
    required this.totals,
    required this.comparison,
    required this.period,
  });

  factory SalesTrends.fromJson(Map<String, dynamic> json) {
    return SalesTrends(
      trends:
          (json['trends'] as List).map((e) => TrendData.fromJson(e)).toList(),
      totals: SalesTotals.fromJson(json['totals']),
      comparison: SalesComparison.fromJson(json['comparison']),
      period: Period.fromJson(json['period']),
    );
  }
}

class TrendData {
  final String date;
  final double revenue;
  final int orders;
  final double averageOrderValue;

  TrendData({
    required this.date,
    required this.revenue,
    required this.orders,
    required this.averageOrderValue,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      date: json['_id'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
    );
  }
}

class SalesTotals {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;

  SalesTotals({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
  });

  factory SalesTotals.fromJson(Map<String, dynamic> json) {
    return SalesTotals(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
    );
  }
}

class SalesComparison {
  final double revenueGrowth;
  final double ordersGrowth;
  final double avgOrderValueGrowth;

  SalesComparison({
    required this.revenueGrowth,
    required this.ordersGrowth,
    required this.avgOrderValueGrowth,
  });

  factory SalesComparison.fromJson(Map<String, dynamic> json) {
    return SalesComparison(
      revenueGrowth: (json['revenueGrowth'] ?? 0).toDouble(),
      ordersGrowth: (json['ordersGrowth'] ?? 0).toDouble(),
      avgOrderValueGrowth: (json['avgOrderValueGrowth'] ?? 0).toDouble(),
    );
  }
}

class Period {
  final String start;
  final String end;
  final String interval;

  Period({
    required this.start,
    required this.end,
    required this.interval,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      interval: json['interval'] ?? 'day',
    );
  }
}

// Product Performance Models

class ProductPerformance {
  final List<TopProduct> topProducts;
  final List<TopProduct> bottomProducts;
  final List<CategoryPerformance> categoryPerformance;
  final StockAnalysis? stockAnalysis;

  ProductPerformance({
    required this.topProducts,
    required this.bottomProducts,
    required this.categoryPerformance,
    this.stockAnalysis,
  });

  factory ProductPerformance.fromJson(Map<String, dynamic> json) {
    return ProductPerformance(
      topProducts: (json['topProducts'] as List? ?? [])
          .map((e) => TopProduct.fromJson(e))
          .toList(),
      bottomProducts: (json['bottomProducts'] as List? ?? [])
          .map((e) => TopProduct.fromJson(e))
          .toList(),
      categoryPerformance: (json['categoryPerformance'] as List? ?? [])
          .map((e) => CategoryPerformance.fromJson(e))
          .toList(),
      stockAnalysis: json['stockAnalysis'] != null
          ? StockAnalysis.fromJson(json['stockAnalysis'])
          : null,
    );
  }
}

class TopProduct {
  final ProductInfo product;
  final double totalRevenue;
  final int totalQuantity;
  final int? orderCount;

  TopProduct({
    required this.product,
    required this.totalRevenue,
    required this.totalQuantity,
    this.orderCount,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      product: ProductInfo.fromJson(json['_id']),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalQuantity: json['totalQuantity'] ?? 0,
      orderCount: json['orderCount'],
    );
  }
}

class ProductInfo {
  final String id;
  final String title;
  final List<String> images;
  final double price;
  final String? category;
  final int? stock;

  ProductInfo({
    required this.id,
    required this.title,
    required this.images,
    required this.price,
    this.category,
    this.stock,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Unknown Product',
      images: List<String>.from(json['images'] ?? []),
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'],
      stock: json['stock'],
    );
  }
}

class CategoryPerformance {
  final String categoryId;
  final double revenue;
  final int quantity;

  CategoryPerformance({
    required this.categoryId,
    required this.revenue,
    required this.quantity,
  });

  factory CategoryPerformance.fromJson(Map<String, dynamic> json) {
    return CategoryPerformance(
      categoryId: json['_id']?.toString() ?? 'Unknown',
      revenue: (json['revenue'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
    );
  }
}

class StockAnalysis {
  final int totalProducts;
  final int lowStock;
  final int outOfStock;
  final List<LowStockProduct> lowStockProducts;

  StockAnalysis({
    required this.totalProducts,
    required this.lowStock,
    required this.outOfStock,
    required this.lowStockProducts,
  });

  factory StockAnalysis.fromJson(Map<String, dynamic> json) {
    return StockAnalysis(
      totalProducts: json['totalProducts'] ?? 0,
      lowStock: json['lowStock'] ?? 0,
      outOfStock: json['outOfStock'] ?? 0,
      lowStockProducts: (json['lowStockProducts'] as List? ?? [])
          .map((e) => LowStockProduct.fromJson(e))
          .toList(),
    );
  }
}

class LowStockProduct {
  final String id;
  final String title;
  final int stock;
  final String? image;

  LowStockProduct({
    required this.id,
    required this.title,
    required this.stock,
    this.image,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      stock: json['stock'] ?? 0,
      image: json['image'],
    );
  }
}

// Customer Behavior Models

class CustomerBehavior {
  final CustomerSummary summary;
  final List<TopCustomer> topCustomers;

  CustomerBehavior({
    required this.summary,
    required this.topCustomers,
  });

  factory CustomerBehavior.fromJson(Map<String, dynamic> json) {
    return CustomerBehavior(
      summary: CustomerSummary.fromJson(json['summary']),
      topCustomers: (json['topCustomers'] as List? ?? [])
          .map((e) => TopCustomer.fromJson(e))
          .toList(),
    );
  }
}

class CustomerSummary {
  final int totalCustomers;
  final int newCustomers;
  final int returningCustomers;
  final double avgLifetimeValue;
  final double avgOrdersPerCustomer;

  CustomerSummary({
    required this.totalCustomers,
    required this.newCustomers,
    required this.returningCustomers,
    required this.avgLifetimeValue,
    required this.avgOrdersPerCustomer,
  });

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    return CustomerSummary(
      totalCustomers: json['totalCustomers'] ?? 0,
      newCustomers: json['newCustomers'] ?? 0,
      returningCustomers: json['returningCustomers'] ?? 0,
      avgLifetimeValue: (json['avgLifetimeValue'] ?? 0).toDouble(),
      avgOrdersPerCustomer: (json['avgOrdersPerCustomer'] ?? 0).toDouble(),
    );
  }
}

class TopCustomer {
  final CustomerInfo customer;
  final int orderCount;
  final double totalSpent;
  final String firstOrder;
  final String lastOrder;

  TopCustomer({
    required this.customer,
    required this.orderCount,
    required this.totalSpent,
    required this.firstOrder,
    required this.lastOrder,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      customer: CustomerInfo.fromJson(json['_id']),
      orderCount: json['orderCount'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      firstOrder: json['firstOrder'] ?? '',
      lastOrder: json['lastOrder'] ?? '',
    );
  }
}

class CustomerInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;

  CustomerInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
    );
  }

  String get fullName => '$firstName $lastName';
}

// Supplier Performance Models

class SupplierPerformance {
  final OrderMetrics orderMetrics;
  final double fulfillmentRate;
  final double avgDeliveryTime;
  final ProductStats productStats;

  SupplierPerformance({
    required this.orderMetrics,
    required this.fulfillmentRate,
    required this.avgDeliveryTime,
    required this.productStats,
  });

  factory SupplierPerformance.fromJson(Map<String, dynamic> json) {
    return SupplierPerformance(
      orderMetrics: OrderMetrics.fromJson(json['orderMetrics']),
      fulfillmentRate: double.parse(json['fulfillmentRate'] ?? '0'),
      avgDeliveryTime: double.parse(json['avgDeliveryTime'] ?? '0'),
      productStats: ProductStats.fromJson(json['productStats']),
    );
  }
}

class OrderMetrics {
  final int totalOrders;
  final int delivered;
  final int cancelled;
  final int processing;

  OrderMetrics({
    required this.totalOrders,
    required this.delivered,
    required this.cancelled,
    required this.processing,
  });

  factory OrderMetrics.fromJson(Map<String, dynamic> json) {
    return OrderMetrics(
      totalOrders: json['totalOrders'] ?? 0,
      delivered: json['delivered'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      processing: json['processing'] ?? 0,
    );
  }
}

class ProductStats {
  final int totalProducts;
  final int activeProducts;

  ProductStats({
    required this.totalProducts,
    required this.activeProducts,
  });

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
    );
  }
}

// Comparative Analysis Models

class ComparativeAnalysis {
  final String period;
  final PeriodRange currentPeriod;
  final PeriodRange previousPeriod;
  final ComparisonMetrics comparison;

  ComparativeAnalysis({
    required this.period,
    required this.currentPeriod,
    required this.previousPeriod,
    required this.comparison,
  });

  factory ComparativeAnalysis.fromJson(Map<String, dynamic> json) {
    return ComparativeAnalysis(
      period: json['period'] ?? '',
      currentPeriod: PeriodRange.fromJson(json['currentPeriod']),
      previousPeriod: PeriodRange.fromJson(json['previousPeriod']),
      comparison: ComparisonMetrics.fromJson(json['comparison']),
    );
  }
}

class PeriodRange {
  final String start;
  final String end;

  PeriodRange({
    required this.start,
    required this.end,
  });

  factory PeriodRange.fromJson(Map<String, dynamic> json) {
    return PeriodRange(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }
}

class ComparisonMetrics {
  final MetricComparison revenue;
  final MetricComparison orders;
  final MetricComparison avgOrderValue;

  ComparisonMetrics({
    required this.revenue,
    required this.orders,
    required this.avgOrderValue,
  });

  factory ComparisonMetrics.fromJson(Map<String, dynamic> json) {
    return ComparisonMetrics(
      revenue: MetricComparison.fromJson(json['revenue']),
      orders: MetricComparison.fromJson(json['orders']),
      avgOrderValue: MetricComparison.fromJson(json['avgOrderValue']),
    );
  }
}

class MetricComparison {
  final double current;
  final double previous;
  final double change;
  final String trend;

  MetricComparison({
    required this.current,
    required this.previous,
    required this.change,
    required this.trend,
  });

  factory MetricComparison.fromJson(Map<String, dynamic> json) {
    return MetricComparison(
      current: (json['current'] ?? 0).toDouble(),
      previous: (json['previous'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'flat',
    );
  }

  bool get isPositive => trend == 'up';
  bool get isNegative => trend == 'down';
}

// Predictive Insights Models

class PredictiveInsights {
  final TrendAnalysis trendAnalysis;
  final ForecastData forecasts;
  final PredictionData predictions;
  final List<Recommendation> recommendations;

  PredictiveInsights({
    required this.trendAnalysis,
    required this.forecasts,
    required this.predictions,
    required this.recommendations,
  });

  factory PredictiveInsights.fromJson(Map<String, dynamic> json) {
    return PredictiveInsights(
      trendAnalysis: TrendAnalysis.fromJson(json['trendAnalysis']),
      forecasts: ForecastData.fromJson(json['forecasts']),
      predictions: PredictionData.fromJson(json['predictions']),
      recommendations: (json['recommendations'] as List? ?? [])
          .map((e) => Recommendation.fromJson(e))
          .toList(),
    );
  }
}

class TrendAnalysis {
  final String direction;
  final double growthRate;
  final double slope;
  final double volatility;
  final double trendStrength;
  final int dataPoints;

  TrendAnalysis({
    required this.direction,
    required this.growthRate,
    required this.slope,
    required this.volatility,
    required this.trendStrength,
    required this.dataPoints,
  });

  factory TrendAnalysis.fromJson(Map<String, dynamic> json) {
    return TrendAnalysis(
      direction: json['direction'] ?? 'stable',
      growthRate: (json['growthRate'] ?? 0).toDouble(),
      slope: (json['slope'] ?? 0).toDouble(),
      volatility: (json['volatility'] ?? 0).toDouble(),
      trendStrength: (json['trendStrength'] ?? 0).toDouble(),
      dataPoints: json['dataPoints'] ?? 0,
    );
  }

  bool get isIncreasing => direction == 'increasing';
  bool get isDecreasing => direction == 'decreasing';
  bool get isStable => direction == 'stable';
}

class ForecastData {
  final List<ForecastPoint> revenue;
  final List<ForecastPoint> orders;

  ForecastData({
    required this.revenue,
    required this.orders,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      revenue: (json['revenue'] as List? ?? [])
          .map((e) => ForecastPoint.fromJson(e))
          .toList(),
      orders: (json['orders'] as List? ?? [])
          .map((e) => ForecastPoint.fromJson(e))
          .toList(),
    );
  }
}

class ForecastPoint {
  final String date;
  final double predicted;

  ForecastPoint({
    required this.date,
    required this.predicted,
  });

  factory ForecastPoint.fromJson(Map<String, dynamic> json) {
    return ForecastPoint(
      date: json['date'] ?? '',
      predicted: (json['predicted'] ?? 0).toDouble(),
    );
  }
}

class PredictionData {
  final double nextWeekRevenue;
  final double nextWeekOrders;
  final double growthRate;
  final String confidence;

  PredictionData({
    required this.nextWeekRevenue,
    required this.nextWeekOrders,
    required this.growthRate,
    required this.confidence,
  });

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    return PredictionData(
      nextWeekRevenue: (json['nextWeekRevenue'] ?? 0).toDouble(),
      nextWeekOrders: (json['nextWeekOrders'] ?? 0).toDouble(),
      growthRate: (json['growthRate'] ?? 0).toDouble(),
      confidence: json['confidence'] ?? 'low',
    );
  }

  bool get isHighConfidence => confidence == 'high';
  bool get isMediumConfidence => confidence == 'medium';
  bool get isLowConfidence => confidence == 'low';
}

class Recommendation {
  final String type;
  final String message;
  final String priority;

  Recommendation({
    required this.type,
    required this.message,
    required this.priority,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      type: json['type'] ?? 'info',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'low',
    );
  }

  bool get isHighPriority => priority == 'high';
  bool get isMediumPriority => priority == 'medium';
  bool get isLowPriority => priority == 'low';
}

// User Segmentation Models

class UserSegmentation {
  final Map<String, List<CustomerSegment>> segments;
  final Map<String, SegmentStatistics> statistics;
  final int totalCustomers;

  UserSegmentation({
    required this.segments,
    required this.statistics,
    required this.totalCustomers,
  });

  factory UserSegmentation.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] as Map<String, dynamic>? ?? {};
    final segments = <String, List<CustomerSegment>>{};
    segmentsJson.forEach((key, value) {
      segments[key] = (value as List? ?? [])
          .map((e) => CustomerSegment.fromJson(e))
          .toList();
    });

    final statisticsJson = json['statistics'] as Map<String, dynamic>? ?? {};
    final statistics = <String, SegmentStatistics>{};
    statisticsJson.forEach((key, value) {
      statistics[key] = SegmentStatistics.fromJson(value);
    });

    return UserSegmentation(
      segments: segments,
      statistics: statistics,
      totalCustomers: json['totalCustomers'] ?? 0,
    );
  }
}

class CustomerSegment {
  final CustomerInfo customer;
  final int orderCount;
  final double totalSpent;
  final double avgOrderValue;
  final String firstOrder;
  final String lastOrder;

  CustomerSegment({
    required this.customer,
    required this.orderCount,
    required this.totalSpent,
    required this.avgOrderValue,
    required this.firstOrder,
    required this.lastOrder,
  });

  factory CustomerSegment.fromJson(Map<String, dynamic> json) {
    return CustomerSegment(
      customer: CustomerInfo.fromJson(json['_id']),
      orderCount: json['orderCount'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      avgOrderValue: (json['avgOrderValue'] ?? 0).toDouble(),
      firstOrder: json['firstOrder'] ?? '',
      lastOrder: json['lastOrder'] ?? '',
    );
  }
}

class SegmentStatistics {
  final int count;
  final double totalRevenue;
  final double avgOrderValue;
  final double avgOrdersPerCustomer;

  SegmentStatistics({
    required this.count,
    required this.totalRevenue,
    required this.avgOrderValue,
    required this.avgOrdersPerCustomer,
  });

  factory SegmentStatistics.fromJson(Map<String, dynamic> json) {
    return SegmentStatistics(
      count: json['count'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      avgOrderValue: (json['avgOrderValue'] ?? 0).toDouble(),
      avgOrdersPerCustomer: (json['avgOrdersPerCustomer'] ?? 0).toDouble(),
    );
  }
}
