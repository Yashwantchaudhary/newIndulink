import '../models/product.dart';
import 'api_service.dart';

class WishlistService {
  final ApiService _apiService = ApiService();

  // Get user's wishlist
  Future<List<Product>> getWishlist() async {
    try {
      final response = await _apiService.get('/wishlist');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final productsData = response.data['data']['items'] as List;
        return productsData
            .map((json) => Product.fromJson(json['product']))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Add product to wishlist
  Future<void> addToWishlist(String productId) async {
    try {
      await _apiService.post(
        '/wishlist',
        data: {'product': productId},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Remove product from wishlist
  Future<void> removeFromWishlist(String productId) async {
    try {
      await _apiService.delete('/wishlist/$productId');
    } catch (e) {
      rethrow;
    }
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String productId) async {
    try {
      final response = await _apiService.get('/wishlist/check/$productId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['inWishlist'] as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Clear entire wishlist
  Future<void> clearWishlist() async {
    try {
      await _apiService.delete('/wishlist');
    } catch (e) {
      rethrow;
    }
  }
}
