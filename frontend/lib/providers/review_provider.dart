import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../core/constants/app_config.dart';

/// 📝 Review Provider
/// Manages product reviews state and API interactions
class ReviewProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  List<Review> _reviews = [];
  ReviewStats? _reviewStats;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Getters
  List<Review> get reviews => _reviews;
  ReviewStats? get reviewStats => _reviewStats;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set submitting state
  void _setSubmitting(bool submitting) {
    _isSubmitting = submitting;
    notifyListeners();
  }

  /// Fetch reviews for a product
  Future<void> fetchProductReviews(String productId, {int page = 1, int limit = 10}) async {
    _setLoading(true);
    _clearError();

    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.productReviewsEndpoint,
        {'id': productId},
      );
      final response = await _apiService.get(
        endpoint,
        params: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.isSuccess && response.data != null) {
        final reviewsData = response.data['data'] as List<dynamic>? ?? [];
        _reviews = reviewsData.map((json) => Review.fromJson(json)).toList();
      } else {
        _setError(response.message ?? 'Failed to load reviews');
      }
    } catch (e) {
      _setError('Error loading reviews: $e');
    }

    _setLoading(false);
  }

  /// Submit a new review
  Future<bool> submitReview(ReviewSubmission submission) async {
    _setSubmitting(true);
    _clearError();

    try {
      // Prepare the request data
      final requestData = {
        'product': submission.productId,
        'rating': submission.rating,
        'comment': submission.comment,
      };

      if (submission.orderId != null) {
        requestData['order'] = submission.orderId!;
      }

      if (submission.title != null && submission.title!.isNotEmpty) {
        requestData['title'] = submission.title!;
      }

      // TODO: Handle image uploads when implementing multi-image upload
      // For now, we'll skip images

      final response = await _apiService.post(AppConfig.addReviewEndpoint, body: requestData);

      if (response.isSuccess) {
        // Refresh reviews after successful submission
        await fetchProductReviews(submission.productId);
        _setSubmitting(false);
        return true;
      } else {
        _setError(response.message ?? 'Failed to submit review');
        _setSubmitting(false);
        return false;
      }
    } catch (e) {
      _setError('Error submitting review: $e');
      _setSubmitting(false);
      return false;
    }
  }

  /// Update an existing review
  Future<bool> updateReview(String reviewId, {
    int? rating,
    String? title,
    String? comment,
  }) async {
    _setSubmitting(true);
    _clearError();

    try {
      final updateData = <String, dynamic>{};
      if (rating != null) updateData['rating'] = rating;
      if (title != null) updateData['title'] = title;
      if (comment != null) updateData['comment'] = comment;

      final response = await _apiService.put('/api/reviews/$reviewId', body: updateData);

      if (response.isSuccess) {
        // Update local review
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          final updatedReview = _reviews[index].copyWith(
            rating: rating ?? _reviews[index].rating,
            title: title ?? _reviews[index].title,
            comment: comment ?? _reviews[index].comment,
            updatedAt: DateTime.now(),
          );
          _reviews[index] = updatedReview;
          notifyListeners();
        }
        _setSubmitting(false);
        return true;
      } else {
        _setError(response.message ?? 'Failed to update review');
        _setSubmitting(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating review: $e');
      _setSubmitting(false);
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    _setSubmitting(true);
    _clearError();

    try {
      final response = await _apiService.delete('/api/reviews/$reviewId');

      if (response.isSuccess) {
        // Remove from local list
        _reviews.removeWhere((r) => r.id == reviewId);
        notifyListeners();
        _setSubmitting(false);
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete review');
        _setSubmitting(false);
        return false;
      }
    } catch (e) {
      _setError('Error deleting review: $e');
      _setSubmitting(false);
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markReviewHelpful(String reviewId) async {
    try {
      final response = await _apiService.put('/api/reviews/$reviewId/helpful');

      if (response.isSuccess && response.data != null) {
        // Update local review helpful count
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          final newHelpfulCount = response.data['helpfulCount'] ?? _reviews[index].helpfulCount;
          final updatedReview = _reviews[index].copyWith(
            helpfulCount: newHelpfulCount,
          );
          _reviews[index] = updatedReview;
          notifyListeners();
        }
        return true;
      } else {
        _setError(response.message ?? 'Failed to mark review as helpful');
        return false;
      }
    } catch (e) {
      _setError('Error marking review as helpful: $e');
      return false;
    }
  }

  /// Check if user can review a product
  Future<Map<String, dynamic>> checkReviewEligibility(String productId) async {
    try {
      // This would typically check if user has purchased the product
      // For now, return basic eligibility
      return {
        'canReview': true,
        'hasPurchased': false,
        'message': 'You can review this product',
      };
    } catch (e) {
      return {
        'canReview': false,
        'hasPurchased': false,
        'message': 'Unable to check review eligibility',
      };
    }
  }

  /// Clear all reviews (for when switching products)
  void clearReviews() {
    _reviews = [];
    _reviewStats = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh reviews
  Future<void> refresh() async {
    // This would need the current product ID
    // For now, just clear error
    _clearError();
  }
}