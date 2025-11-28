import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Image carousel widget for product images
class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double? height;
  final BorderRadius? borderRadius;

  const ImageCarousel({
    super.key,
    required this.imageUrls,
    this.height,
    this.borderRadius,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.imageUrls.isEmpty) {
      return _buildPlaceholder(isDark);
    }

    return Column(
      children: [
        Stack(
          children: [
            // Image PageView
            SizedBox(
              height: widget.height ?? 350,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: widget.imageUrls.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: widget.borderRadius ?? BorderRadius.zero,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPlaceholder(isDark),
                    ),
                  );
                },
              ),
            ),

            // Navigation buttons (if multiple images)
            if (widget.imageUrls.length > 1) ...[
              // Previous button
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      if (_currentIndex > 0) {
                        _pageController.animateToPage(
                          _currentIndex - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const Icon(Icons.chevron_left, size: 28),
                  ),
                ),
              ),

              // Next button
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      if (_currentIndex < widget.imageUrls.length - 1) {
                        _pageController.animateToPage(
                          _currentIndex + 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const Icon(Icons.chevron_right, size: 28),
                  ),
                ),
              ),
            ],
          ],
        ),

        // Page indicator
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: AppConstants.spacing16),
          AnimatedSmoothIndicator(
            activeIndex: _currentIndex,
            count: widget.imageUrls.length,
            effect: WormEffect(
              dotWidth: 8,
              dotHeight: 8,
              activeDotColor: AppColors.primaryBlue,
              dotColor: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            onDotClicked: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      height: widget.height ?? 350,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }
}
