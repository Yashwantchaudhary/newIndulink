import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/websocket_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';

/// 🌐 Real-time Data Sync Widget
/// Connects WebSocket events to Cart and Order providers for live updates
class RealTimeDataSyncWidget extends StatefulWidget {
  final Widget child;

  const RealTimeDataSyncWidget({super.key, required this.child});

  @override
  State<RealTimeDataSyncWidget> createState() => _RealTimeDataSyncWidgetState();
}

class _RealTimeDataSyncWidgetState extends State<RealTimeDataSyncWidget> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _setupWebSocketCallbacks();
      _isInitialized = true;
    }
  }

  void _setupWebSocketCallbacks() {
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Set up WebSocket callbacks
    wsProvider.setCallbacks(
      // Cart update - refresh cart when items change
      onCartUpdated: (data) {
        debugPrint('🛒 Refreshing cart from WebSocket event');
        cartProvider.fetchCart();
      },

      // New order received (for suppliers/admins)
      onNewOrder: (data) {
        debugPrint('📦 New order notification received');
        orderProvider.refresh();
      },

      // Order status changed (for customers)
      onOrderStatusChanged: (data) {
        debugPrint('📦 Order status updated notification received');
        orderProvider.refresh();
      },

      // Order created (for the customer who placed the order)
      onOrderCreated: (data) {
        debugPrint('📦 Order created - refreshing cart and orders');
        cartProvider.fetchCart();
        orderProvider.refresh();
      },
    );

    // Listen for auth state changes to connect/disconnect WebSocket
    authProvider.addListener(() {
      wsProvider.onAuthStateChanged();
    });

    // Connect WebSocket if already authenticated
    if (authProvider.isAuthenticated) {
      wsProvider.connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
