import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../providers/review_provider.dart';
import '../../models/review.dart';

/// Modern Product Reviews Screen - Integrated with Backend
class ModernProductReviewsScreen extends ConsumerStatefulWidget {
  final String productId;
  final double averageRating;
  final int totalReviews;

  const ModernProductReviewsScreen({
    super.key,
    required this.productId,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  ConsumerState<ModernProductReviewsScreen> createState() =>
      _ModernProductReviewsScreenState();
}

class _ModernProductReviewsScreenState
    extends ConsumerState<ModernProductReviewsScreen> {
  String _selectedFilter = 'All';
  final _filters = ['All', '5 Star', '4 Star', '3 Star', '2 Star', '1 Star'];

  @override
  void initState() {
    super.initState();
    // Load reviews on init
    Future.microtask(() {
      ref.read(reviewProvider.notifier).loadProductReviews(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reviewState = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Reviews & Ratings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Rating Overview
          _buildRatingOverview(theme, isDark),

          // Filter Chips
          _buildFilterChips(),

          // Reviews List
          Expanded(
            child: _buildReviewsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWriteReviewDialog(),
        icon: const Icon(Icons.rate_review),
        label: const Text('Write Review'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildRatingOverview(ThemeData theme, bool isDark) {
    return Container(
      padding: AppConstants.paddingAll20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.1),
            AppColors.secondaryPurple.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Overall Rating
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  widget.averageRating.toStringAsFixed(1),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStarRating(widget.averageRating, size: 20),
                const SizedBox(height: 8),
                Text(
                  '${widget.totalReviews} reviews',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Rating Breakdown
          Expanded(
            flex: 3,
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final percentage = _getRatingPercentage(star);
                return _buildRatingBar(star, percentage, theme);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : (index < rating ? Icons.star_half : Icons.star_border),
          color: AppColors.accentYellow,
          size: size,
        );
      }),
    );
  }

  Widget _buildRatingBar(int stars, double percentage, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, color: AppColors.accentYellow, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.lightSurfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accentYellow,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toInt()}%',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              selectedColor: AppColors.primaryBlue,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsList() {
    final reviewState = ref.watch(reviewProvider);
    final reviews = reviewState.reviews;

    if (reviewState.isLoading && reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reviews.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.rate_review_outlined,
        title: 'No Reviews Yet',
        message: 'Be the first to review this product',
        actionText: 'Write Review',
        onAction: _showWriteReviewDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(reviewProvider.notifier)
            .loadProductReviews(widget.productId);
      },
      child: ListView.builder(
        padding: AppConstants.paddingAll16,
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          return _buildReviewCard(reviews[index]);
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  (review.user?['firstName'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${review.user?['firstName'] ?? ''} ${review.user?['lastName'] ?? ''}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateFormat.format(review.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentYellow.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.accentYellow,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review Content
          Text(
            review.review,
            style: theme.textTheme.bodyMedium,
          ),

          // Review Images
          if (review.images?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images!.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: AppConstants.borderRadiusSmall,
                      image: DecorationImage(
                        image: NetworkImage(review.images![index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Helpful Actions
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(reviewProvider.notifier)
                      .markHelpful(review.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as helpful')),
                    );
                  }
                },
                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                label: Text('Helpful (${review.helpfulCount ?? 0})'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _showReportDialog(review.id);
                },
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Report'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lightTextSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog() {
    double rating = 5;
    final titleController = TextEditingController();
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: AppConstants.paddingAll20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightTextTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Write a Review',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // Star Rating
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() => rating = (index + 1).toDouble());
                        },
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: AppColors.accentYellow,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Review Title',
                    hintText: 'Summarize your experience',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),

                // Comment
                TextFormField(
                  controller: commentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Your Review',
                    hintText: 'Share your thoughts about this product',
                    prefixIcon: Icon(Icons.comment),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                AnimatedButton(
                  text: 'Submit Review',
                  icon: Icons.send,
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please write a review'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    final success =
                        await ref.read(reviewProvider.notifier).createReview(
                              productId: widget.productId,
                              rating: rating,
                              review: commentController.text.trim(),
                            );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Thank you for your review!'
                              : 'Failed to submit review'),
                          backgroundColor:
                              success ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  },
                  gradient: AppColors.primaryGradient,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getRatingPercentage(int star) {
    // Mock percentages
    final map = {5: 60.0, 4: 25.0, 3: 10.0, 2: 3.0, 1: 2.0};
    return map[star] ?? 0;
  }

  void _showReportDialog(String reviewId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Review'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why are you reporting this review?',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;

              final success =
                  await ref.read(reviewProvider.notifier).reportReview(
                        reviewId,
                        reasonController.text.trim(),
                      );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Review reported'
                        : 'Failed to report review'),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
