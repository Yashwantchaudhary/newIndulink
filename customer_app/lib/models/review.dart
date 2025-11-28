class Review {
  final String id;
  final String productId;
  final String userId;
  final Map<String, dynamic>? user;
  final String orderId;
  final int rating;
  final String? title;
  final String review;
  final List<String>? images;
  final List<String> helpful;
  final int helpfulCount;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    this.user,
    required this.orderId,
    required this.rating,
    this.title,
    required this.review,
    this.images,
    this.helpful = const [],
    this.helpfulCount = 0,
    this.isVerifiedPurchase = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? '',
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      user: json['user'],
      orderId: json['orderId'] ?? '',
      rating: json['rating'] ?? 5,
      title: json['title'],
      review: json['review'] ?? json['comment'] ?? '',
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      helpful: (json['helpful'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      helpfulCount: json['helpfulCount'] ?? 0,
      isVerifiedPurchase: json['isVerifiedPurchase'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productId,
      'userId': userId,
      if (user != null) 'user': user,
      'orderId': orderId,
      'rating': rating,
      if (title != null) 'title': title,
      'review': review,
      if (images != null) 'images': images,
      'helpful': helpful,
      'helpfulCount': helpfulCount,
      'isVerifiedPurchase': isVerifiedPurchase,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  bool isHelpfulBy(String userId) => helpful.contains(userId);
}
