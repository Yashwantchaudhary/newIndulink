import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'offline_cache_service.dart';

/// 🌐 Cached API Service
/// Enhanced API service with offline caching and sync capabilities

class CachedApiService {
  final ApiService _apiService = ApiService();
  final OfflineCacheService _cacheService = OfflineCacheService();

  bool get isInitialized => _cacheService.isInitialized;
  bool get isOnline => _cacheService.isOnline;

  /// Initialize the cached API service
  Future<void> initialize() async {
    try {
      await _cacheService.initialize();
    } catch (e) {
      debugPrint(
          '⚠️ Cache service initialization failed (likely web platform): $e');
      // Continue without cache on web
    }
  }

  /// GET request with caching
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? params,
    bool useCache = true,
    Duration? cacheDuration,
    String? cacheKey,
    bool forceRefresh = false,
  }) async {
    final key = cacheKey ?? _generateCacheKey('GET', endpoint, params);

    // Try to get from cache first (if not forcing refresh)
    if (useCache && !forceRefresh) {
      final cachedData = await _cacheService.get(key);
      if (cachedData != null) {
        debugPrint('✅ Cache hit for: $endpoint');
        return _createApiResponseFromCache(cachedData);
      }
    }

    // If offline, return cached data or error
    if (!isOnline) {
      final cachedData = await _cacheService.get(key);
      if (cachedData != null) {
        debugPrint('📴 Offline - returning cached data for: $endpoint');
        return _createApiResponseFromCache(cachedData);
      } else {
        return ApiResponse(
          success: false,
          statusCode: 0,
          message: 'No internet connection and no cached data available',
        );
      }
    }

    // Make the actual API call
    final response = await _apiService.get(endpoint, params: params);

    // Cache successful responses
    if (useCache && response.isSuccess) {
      await _cacheService.set(
        key,
        _serializeApiResponse(response),
        type: 'api_response',
        ttl: cacheDuration ?? const Duration(hours: 1),
      );
      debugPrint('💾 Cached response for: $endpoint');
    }

    return response;
  }

  /// Create ApiResponse from cached data
  ApiResponse _createApiResponseFromCache(dynamic cachedData) {
    return ApiResponse(
      success: cachedData['success'] ?? false,
      statusCode: cachedData['statusCode'] ?? 200,
      message: cachedData['message'],
      data: cachedData['data'],
    );
  }

  /// Serialize ApiResponse for caching
  Map<String, dynamic> _serializeApiResponse(ApiResponse response) {
    return {
      'success': response.success,
      'statusCode': response.statusCode,
      'message': response.message,
      'data': response.data,
    };
  }

  /// POST request with offline queueing
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool queueOffline = true,
    String? cacheKey,
  }) async {
    // If offline, add to sync queue
    if (!isOnline && queueOffline) {
      await _cacheService.addToSyncQueue(
        operation: 'POST',
        endpoint: endpoint,
        data: body,
      );

      return ApiResponse(
        success: true,
        statusCode: 202, // Accepted
        message: 'Request queued for when device comes online',
        data: {'queued': true},
      );
    }

    // Make the actual API call
    final response = await _apiService.post(endpoint, body: body);

    // Invalidate related cache if successful
    if (response.isSuccess && cacheKey != null) {
      await _cacheService.delete(cacheKey);
    }

    return response;
  }

  /// PUT request with offline queueing
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool queueOffline = true,
    String? cacheKey,
  }) async {
    // If offline, add to sync queue
    if (!isOnline && queueOffline) {
      await _cacheService.addToSyncQueue(
        operation: 'PUT',
        endpoint: endpoint,
        data: body,
      );

      return ApiResponse(
        success: true,
        statusCode: 202,
        message: 'Request queued for when device comes online',
        data: {'queued': true},
      );
    }

    final response = await _apiService.put(endpoint, body: body);

    // Invalidate related cache if successful
    if (response.isSuccess && cacheKey != null) {
      await _cacheService.delete(cacheKey);
    }

    return response;
  }

  /// DELETE request with offline queueing
  Future<ApiResponse> delete(
    String endpoint, {
    bool queueOffline = true,
    String? cacheKey,
  }) async {
    // If offline, add to sync queue
    if (!isOnline && queueOffline) {
      await _cacheService.addToSyncQueue(
        operation: 'DELETE',
        endpoint: endpoint,
      );

      return ApiResponse(
        success: true,
        statusCode: 202,
        message: 'Request queued for when device comes online',
        data: {'queued': true},
      );
    }

    final response = await _apiService.delete(endpoint);

    // Invalidate related cache if successful
    if (response.isSuccess && cacheKey != null) {
      await _cacheService.delete(cacheKey);
    }

    return response;
  }

  /// Cache user-specific data
  Future<bool> cacheUserData(
      String userId, String dataType, dynamic data) async {
    return await _cacheService.setUserData(userId, dataType, data);
  }

  /// Get cached user data
  Future<dynamic> getUserData(String userId, String dataType) async {
    return await _cacheService.getUserData(userId, dataType);
  }

  /// Clear user cache
  Future<bool> clearUserCache(String userId) async {
    return await _cacheService.clearUserData(userId);
  }

  /// Cache file with offline support
  Future<String?> cacheFile(String url, List<int> bytes,
      {String? filename}) async {
    return await _cacheService.cacheFile(url, bytes, filename: filename);
  }

  /// Get cached file
  Future<String?> getCachedFile(String url) async {
    return await _cacheService.getCachedFile(url);
  }

  /// Process sync queue
  Future<void> processSyncQueue() async {
    await _cacheService.processSyncQueue();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }

  /// Clear cache by type
  Future<int> clearCacheByType(String type) async {
    return await _cacheService.clearByType(type);
  }

  /// Clear all cache
  Future<int> clearAllCache() async {
    return await _cacheService.clearAll();
  }

  /// Generate cache key
  String _generateCacheKey(
      String method, String endpoint, Map<String, dynamic>? params) {
    final key = '$method:$endpoint';
    if (params != null && params.isNotEmpty) {
      final sortedParams = Map.fromEntries(
          params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      return '$key:${jsonEncode(sortedParams)}';
    }
    return key;
  }

  /// Invalidate cache patterns
  Future<void> invalidateCache(String pattern) async {
    // This would require pattern matching in the cache service
    // For now, we'll clear by type or implement pattern matching
    debugPrint('🧹 Invalidating cache pattern: $pattern');
  }

  /// Preload critical data for offline use
  Future<void> preloadCriticalData(String userId) async {
    debugPrint('🔄 Preloading critical data for user: $userId');

    try {
      // Preload user profile
      await get('/auth/profile', cacheKey: 'user:profile:$userId');

      // Preload user products (if supplier)
      await get('/products/user/$userId', cacheKey: 'user:products:$userId');

      // Preload categories
      await get('/categories', cacheKey: 'categories:list');

      debugPrint('✅ Critical data preloaded');
    } catch (error) {
      debugPrint('❌ Failed to preload critical data: $error');
    }
  }

  /// Close resources
  Future<void> close() async {
    await _cacheService.close();
  }
}
