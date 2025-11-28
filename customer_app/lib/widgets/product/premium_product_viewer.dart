import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

/// Premium 360° Product Viewer Widget
class Premium360ProductViewer extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const Premium360ProductViewer({
    super.key,
    required this.imageUrls,
    this.height = 400,
  });

  @override
  State<Premium360ProductViewer> createState() =>
      _Premium360ProductViewerState();
}

class _Premium360ProductViewerState extends State<Premium360ProductViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  double _dragStart = 0;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade100,
            Colors.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          // 360° Image Viewer
          GestureDetector(
            onHorizontalDragStart: (details) {
              _dragStart = details.globalPosition.dx;
            },
            onHorizontalDragUpdate: (details) {
              final delta = details.globalPosition.dx - _dragStart;
              if (delta.abs() > 50) {
                final direction = delta > 0 ? -1 : 1;
                _rotateTo(direction);
                _dragStart = details.globalPosition.dx;
              }
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                    }
                    return Center(
                      child: SizedBox(
                        height: Curves.easeOut.transform(value) * widget.height,
                        child: child,
                      ),
                    );
                  },
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 100),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // 360° Indicator
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.threesixty, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    '360° View',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Swipe Instruction (First Time Only)
          if (_currentIndex == 0)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Swipe to rotate',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Page Indicators
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.primaryBlue
                        : Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _rotateTo(int direction) {
    int nextIndex = _currentIndex + direction;
    if (nextIndex < 0) nextIndex = widget.imageUrls.length - 1;
    if (nextIndex >= widget.imageUrls.length) nextIndex = 0;

    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

/// Premium Video Player Widget
class PremiumVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;

  const PremiumVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  @override
  State<PremiumVideoPlayer> createState() => _PremiumVideoPlayerState();
}

class _PremiumVideoPlayerState extends State<PremiumVideoPlayer> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail
          Image.network(
            widget.thumbnailUrl,
            fit: BoxFit.cover,
            width: double.infinity,
          ),

          // Play Button Overlay
          if (!_isPlaying)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.9),
                    AppColors.secondaryPurple.withValues(alpha: 0.9),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 50,
                onPressed: () {
                  setState(() => _isPlaying = true);
                  // TODO: Initialize actual video player
                },
                icon: const Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Advanced Image Zoom Viewer
class AdvancedImageZoomViewer extends StatefulWidget {
  final String imageUrl;

  const AdvancedImageZoomViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  State<AdvancedImageZoomViewer> createState() =>
      _AdvancedImageZoomViewerState();
}

class _AdvancedImageZoomViewerState extends State<AdvancedImageZoomViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.network(
          widget.imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _handleDoubleTap() {
    Matrix4 endMatrix;
    if (_transformationController.value != Matrix4.identity()) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix = Matrix4.identity()..scale(2.0);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurveTween(curve: Curves.easeInOut).animate(_animationController),
    );

    _animationController.forward(from: 0).then((_) {
      _transformationController.value = endMatrix;
    });

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
  }
}
