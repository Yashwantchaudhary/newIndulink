import '../services/cdn_service.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? compareAtPrice;
  final List<ProductImage> images;
  final String categoryId;
  final String supplierId;
  final int stock;
  final String? sku;
  final double averageRating;
  final int totalReviews;
  final String status;
  final bool isFeatured;
  final DateTime createdAt;

  // Populated fields
  final Category? category;
  final Supplier? supplier;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.compareAtPrice,
    this.images = const [],
    required this.categoryId,
    required this.supplierId,
    required this.stock,
    this.sku,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.status = 'active',
    this.isFeatured = false,
    required this.createdAt,
    this.category,
    this.supplier,
  });

  bool get isInStock => stock > 0;

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  int get discountPercentage {
    if (!hasDiscount) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  bool get isNew => DateTime.now().difference(createdAt).inDays <= 7;

  String get primaryImageUrl {
    if (images.isEmpty) return '';
    final primary = images.firstWhere(
      (img) => img.isPrimary,
      orElse: () => images.first,
    );
    return primary.url;
  }

  // CDN-optimized image URL with automatic format conversion and sizing
  String getOptimizedImageUrl({
    int? width,
    int? height,
    String quality = 'high',
    String format = 'webp',
    String fit = 'cover',
  }) {
    final baseUrl = primaryImageUrl;
    if (baseUrl.isEmpty) return '';

    // Use CDN service for optimized URL generation and fallback
    return CdnService().getOptimizedImageUrl(
      baseUrl,
      width: width,
      height: height,
      quality: quality,
      format: format,
      fit: fit,
    );
  }

  // Predefined optimized URLs for common use cases
  String get thumbnailUrl =>
      getOptimizedImageUrl(width: 150, height: 150, quality: 'medium');
  String get cardImageUrl =>
      getOptimizedImageUrl(width: 300, height: 300, quality: 'high');
  String get detailImageUrl =>
      getOptimizedImageUrl(width: 600, height: 600, quality: 'high');
  String get fullImageUrl => getOptimizedImageUrl(width: 1200, quality: 'high');

  String get name => title;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      compareAtPrice: json['compareAtPrice']?.toDouble(),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categoryId: json['category'] is String
          ? json['category']
          : json['category']?['_id'] ?? '',
      supplierId: json['supplier'] is String
          ? json['supplier']
          : json['supplier']?['_id'] ?? '',
      stock: json['stock'] ?? 0,
      sku: json['sku'],
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      status: json['status'] ?? 'active',
      isFeatured: json['isFeatured'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      category: json['category'] is Map
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      supplier: json['supplier'] is Map
          ? Supplier.fromJson(json['supplier'] as Map<String, dynamic>)
          : null,
    );
  }
}

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
}

class Category {
  final String id;
  final String name;
  final String? slug;

  Category({
    required this.id,
    required this.name,
    this.slug,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'],
    );
  }
}

class Supplier {
  final String id;
  final String firstName;
  final String lastName;
  final String? businessName;

  Supplier({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.businessName,
  });

  String get displayName => businessName ?? '$firstName $lastName';

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      businessName: json['businessName'],
    );
  }
}
