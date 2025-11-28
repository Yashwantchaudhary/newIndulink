import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';

/// Comprehensive caching service for offline support
class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _metadataPrefix = 'meta_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Cache data with metadata
  Future<void> setCache(
    String key,
    dynamic data, {
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _ensureInitialized();

      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_metadataPrefix$key';

      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now()
            .add(duration ?? _defaultCacheDuration)
            .toIso8601String(),
        'metadata': metadata ?? {},
      };

      final encodedData = jsonEncode(cacheData);
      await _prefs!.setString(cacheKey, encodedData);

      if (kDebugMode) {
        print('💾 Cached data for key: $key');
      }
    } catch (e) {
      ErrorHandler().reportError(
        AppError.generic(
          message: 'Failed to cache data for key: $key',
          category: ErrorCategory.storage,
          originalError: e,
        ),
      );
    }
  }

  /// Get cached data if not expired
  Future<CacheEntry?> getCache(String key) async {
    try {
      await _ensureInitialized();

      final cacheKey = '$_cachePrefix$key';
      final cachedData = _prefs!.getString(cacheKey);

      if (cachedData == null) {
        return null;
      }

      final decodedData = jsonDecode(cachedData) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(decodedData['expiresAt']);

      if (DateTime.now().isAfter(expiresAt)) {
        // Cache expired, remove it
        await removeCache(key);
        return null;
      }

      return CacheEntry(
        data: decodedData['data'],
        timestamp: DateTime.parse(decodedData['timestamp']),
        expiresAt: expiresAt,
        metadata: decodedData['metadata'] ?? {},
      );
    } catch (e) {
      ErrorHandler().reportError(
        AppError.generic(
          message: 'Failed to retrieve cached data for key: $key',
          category: ErrorCategory.storage,
          originalError: e,
        ),
      );
      return null;
    }
  }

  /// Get cached data even if expired (for offline mode)
  Future<CacheEntry?> getCacheOffline(String key) async {
    try {
      await _ensureInitialized();

      final cacheKey = '$_cachePrefix$key';
      final cachedData = _prefs!.getString(cacheKey);

      if (cachedData == null) {
        return null;
      }

      final decodedData = jsonDecode(cachedData) as Map<String, dynamic>;

      return CacheEntry(
        data: decodedData['data'],
        timestamp: DateTime.parse(decodedData['timestamp']),
        expiresAt: DateTime.parse(decodedData['expiresAt']),
        metadata: decodedData['metadata'] ?? {},
        isExpired:
            DateTime.now().isAfter(DateTime.parse(decodedData['expiresAt'])),
      );
    } catch (e) {
      return null;
    }
  }

  /// Remove cached data
  Future<void> removeCache(String key) async {
    try {
      await _ensureInitialized();

      final cacheKey = '$_cachePrefix$key';
      await _prefs!.remove(cacheKey);

      if (kDebugMode) {
        print('🗑️ Removed cache for key: $key');
      }
    } catch (e) {
      ErrorHandler().reportError(
        AppError.generic(
          message: 'Failed to remove cached data for key: $key',
          category: ErrorCategory.storage,
          originalError: e,
        ),
      );
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      await _ensureInitialized();

      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));

      for (final key in cacheKeys) {
        await _prefs!.remove(key);
      }

      if (kDebugMode) {
        print('🧹 Cleared all cached data');
      }
    } catch (e) {
      ErrorHandler().reportError(
        AppError.generic(
          message: 'Failed to clear all cached data',
          category: ErrorCategory.storage,
          originalError: e,
        ),
      );
    }
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    try {
      await _ensureInitialized();

      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));

      int totalEntries = 0;
      int expiredEntries = 0;
      int validEntries = 0;
      int totalSize = 0;

      for (final key in cacheKeys) {
        totalEntries++;
        final data = _prefs!.getString(key);
        if (data != null) {
          totalSize += data.length;

          try {
            final decodedData = jsonDecode(data) as Map<String, dynamic>;
            final expiresAt = DateTime.parse(decodedData['expiresAt']);

            if (DateTime.now().isAfter(expiresAt)) {
              expiredEntries++;
            } else {
              validEntries++;
            }
          } catch (e) {
            // Invalid cache entry
          }
        }
      }

      return CacheStats(
        totalEntries: totalEntries,
        validEntries: validEntries,
        expiredEntries: expiredEntries,
        totalSizeBytes: totalSize,
      );
    } catch (e) {
      return CacheStats.empty();
    }
  }

  /// Clean expired cache entries
  Future<void> cleanExpiredCache() async {
    try {
      await _ensureInitialized();

      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));

      for (final key in cacheKeys) {
        final data = _prefs!.getString(key);
        if (data != null) {
          try {
            final decodedData = jsonDecode(data) as Map<String, dynamic>;
            final expiresAt = DateTime.parse(decodedData['expiresAt']);

            if (DateTime.now().isAfter(expiresAt)) {
              await _prefs!.remove(key);
            }
          } catch (e) {
            // Remove invalid entries
            await _prefs!.remove(key);
          }
        }
      }

      if (kDebugMode) {
        print('🧽 Cleaned expired cache entries');
      }
    } catch (e) {
      ErrorHandler().reportError(
        AppError.generic(
          message: 'Failed to clean expired cache',
          category: ErrorCategory.storage,
          originalError: e,
        ),
      );
    }
  }
}

