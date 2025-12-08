import '../core/constants/app_config.dart';
import '../models/cart.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// 🛒 Cart Service
/// Handles shopping cart operations
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // ==================== Cart Operations ====================

  /// Get user's cart
  Future<CartResult> getCart() async {
    try {
      final response = await _api.get(AppConfig.cartEndpoint);

      if (response.isSuccess && response.data != null) {
        final cart = Cart.fromJson(response.data['data']);

        // Sync with local storage
        await _saveCartLocally(cart);

        return CartResult(
          success: true,
          cart: cart,
        );
      } else {
        // Try to get from local storage
        final localCart = await _getCartLocally();
        if (localCart != null) {
          return CartResult(success: true, cart: localCart);
        }

        return CartResult(
          success: false,
          message: response.message ?? 'Failed to fetch cart',
        );
      }
    } catch (e) {
      // Fallback to local cart
      final localCart = await _getCartLocally();
      if (localCart != null) {
        return CartResult(success: true, cart: localCart);
      }

      return CartResult(
        success: false,
        message: 'An error occurred while fetching cart',
      );
    }
  }

  /// Add item to cart
  Future<CartResult> addToCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      final response = await _api.post(
        AppConfig.cartEndpoint,
        body: {
          'productId': productId,
          'quantity': quantity,
        },
      );

      if (response.isSuccess && response.data != null) {
        final cart = Cart.fromJson(response.data['data']);
        await _saveCartLocally(cart);

        return CartResult(
          success: true,
          cart: cart,
          message: 'Item added to cart',
        );
      } else {
        return CartResult(
          success: false,
          message: response.message ?? 'Failed to add item to cart',
        );
      }
    } catch (e) {
      return CartResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Update cart item quantity
  Future<CartResult> updateCartItem({
    required String productId,
    required int quantity,
  }) async {
    try {
      final response = await _api.put(
        '${AppConfig.cartEndpoint}/$productId',
        body: {
          'quantity': quantity,
        },
      );

      if (response.isSuccess && response.data != null) {
        final cart = Cart.fromJson(response.data['data']);
        await _saveCartLocally(cart);

        return CartResult(
          success: true,
          cart: cart,
          message: 'Cart updated',
        );
      } else {
        return CartResult(
          success: false,
          message: response.message ?? 'Failed to update cart',
        );
      }
    } catch (e) {
      return CartResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Remove item from cart
  Future<CartResult> removeFromCart(String productId) async {
    try {
      final response = await _api.delete(
        '${AppConfig.cartEndpoint}/$productId',
      );

      if (response.isSuccess) {
        final cart = response.data['data'] != null
            ? Cart.fromJson(response.data['data'])
            : null;

        if (cart != null) {
          await _saveCartLocally(cart);
        }

        return CartResult(
          success: true,
          cart: cart,
          message: 'Item removed from cart',
        );
      } else {
        return CartResult(
          success: false,
          message: response.message ?? 'Failed to remove item',
        );
      }
    } catch (e) {
      return CartResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Clear entire cart
  Future<CartResult> clearCart() async {
    try {
      final response = await _api.delete(AppConfig.cartEndpoint);

      if (response.isSuccess) {
        await _storage.clearCart();

        return CartResult(
          success: true,
          message: 'Cart cleared',
        );
      } else {
        return CartResult(
          success: false,
          message: response.message ?? 'Failed to clear cart',
        );
      }
    } catch (e) {
      return CartResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  // ==================== Local Cart Management ====================

  /// Save cart to local storage
  Future<void> _saveCartLocally(Cart cart) async {
    final items = cart.items.map((item) {
      return {
        'productId': item.productId,
        'quantity': item.quantity,
        'priceAtAddition': item.priceAtAddition,
        'product': item.product.toJson(),
      };
    }).toList();

    await _storage.saveCartItems(items);
  }

  /// Get cart from local storage
  Future<Cart?> _getCartLocally() async {
    try {
      final items = await _storage.getCartItems();

      if (items.isEmpty) {
        return null;
      }

      final cartItems = items.map((item) {
        return CartItem.fromJson(item);
      }).toList();

      // Create a temporary cart
      return Cart(
        id: 'local',
        userId: 'local',
        items: cartItems,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Sync local cart with backend
  Future<void> syncCart() async {
    try {
      final localCart = await _getCartLocally();

      if (localCart == null || localCart.items.isEmpty) {
        return;
      }

      // Add each item to backend cart
      for (final item in localCart.items) {
        await addToCart(
          productId: item.productId,
          quantity: item.quantity,
        );
      }

      // Clear local cart after successful sync
      await _storage.clearCart();
    } catch (e) {
      // Sync failed, keep local cart
    }
  }
}

/// 📋 Cart Result Model
class CartResult {
  final bool success;
  final String? message;
  final Cart? cart;

  CartResult({
    required this.success,
    this.message,
    this.cart,
  });
}
