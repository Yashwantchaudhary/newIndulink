import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 💾 Offline Cache Service
/// Advanced offline data caching with SQLite and file storage

class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  Database? _database;
  SharedPreferences? _prefs;
  final Connectivity _connectivity = Connectivity();

  // Cache configuration
  static const String _dbName = 'indulink_cache.db';
  static const int _dbVersion = 1;
  static const Duration _defaultCacheDuration = Duration(hours: 24);
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB

  bool _isInitialized = false;
  bool _isOnline = true;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize SQLite database
      await _initDatabase();

      // Setup connectivity monitoring
      await _setupConnectivityMonitoring();

      // Check initial connectivity
      await _checkConnectivity();

      // Clean up expired cache
      await _cleanupExpiredCache();

      _isInitialized = true;
      debugPrint('✅ Offline cache service initialized');
    } catch (error) {
      debugPrint('❌ Failed to initialize offline cache: $error');
      rethrow;
    }
  }

  /// Initialize SQLite database
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Cache entries table
    await db.execute('''
      CREATE TABLE cache_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        data TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        expires_at INTEGER,
        size INTEGER NOT NULL,
        priority INTEGER DEFAULT 0,
        tags TEXT
      )
    ''');

    // Sync queue table for offline operations
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        data TEXT,
        headers TEXT,
        timestamp INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        max_retries INTEGER DEFAULT 3,
        status TEXT DEFAULT 'pending'
      )
    ''');

    // User data table
    await db.execute('''
      CREATE TABLE user_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        data_type TEXT NOT NULL,
        data TEXT NOT NULL,
        last_sync INTEGER NOT NULL,
        version INTEGER DEFAULT 1,
        UNIQUE(user_id, data_type)
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_cache_key ON cache_entries(key)');
    await db.execute('CREATE INDEX idx_cache_type ON cache_entries(type)');
    await db
        .execute('CREATE INDEX idx_cache_expires ON cache_entries(expires_at)');
    await db.execute('CREATE INDEX idx_sync_status ON sync_queue(status)');
    await db
        .execute('CREATE INDEX idx_user_data ON user_data(user_id, data_type)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database migrations
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      // Migration logic for each version
    }
  }

  /// Setup connectivity monitoring
  Future<void> _setupConnectivityMonitoring() async {
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        // Came back online, trigger sync
        _onConnectivityRestored();
      } else if (wasOnline && !_isOnline) {
        // Went offline
        debugPrint('📴 Device went offline');
      }
    });
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;
    } catch (error) {
      debugPrint('❌ Connectivity check failed: $error');
      _isOnline = false;
    }
  }

  /// Handle connectivity restoration
  Future<void> _onConnectivityRestored() async {
    debugPrint('📡 Connectivity restored, starting sync...');

    try {
      // Process sync queue
      await processSyncQueue();

      // Refresh critical data
      await _refreshCriticalData();

      debugPrint('✅ Sync completed after connectivity restoration');
    } catch (error) {
      debugPrint('❌ Sync failed after connectivity restoration: $error');
    }
  }

  // ==================== CACHE OPERATIONS ====================

  /// Store data in cache
  Future<bool> set(
    String key,
    dynamic data, {
    String type = 'general',
    Duration? ttl,
    int priority = 0,
    List<String>? tags,
  }) async {
    if (!_isInitialized || _database == null) return false;

    try {
      final jsonData = jsonEncode(data);
      final size = utf8.encode(jsonData).length;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = ttl != null ? timestamp + ttl.inMilliseconds : null;

      // Check cache size limits
      if (await _getCacheSize() + size > _maxCacheSize) {
        await _evictCache(size);
      }

      await _database!.insert(
        'cache_entries',
        {
          'key': key,
          'data': jsonData,
          'type': type,
          'timestamp': timestamp,
          'expires_at': expiresAt,
          'size': size,
          'priority': priority,
          'tags': tags != null ? jsonEncode(tags) : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return true;
    } catch (error) {
      debugPrint('❌ Cache set error: $error');
      return false;
    }
  }

  /// Retrieve data from cache
  Future<dynamic> get(String key) async {
    if (!_isInitialized || _database == null) return null;

    try {
      final result = await _database!.query(
        'cache_entries',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (result.isEmpty) return null;

      final entry = result.first;
      final expiresAt = entry['expires_at'] as int?;

      // Check if expired
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await delete(key);
        return null;
      }

      return jsonDecode(entry['data'] as String);
    } catch (error) {
      debugPrint('❌ Cache get error: $error');
      return null;
    }
  }

  /// Delete cache entry
  Future<bool> delete(String key) async {
    if (!_isInitialized || _database == null) return false;

    try {
      await _database!.delete(
        'cache_entries',
        where: 'key = ?',
        whereArgs: [key],
      );
      return true;
    } catch (error) {
      debugPrint('❌ Cache delete error: $error');
      return false;
    }
  }

  /// Check if key exists in cache
  Future<bool> exists(String key) async {
    if (!_isInitialized || _database == null) return false;

    try {
      final result = await _database!.query(
        'cache_entries',
        columns: ['id'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (error) {
      debugPrint('❌ Cache exists error: $error');
      return false;
    }
  }

  /// Clear cache by type
  Future<int> clearByType(String type) async {
    if (!_isInitialized || _database == null) return 0;

    try {
      final result = await _database!.delete(
        'cache_entries',
        where: 'type = ?',
        whereArgs: [type],
      );
      debugPrint('🧹 Cleared $result cache entries of type: $type');
      return result;
    } catch (error) {
      debugPrint('❌ Clear by type error: $error');
      return 0;
    }
  }

  /// Clear expired cache entries
  Future<int> clearExpired() async {
    if (!_isInitialized || _database == null) return 0;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = await _database!.delete(
        'cache_entries',
        where: 'expires_at IS NOT NULL AND expires_at < ?',
        whereArgs: [now],
      );
      debugPrint('🧹 Cleared $result expired cache entries');
      return result;
    } catch (error) {
      debugPrint('❌ Clear expired error: $error');
      return 0;
    }
  }

  /// Clear all cache
  Future<int> clearAll() async {
    if (!_isInitialized || _database == null) return 0;

    try {
      final result = await _database!.delete('cache_entries');
      debugPrint('🧹 Cleared all $result cache entries');
      return result;
    } catch (error) {
      debugPrint('❌ Clear all error: $error');
      return 0;
    }
  }

  // ==================== SYNC QUEUE ====================

  /// Add operation to sync queue
  Future<int> addToSyncQueue({
    required String operation,
    required String endpoint,
    dynamic data,
    Map<String, String>? headers,
    int maxRetries = 3,
  }) async {
    if (!_isInitialized || _database == null) return -1;

    try {
      final id = await _database!.insert('sync_queue', {
        'operation': operation,
        'endpoint': endpoint,
        'data': data != null ? jsonEncode(data) : null,
        'headers': headers != null ? jsonEncode(headers) : null,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'max_retries': maxRetries,
      });

      debugPrint('📋 Added operation to sync queue: $operation $endpoint');
      return id;
    } catch (error) {
      debugPrint('❌ Add to sync queue error: $error');
      return -1;
    }
  }

  /// Process sync queue
  Future<void> processSyncQueue() async {
    if (!_isInitialized || _database == null || !_isOnline) return;

    try {
      final pendingOperations = await _database!.query(
        'sync_queue',
        where: 'status = ? AND retry_count < max_retries',
        whereArgs: ['pending'],
        orderBy: 'timestamp ASC',
      );

      for (final operation in pendingOperations) {
        await _processSyncOperation(operation);
      }
    } catch (error) {
      debugPrint('❌ Process sync queue error: $error');
    }
  }

  /// Process individual sync operation
  Future<void> _processSyncOperation(Map<String, dynamic> operation) async {
    try {
      // Update status to processing
      await _database!.update(
        'sync_queue',
        {'status': 'processing'},
        where: 'id = ?',
        whereArgs: [operation['id']],
      );

      // Parse operation data
      final operationType = operation['operation'] as String;
      final endpoint = operation['endpoint'] as String;
      final data =
          operation['data'] != null ? jsonDecode(operation['data']) : null;
      final headers = operation['headers'] != null
          ? jsonDecode(operation['headers'])
          : null;

      // Execute operation (this would integrate with your API service)
      final success =
          await _executeSyncOperation(operationType, endpoint, data, headers);

      if (success) {
        // Mark as completed
        await _database!.update(
          'sync_queue',
          {'status': 'completed'},
          where: 'id = ?',
          whereArgs: [operation['id']],
        );
        debugPrint('✅ Sync operation completed: ${operation['id']}');
      } else {
        // Increment retry count
        final newRetryCount = (operation['retry_count'] as int) + 1;
        await _database!.update(
          'sync_queue',
          {'status': 'pending', 'retry_count': newRetryCount},
          where: 'id = ?',
          whereArgs: [operation['id']],
        );
        debugPrint('⚠️ Sync operation failed, retry count: $newRetryCount');
      }
    } catch (error) {
      debugPrint('❌ Process sync operation error: $error');

      // Mark as failed
      await _database!.update(
        'sync_queue',
        {'status': 'failed'},
        where: 'id = ?',
        whereArgs: [operation['id']],
      );
    }
  }

  /// Execute sync operation (integrates with API service)
  Future<bool> _executeSyncOperation(String operation, String endpoint,
      dynamic data, Map<String, String>? headers) async {
    // This would integrate with your actual API service
    // For now, return true to simulate success
    debugPrint('🔄 Executing sync operation: $operation $endpoint');
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return true;
  }

  // ==================== USER DATA CACHE ====================

  /// Cache user-specific data
  Future<bool> setUserData(String userId, String dataType, dynamic data) async {
    if (!_isInitialized || _database == null) return false;

    try {
      final jsonData = jsonEncode(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await _database!.insert(
        'user_data',
        {
          'user_id': userId,
          'data_type': dataType,
          'data': jsonData,
          'last_sync': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return true;
    } catch (error) {
      debugPrint('❌ Set user data error: $error');
      return false;
    }
  }

  /// Get user-specific data
  Future<dynamic> getUserData(String userId, String dataType) async {
    if (!_isInitialized || _database == null) return null;

    try {
      final result = await _database!.query(
        'user_data',
        where: 'user_id = ? AND data_type = ?',
        whereArgs: [userId, dataType],
      );

      if (result.isEmpty) return null;

      return jsonDecode(result.first['data'] as String);
    } catch (error) {
      debugPrint('❌ Get user data error: $error');
      return null;
    }
  }

  /// Clear user data
  Future<bool> clearUserData(String userId) async {
    if (!_isInitialized || _database == null) return false;

    try {
      await _database!.delete(
        'user_data',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (error) {
      debugPrint('❌ Clear user data error: $error');
      return false;
    }
  }

  // ==================== FILE CACHE ====================

  /// Cache file to local storage
  Future<String?> cacheFile(String url, List<int> bytes,
      {String? filename}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/cache/files');

      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final fileName = filename ?? _generateFileName(url);
      final file = File('${cacheDir.path}/$fileName');

      await file.writeAsBytes(bytes);

      // Store file metadata in cache
      await set(
        'file:$url',
        {
          'path': file.path,
          'size': bytes.length,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        type: 'file',
        ttl: const Duration(days: 7),
      );

      return file.path;
    } catch (error) {
      debugPrint('❌ Cache file error: $error');
      return null;
    }
  }

  /// Get cached file path
  Future<String?> getCachedFile(String url) async {
    try {
      final metadata = await get('file:$url');
      if (metadata == null) return null;

      final file = File(metadata['path']);
      if (await file.exists()) {
        return file.path;
      } else {
        // File doesn't exist, remove metadata
        await delete('file:$url');
        return null;
      }
    } catch (error) {
      debugPrint('❌ Get cached file error: $error');
      return null;
    }
  }

  /// Generate filename from URL
  String _generateFileName(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    final extension = path.split('.').last;
    final hash = url.hashCode.abs().toString();
    return '$hash.$extension';
  }

  // ==================== UTILITY METHODS ====================

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (!_isInitialized || _database == null) {
      return {'initialized': false};
    }

    try {
      final cacheStats = await _database!.rawQuery('''
        SELECT
          COUNT(*) as total_entries,
          SUM(size) as total_size,
          AVG(size) as avg_size,
          MIN(timestamp) as oldest_entry,
          MAX(timestamp) as newest_entry
        FROM cache_entries
      ''');

      final syncStats = await _database!.rawQuery('''
        SELECT
          status,
          COUNT(*) as count
        FROM sync_queue
        GROUP BY status
      ''');

      final userDataStats = await _database!.rawQuery('''
        SELECT COUNT(*) as user_data_entries FROM user_data
      ''');

      return {
        'initialized': true,
        'cache': cacheStats.first,
        'sync_queue': syncStats,
        'user_data': userDataStats.first,
        'online': _isOnline,
      };
    } catch (error) {
      debugPrint('❌ Get cache stats error: $error');
      return {'initialized': false, 'error': error.toString()};
    }
  }

  /// Get current cache size
  Future<int> _getCacheSize() async {
    if (!_isInitialized || _database == null) return 0;

    try {
      final result = await _database!
          .rawQuery('SELECT SUM(size) as total FROM cache_entries');
      return (result.first['total'] as int?) ?? 0;
    } catch (error) {
      return 0;
    }
  }

  /// Evict cache to make room for new data
  Future<void> _evictCache(int requiredSize) async {
    if (!_isInitialized || _database == null) return;

    try {
      // First, remove expired entries
      await clearExpired();

      // If still not enough space, remove lowest priority items
      final currentSize = await _getCacheSize();
      if (currentSize + requiredSize > _maxCacheSize) {
        final toRemove = currentSize + requiredSize - _maxCacheSize;

        // Remove oldest low-priority items
        await _database!.rawDelete('''
          DELETE FROM cache_entries
          WHERE id IN (
            SELECT id FROM cache_entries
            WHERE priority = 0
            ORDER BY timestamp ASC
            LIMIT ?
          )
        ''', [100]); // Remove in batches
      }
    } catch (error) {
      debugPrint('❌ Cache eviction error: $error');
    }
  }

  /// Cleanup expired cache entries
  Future<void> _cleanupExpiredCache() async {
    await clearExpired();
  }

  /// Refresh critical data after coming online
  Future<void> _refreshCriticalData() async {
    // This would refresh critical user data, settings, etc.
    debugPrint('🔄 Refreshing critical data...');
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
      debugPrint('✅ Offline cache database closed');
    }
  }
}
