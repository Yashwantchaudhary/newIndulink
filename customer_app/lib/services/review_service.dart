import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  final ApiService _apiService = ApiService();

  // Get reviews for a product
  Future<List<Review>> getProductReviews(
    String productId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/reviews/product/$productId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final reviewsData = response.data['data']['reviews'] as List;
        return reviewsData.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Get user's reviews
  Future<List<Review>> getMyReviews({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/reviews/my-reviews',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final reviewsData = response.data['data']['reviews'] as List;
        return reviewsData.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Create a review
  Future<Review> createReview({
    required String productId,
    required double rating,
    required String review,
    List<String>? images,
  }) async {
    try {
      final response = await _apiService.post(
        '/reviews',
        data: {
          'product': productId,
          'rating': rating,
          'review': review,
          if (images != null) 'images': images,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return Review.fromJson(response.data['data']);
      }
      throw Exception('Failed to create review');
    } catch (e) {
      rethrow;
    }
  }

  // Update a review
  Future<Review> updateReview(
    String reviewId, {
    double? rating,
    String? review,
    List<String>? images,
  }) async {
    try {
      final response = await _apiService.put(
        '/reviews/$reviewId',
        data: {
          if (rating != null) 'rating': rating,
          if (review != null) 'review': review,
          if (images != null) 'images': images,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Review.fromJson(response.data['data']);
      }
      throw Exception('Failed to update review');
    } catch (e) {
      rethrow;
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _apiService.delete('/reviews/$reviewId');
    } catch (e) {
      rethrow;
    }
  }

  // Mark review as helpful
  Future<void> markHelpful(String reviewId) async {
    try {
      await _apiService.post('/reviews/$reviewId/helpful');
    } catch (e) {
      rethrow;
    }
  }

  // Report a review
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await _apiService.post(
        '/reviews/$reviewId/report',
        data: {'reason': reason},
      );
    } catch (e) {
      rethrow;
    }
  }
}
