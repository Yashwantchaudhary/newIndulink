class RFQItem {
  final String productId;
  final String? productTitle;
  final String? productImage;
  final int quantity;
  final String? specifications;

  RFQItem({
    required this.productId,
    this.productTitle,
    this.productImage,
    required this.quantity,
    this.specifications,
  });

  factory RFQItem.fromJson(Map<String, dynamic> json) {
    return RFQItem(
      productId: json['productId'] ?? '',
      productTitle: json['productSnapshot']?['title'],
      productImage: json['productSnapshot']?['image'],
      quantity: json['quantity'] ?? 1,
      specifications: json['specifications'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      if (productTitle != null || productImage != null)
        'productSnapshot': {
          if (productTitle != null) 'title': productTitle,
          if (productImage != null) 'image': productImage,
        },
      'quantity': quantity,
      if (specifications != null) 'specifications': specifications,
    };
  }
}

class Quote {
  final String? id;
  final String supplierId;
  final String? supplierName;
  final double totalAmount;
  final String? notes;
  final DateTime? validUntil;
  final String status;
  final DateTime createdAt;
  final double? price;
  final String? supplier;
  final String? description;
  final int? deliveryTime;

  Quote({
    this.id,
    required this.supplierId,
    this.supplierName,
    required this.totalAmount,
    this.notes,
    this.validUntil,
    this.status = 'pending',
    required this.createdAt,
    this.price,
    this.supplier,
    this.description,
    this.deliveryTime,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['_id']?.toString(),
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      notes: json['notes'],
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      supplier: json['supplier'],
      description: json['description'],
      deliveryTime:
          json['deliveryTime'] != null ? json['deliveryTime'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'supplierId': supplierId,
      'totalAmount': totalAmount,
      if (notes != null) 'notes': notes,
      if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class RFQ {
  final String id;
  final String rfqNumber;
  final String customerId;
  final List<RFQItem> items;
  final String status;
  final List<Quote> quotes;
  final String? selectedQuoteId;
  final String? notes;
  final String? description;
  final int? quantity;
  final double? idealPrice;
  final DateTime? deliveryDate;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? closedAt;

  RFQ({
    required this.id,
    required this.rfqNumber,
    required this.customerId,
    required this.items,
    this.status = 'pending',
    this.quotes = const [],
    this.selectedQuoteId,
    this.notes,
    this.description,
    this.quantity,
    this.idealPrice,
    this.deliveryDate,
    required this.expiresAt,
    required this.createdAt,
    this.closedAt,
  });

  factory RFQ.fromJson(Map<String, dynamic> json) {
    return RFQ(
      id: json['_id'] ?? '',
      rfqNumber: json['rfqNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => RFQItem.fromJson(item))
              .toList() ??
          [],
      status: json['status'] ?? 'pending',
      quotes: (json['quotes'] as List<dynamic>?)
              ?.map((quote) => Quote.fromJson(quote))
              .toList() ??
          [],
      selectedQuoteId: json['selectedQuoteId'],
      notes: json['notes'],
      description: json['description'],
      quantity: json['quantity'] != null ? json['quantity'] as int : null,
      idealPrice: json['idealPrice'] != null
          ? (json['idealPrice'] as num).toDouble()
          : null,
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(days: 7)),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      closedAt:
          json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'rfqNumber': rfqNumber,
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'quotes': quotes.map((quote) => quote.toJson()).toList(),
      if (selectedQuoteId != null) 'selectedQuoteId': selectedQuoteId,
      if (notes != null) 'notes': notes,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
    };
  }

  int get quoteCount => quotes.length;

  bool get hasQuotes => quotes.isNotEmpty;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  List<String> get products => items.map((item) => item.productId).toList();
}
