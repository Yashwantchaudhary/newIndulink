/// Order models for e-commerce orders
library;

/// Shipping address model
class ShippingAddress {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'Nepal',
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
      };

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      ShippingAddress(
        fullName: json['fullName'] ?? '',
        phone: json['phone'] ?? '',
        addressLine1: json['addressLine1'] ?? '',
        addressLine2: json['addressLine2'],
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        postalCode: json['postalCode'] ?? '',
        country: json['country'] ?? 'Nepal',
      );
}

/// Order item model
class OrderItem {
  final String? productId;
  final String title;
  final String? image;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    this.productId,
    required this.title,
    this.image,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() => {
        'product': productId,
        'productSnapshot': {
          'title': title,
          'image': image,
        },
        'quantity': quantity,
        'price': price,
        'subtotal': subtotal,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final snapshot = json['productSnapshot'] as Map<String, dynamic>?;
    return OrderItem(
      productId: json['product'],
      title: snapshot?['title'] ?? '',
      image: snapshot?['image'],
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

/// Order status enum
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded;

  static OrderStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  String toServerString() {
    switch (this) {
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      default:
        return name;
    }
  }
}

/// Payment method enum
enum PaymentMethod {
  cashOnDelivery,
  online,
  wallet;

  static PaymentMethod fromString(String method) {
    switch (method) {
      case 'cash_on_delivery':
        return PaymentMethod.cashOnDelivery;
      case 'online':
        return PaymentMethod.online;
      case 'wallet':
        return PaymentMethod.wallet;
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }

  String toServerString() {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'cash_on_delivery';
      default:
        return name;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.online:
        return 'Online Payment';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }
}

/// Order model
class Order {
  final String id;
  final String orderNumber;
  final String? customerId;
  final String? supplierId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final double total;
  final ShippingAddress shippingAddress;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentStatus;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.orderNumber,
    this.customerId,
    this.supplierId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shippingCost,
    required this.total,
    required this.shippingAddress,
    required this.status,
    required this.paymentMethod,
    this.paymentStatus,
    required this.createdAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerId: json['customer'],
      supplierId: json['supplier'],
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      shippingCost: (json['shippingCost'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      shippingAddress: json['shippingAddress'] != null
          ? ShippingAddress.fromJson(json['shippingAddress'])
          : ShippingAddress(
              fullName: '',
              phone: '',
              addressLine1: '',
              city: '',
              state: '',
              postalCode: '',
            ),
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      paymentMethod:
          PaymentMethod.fromString(json['paymentMethod'] ?? 'cash_on_delivery'),
      paymentStatus: json['paymentStatus'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      shippedAt:
          json['shippedAt'] != null ? DateTime.parse(json['shippedAt']) : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
