import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

/// ❤️ Wishlist Provider
/// Manages user wishlist state and synchronization
class WishlistProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  List<Product> _wishlistItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Product> get wishlistItems => _wishlistItems;
  int get itemCount => _wishlistItems.length;
  bool get isEmpty => _wishlistItems.isEmpty;
  bool get isNotEmpty => _wishlistItems.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize wishlist (fetch from backend)
  Future<void> init() async {
    await fetchWishlist();
  }

  /// Fetch wishlist from backend
  Future<void> fetchWishlist() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/wishlist');

      if (response.success) {
        final List<dynamic> items = response.data['items'] ?? [];
        _wishlistItems =
            items.map((item) => Product.fromJson(item['product'])).toList();
      } else {
        _setError(response.message ?? 'Failed to load wishlist');
      }
    } catch (e) {
      _setError('An error occurred while loading wishlist');
      debugPrint('Wishlist fetch error: $e');
    }

    _setLoading(false);
  }

  /// Add product to wishlist
  Future<bool> addToWishlist(Product product) async {
    _clearError();

    // Optimistic update
    if (!isInWishlist(product.id)) {
      _wishlistItems.add(product);
      notifyListeners();
    }

    try {
      final response = await _apiService.post(
        '/wishlist/add',
        body: {'productId': product.id},
      );

      if (response.success) {
        // Backend confirmed, update with server data if needed
        await fetchWishlist();
        return true;
      } else {
        // Revert optimistic update on failure
        _wishlistItems.removeWhere((item) => item.id == product.id);
        _setError(response.message ?? 'Failed to add to wishlist');
        return false;
      }
    } catch (e) {
      // Revert optimistic update on error
      _wishlistItems.removeWhere((item) => item.id == product.id);
      _setError('An error occurred');
      notifyListeners();
      debugPrint('Add to wishlist error: $e');
      return false;
    }
  }

  /// Remove product from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    _clearError();

    // Find and save item for potential rollback
    final removedItem =
        _wishlistItems.firstWhere((item) => item.id == productId);
    final removedIndex = _wishlistItems.indexOf(removedItem);

    // Optimistic update
    _wishlistItems.removeWhere((item) => item.id == productId);
    notifyListeners();

    try {
      final response = await _apiService.delete('/wishlist/remove/$productId');

      if (response.success) {
        return true;
      } else {
        // Revert on failure
        _wishlistItems.insert(removedIndex, removedItem);
        _setError(response.message ?? 'Failed to remove from wishlist');
        return false;
      }
    } catch (e) {
      // Revert on error
      _wishlistItems.insert(removedIndex, removedItem);
      _setError('An error occurred');
      notifyListeners();
      debugPrint('Remove from wishlist error: $e');
      return false;
    }
  }

  /// Toggle product in wishlist (add if not exists, remove if exists)
  Future<bool> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      return await removeFromWishlist(product.id);
    } else {
      return await addToWishlist(product);
    }
  }

  /// Clear entire wishlist
  Future<bool> clearWishlist() async {
    _clearError();

    // Save for potential rollback
    final savedItems = List<Product>.from(_wishlistItems);

    // Optimistic update
    _wishlistItems.clear();
    notifyListeners();

    try {
      final response = await _apiService.delete('/wishlist/clear');

      if (response.success) {
        return true;
      } else {
        // Revert on failure
        _wishlistItems = savedItems;
        _setError(response.message ?? 'Failed to clear wishlist');
        return false;
      }
    } catch (e) {
      // Revert on error
      _wishlistItems = savedItems;
      _setError('An error occurred');
      notifyListeners();
      debugPrint('Clear wishlist error: $e');
      return false;
    }
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }

  /// Get wishlist product IDs (useful for checking multiple products)
  Set<String> get wishlistProductIds {
    return _wishlistItems.map((item) => item.id).toSet();
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
