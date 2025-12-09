import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Add kIsWeb check
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Added MediaType support
import 'package:cross_file/cross_file.dart'; // Ensure correct XFile import
import '../core/constants/app_config.dart';
import 'storage_service.dart';

/// 📸 Image Service
/// Handles image picking, cropping, compression, and backend upload
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Request necessary permissions for image operations
  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final photosStatus = await Permission.photos.request();

    return cameraStatus.isGranted && photosStatus.isGranted;
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera({
    ImageSource source = ImageSource.camera,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      return pickedFile;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
    }
    return null;
  }

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      return pickedFile;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
    }
    return null;
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages({
    int maxImages = 5,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFiles.length > maxImages) {
        return pickedFiles.take(maxImages).toList();
      }

      return pickedFiles;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Crop image
  Future<XFile?> cropImage(
    XFile imageFile, {
    CropAspectRatioPreset? aspectRatioPreset,
  }) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile != null) {
        return XFile(croppedFile.path); // Return XFile directly
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
    }
    return null;
  }

  /// Compress image
  Future<XFile?> compressImage(
    XFile imageFile, {
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    if (kIsWeb) return imageFile; // Skip compression on web for simplicity

    try {
      // For now, we'll return original as full compression requires complex web/native branching
      // In a production app, use flutter_image_compress with Uint8List for web support
      return imageFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }

  /// Upload image to backend
  Future<String?> uploadImageToBackend(
    XFile imageFile, {
    required String folder,
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      String mimeType = 'image/jpeg';
      String extension = 'jpg';

      if (imageFile.mimeType != null) {
        mimeType = imageFile.mimeType!;
        if (mimeType == 'image/png')
          extension = 'png';
        else if (mimeType == 'image/gif')
          extension = 'gif';
        else if (mimeType == 'image/webp') extension = 'webp';
      } else {
        final name = imageFile.name.toLowerCase();
        if (name.endsWith('.png')) {
          extension = 'png';
          mimeType = 'image/png';
        } else if (name.endsWith('.gif')) {
          extension = 'gif';
          mimeType = 'image/gif';
        } else if (name.endsWith('.webp')) {
          extension = 'webp';
          mimeType = 'image/webp';
        }
      }

      final String actualFileName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Create multipart request
      final uri = Uri.parse('${AppConfig.baseUrl}/upload/image');
      final request = http.MultipartRequest('POST', uri);

      // Add file using bytes
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: actualFileName,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);
      request.fields['folder'] = folder;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        debugPrint(
            'Error uploading image: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image to backend: $e');
      return null;
    }
  }

  /// Upload multiple images to backend
  Future<List<String>> uploadMultipleImagesToBackend(
    List<XFile> imageFiles, {
    required String folder,
    Function(double, int)? onProgress, // progress, currentIndex
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final XFile imageFile = imageFiles[i];
      final String? downloadUrl = await uploadImageToBackend(
        imageFile,
        folder: folder,
        onProgress: (progress) => onProgress?.call(progress, i),
      );

      if (downloadUrl != null) {
        downloadUrls.add(downloadUrl);
      }
    }

    return downloadUrls;
  }

  /// Delete image from backend
  Future<bool> deleteImageFromBackend(String imageUrl) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/upload/delete');
      final response = await http.delete(uri, body: {'url': imageUrl});

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting image from backend: $e');
      return false;
    }
  }

  /// Upload profile image to backend (with authentication)
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      // Get authentication token
      final StorageService storage = StorageService();
      final token = await storage.getAccessToken();

      if (token == null) {
        debugPrint('Error: No auth token available for profile upload');
        return null;
      }

      // Determine MIME type
      String mimeType = 'image/jpeg';
      String extension = 'jpg';

      if (imageFile.mimeType != null) {
        mimeType = imageFile.mimeType!;
        if (mimeType == 'image/png')
          extension = 'png';
        else if (mimeType == 'image/gif')
          extension = 'gif';
        else if (mimeType == 'image/webp') extension = 'webp';
      } else {
        final name = imageFile.name.toLowerCase();
        if (name.endsWith('.png')) {
          extension = 'png';
          mimeType = 'image/png';
        } else if (name.endsWith('.gif')) {
          extension = 'gif';
          mimeType = 'image/gif';
        } else if (name.endsWith('.webp')) {
          extension = 'webp';
          mimeType = 'image/webp';
        }
      }

      final String actualFileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Create multipart request to profile image endpoint
      final uri = Uri.parse('${AppConfig.baseUrl}/users/profile/image');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add file using bytes
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'profileImage',
        bytes,
        filename: actualFileName,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      // Send request
      debugPrint('📸 Uploading profile image...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profileImageUrl =
            data['data']?['profileImage'] ?? data['profileImage'];
        debugPrint('✅ Profile image uploaded: $profileImageUrl');
        return profileImageUrl;
      } else {
        debugPrint(
            '❌ Error uploading profile image: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      return null;
    }
  }

  /// Get image dimensions
  Future<Size?> getImageDimensions(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      return Size(
          decodedImage.width.toDouble(), decodedImage.height.toDouble());
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
      return null;
    }
  }

  Future<bool> validateImage(
    XFile imageFile, {
    int maxSizeInMB = 50, // Increased from 10MB to 50MB to match backend
    List<String> allowedExtensions = const [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
      'tiff',
      'tif',
      'ico',
      'heic',
      'heif'
    ],
  }) async {
    try {
      // Get file path - may be a blob URL on web
      final String filePath = imageFile.path;

      // Check file extension (extract from path or blob URL)
      String extension = '';

      // Handle both file:// paths and blob URLs
      if (filePath.contains('.')) {
        extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
      }

      // If extension is empty or unrecognizable (common on web), allow it
      // The backend will validate the actual file content
      if (extension.isNotEmpty && !allowedExtensions.contains(extension)) {
        debugPrint('Image validation failed: Invalid extension "$extension"');
        return false;
      }

      // Try to check file size - may fail on web
      try {
        final int fileSize = await imageFile.length();
        final int maxSizeInBytes = maxSizeInMB * 1024 * 1024;
        if (fileSize > maxSizeInBytes) {
          debugPrint(
              'Image validation failed: File too large ($fileSize bytes > $maxSizeInBytes bytes)');
          return false;
        }
        debugPrint(
            'Image validated: ${fileSize ~/ 1024}KB, extension: ${extension.isEmpty ? "unknown" : extension}');
      } catch (e) {
        // On Web, file.length() may not work - skip size check
        debugPrint('Could not check file size (likely web platform): $e');
        // Allow the upload anyway - backend will validate
      }

      return true;
    } catch (e) {
      debugPrint('Error validating image: $e');
      // On error (likely web platform issue), allow the upload
      // Backend will validate the file properly
      return true;
    }
  }

  /// Generate thumbnail from image
  Future<XFile?> generateThumbnail(
    XFile imageFile, {
    int maxWidth = 200,
    int maxHeight = 200,
    int quality = 80,
  }) async {
    try {
      // For now, return the original image
      // In production, implement actual thumbnail generation
      return imageFile;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
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
  }
}

/// 📋 Image Upload Result
class ImageUploadResult {
  final bool success;
  final String? downloadUrl;
  final String? errorMessage;

  ImageUploadResult({
    required this.success,
    this.downloadUrl,
    this.errorMessage,
  });
}

/// 📊 Image Processing Options
class ImageProcessingOptions {
  final bool compress;
  final bool crop;
  final int quality;
  final int? maxWidth;
  final int? maxHeight;
  final CropAspectRatioPreset? cropAspectRatio;

  const ImageProcessingOptions({
    this.compress = true,
    this.crop = false,
    this.quality = 80,
    this.maxWidth,
    this.maxHeight,
    this.cropAspectRatio,
  });
}
