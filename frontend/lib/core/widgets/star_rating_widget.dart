import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// ⭐ Star Rating Widget
/// Interactive star rating display and input
class StarRatingWidget extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24.0,
    this.interactive = false,
    this.onRatingChanged,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        return GestureDetector(
          onTap: interactive && onRatingChanged != null
              ? () => onRatingChanged!(index + 1)
              : null,
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            size: size,
            color: index < rating
                ? (activeColor ?? AppColors.warning)
                : (inactiveColor ?? AppColors.textTertiary),
          ),
        );
      }),
    );
  }
}

/// 📊 Rating Summary Widget
/// Shows average rating and distribution
class RatingSummaryWidget extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final double size;

  const RatingSummaryWidget({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Average rating display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 4),
              StarRatingWidget(
                rating: averageRating.round(),
                size: size,
                interactive: false,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Total reviews
        Text(
          '($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})',
          style: TextStyle(
            fontSize: size - 2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 📈 Rating Distribution Widget
/// Shows breakdown of ratings by star count
class RatingDistributionWidget extends StatelessWidget {
  final Map<int, int> ratingDistribution;
  final int totalReviews;
  final double barHeight;

  const RatingDistributionWidget({
    super.key,
    required this.ratingDistribution,
    required this.totalReviews,
    this.barHeight = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        final starCount = 5 - index; // 5, 4, 3, 2, 1
        final count = ratingDistribution[starCount] ?? 0;
        final percentage = totalReviews > 0 ? (count / totalReviews) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // Star count
              Text(
                '$starCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 12, color: AppColors.warning),

              const SizedBox(width: 8),

              // Progress bar
              Expanded(
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(barHeight / 2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(barHeight / 2),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Count
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// ✍️ Review Input Widget
/// Star rating input for review submission
class ReviewRatingInput extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const ReviewRatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 32.0,
  });

  @override
  State<ReviewRatingInput> createState() => _ReviewRatingInputState();
}

class _ReviewRatingInputState extends State<ReviewRatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starRating = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starRating;
            });
            widget.onRatingChanged(starRating);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            child: Icon(
              starRating <= _currentRating ? Icons.star : Icons.star_border,
              size: widget.size,
              color: starRating <= _currentRating
                  ? AppColors.warning
                  : AppColors.textTertiary,
            ),
          ),
        );
      }),
    );
  }
}