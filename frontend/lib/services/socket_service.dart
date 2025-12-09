import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/constants/app_config.dart';

/// 🔌 Socket Service
/// Manages real-time WebSocket connections and events
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  // Streams for events
  final _messageController = StreamController<dynamic>.broadcast();
  final _orderController = StreamController<dynamic>.broadcast();
  final _productController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<dynamic> get orderStream => _orderController.stream;
  Stream<dynamic> get productStream => _productController.stream;

  bool get isConnected => _isConnected;

  /// Initialize and connect socket
  void connect(String token, String userId, String role) {
    if (_socket != null && _socket!.connected) return;

    final uri = AppConfig.serverUrl;
    debugPrint('🔌 Connecting to Socket: $uri');

    try {
      _socket = io.io(
        uri,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('✅ Socket Connected: ${_socket!.id}');
        _socket!.emit('join', {'userId': userId, 'role': role});
        debugPrint('👤 Joined rooms for user: $userId, role: $role');
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ Socket Disconnected');
        _isConnected = false;
      });

      _socket!.onError((data) => debugPrint('⚠️ Socket Error: $data'));
      _socket!.onConnectError(
          (data) => debugPrint('⚠️ Socket Connect Error: $data'));

      // Listeners
      _setupListeners();
    } catch (e) {
      debugPrint('Error creating socket: $e');
    }
  }

  void _setupListeners() {
    if (_socket == null) return;

    // Messages
    _socket!.on('message:new', (data) {
      debugPrint('📨 New Message Received: $data');
      _messageController.add(data);
    });

    // Orders
    _socket!.on('order:new', (data) {
      debugPrint('📦 New Order Received: $data');
      _orderController.add({'type': 'new', 'data': data});
    });

    _socket!.on('order:updated', (data) {
      debugPrint('📦 Order Updated: $data');
      _orderController.add({'type': 'updated', 'data': data});
    });

    // Products
    _socket!.on('product_updated', (data) {
      debugPrint('🆕 Product Update Received: $data');
      _productController.add(data);
    });
  }

  /// Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }
}
