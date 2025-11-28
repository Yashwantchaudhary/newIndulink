import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';

// Review State
class ReviewState {
  final List<Review> reviews;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  ReviewState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Review Notifier
class ReviewNotifier extends StateNotifier<ReviewState> {
  final ReviewService _reviewService = ReviewService();

  ReviewNotifier() : super(ReviewState());

  // Load product reviews
  Future<void> loadProductReviews(String productId,
      {bool loadMore = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = loadMore ? state.currentPage + 1 : 1;
      final newReviews =
          await _reviewService.getProductReviews(productId, page: page);

      state = state.copyWith(
        reviews: loadMore ? [...state.reviews, ...newReviews] : newReviews,
        isLoading: false,
        currentPage: page,
        hasMore: newReviews.length >= 20, // Assuming 20 is the page size
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Load user's reviews
  Future<void> loadMyReviews({bool loadMore = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = loadMore ? state.currentPage + 1 : 1;
      final newReviews = await _reviewService.getMyReviews(page: page);

      state = state.copyWith(
        reviews: loadMore ? [...state.reviews, ...newReviews] : newReviews,
        isLoading: false,
        currentPage: page,
        hasMore: newReviews.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create review
  Future<bool> createReview({
    required String productId,
    required double rating,
    required String review,
    List<String>? images,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newReview = await _reviewService.createReview(
        productId: productId,
        rating: rating,
        review: review,
        images: images,
      );

      state = state.copyWith(
        reviews: [newReview, ...state.reviews],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Update review
  Future<bool> updateReview(
    String reviewId, {
    double? rating,
    String? review,
    List<String>? images,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedReview = await _reviewService.updateReview(
        reviewId,
        rating: rating,
        review: review,
        images: images,
      );

      final updatedReviews = state.reviews.map((r) {
        return r.id == reviewId ? updatedReview : r;
      }).toList();

      state = state.copyWith(
        reviews: updatedReviews,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Delete review
  Future<bool> deleteReview(String reviewId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _reviewService.deleteReview(reviewId);

      state = state.copyWith(
        reviews: state.reviews.where((r) => r.id != reviewId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Mark review as helpful
  Future<void> markHelpful(String reviewId) async {
    try {
      await _reviewService.markHelpful(reviewId);
      // Optionally update local state to reflect helpful count
    } catch (e) {
      // Handle error silently or show toast
    }
  }

  // Report review
  Future<bool> reportReview(String reviewId, String reason) async {
    try {
      await _reviewService.reportReview(reviewId, reason);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear reviews
  void clearReviews() {
    state = ReviewState();
  }
}

// Provider
final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier();
});
