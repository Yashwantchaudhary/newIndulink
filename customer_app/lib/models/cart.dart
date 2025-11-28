/// Cart data models for shopping cart functionality
library;

class Cart {
  final String? id;
  final String? userId;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final DateTime? updatedAt;

  Cart({
    this.id,
    this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.updatedAt,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  factory Cart.empty() {
    return Cart(
      items: [],
      subtotal: 0,
      tax: 0,
      total: 0,
    );
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return Cart(
      id: json['_id'] as String?,
      userId: json['user'] as String?,
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (userId != null) 'user': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Cart copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CartItem {
  final String? id;
  final CartProduct product;
  final int quantity;
  final double price;
  final double subtotal;

  CartItem({
    this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] as String?,
      product: CartProduct.fromJson(
        json['product'] as Map<String, dynamic>? ?? {},
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  CartItem copyWith({
    String? id,
    CartProduct? product,
    int? quantity,
    double? price,
    double? subtotal,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}

class CartProduct {
  final String id;
  final String title;
  final String? image;
  final double price;
  final int stock;

  CartProduct({
    required this.id,
    required this.title,
    this.image,
    required this.price,
    required this.stock,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    // Handle both populated product object and simple product reference
    final productData = json['_id'] != null ? json : {};

    // Get first image URL if available
    String? imageUrl;
    if (productData['images'] != null && productData['images'] is List) {
      final images = productData['images'] as List;
      if (images.isNotEmpty) {
        final firstImage = images[0];
        imageUrl = firstImage is Map ? firstImage['url'] as String? : null;
      }
    }

    return CartProduct(
      id: productData['_id'] as String? ?? json['_id'] as String? ?? '',
      title: productData['title'] as String? ?? '',
      image: imageUrl,
      price: (productData['price'] as num?)?.toDouble() ?? 0.0,
      stock: (productData['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      if (image != null)
        'images': [
          {'url': image}
        ],
      'price': price,
      'stock': stock,
    };
  }
}
