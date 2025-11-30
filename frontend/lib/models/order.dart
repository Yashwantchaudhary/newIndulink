import 'user.dart';
import 'product.dart';

/// 📦 Order Model
class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final User? user;
  final List<OrderItem> items;
  final Address shippingAddress;
  final String paymentMethod;
  final OrderStatus status;
  final double subtotal;
  final double tax;
  final double shippingFee;
  final double total;
  final String? trackingNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderStatusHistory>? statusHistory;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    this.user,
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.status,
    required this.subtotal,
    required this.tax,
    this.shippingFee = 0,
    required this.total,
    this.trackingNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.statusHistory,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusDisplayName => status.displayName;

  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.processing;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      userId: json['userId'] ?? json['user']?['_id'] ?? '',
      user: json['user'] != null && json['user'] is Map
          ? User.fromJson(json['user'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList()
          : [],
      shippingAddress: Address.fromJson(json['shippingAddress'] ?? {}),
      paymentMethod: json['paymentMethod'] ?? 'Cash on Delivery',
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      shippingFee: (json['shippingFee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      trackingNumber: json['trackingNumber'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      statusHistory: json['statusHistory'] != null
          ? (json['statusHistory'] as List)
              .map((e) => OrderStatusHistory.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderNumber': orderNumber,
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'shippingAddress': shippingAddress.toJson(),
      'paymentMethod': paymentMethod,
      'status': status.value,
      'subtotal': subtotal,
      'tax': tax,
      'shippingFee': shippingFee,
      'total': total,
      'trackingNumber': trackingNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (statusHistory != null)
        'statusHistory': statusHistory!.map((e) => e.toJson()).toList(),
    };
  }
}

/// 📋 Order Item Model
class OrderItem {
  final String productId;
  final Product? product;
  final String productName;
  final String? productImage;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    required this.productId,
    this.product,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? json['product']?['_id'] ?? '',
      product: json['product'] != null && json['product'] is Map
          ? Product.fromJson(json['product'])
          : null,
      productName: json['productName'] ?? json['product']?['title'] ?? '',
      productImage:
          json['productImage'] ?? json['product']?['images']?[0]?['url'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      if (product != null) 'product': product!.toJson(),
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}

/// 📊 Order Status Enum
enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled;

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

/// 📜 Order Status History
class OrderStatusHistory {
  final OrderStatus status;
  final DateTime timestamp;
  final String? notes;

  OrderStatusHistory({
    required this.status,
    required this.timestamp,
    this.notes,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'timestamp': timestamp.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}
