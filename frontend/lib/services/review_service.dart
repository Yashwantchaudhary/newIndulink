import '../models/review.dart';
import 'api_service.dart';

/// 📝 Review Service
/// Handles product review operations
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final ApiService _api = ApiService();

  // ==================== Fetch Reviews ====================

  /// Get all reviews for a product
  Future<ReviewResult> getProductReviews(String productId) async {
    try {
      final endpoint = '/reviews/product/$productId';
      final response = await _api.get(
        endpoint,
        requiresAuth: false,
        retries: 2,
      );

      if (response.isSuccess && response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;

        // Unwrap data if needed
        final actualData = dataMap.containsKey('data')
            ? Map<String, dynamic>.from(dataMap['data'] as Map)
            : dataMap;

        final reviewsJson = actualData['reviews'] ?? actualData['data'] ?? [];
        final reviews =
            (reviewsJson as List).map((json) => Review.fromJson(json)).toList();

        return ReviewResult(
          success: true,
          reviews: reviews,
          total: actualData['total'] ?? reviews.length,
          averageRating: actualData['averageRating']?.toDouble() ?? 0.0,
          ratingBreakdown: actualData['ratingBreakdown'] != null
              ? Map<String, int>.from(actualData['ratingBreakdown'])
              : {},
        );
      } else {
        return ReviewResult(
          success: false,
          message: response.message ?? 'Failed to fetch reviews',
        );
      }
    } catch (e) {
      return ReviewResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Create a review (requires authentication)
  Future<ReviewResult> createReview({
    required String productId,
    required int rating,
    required String comment,
    String? title,
    List<String>? images,
  }) async {
    try {
      final response = await _api.post(
        '/reviews',
        body: {
          'productId': productId,
          'rating': rating,
          'comment': comment,
          if (title != null) 'title': title,
          if (images != null) 'images': images,
        },
      );

      if (response.isSuccess && response.data != null) {
        final review = Review.fromJson(response.data);
        return ReviewResult(
          success: true,
          reviews: [review],
          message: 'Review posted successfully',
        );
      } else {
        return ReviewResult(
          success: false,
          message: response.message ?? 'Failed to create review',
        );
      }
    } catch (e) {
      return ReviewResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Mark review as helpful
  Future<bool> markReviewHelpful(String reviewId) async {
    try {
      final response = await _api.put('/reviews/$reviewId/helpful');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }
}

/// 📋 Review Result Model
class ReviewResult {
  final bool success;
  final String? message;
  final List<Review> reviews;
  final int? total;
  final double? averageRating;
  final Map<String, int>? ratingBreakdown;

  ReviewResult({
    required this.success,
    this.message,
    this.reviews = const [],
    this.total,
    this.averageRating,
    this.ratingBreakdown,
  });
}