/// Cache entry with metadata
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final DateTime expiresAt;
  final Map<String, dynamic> metadata;
  final bool isExpired;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiresAt,
    required this.metadata,
    this.isExpired = false,
  });

  bool get isValid => !isExpired && DateTime.now().isBefore(expiresAt);

  Duration get timeToExpiry => expiresAt.difference(DateTime.now());

  @override
  String toString() {
    return 'CacheEntry(valid: $isValid, expires: $expiresAt, data: ${data.toString().substring(0, min(50, data.toString().length))})';
  }

  int min(int a, int b) => a < b ? a : b;
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int totalSizeBytes;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.totalSizeBytes,
  });

  factory CacheStats.empty() {
    return CacheStats(
      totalEntries: 0,
      validEntries: 0,
      expiredEntries: 0,
      totalSizeBytes: 0,
    );
  }

  double get hitRate => totalEntries > 0 ? validEntries / totalEntries : 0.0;

  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '${totalSizeBytes}B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  @override
  String toString() {
    return 'CacheStats(entries: $totalEntries, valid: $validEntries, expired: $expiredEntries, size: $formattedSize)';
  }
}

/// Offline data manager for handling offline/online sync
class OfflineDataManager {
  final CacheService _cacheService = CacheService();

  /// Queue for pending operations to sync when online
  final List<PendingOperation> _pendingOperations = [];

  /// Execute operation with offline support
  Future<Result<T>> executeWithOfflineSupport<T>(
    String cacheKey,
    Future<T> Function() onlineOperation, {
    Duration cacheDuration = const Duration(hours: 1),
    bool forceRefresh = false,
  }) async {
    try {
      // Try online operation first
      final result = await onlineOperation();

      // Cache successful result
      await _cacheService.setCache(cacheKey, result, duration: cacheDuration);

      return Result.success(result);
    } catch (error) {
      final appError = ErrorHandler.convertToAppError(error);

      // If network error, try to get cached data
      if (appError.category == ErrorCategory.network) {
        final cachedData = await _cacheService.getCacheOffline(cacheKey);

        if (cachedData != null && cachedData.data != null) {
          // Return cached data with offline indicator
          return Result.success(cachedData.data as T);
        }
      }

      // Queue operation for later sync if it's a network error
      if (appError.category == ErrorCategory.network && appError.isRetryable) {
        _queueOperation(cacheKey, onlineOperation);
      }

      return Result.failure(appError);
    }
  }

  /// Sync pending operations when back online
  Future<void> syncPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    final operationsToRemove = <int>[];

    for (int i = 0; i < _pendingOperations.length; i++) {
      final operation = _pendingOperations[i];

      try {
        await operation.execute();
        operationsToRemove.add(i);

        if (kDebugMode) {
          print('✅ Synced pending operation: ${operation.cacheKey}');
        }
      } catch (e) {
        // Keep failed operations for next sync attempt
        if (kDebugMode) {
          print('❌ Failed to sync operation: ${operation.cacheKey}');
        }
      }
    }

    // Remove successfully synced operations
    for (int i = operationsToRemove.length - 1; i >= 0; i--) {
      _pendingOperations.removeAt(operationsToRemove[i]);
    }
  }

  /// Queue operation for later execution
  void _queueOperation<T>(String cacheKey, Future<T> Function() operation) {
    _pendingOperations.add(PendingOperation(
      cacheKey: cacheKey,
      execute: () => operation(),
      timestamp: DateTime.now(),
    ));

    if (kDebugMode) {
      print('📋 Queued operation for offline sync: $cacheKey');
    }
  }

  /// Get pending operations count
  int get pendingOperationsCount => _pendingOperations.length;

  /// Clear all pending operations
  void clearPendingOperations() {
    _pendingOperations.clear();
  }
}

/// Pending operation for offline sync
class PendingOperation {
  final String cacheKey;
  final Future<void> Function() execute;
  final DateTime timestamp;

  PendingOperation({
    required this.cacheKey,
    required this.execute,
    required this.timestamp,
  });
}
