import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widgets.dart';
import '../../../core/widgets/report_dialog.dart';
import '../../../core/widgets/review_card_widget.dart';

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
            child: _buildReviewsList(),
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
                Text(
                  'Customer Reviews',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
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
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildReviewsList() {
    // TODO: Replace with actual review provider data
    // For now, showing mock reviews
    final mockReviews = _getMockReviews();

    // Apply filters
    var filteredReviews = mockReviews;
    if (_ratingFilter > 0) {
      filteredReviews = filteredReviews.where((review) =>
          (review as Map<String, dynamic>)['rating'] == _ratingFilter).toList();
    }

    // Apply sorting
    filteredReviews.sort((a, b) {
      final reviewA = a as Map<String, dynamic>;
      final reviewB = b as Map<String, dynamic>;

      switch (_sortBy) {
        case 'oldest':
          return reviewA['date'].compareTo(reviewB['date']);
        case 'highest':
          return reviewB['rating'].compareTo(reviewA['rating']);
        case 'lowest':
          return reviewA['rating'].compareTo(reviewB['rating']);
        case 'newest':
        default:
          return reviewB['date'].compareTo(reviewA['date']);
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
                  ? 'No ${_ratingFilter}-star reviews yet'
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
        final review = filteredReviews[index] as Map<String, dynamic>;
        return _buildMockReviewCard(review);
      },
    );
  }

  Widget _buildMockReviewCard(Map<String, dynamic> review) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLightest,
                child: Text(
                  review['userName'][0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review['userName'],
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (review['verified']) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < review['rating'] ? Icons.star : Icons.star_border,
                              size: 16,
                              color: index < review['rating'] ? AppColors.warning : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${review['date'].difference(DateTime.now()).inDays.abs()} days ago',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Review content
          if (review['title'] != null) ...[
            Text(
              review['title'],
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],

          Text(
            review['comment'],
            style: AppTypography.bodyMedium.copyWith(
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  // TODO: Mark as helpful
                },
                icon: Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  'Helpful (${review['helpful']})',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final result = await ReportDialog.show(
                    context,
                    contentType: 'review',
                    contentId: review['id'],
                    contentTitle: review['title'] ?? 'Review by ${review['userName']}',
                  );

                  if (result == true && context.mounted) {
                    // Report was submitted successfully
                    // Could update UI to show report submitted state
                  }
                },
                child: Text(
                  'Report',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockReviews() {
    return [
      {
        'id': '1',
        'userId': 'user1',
        'userName': 'Rajesh Kumar',
        'userAvatar': null,
        'rating': 5,
        'title': 'Excellent quality cement',
        'comment': 'This cement is of very high quality. Used it for my house construction and the results are amazing. The finish is smooth and the setting time is perfect. Highly recommended for anyone looking for reliable construction materials.',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'helpful': 12,
        'images': [],
        'verified': true,
      },
      {
        'id': '2',
        'userId': 'user2',
        'userName': 'Priya Sharma',
        'userAvatar': null,
        'rating': 4,
        'title': 'Good value for money',
        'comment': 'Decent quality steel rods. The price is reasonable compared to other brands. Delivery was on time and the packaging was good. Would buy again.',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'helpful': 8,
        'images': [],
        'verified': true,
      },
      {
        'id': '3',
        'userId': 'user3',
        'userName': 'Amit Patel',
        'userAvatar': null,
        'rating': 5,
        'title': 'Perfect for construction',
        'comment': 'These bricks are exactly what I needed for my project. The size and quality are consistent. The supplier was very helpful with delivery arrangements.',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'helpful': 15,
        'images': [],
        'verified': true,
      },
      {
        'id': '4',
        'userId': 'user4',
        'userName': 'Sunita Verma',
        'userAvatar': null,
        'rating': 3,
        'title': 'Average quality',
        'comment': 'The paint is okay but not exceptional. It covers well but the finish could be better. For the price, it\'s acceptable but I\'ve used better brands before.',
        'date': DateTime.now().subtract(const Duration(days: 10)),
        'helpful': 3,
        'images': [],
        'verified': false,
      },
      {
        'id': '5',
        'userId': 'user5',
        'userName': 'Vikram Singh',
        'userAvatar': null,
        'rating': 5,
        'title': 'Outstanding service',
        'comment': 'Not only is the product excellent, but the customer service from INDULINK is top-notch. They helped me choose the right materials for my project and the delivery was flawless.',
        'date': DateTime.now().subtract(const Duration(days: 12)),
        'helpful': 20,
        'images': [],
        'verified': true,
      },
    ];
  }
}