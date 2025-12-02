import 'package:equatable/equatable.dart';
import 'user.dart';

/// 📝 Review Model
/// Represents a product review with rating, comments, and metadata
class Review extends Equatable {
  final String id;
  final String productId;
  final User customer;
  final String? orderId;
  final int rating;
  final String? title;
  final String comment;
  final List<ReviewImage> images;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final List<String> helpfulBy;
  final ReviewStatus status;
  final SupplierResponse? response;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Review({
    required this.id,
    required this.productId,
    required this.customer,
    this.orderId,
    required this.rating,
    this.title,
    required this.comment,
    this.images = const [],
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    this.helpfulBy = const [],
    this.status = ReviewStatus.approved,
    this.response,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Review from JSON
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? json['id'] ?? '',
      productId: json['product'] ?? '',
      customer: User.fromJson(json['customer'] ?? {}),
      orderId: json['order'],
      rating: json['rating'] ?? 0,
      title: json['title'],
      comment: json['comment'] ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((img) => ReviewImage.fromJson(img))
              .toList() ??
          [],
      isVerifiedPurchase: json['isVerifiedPurchase'] ?? false,
      helpfulCount: json['helpfulCount'] ?? 0,
      helpfulBy: (json['helpfulBy'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          [],
      status: ReviewStatus.fromString(json['status'] ?? 'approved'),
      response: json['response'] != null
          ? SupplierResponse.fromJson(json['response'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert Review to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'product': productId,
      'customer': customer.toJson(),
      'order': orderId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images.map((img) => img.toJson()).toList(),
      'isVerifiedPurchase': isVerifiedPurchase,
      'helpfulCount': helpfulCount,
      'helpfulBy': helpfulBy,
      'status': status.value,
      'response': response?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Check if current user marked this review as helpful
  bool isMarkedHelpfulBy(String userId) {
    return helpfulBy.contains(userId);
  }

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  /// Get star rating display
  List<bool> get starRating {
    return List.generate(5, (index) => index < rating);
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        customer,
        orderId,
        rating,
        title,
        comment,
        images,
        isVerifiedPurchase,
        helpfulCount,
        helpfulBy,
        status,
        response,
        createdAt,
        updatedAt,
      ];

  /// Copy with method
  Review copyWith({
    String? id,
    String? productId,
    User? customer,
    String? orderId,
    int? rating,
    String? title,
    String? comment,
    List<ReviewImage>? images,
    bool? isVerifiedPurchase,
    int? helpfulCount,
    List<String>? helpfulBy,
    ReviewStatus? status,
    SupplierResponse? response,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      customer: customer ?? this.customer,
      orderId: orderId ?? this.orderId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulBy: helpfulBy ?? this.helpfulBy,
      status: status ?? this.status,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 🖼️ Review Image Model
class ReviewImage extends Equatable {
  final String url;
  final String? alt;

  const ReviewImage({
    required this.url,
    this.alt,
  });

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(
      url: json['url'] ?? '',
      alt: json['alt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'alt': alt,
    };
  }

  @override
  List<Object?> get props => [url, alt];
}

/// 📊 Review Status Enum
enum ReviewStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const ReviewStatus(this.value);
  final String value;

  static ReviewStatus fromString(String value) {
    return ReviewStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReviewStatus.approved,
    );
  }

  String get displayName {
    switch (this) {
      case ReviewStatus.pending:
        return 'Pending';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.rejected:
        return 'Rejected';
    }
  }
}

/// 💬 Supplier Response Model
class SupplierResponse extends Equatable {
  final String comment;
  final DateTime respondedAt;

  const SupplierResponse({
    required this.comment,
    required this.respondedAt,
  });

  factory SupplierResponse.fromJson(Map<String, dynamic> json) {
    return SupplierResponse(
      comment: json['comment'] ?? '',
      respondedAt: DateTime.parse(json['respondedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
      'respondedAt': respondedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [comment, respondedAt];
}

/// 📋 Review Statistics Model
class ReviewStats extends Equatable {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1-5 stars count

  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: {
        1: json['ratingDistribution']?['1'] ?? 0,
        2: json['ratingDistribution']?['2'] ?? 0,
        3: json['ratingDistribution']?['3'] ?? 0,
        4: json['ratingDistribution']?['4'] ?? 0,
        5: json['ratingDistribution']?['5'] ?? 0,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
    };
  }

  @override
  List<Object?> get props => [averageRating, totalReviews, ratingDistribution];
}

/// 📝 Review Submission Model
class ReviewSubmission extends Equatable {
  final String productId;
  final String? orderId;
  final int rating;
  final String? title;
  final String comment;
  final List<String> imagePaths; // Local file paths for upload

  const ReviewSubmission({
    required this.productId,
    this.orderId,
    required this.rating,
    this.title,
    required this.comment,
    this.imagePaths = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'order': orderId,
      'rating': rating,
      'title': title,
      'comment': comment,
      // Images will be handled separately as multipart
    };
  }

  @override
  List<Object?> get props => [productId, orderId, rating, title, comment, imagePaths];
}