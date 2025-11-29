import '../core/constants/app_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// 📦 Product Service
/// Handles product data operations
class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // ==================== Fetch Products ====================

  /// Get all products with pagination
  Future<ProductResult> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
  }) async {
    try {
      // Build query parameters
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null) params['category'] = category;
      if (minPrice != null) params['minPrice'] = minPrice.toString();
      if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
      if (minRating != null) params['minRating'] = minRating.toString();
      if (sortBy != null) params['sortBy'] = sortBy;

      final response = await _api.get(
        AppConfig.productsEndpoint,
        params: params,
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final productsJson = data['products'] ?? data['data'] ?? [];
        final products = (productsJson as List)
            .map((json) => Product.fromJson(json))
            .toList();

        return ProductResult(
          success: true,
          products: products,
          total: data['total'] ?? products.length,
          page: data['page'] ?? page,
          totalPages: data['totalPages'] ?? 1,
        );
      } else {
        return ProductResult(
          success: false,
          message: response.message ?? 'Failed to fetch products',
        );
      }
    } catch (e) {
      return ProductResult(
        success: false,
        message: 'An error occurred while fetching products',
      );
    }
  }

  /// Get featured products
  Future<ProductResult> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await _api.get(
        AppConfig.featuredProductsEndpoint,
        params: {'limit': limit.toString()},
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final productsJson = response.data['products'] ?? response.data ?? [];
        final products = (productsJson as List)
            .map((json) => Product.fromJson(json))
            .toList();

        return ProductResult(
          success: true,
          products: products,
        );
      } else {
        return ProductResult(
          success: false,
          message: response.message ?? 'Failed to fetch featured products',
        );
      }
    } catch (e) {
      return ProductResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Search products
  Future<ProductResult> searchProducts({
    required String query,
    int page = 1,
    int limit = 20,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null) params['category'] = category;
      if (minPrice != null) params['minPrice'] = minPrice.toString();
      if (maxPrice != null) params['maxPrice'] = maxPrice.toString();

      final response = await _api.get(
        AppConfig.searchProductsEndpoint,
        params: params,
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final productsJson = data['products'] ?? data['results'] ?? [];
        final products = (productsJson as List)
            .map((json) => Product.fromJson(json))
            .toList();

        // Save search query to history
        if (query.isNotEmpty) {
          await _storage.addSearchQuery(query);
        }

        return ProductResult(
          success: true,
          products: products,
          total: data['total'] ?? products.length,
        );
      } else {
        return ProductResult(
          success: false,
          message: response.message ?? 'Search failed',
        );
      }
    } catch (e) {
      return ProductResult(
        success: false,
        message: 'An error occurred during search',
      );
    }
  }

  /// Get product details by ID
  Future<ProductDetailResult> getProductDetails(String productId) async {
    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.productDetailsEndpoint,
        {'id': productId},
      );

      final response = await _api.get(endpoint, requiresAuth: false);

      if (response.isSuccess && response.data != null) {
        final product = Product.fromJson(response.data);

        // Add to recently viewed
        await _storage.addRecentlyViewed(productId);

        return ProductDetailResult(
          success: true,
          product: product,
        );
      } else {
        return ProductDetailResult(
          success: false,
          message: response.message ?? 'Product not found',
        );
      }
    } catch (e) {
      return ProductDetailResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  // ==================== Categories ====================

  /// Get all categories
  Future<CategoryResult> getCategories() async {
    try {
      final response = await _api.get(
        AppConfig.categoriesEndpoint,
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final categoriesJson =
            response.data['categories'] ?? response.data ?? [];
        final categories = (categoriesJson as List)
            .map((json) => Category.fromJson(json))
            .toList();

        return CategoryResult(
          success: true,
          categories: categories,
        );
      } else {
        return CategoryResult(
          success: false,
          message: response.message ?? 'Failed to fetch categories',
        );
      }
    } catch (e) {
      return CategoryResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Get products by category
  Future<ProductResult> getProductsByCategory({
    required String categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.categoryProductsEndpoint,
        {'id': categoryId},
      );

      final response = await _api.get(
        endpoint,
        params: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final productsJson = data['products'] ?? [];
        final products = (productsJson as List)
            .map((json) => Product.fromJson(json))
            .toList();

        return ProductResult(
          success: true,
          products: products,
          total: data['total'] ?? products.length,
        );
      } else {
        return ProductResult(
          success: false,
          message: response.message ?? 'Failed to fetch products',
        );
      }
    } catch (e) {
      return ProductResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  // ==================== Recently Viewed ====================

  /// Get recently viewed products
  Future<ProductResult> getRecentlyViewed() async {
    try {
      final productIds = await _storage.getRecentlyViewed();

      if (productIds.isEmpty) {
        return ProductResult(
          success: true,
          products: [],
        );
      }

      // Fetch products by IDs (implement this endpoint in backend if needed)
      // For now, return empty list
      return ProductResult(
        success: true,
        products: [],
      );
    } catch (e) {
      return ProductResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }
}

/// 📋 Product Result Model
class ProductResult {
  final bool success;
  final String? message;
  final List<Product> products;
  final int? total;
  final int? page;
  final int? totalPages;

  ProductResult({
    required this.success,
    this.message,
    this.products = const [],
    this.total,
    this.page,
    this.totalPages,
  });
}

/// 📋 Product Detail Result
class ProductDetailResult {
  final bool success;
  final String? message;
  final Product? product;

  ProductDetailResult({
    required this.success,
    this.message,
    this.product,
  });
}

/// 📋 Category Result
class CategoryResult {
  final bool success;
  final String? message;
  final List<Category> categories;

  CategoryResult({
    required this.success,
    this.message,
    this.categories = const [],
  });
}
