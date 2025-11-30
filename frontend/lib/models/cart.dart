import 'product.dart';

/// 🛒 Cart Model
class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  double get taxAmount => subtotal * 0.13; // 13% VAT

  double get shippingFee => 50.0; // Flat shipping rate

  double get total => subtotal + taxAmount + shippingFee;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((e) => CartItem.fromJson(e)).toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// 🛍️ Cart Item Model
class CartItem {
  final String productId;
  final Product product;
  final int quantity;
  final double priceAtAddition;

  CartItem({
    required this.productId,
    required this.product,
    required this.quantity,
    required this.priceAtAddition,
  });

  double get subtotal => priceAtAddition * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? json['product']?['_id'] ?? '',
      product: Product.fromJson(
        json['product'] is Map ? json['product'] : {'_id': json['productId']},
      ),
      quantity: json['quantity'] ?? 1,
      priceAtAddition:
          (json['priceAtAddition'] ?? json['product']?['price'] ?? 0)
              .toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'product': product.toJson(),
      'quantity': quantity,
      'priceAtAddition': priceAtAddition,
    };
  }

  CartItem copyWith({
    String? productId,
    Product? product,
    int? quantity,
    double? priceAtAddition,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      priceAtAddition: priceAtAddition ?? this.priceAtAddition,
    );
  }
}
