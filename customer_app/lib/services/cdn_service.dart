import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// CDN Service for handling image optimization, caching, and fallback logic
class CdnService {
  static final CdnService _instance = CdnService._internal();
  factory CdnService() => _instance;

  CdnService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
  ));

  bool _cdnAvailable = true;
  DateTime? _lastHealthCheck;

  /// Check CDN health status
  Future<bool> checkCdnHealth() async {
    try {
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      final response = await _dio.get('$baseUrl/cdn/status');

      if (response.statusCode == 200) {
        final data = response.data;
        _cdnAvailable = data['success'] == true;
        _lastHealthCheck = DateTime.now();
        return _cdnAvailable;
      }
    } catch (e) {
      _cdnAvailable = false;
      _lastHealthCheck = DateTime.now();
    }
    return false;
  }

  /// Get optimized image URL with fallback
  String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'high',
    String format = 'webp',
    String fit = 'cover',
  }) {
    // If CDN is not available or health check is old, use original URL
    if (!_cdnAvailable ||
        (_lastHealthCheck != null &&
            DateTime.now().difference(_lastHealthCheck!) >
                const Duration(minutes: 5))) {
      return originalUrl;
    }

    // For development, use local CDN endpoint
    final cdnBase = AppConfig.apiBaseUrl.replaceAll('/api', '/cdn/image');

    final params = <String, String>{
      'url': originalUrl,
      'quality': quality,
      'format': format,
      'fit': fit,
    };

    if (width != null) params['width'] = width.toString();
    if (height != null) params['height'] = height.toString();

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$cdnBase?$queryString';
  }

  /// Purge CDN cache for specific URLs
  Future<bool> purgeCache(List<String> urls) async {
    try {
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      final response = await _dio.post(
        '$baseUrl/cdn/purge',
        data: {'urls': urls},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get CDN analytics/performance data
  Future<Map<String, dynamic>?> getAnalytics() async {
    try {
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      final response = await _dio.get('$baseUrl/cdn/analytics');

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Analytics not available
    }
    return null;
  }

  /// Preload critical images
  Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await _dio.get(url, options: Options(responseType: ResponseType.bytes));
      } catch (e) {
        // Ignore preload failures
      }
    }
  }

  /// Get image URL with automatic fallback on error
  Future<String> getImageUrlWithFallback(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'high',
  }) async {
    final optimizedUrl = getOptimizedImageUrl(
      originalUrl,
      width: width,
      height: height,
      quality: quality,
    );

    // Test optimized URL
    try {
      final response = await _dio.head(optimizedUrl);
      if (response.statusCode == 200) {
        return optimizedUrl;
      }
    } catch (e) {
      // Optimized URL failed, use original
    }

    return originalUrl;
  }

  /// CDN status getter
  bool get isCdnAvailable => _cdnAvailable;

  /// Force refresh CDN status
  Future<void> refreshCdnStatus() async {
    await checkCdnHealth();
  }
}
