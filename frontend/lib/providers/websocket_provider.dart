import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_provider.dart';

/// 🌐 WebSocket Provider for Real-time Updates
/// Manages WebSocket connection and real-time data synchronization
class WebSocketProvider with ChangeNotifier {
  io.Socket? _socket;
  bool _isConnected = false;
  final AuthProvider _authProvider;

  // Connection status
  bool get isConnected => _isConnected;

  // Event callbacks
  Function(Map<String, dynamic>)? onDataChanged;
  Function(Map<String, dynamic>)? onUserDataChanged;
  Function(Map<String, dynamic>)? onOrderUpdated;
  Function(Map<String, dynamic>)? onProductUpdated;
  Function(Map<String, dynamic>)? onNewMessage;

  WebSocketProvider(this._authProvider) {
    _initializeSocket();
  }

  void _initializeSocket() {
    // WebSocket server URL (adjust for your environment)
    final String serverUrl = const String.fromEnvironment(
      'WEBSOCKET_URL',
      defaultValue: 'http://10.10.9.113:5000', // Local development
    );

    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'forceNew': true,
    });

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('🔌 WebSocket connected');
      _authenticate();
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('🔌 WebSocket disconnected');
      notifyListeners();
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      debugPrint('🔌 WebSocket connection error: $error');
      notifyListeners();
    });

    // Authentication events
    _socket!.on('authenticated', (data) {
      debugPrint('✅ WebSocket authenticated: $data');
    });

    _socket!.on('auth_error', (error) {
      debugPrint('❌ WebSocket auth error: $error');
    });

    // Data change events
    _socket!.on('data_changed', (data) {
      debugPrint('📊 Data changed: $data');
      onDataChanged?.call(data);
    });

    _socket!.on('user_data_changed', (data) {
      debugPrint('👤 User data changed: $data');
      onUserDataChanged?.call(data);
    });

    _socket!.on('order_updated', (data) {
      debugPrint('📦 Order updated: $data');
      onOrderUpdated?.call(data);
    });

    _socket!.on('product_updated', (data) {
      debugPrint('🛍️ Product updated: $data');
      onProductUpdated?.call(data);
    });

    _socket!.on('new_message', (data) {
      debugPrint('💬 New message: $data');
      onNewMessage?.call(data);
    });

    // Ping/Pong for connection health
    _socket!.on('pong', (_) {
      debugPrint('🏓 WebSocket pong received');
    });
  }

  void _authenticate() async {
    if (_socket == null || !_authProvider.isAuthenticated) return;

    final token = await _authProvider.getToken();
    if (token != null) {
      _socket!.emit('authenticate', {'token': token});
    }
  }

  /// Connect to WebSocket server
  void connect() {
    if (_socket != null && !_socket!.connected) {
      debugPrint('🔌 Connecting to WebSocket...');
      _socket!.connect();
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    if (_socket != null && _socket!.connected) {
      debugPrint('🔌 Disconnecting from WebSocket...');
      _socket!.disconnect();
    }
  }

  /// Send ping to check connection
  void ping() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('ping');
    }
  }

  /// Set event callbacks
  void setCallbacks({
    Function(Map<String, dynamic>)? onDataChanged,
    Function(Map<String, dynamic>)? onUserDataChanged,
    Function(Map<String, dynamic>)? onOrderUpdated,
    Function(Map<String, dynamic>)? onProductUpdated,
    Function(Map<String, dynamic>)? onNewMessage,
  }) {
    this.onDataChanged = onDataChanged;
    this.onUserDataChanged = onUserDataChanged;
    this.onOrderUpdated = onOrderUpdated;
    this.onProductUpdated = onProductUpdated;
    this.onNewMessage = onNewMessage;
  }

  /// Reconnect when auth state changes
  void onAuthStateChanged() {
    if (_authProvider.isAuthenticated) {
      connect();
    } else {
      disconnect();
    }
  }

  @override
  void dispose() {
    disconnect();
    _socket?.dispose();
    super.dispose();
  }
}