import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import 'star_rating_widget.dart';
import 'report_dialog.dart';

/// 💬 Review Card Widget
/// Displays individual product reviews with interactions
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showProductInfo;
  final VoidCallback? onTap;

  const ReviewCard({
    super.key,
    required this.review,
    this.showProductInfo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        margin: const EdgeInsets.only(bottom: AppDimensions.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User info and rating
            _buildReviewHeader(),

            const SizedBox(height: AppDimensions.space16),

            // Review content
            _buildReviewContent(),

            // Images (if any)
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space16),
              _buildReviewImages(),
            ],

            // Actions: Helpful, Report
            const SizedBox(height: AppDimensions.space16),
            _buildReviewActions(context),

            // Supplier response (if any)
            if (review.response != null) ...[
              const SizedBox(height: AppDimensions.space16),
              _buildSupplierResponse(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHeader() {
    return Row(
      children: [
        // User avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryLightest,
          backgroundImage: review.customer.profileImage != null
              ? CachedNetworkImageProvider(review.customer.profileImage!)
              : null,
          child: review.customer.profileImage == null
              ? Text(
                  review.customer.firstName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),

        const SizedBox(width: AppDimensions.space16),

        // User info and rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and verification
              Row(
                children: [
                  Text(
                    review.customer.fullName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  if (review.isVerifiedPurchase) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
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

              // Rating and date
              Row(
                children: [
                  StarRatingWidget(
                    rating: review.rating,
                    size: 14,
                    interactive: false,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    review.formattedDate,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (if provided)
        if (review.title != null && review.title!.isNotEmpty) ...[
          Text(
            review.title!,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Comment
        Text(
          review.comment,
          style: AppTypography.bodyMedium.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewImages() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: review.images.length,
        itemBuilder: (context, index) {
          final image = review.images[index];
          return Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: image.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.background,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.background,
                  child: const Icon(Icons.broken_image,
                      color: AppColors.textTertiary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewActions(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final reviewProvider = context.watch<ReviewProvider>();
    final currentUserId = authProvider.user?.id;

    return Row(
      children: [
        // Helpful button
        TextButton.icon(
          onPressed: currentUserId != null
              ? () => reviewProvider.markReviewHelpful(review.id)
              : null,
          icon: Icon(
            review.isMarkedHelpfulBy(currentUserId ?? '')
                ? Icons.thumb_up
                : Icons.thumb_up_outlined,
            size: 16,
            color: review.isMarkedHelpfulBy(currentUserId ?? '')
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
          label: Text(
            'Helpful (${review.helpfulCount})',
            style: TextStyle(
              fontSize: 12,
              color: review.isMarkedHelpfulBy(currentUserId ?? '')
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),

        const Spacer(),

        // Report button
        TextButton(
          onPressed: () async {
            final result = await ReportDialog.show(
              context,
              contentType: 'review',
              contentId: review.id,
              contentTitle:
                  review.title ?? 'Review by ${review.customer.fullName}',
            );

            if (result == true && context.mounted) {
              // Report was submitted successfully
              // Could update UI to show report submitted state
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: Text(
            'Report',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierResponse() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primaryLightest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Supplier Response',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: AppTypography.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.response!.comment,
            style: AppTypography.bodySmall.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd, yyyy').format(review.response!.respondedAt),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 📝 Review Summary Widget
/// Shows overall rating and review count for a product
class ReviewSummaryWidget extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  const ReviewSummaryWidget({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Average rating
          RatingSummaryWidget(
            averageRating: averageRating,
            totalReviews: totalReviews,
            ratingDistribution: ratingDistribution,
          ),

          if (totalReviews > 0) ...[
            const SizedBox(height: AppDimensions.space24),

            // Rating distribution
            RatingDistributionWidget(
              ratingDistribution: ratingDistribution,
              totalReviews: totalReviews,
            ),
          ],
        ],
      ),
    );
  }
}
