import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/storage_service.dart';

/// 🛒 Cart Provider
/// Manages shopping cart state
class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final StorageService _storageService = StorageService();

  // State
  Cart? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Cart? get cart => _cart;
  List<CartItem> get items => _cart?.items ?? [];
  int get itemCount => _cart?.totalItems ?? 0;
  double get subtotal => _cart?.subtotal ?? 0;
  double get tax => _cart?.taxAmount ?? 0;
  double get shippingFee => _cart?.shippingFee ?? 0;
  double get total => _cart?.total ?? 0;
  bool get isEmpty => _cart == null || _cart!.isEmpty;
  bool get isNotEmpty => !isEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Check if current user is a customer
  Future<bool> _isCustomer() async {
    final role = await _storageService.getUserRole();
    return role == 'customer';
  }

  /// Initialize cart (fetch from backend or local storage)
  Future<void> init() async {
    await fetchCart();
  }

  /// Fetch cart (only for customers)
  Future<void> fetchCart() async {
    // Only fetch cart for customer users
    if (!await _isCustomer()) {
      debugPrint('📦 Cart: Skipping fetch - user is not a customer');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _cartService.getCart();

      if (result.success) {
        _cart = result.cart;
      } else {
        _setError(result.message ?? 'Failed to load cart');
      }
    } catch (e) {
      _setError('An error occurred');
    }

    _setLoading(false);
  }

  /// Add item to cart
  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    _clearError();

    try {
      final result = await _cartService.addToCart(
        productId: product.id,
        quantity: quantity,
      );

      if (result.success) {
        _cart = result.cart;
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Failed to add to cart');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      return false;
    }
  }

  /// Update item quantity
  Future<bool> updateQuantity({
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return await removeItem(productId);
    }

    _clearError();

    try {
      final result = await _cartService.updateCartItem(
        productId: productId,
        quantity: quantity,
      );

      if (result.success) {
        _cart = result.cart;
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Failed to update quantity');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      return false;
    }
  }

  /// Increment item quantity
  Future<void> incrementQuantity(String productId) async {
    final item = items.firstWhere((item) => item.productId == productId);
    await updateQuantity(productId: productId, quantity: item.quantity + 1);
  }

  /// Decrement item quantity
  Future<void> decrementQuantity(String productId) async {
    final item = items.firstWhere((item) => item.productId == productId);
    if (item.quantity > 1) {
      await updateQuantity(productId: productId, quantity: item.quantity - 1);
    } else {
      await removeItem(productId);
    }
  }

  /// Remove item from cart
  Future<bool> removeItem(String productId) async {
    _clearError();

    try {
      final result = await _cartService.removeFromCart(productId);

      if (result.success) {
        _cart = result.cart;
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Failed to remove item');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      return false;
    }
  }

  /// Clear entire cart
  Future<bool> clearCart() async {
    _clearError();

    try {
      final result = await _cartService.clearCart();

      if (result.success) {
        _cart = null;
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Failed to clear cart');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      return false;
    }
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    return items.any((item) => item.productId == productId);
  }

  /// Get item quantity for a product
  int getItemQuantity(String productId) {
    try {
      final item = items.firstWhere((item) => item.productId == productId);
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// Sync cart after login
  Future<void> syncCart() async {
    await _cartService.syncCart();
    await fetchCart();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
