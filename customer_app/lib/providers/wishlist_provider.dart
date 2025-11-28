import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/wishlist_service.dart';

// Wishlist State
class WishlistState {
  final List<Product> items;
  final bool isLoading;
  final String? error;

  WishlistState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  WishlistState copyWith({
    List<Product>? items,
    bool? isLoading,
    String? error,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isInWishlist(String productId) {
    return items.any((product) => product.id == productId);
  }

  int get itemCount => items.length;
}

// Wishlist Notifier
class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistService _wishlistService = WishlistService();

  WishlistNotifier() : super(WishlistState());

  // Load wishlist
  Future<void> loadWishlist() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final products = await _wishlistService.getWishlist();
      state = state.copyWith(
        items: products,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Add to wishlist
  Future<bool> addToWishlist(String productId, Product product) async {
    // Optimistic update
    state = state.copyWith(
      items: [...state.items, product],
    );

    try {
      await _wishlistService.addToWishlist(productId);
      return true;
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        items: state.items.where((p) => p.id != productId).toList(),
        error: e.toString(),
      );
      return false;
    }
  }

  // Remove from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    // Store current items for rollback
    final previousItems = state.items;

    // Optimistic update
    state = state.copyWith(
      items: state.items.where((p) => p.id != productId).toList(),
    );

    try {
      await _wishlistService.removeFromWishlist(productId);
      return true;
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        items: previousItems,
        error: e.toString(),
      );
      return false;
    }
  }

  // Toggle wishlist
  Future<bool> toggleWishlist(String productId, Product product) async {
    if (state.isInWishlist(productId)) {
      return await removeFromWishlist(productId);
    } else {
      return await addToWishlist(productId, product);
    }
  }

  // Clear wishlist
  Future<bool> clearWishlist() async {
    // Store current items for rollback
    final previousItems = state.items;

    // Optimistic update
    state = state.copyWith(items: []);

    try {
      await _wishlistService.clearWishlist();
      return true;
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        items: previousItems,
        error: e.toString(),
      );
      return false;
    }
  }

  // Check if product is in wishlist (from server)
  Future<bool> checkIsInWishlist(String productId) async {
    try {
      return await _wishlistService.isInWishlist(productId);
    } catch (e) {
      return false;
    }
  }
}

// Provider
final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier();
});
