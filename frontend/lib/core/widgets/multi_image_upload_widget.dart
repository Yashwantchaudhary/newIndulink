import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

/// 📸 Multi Image Upload Widget
/// Allows users to select, preview, and manage multiple images
class MultiImageUploadWidget extends StatefulWidget {
  final List<String> initialImages; // URLs for existing images
  final int maxImages;
  final Function(List<File>) onImagesSelected;
  final Function(List<String>)? onImagesUploaded; // For uploaded URLs
  final String uploadFolder;
  final bool showUploadProgress;

  const MultiImageUploadWidget({
    super.key,
    this.initialImages = const [],
    this.maxImages = 5,
    required this.onImagesSelected,
    this.onImagesUploaded,
    this.uploadFolder = 'products',
    this.showUploadProgress = true,
  });

  @override
  State<MultiImageUploadWidget> createState() => _MultiImageUploadWidgetState();
}

class _MultiImageUploadWidgetState extends State<MultiImageUploadWidget> {
  final ImageService _imageService = ImageService();
  final List<File> _selectedImages = [];
  final List<String> _uploadedUrls = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _currentUploadIndex = 0;

  @override
  void initState() {
    super.initState();
    _uploadedUrls.addAll(widget.initialImages);
  }

  @override
  Widget build(BuildContext context) {
    final int totalImages = _selectedImages.length + _uploadedUrls.length;
    final bool canAddMore = totalImages < widget.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count
        Row(
          children: [
            Text(
              'Product Images',
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLightest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalImages/${widget.maxImages}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.space16),

        // Image grid
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: totalImages + (canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _uploadedUrls.length) {
                // Existing uploaded image
                return _buildImageItem(_uploadedUrls[index],
                    isUploaded: true, index: index);
              } else if (index < totalImages) {
                // Newly selected image
                final localIndex = index - _uploadedUrls.length;
                return _buildImageItem(_selectedImages[localIndex].path,
                    isUploaded: false, index: index);
              } else {
                // Add image button
                return _buildAddImageButton();
              }
            },
          ),
        ),

        // Upload progress
        if (_isUploading && widget.showUploadProgress)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.space16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _uploadProgress / 100,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploading image ${_currentUploadIndex + 1} of ${_selectedImages.length}...',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

        // Helper text
        Padding(
          padding: const EdgeInsets.only(top: AppDimensions.space8),
          child: Text(
            'Upload up to ${widget.maxImages} high-quality images. First image will be the main product image.',
            style:
                AppTypography.caption.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(String imagePath,
      {required bool isUploaded, required int index}) {
    return Stack(
      children: [
        // Image
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isUploaded
                ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.background,
                      child: const Icon(Icons.broken_image,
                          color: AppColors.textTertiary),
                    ),
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.background,
                      child: const Icon(Icons.broken_image,
                          color: AppColors.textTertiary),
                    ),
                  ),
          ),
        ),

        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index, isUploaded: isUploaded),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 204),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Main image indicator
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 204),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Main',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
            width: 2,
          ),
          color: AppColors.background,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 4),
            Text(
              'Add Image',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final File? imageFile = source == ImageSource.camera
          ? await _imageService.pickImageFromCamera()
          : await _imageService.pickImageFromGallery();

      if (imageFile != null) {
        // Validate image
        final isValid = await _imageService.validateImage(imageFile);
        if (!isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Invalid image. Please select a valid image file under 10MB.'),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImages.add(imageFile);
        });

        // Notify parent
        widget.onImagesSelected(_selectedImages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  void _removeImage(int index, {required bool isUploaded}) {
    setState(() {
      if (isUploaded) {
        _uploadedUrls.removeAt(index);
      } else {
        final localIndex = index - _uploadedUrls.length;
        if (localIndex >= 0 && localIndex < _selectedImages.length) {
          _selectedImages.removeAt(localIndex);
        }
      }
    });

    // Notify parent
    widget.onImagesSelected(_selectedImages);
  }

  /// Upload selected images to Backend
  Future<void> uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentUploadIndex = 0;
    });

    try {
      final List<String> uploadedUrls =
          await _imageService.uploadMultipleImagesToBackend(
        _selectedImages,
        folder: widget.uploadFolder,
        onProgress: (double progress, int index) {
          setState(() {
            _uploadProgress = progress;
            _currentUploadIndex = index;
          });
        },
      );

      setState(() {
        _uploadedUrls.addAll(uploadedUrls);
        _selectedImages.clear();
        _isUploading = false;
      });

      // Notify parent of uploaded URLs
      widget.onImagesUploaded?.call(_uploadedUrls);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${uploadedUrls.length} image(s) uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Get all image URLs (uploaded + selected for preview)
  List<String> getAllImageUrls() {
    return [..._uploadedUrls, ..._selectedImages.map((file) => file.path)];
  }

  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => _selectedImages.isNotEmpty;
}
