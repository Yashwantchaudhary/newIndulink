import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/review_card_widget.dart';
import '../../../core/widgets/loading_widgets.dart';
import '../../../providers/review_provider.dart';
import '../../../models/review.dart';

/// 📝 Full Reviews Screen
/// Shows all reviews for a specific product with filtering and sorting
class FullReviewsScreen extends StatefulWidget {
  final String productId;
  final String productTitle;
  final String? productImage;

  const FullReviewsScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    this.productImage,
  });

  @override
  State<FullReviewsScreen> createState() => _FullReviewsScreenState();
}

class _FullReviewsScreenState extends State<FullReviewsScreen> {
  String _sortBy = 'newest'; // newest, oldest, highest, lowest
  int _ratingFilter = 0; // 0 = all, 1-5 = specific rating
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // Fetch reviews when screen loads
      Future.microtask(() => Provider.of<ReviewProvider>(context, listen: false)
          .fetchProductReviews(widget.productId, refresh: true));
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Reviews'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Product Header
          _buildProductHeader(),

          // Filters and Sorting
          _buildFiltersSection(),

          // Reviews List
          Expanded(
            child: Consumer<ReviewProvider>(
              builder: (context, reviewProvider, _) {
                if (reviewProvider.isLoading &&
                    reviewProvider.reviews.isEmpty) {
                  return const Center(child: LoadingSpinner());
                }

                if (reviewProvider.errorMessage != null) {
                  return Center(child: Text(reviewProvider.errorMessage!));
                }

                return _buildReviewsList(reviewProvider.reviews);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      color: Colors.white,
      child: Row(
        children: [
          // Product Image
          if (widget.productImage != null)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(widget.productImage!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.textTertiary,
                size: 30,
              ),
            ),

          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productTitle,
                  style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Consumer<ReviewProvider>(
                  builder: (context, provider, _) => Text(
                    '${provider.reviews.length} Customer Reviews',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort By
          Text(
            'Sort by',
            style:
                AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip('Newest', 'newest'),
                const SizedBox(width: 8),
                _buildSortChip('Oldest', 'oldest'),
                const SizedBox(width: 8),
                _buildSortChip('Highest Rated', 'highest'),
                const SizedBox(width: 8),
                _buildSortChip('Lowest Rated', 'lowest'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter by Rating
          Text(
            'Filter by rating',
            style:
                AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRatingFilterChip('All', 0),
                const SizedBox(width: 8),
                _buildRatingFilterChip('5 Stars', 5),
                const SizedBox(width: 8),
                _buildRatingFilterChip('4 Stars', 4),
                const SizedBox(width: 8),
                _buildRatingFilterChip('3 Stars', 3),
                const SizedBox(width: 8),
                _buildRatingFilterChip('2 Stars', 2),
                const SizedBox(width: 8),
                _buildRatingFilterChip('1 Star', 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _sortBy = value);
        }
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryLightest,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildRatingFilterChip(String label, int rating) {
    final isSelected = _ratingFilter == rating;
    return FilterChip(
      label: Row(
        children: [
          if (rating > 0) ...[
            Icon(
              Icons.star,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.warning,
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _ratingFilter = selected ? rating : 0);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryLightest,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildReviewsList(List<Review> reviews) {
    // Apply filters matching local logic
    // (Ideally backend handles this via API params, but we do client side filtering for now as per original code logic)
    var filteredReviews = reviews.toList();
    if (_ratingFilter > 0) {
      filteredReviews = filteredReviews
          .where((review) => review.rating == _ratingFilter)
          .toList();
    }

    // Apply sorting
    filteredReviews.sort((a, b) {
      switch (_sortBy) {
        case 'oldest':
          return a.createdAt.compareTo(b.createdAt);
        case 'highest':
          return b.rating.compareTo(a.rating);
        case 'lowest':
          return a.rating.compareTo(b.rating);
        case 'newest':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    if (filteredReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              _ratingFilter > 0
                  ? 'No $_ratingFilter-star reviews yet'
                  : 'No reviews found',
              style: AppTypography.h6.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to leave a review!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: filteredReviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final review = filteredReviews[index];
        return ReviewCard(review: review);
      },
    );
  }
}
