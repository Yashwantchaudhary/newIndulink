import 'package:flutter/material.dart';

/// ⭐ Star Rating Widget
/// Displays a row of stars, either static or interactive
class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final Function(double)? onRatingChanged;

  const StarRating({
    super.key,
    this.rating = 0,
    this.starCount = 5,
    this.size = 24.0,
    this.color = Colors.amber,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        return GestureDetector(
          onTap: onRatingChanged != null
              ? () => onRatingChanged!(index + 1.0)
              : null,
          child: Icon(
            index < rating
                ? (rating >= index + 0.5 && rating < index + 1
                    ? Icons.star_half
                    : Icons.star)
                : Icons.star_border,
            color: color,
            size: size,
          ),
        );
      }),
    );
  }
}
