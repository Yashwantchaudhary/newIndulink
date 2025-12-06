import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../../../models/review.dart';
import '../../../../services/review_service.dart';
import '../../../../core/constants/app_typography.dart';
import 'package:intl/intl.dart';

class SupplierReviewsScreen extends StatefulWidget {
  const SupplierReviewsScreen({super.key});

  @override
  State<SupplierReviewsScreen> createState() => _SupplierReviewsScreenState();
}

class _SupplierReviewsScreenState extends State<SupplierReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  bool _isLoading = true;
  List<Review> _reviews = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final result = await _reviewService.getSupplierReviews();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _reviews = result.reviews;
        } else {
          _error = result.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: LoadingSpinner());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReviews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const Center(child: Text('No reviews yet.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Product Reviews')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        review.product?.title ?? 'Unknown Product',
                        style: AppTypography.h6,
                      ),
                      Row(
                        children: List.generate(
                            5,
                            (i) => Icon(
                                  i < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${review.customer?.fullName ?? 'Anonymous'} on ${DateFormat('MMM dd, yyyy').format(review.createdAt)}',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 12),
                  if (review.title != null)
                    Text(review.title!,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(review.comment),
                  if (review.response != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey[100],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Response:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(review.response!.comment),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
