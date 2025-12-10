import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_config.dart';
import '../models/review.dart';
import '../services/api_service.dart';

/// 🌟 Review Provider
/// Manages product reviews state and API interactions
class ReviewProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<Review> _currentProductReviews = [];
  ReviewStats? _currentProductStats;

  // Pagination
  int _currentPage = 1;
  // ignore: unused_field
  int _totalPages = 1;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Review> get reviews => _currentProductReviews;
  ReviewStats? get stats => _currentProductStats;

  /// Fetch reviews for a specific product
  Future<void> fetchProductReviews(String productId,
      {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _currentProductReviews = [];
    }

    _setLoading(true);

    try {
      final endpoint =
          AppConfig.productReviewsEndpoint.replaceAll(':id', productId) +
              '?page=$_currentPage&limit=10';

      final response = await _apiService.get(endpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data['data'] as List;
        final newReviews = data.map((json) => Review.fromJson(json)).toList();

        if (refresh) {
          _currentProductReviews = newReviews;
        } else {
          _currentProductReviews.addAll(newReviews);
        }

        _totalPages = response.data['pages'] ?? 1;
        _currentPage++;

        // Also fetch stats if refreshing
        if (refresh) {
          await _fetchProductStats(productId);
        }
      } else {
        _setError(response.message ?? 'Failed to load reviews');
      }
    } catch (e) {
      _setError('Error fetching reviews: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Internal method to fetch stats (mocked or from API if available)
  Future<void> _fetchProductStats(String productId) async {
    if (_currentProductReviews.isNotEmpty) {
      double totalRating = 0;
      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var r in _currentProductReviews) {
        totalRating += r.rating;
        // Ensure rating is valid integer 1-5
        int rating = r.rating.toInt();
        if (rating < 1) rating = 1;
        if (rating > 5) rating = 5;

        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      _currentProductStats = ReviewStats(
        averageRating: totalRating / _currentProductReviews.length,
        totalReviews: _currentProductReviews.length,
        ratingDistribution: distribution,
      );
      notifyListeners();
    }
  }

  /// Submit a new review
  Future<bool> submitReview(ReviewSubmission submission) async {
    _setLoading(true);

    try {
      // If there are images, we need to upload them
      if (submission.imagePaths.isNotEmpty) {
        // Convert paths to XFiles
        final files = submission.imagePaths.map((path) => XFile(path)).toList();

        // Prepare fields
        final fields = {
          'product': submission.productId,
          'rating': submission.rating.toString(),
          'comment': submission.comment,
        };

        if (submission.title != null) fields['title'] = submission.title!;
        if (submission.orderId != null) fields['order'] = submission.orderId!;

        final response = await _apiService.uploadFiles(
          AppConfig.addReviewEndpoint,
          files,
          fields: fields,
          fileField: 'images', // Backend expects 'images' field for files
        );

        if (response.isSuccess) {
          await fetchProductReviews(submission.productId, refresh: true);
          return true;
        } else {
          _setError(response.message ?? 'Failed to submit review');
          return false;
        }
      } else {
        // No images, standard POST request
        final body = submission.toJson();

        final response = await _apiService.post(
          AppConfig.addReviewEndpoint,
          body: body,
        );

        if (response.isSuccess) {
          await fetchProductReviews(submission.productId, refresh: true);
          return true;
        } else {
          _setError(response.message ?? 'Failed to submit review');
          return false;
        }
      }
    } catch (e) {
      _setError('Error submitting review: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mark review as helpful
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      final endpoint =
          AppConfig.markReviewHelpfulEndpoint.replaceAll(':id', reviewId);
      final response = await _apiService.put(endpoint);

      if (response.isSuccess) {
        // Update local state
        final index =
            _currentProductReviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          final review = _currentProductReviews[index];

          if (response.data != null && response.data['data'] != null) {
            final newCount = response.data['data']['helpfulCount'];
            // Create new review object with updated count
            _currentProductReviews[index] =
                review.copyWith(helpfulCount: newCount);
            notifyListeners();
          } else {
            // If no data returned, just increment locally as fallback
            // (Assuming toggle behavior, but typically helpful is increment only or toggle)
            // Ideally backend returns the new state.
          }
        }
      }
    } catch (e) {
      debugPrint('Error marking helpful: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _isLoading = false;
    notifyListeners();
  }
}
