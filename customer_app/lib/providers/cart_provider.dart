import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart.dart';
import '../services/cart_service.dart';
import 'auth_provider.dart';

/// Provider for cart service
final cartServiceProvider = Provider<CartService>((ref) {
  final service = CartService();

  // Watch auth state to set token
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.token != null) {
      service.setToken(next.token!);
    }
  });

  // Set initial token if available
  final authState = ref.read(authProvider);
  if (authState.token != null) {
    service.setToken(authState.token!);
  }

  return service;
});

/// Cart state
class CartState {
  final Cart cart;
  final bool isLoading;
  final String? error;

  CartState({
    required this.cart,
    this.isLoading = false,
    this.error,
  });

  int get itemCount => cart.itemCount;
  bool get isEmpty => cart.isEmpty;
  bool get hasItems => !cart.isEmpty;
  List<CartItem> get items => cart.items;
  double get subtotal => cart.subtotal;
  double get tax => cart.tax;
  double get total => cart.total;

  CartState copyWith({
    Cart? cart,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Cart provider with state management
class CartNotifier extends StateNotifier<CartState> {
  final CartService _service;
  final Ref _ref;

  CartNotifier(this._service, this._ref)
      : super(CartState(cart: Cart.empty())) {
    // Listen to auth state changes
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user?.role == 'customer' &&
          (previous?.user?.role != 'customer')) {
        _loadCart();
      }
    });

    // Only load cart if user is a customer
    final authState = _ref.read(authProvider);
    if (authState.user?.role == 'customer') {
      _loadCart();
    }
  }

  /// Load cart from backend
  Future<void> _loadCart() async {
    try {
      final cart = await _service.getCart();
      state = state.copyWith(cart: cart);
      await _saveCartToLocal(cart);
    } catch (e) {
      // Load from local storage if API fails
      await _loadCartFromLocal();
    }
  }

  /// Refresh cart
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cart = await _service.getCart();
      state = state.copyWith(cart: cart, isLoading: false);
      await _saveCartToLocal(cart);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add item to cart
  Future<bool> addToCart({
    required String productId,
    required int quantity,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedCart = await _service.addToCart(
        productId: productId,
        quantity: quantity,
      );
      state = state.copyWith(cart: updatedCart, isLoading: false);
      await _saveCartToLocal(updatedCart);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update cart item quantity
  Future<bool> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    if (quantity < 1) {
      return removeFromCart(itemId);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedCart = await _service.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );
      state = state.copyWith(cart: updatedCart, isLoading: false);
      await _saveCartToLocal(updatedCart);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedCart = await _service.removeFromCart(itemId);
      state = state.copyWith(cart: updatedCart, isLoading: false);
      await _saveCartToLocal(updatedCart);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear cart
  Future<bool> clearCart() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.clearCart();
      state = state.copyWith(cart: Cart.empty(), isLoading: false);
      await _clearLocalCart();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Save cart to local storage
  Future<void> _saveCartToLocal(Cart cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart', jsonEncode(cart.toJson()));
    } catch (e) {
      // Ignore local storage errors
    }
  }

  /// Load cart from local storage
  Future<void> _loadCartFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart');
      if (cartJson != null) {
        final cart = Cart.fromJson(jsonDecode(cartJson));
        state = state.copyWith(cart: cart);
      }
    } catch (e) {
      // Ignore local storage errors
    }
  }

  /// Clear local cart
  Future<void> _clearLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart');
    } catch (e) {
      // Ignore local storage errors
    }
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final service = ref.watch(cartServiceProvider);
  return CartNotifier(service, ref);
});

/// Cart item count provider (for badge)
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});
