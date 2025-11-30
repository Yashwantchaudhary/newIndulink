/// 📦 Product Model
/// Represents a building materials product
class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? compareAtPrice;
  final List<ProductImage> images;
  final String categoryId;
  final String? categoryName;
  final String supplierId;
  final String? supplierName;
  final int stock;
  final String? sku;
  final ProductWeight? weight;
  final ProductDimensions? dimensions;
  final List<String> tags;
  final double averageRating;
  final int totalReviews;
  final ProductStatus status;
  final bool isFeatured;
  final String? metaTitle;
  final String? metaDescription;
  final int viewCount;
  final int purchaseCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.compareAtPrice,
    this.images = const [],
    required this.categoryId,
    this.categoryName,
    required this.supplierId,
    this.supplierName,
    this.stock = 0,
    this.sku,
    this.weight,
    this.dimensions,
    this.tags = const [],
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.status = ProductStatus.active,
    this.isFeatured = false,
    this.metaTitle,
    this.metaDescription,
    this.viewCount = 0,
    this.purchaseCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed Properties
  bool get inStock => stock > 0;
  bool get isOutOfStock => stock == 0;
  bool get isLowStock => stock > 0 && stock <= 10;
  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  int get discountPercentage {
    if (compareAtPrice == null || compareAtPrice! <= price) return 0;
    return ((compareAtPrice! - price) / compareAtPrice! * 100).round();
  }

  double get discountAmount {
    if (compareAtPrice == null || compareAtPrice! <= price) return 0;
    return compareAtPrice! - price;
  }

  String get primaryImageUrl {
    if (images.isEmpty) return '';
    final primary = images.firstWhere(
      (img) => img.isPrimary,
      orElse: () => images.first,
    );
    return primary.url;
  }

  String get stockStatusText {
    if (stock == 0) return 'Out of Stock';
    if (stock <= 10) return 'Low Stock ($stock left)';
    if (stock <= 50) return '$stock in stock';
    return 'In Stock';
  }

  // JSON Serialization
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      compareAtPrice: json['compareAtPrice'] != null
          ? (json['compareAtPrice']).toDouble()
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((e) => ProductImage.fromJson(e))
              .toList()
          : [],
      categoryId: json['category'] is String
          ? json['category']
          : json['category']?['_id'] ?? '',
      categoryName:
          json['category'] is Map ? (json['category'] as Map)['name'] : null,
      supplierId: json['supplier'] is String
          ? json['supplier']
          : json['supplier']?['_id'] ?? '',
      supplierName: json['supplier'] is Map
          ? '${json['supplier']?['firstName'] ?? ''} ${json['supplier']?['lastName'] ?? ''}'
              .trim()
          : null,
      stock: json['stock'] ?? 0,
      sku: json['sku'],
      weight: json['weight'] != null
          ? ProductWeight.fromJson(json['weight'])
          : null,
      dimensions: json['dimensions'] != null
          ? ProductDimensions.fromJson(json['dimensions'])
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      status: ProductStatus.fromString(json['status'] ?? 'active'),
      isFeatured: json['isFeatured'] ?? false,
      metaTitle: json['metaTitle'],
      metaDescription: json['metaDescription'],
      viewCount: json['viewCount'] ?? 0,
      purchaseCount: json['purchaseCount'] ?? 0,
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
      'title': title,
      'description': description,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'images': images.map((e) => e.toJson()).toList(),
      'category': categoryId,
      'supplier': supplierId,
      'stock': stock,
      'sku': sku,
      'weight': weight?.toJson(),
      'dimensions': dimensions?.toJson(),
      'tags': tags,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'status': status.value,
      'isFeatured': isFeatured,
      'metaTitle': metaTitle,
      'metaDescription': metaDescription,
      'viewCount': viewCount,
      'purchaseCount': purchaseCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? compareAtPrice,
    List<ProductImage>? images,
    String? categoryId,
    String? categoryName,
    String? supplierId,
    String? supplierName,
    int? stock,
    String? sku,
    ProductWeight? weight,
    ProductDimensions? dimensions,
    List<String>? tags,
    double? averageRating,
    int? totalReviews,
    ProductStatus? status,
    bool? isFeatured,
    String? metaTitle,
    String? metaDescription,
    int? viewCount,
    int? purchaseCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      images: images ?? this.images,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      tags: tags ?? this.tags,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      metaTitle: metaTitle ?? this.metaTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      viewCount: viewCount ?? this.viewCount,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 🖼️ Product Image Model
class ProductImage {
  final String url;
  final String? alt;
  final bool isPrimary;

  ProductImage({
    required this.url,
    this.alt,
    this.isPrimary = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'] ?? '',
      alt: json['alt'],
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'alt': alt,
      'isPrimary': isPrimary,
    };
  }
}

/// ⚖️ Product Weight Model
class ProductWeight {
  final double value;
  final WeightUnit unit;

  ProductWeight({
    required this.value,
    this.unit = WeightUnit.kg,
  });

  String get displayText => '$value ${unit.value}';

  factory ProductWeight.fromJson(Map<String, dynamic> json) {
    return ProductWeight(
      value: (json['value'] ?? 0).toDouble(),
      unit: WeightUnit.fromString(json['unit'] ?? 'kg'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit.value,
    };
  }
}

enum WeightUnit {
  kg,
  g,
  lb;

  String get value => name;

  static WeightUnit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'kg':
        return WeightUnit.kg;
      case 'g':
        return WeightUnit.g;
      case 'lb':
        return WeightUnit.lb;
      default:
        return WeightUnit.kg;
    }
  }
}

/// 📏 Product Dimensions Model
class ProductDimensions {
  final double length;
  final double width;
  final double height;
  final DimensionUnit unit;

  ProductDimensions({
    required this.length,
    required this.width,
    required this.height,
    this.unit = DimensionUnit.cm,
  });

  String get displayText => '$length x $width x $height ${unit.value}';

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    return ProductDimensions(
      length: (json['length'] ?? 0).toDouble(),
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      unit: DimensionUnit.fromString(json['unit'] ?? 'cm'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'width': width,
      'height': height,
      'unit': unit.value,
    };
  }
}

enum DimensionUnit {
  cm,
  inch;

  String get value {
    switch (this) {
      case DimensionUnit.cm:
        return 'cm';
      case DimensionUnit.inch:
        return 'in';
    }
  }

  static DimensionUnit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cm':
        return DimensionUnit.cm;
      case 'in':
      case 'inch':
        return DimensionUnit.inch;
      default:
        return DimensionUnit.cm;
    }
  }
}

/// 📊 Product Status Enum
enum ProductStatus {
  active,
  inactive,
  outOfStock,
  discontinued;

  String get value {
    switch (this) {
      case ProductStatus.active:
        return 'active';
      case ProductStatus.inactive:
        return 'inactive';
      case ProductStatus.outOfStock:
        return 'out_of_stock';
      case ProductStatus.discontinued:
        return 'discontinued';
    }
  }

  String get displayName {
    switch (this) {
      case ProductStatus.active:
        return 'Active';
      case ProductStatus.inactive:
        return 'Inactive';
      case ProductStatus.outOfStock:
        return 'Out of Stock';
      case ProductStatus.discontinued:
        return 'Discontinued';
    }
  }

  static ProductStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return ProductStatus.active;
      case 'inactive':
        return ProductStatus.inactive;
      case 'out_of_stock':
        return ProductStatus.outOfStock;
      case 'discontinued':
        return ProductStatus.discontinued;
      default:
        return ProductStatus.active;
    }
  }
}
