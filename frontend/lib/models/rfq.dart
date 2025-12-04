class RFQ {
  final String id;
  final String rfqNumber;
  final String customerId;
  final List<RFQItem> items;
  final String status; // pending, quoted, accepted, rejected, closed
  final List<Quote> quotes;
  final String? selectedQuoteId;
  final DeliveryAddress? deliveryAddress;
  final String? notes;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RFQ({
    required this.id,
    required this.rfqNumber,
    required this.customerId,
    required this.items,
    this.status = 'pending',
    this.quotes = const [],
    this.selectedQuoteId,
    this.deliveryAddress,
    this.notes,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RFQ.fromJson(Map<String, dynamic> json) {
    return RFQ(
      id: json['_id'] ?? json['id'] ?? '',
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
      deliveryAddress: json['deliveryAddress'] != null
          ? DeliveryAddress.fromJson(json['deliveryAddress'])
          : null,
      notes: json['notes'],
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

/// RFQ Item model
class RFQItem {
  final String productId;
  final Map<String, dynamic>? productSnapshot;
  final int quantity;
  final String? specifications;

  RFQItem({
    required this.productId,
    this.productSnapshot,
    required this.quantity,
    this.specifications,
  });

  factory RFQItem.fromJson(Map<String, dynamic> json) {
    return RFQItem(
      productId: json['productId'] ?? '',
      productSnapshot: json['productSnapshot'],
      quantity: json['quantity'] ?? 0,
      specifications: json['specifications'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      if (specifications != null) 'specifications': specifications,
    };
  }
}

/// Delivery Address model
class DeliveryAddress {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  DeliveryAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      if (addressLine2 != null) 'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }
}

/// Quote Item model
class QuoteItem {
  final String productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  QuoteItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      productId: json['productId'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }
}

/// Quote model (supplier's response to RFQ)
class Quote {
  final String supplierId;
  final List<QuoteItem> items;
  final double totalAmount;
  final DateTime? validUntil;
  final String? notes;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  Quote({
    required this.supplierId,
    required this.items,
    required this.totalAmount,
    this.validUntil,
    this.notes,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      supplierId: json['supplierId'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => QuoteItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
