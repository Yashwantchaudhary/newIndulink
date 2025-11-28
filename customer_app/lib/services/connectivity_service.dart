import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';
import 'cache_service.dart';

/// Service for monitoring network connectivity and managing offline/online states
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    _initialize();
  }

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<List<ConnectivityResult>>
      _connectivityResultController =
      StreamController<List<ConnectivityResult>>.broadcast();

  bool _isOnline = true;
  List<ConnectivityResult> _currentResults = [ConnectivityResult.wifi];
  Timer? _reconnectionTimer;

  /// Stream that emits true when online, false when offline
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Stream that emits connectivity result changes
  Stream<List<ConnectivityResult>> get connectivityResult =>
      _connectivityResultController.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Current connectivity results
  List<ConnectivityResult> get currentResults => _currentResults;

  /// Primary connectivity result (first non-none result, or none if all are none)
  ConnectivityResult get currentResult {
    if (_currentResults.isEmpty) return ConnectivityResult.none;
    return _currentResults.firstWhere(
      (result) => result != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
  }

  void _initialize() async {
    try {
      // Get initial connectivity status
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);

      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          ErrorHandler().reportError(
            AppError.network(
              message: 'Failed to monitor connectivity changes',
              originalError: error,
            ),
          );
        },
      );

      if (kDebugMode) {
        print('🔗 ConnectivityService initialized. Current status: $_isOnline');
      }
    } catch (e) {
      ErrorHandler().reportError(
        AppError.network(
          message: 'Failed to initialize connectivity monitoring',
          originalError: e,
        ),
      );
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _currentResults = results;

    // Determine if we're online based on connectivity results
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    // Emit status change
    _connectionStatusController.add(_isOnline);
    _connectivityResultController.add(results);

    if (kDebugMode) {
      print('🌐 Connectivity changed: $results (Online: $_isOnline)');
    }

    // Handle reconnection logic
    if (!wasOnline && _isOnline) {
      _handleReconnection();
    } else if (wasOnline && !_isOnline) {
      _handleDisconnection();
    }
  }

  void _handleReconnection() {
    if (kDebugMode) {
      print('🔄 Reconnected to network');
    }

    // Cancel any pending reconnection timer
    _reconnectionTimer?.cancel();

    // Notify error handler about reconnection
    ErrorHandler().reportError(
      AppError.generic(
        message: 'Network reconnected',
        userMessage: 'Connection restored. Syncing data...',
        category: ErrorCategory.network,
        severity: ErrorSeverity.low,
      ),
    );

    // Sync pending operations
    _syncPendingOperations();
  }

  Future<void> _syncPendingOperations() async {
    try {
      final offlineManager = OfflineDataManager();
      await offlineManager.syncPendingOperations();

      final pendingCount = offlineManager.pendingOperationsCount;
      if (pendingCount > 0) {
        if (kDebugMode) {
          print('⚠️ Some operations failed to sync: $pendingCount remaining');
        }
      } else {
        if (kDebugMode) {
          print('✅ All pending operations synced successfully');
        }
      }
    } catch (e) {
      ErrorHandler().reportError(
        AppError.generic(
          message: 'Failed to sync pending operations',
          category: ErrorCategory.unknown,
          originalError: e,
        ),
      );
    }
  }

  void _handleDisconnection() {
    if (kDebugMode) {
      print('📴 Disconnected from network');
    }

    // Start a timer to periodically check for reconnection
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        try {
          final result = await _connectivity.checkConnectivity();
          if (result != ConnectivityResult.none) {
            _updateConnectionStatus(result);
            _reconnectionTimer?.cancel();
          }
        } catch (e) {
          // Continue checking
        }
      },
    );

    // Report offline error
    ErrorHandler().reportError(
      AppError.network(
        message: 'Network disconnected',
      ),
    );
  }

  /// Force a connectivity check
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isOnline;
    } catch (e) {
      ErrorHandler().reportError(
        AppError.network(
          message: 'Failed to check connectivity',
          originalError: e,
        ),
      );
      return false;
    }
  }

  /// Get user-friendly connectivity description
  String getConnectivityDescription() {
    final result = currentResult;
    switch (result) {
      case ConnectivityResult.wifi:
        return 'Connected via Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Connected via Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Connected via Ethernet';
      case ConnectivityResult.vpn:
        return 'Connected via VPN';
      case ConnectivityResult.bluetooth:
        return 'Connected via Bluetooth';
      case ConnectivityResult.other:
        return 'Connected via Other Network';
      case ConnectivityResult.none:
        return 'No Internet Connection';
    }
  }

  /// Check if current connection is metered (mobile data)
  bool get isMeteredConnection => currentResult == ConnectivityResult.mobile;

  /// Check if current connection is Wi-Fi
  bool get isWifiConnection => currentResult == ConnectivityResult.wifi;

  /// Dispose resources
  void dispose() {
    _reconnectionTimer?.cancel();
    _connectionStatusController.close();
    _connectivityResultController.close();
  }
}

/// Connectivity-aware operation wrapper
class ConnectivityAwareOperation {
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Execute an operation with connectivity awareness
  Future<Result<T>> execute<T>(
    Future<T> Function() operation, {
    bool requireOnline = true,
    String? offlineMessage,
  }) async {
    // Check connectivity if required
    if (requireOnline && !_connectivityService.isOnline) {
      return Result.failure(
        AppError.network(
          message: 'Operation requires internet connection',
        ),
      );
    }

    try {
      final result = await operation();
      return Result.success(result);
    } catch (error) {
      final appError = ErrorHandler.convertToAppError(error);

      // If we get a network error, double-check connectivity
      if (appError.category == ErrorCategory.network) {
        await _connectivityService.checkConnectivity();
      }

      return Result.failure(appError);
    }
  }

  /// Execute with retry on network failures
  Future<Result<T>> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    bool requireOnline = true,
  }) async {
    return execute(
      () => RetryMechanism.execute(operation, config),
      requireOnline: requireOnline,
    );
  }
}
