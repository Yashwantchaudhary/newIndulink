import 'dart:io';

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

  /// Get all products with pagination and filters
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
        retries: 2,
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
            message: response.message ?? 'Failed to fetch products');
      }
    } catch (e) {
      return ProductResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Get featured products
  Future<ProductResult> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await _api.get(
        AppConfig.featuredProductsEndpoint,
        params: {'limit': limit.toString()},
        requiresAuth: false,
        retries: 2,
      );

      if (response.isSuccess && response.data != null) {
        final productsJson = response.data['products'] ?? response.data ?? [];
        final products = (productsJson as List)
            .map((json) => Product.fromJson(json))
            .toList();

        return ProductResult(success: true, products: products);
      } else {
        return ProductResult(
            success: false,
            message: response.message ?? 'Failed to fetch featured products');
      }
    } catch (e) {
      return ProductResult(success: false, message: 'Error: ${e.toString()}');
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
      final body = <String, dynamic>{
        'query': query,
        'page': page,
        'limit': limit,
        'filters': {},
      };

      if (category != null) body['filters']['categories'] = [category];

      if (minPrice != null || maxPrice != null) {
        body['filters']['priceRange'] = {};
        if (minPrice != null) body['filters']['priceRange']['min'] = minPrice;
        if (maxPrice != null) body['filters']['priceRange']['max'] = maxPrice;
      }

      final response = await _api.post(
        AppConfig.searchProductsEndpoint,
        body: body,
        requiresAuth: false,
        retries: 2,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        // Controller returns { success: true, data: [products] }
        final productsJson = data['data'] ?? data['products'] ?? [];
        final products = (productsJson as List)
            .map((json) => Product.fromJson(json))
            .toList();

        if (query.isNotEmpty) {
          await _storage.addSearchQuery(query);
        }

        return ProductResult(
            success: true,
            products: products,
            total: data['total'] ?? products.length);
      } else {
        return ProductResult(
            success: false, message: response.message ?? 'Search failed');
      }
    } catch (e) {
      return ProductResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Get product details by ID
  Future<ProductDetailResult> getProductDetails(String productId) async {
    try {
      final endpoint = AppConfig.replaceParams(
          AppConfig.productDetailsEndpoint, {'id': productId});
      final response =
          await _api.get(endpoint, requiresAuth: false, retries: 2);

      if (response.isSuccess && response.data != null) {
        final product = Product.fromJson(response.data);
        await _storage.addRecentlyViewed(productId);
        return ProductDetailResult(success: true, product: product);
      } else {
        return ProductDetailResult(
            success: false, message: response.message ?? 'Product not found');
      }
    } catch (e) {
      return ProductDetailResult(
          success: false, message: 'Error: ${e.toString()}');
    }
  }

  // ==================== Categories ====================

  /// Get all categories
  Future<CategoryResult> getCategories() async {
    try {
      final response = await _api.get(AppConfig.categoriesEndpoint,
          requiresAuth: false, retries: 2);

      if (response.isSuccess && response.data != null) {
        final categoriesJson =
            response.data['categories'] ?? response.data ?? [];
        final categories = (categoriesJson as List)
            .map((json) => Category.fromJson(json))
            .toList();
        return CategoryResult(success: true, categories: categories);
      } else {
        return CategoryResult(
            success: false,
            message: response.message ?? 'Failed to fetch categories');
      }
    } catch (e) {
      return CategoryResult(success: false, message: 'Error: ${e.toString()}');
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
          AppConfig.categoryProductsEndpoint, {'id': categoryId});
      final response = await _api.get(
        endpoint,
        params: {'page': page.toString(), 'limit': limit.toString()},
        requiresAuth: false,
        retries: 2,
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
            total: data['total'] ?? products.length);
      } else {
        return ProductResult(
            success: false,
            message: response.message ?? 'Failed to fetch products');
      }
    } catch (e) {
      return ProductResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  // ==================== Recently Viewed ====================

  /// Get recently viewed products
  Future<ProductResult> getRecentlyViewed() async {
    try {
      final productIds = await _storage.getRecentlyViewed();
      if (productIds.isEmpty) {
        return ProductResult(success: true, products: []);
      }

      // Future improvement: fetch products by IDs from backend
      return ProductResult(success: true, products: []);
    } catch (e) {
      return ProductResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  // ==================== Supplier Product Management ====================

  /// Get supplier's own products
  Future<ProductResult> getSupplierProducts(
      {int page = 1, int limit = 20}) async {
    try {
      final response = await _api.get(
        AppConfig.supplierProductsEndpoint,
        params: {'page': page.toString(), 'limit': limit.toString()},
      );

      if (response.isSuccess && response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;
        final actualData = dataMap.containsKey('data')
            ? Map<String, dynamic>.from(dataMap['data'] as Map)
            : dataMap;

        final List<dynamic> productsJson = actualData.containsKey('products')
            ? actualData['products']
            : actualData['data'] ?? [];

        final products =
            productsJson.map((json) => Product.fromJson(json)).toList();

        return ProductResult(
          success: true,
          products: products,
          total: actualData['total'] ?? products.length,
          page: actualData['page'] ?? page,
          totalPages: actualData['totalPages'] ?? 1,
        );
      } else {
        return ProductResult(
            success: false,
            message: response.message ?? 'Failed to fetch supplier products');
      }
    } catch (e) {
      return ProductResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Create a new product (Supplier)
  Future<ProductResult> createProduct(
    Map<String, String> fields,
    List<File> images,
  ) async {
    try {
      final response = await _api.uploadFiles(
        AppConfig.createProductEndpoint,
        images,
        fields: fields,
        fileField: 'images',
      );

      if (response.isSuccess && response.data != null) {
        final productJson = response.data['product'] ?? response.data;
        final product = Product.fromJson(productJson);
        return ProductResult(success: true, products: [product]);
      } else {
        return ProductResult(
          success: false,
          message: response.message ?? 'Failed to create product',
        );
      }
    } catch (e) {
      return ProductResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Update an existing product (Supplier)
  Future<ProductResult> updateProduct(
    String productId,
    Map<String, String> fields,
    List<File> images,
  ) async {
    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.updateProductEndpoint,
        {'id': productId},
      );

      // If no new images, we use a regular PUT request (if backend supports it, verify later)
      // But typically unified endpoint is better.
      // If images present, use Multipart PUT.

      final response = images.isNotEmpty
          ? await _api.uploadFiles(
              endpoint,
              images,
              fields: fields,
              fileField: 'images',
              method: 'PUT',
            )
          : await _api.put(
              endpoint,
              body: fields,
            );

      if (response.isSuccess && response.data != null) {
        final productJson = response.data['product'] ?? response.data;
        final product = Product.fromJson(productJson);
        return ProductResult(success: true, products: [product]);
      } else {
        return ProductResult(
          success: false,
          message: response.message ?? 'Failed to update product',
        );
      }
    } catch (e) {
      return ProductResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Delete a product (Supplier)
  Future<bool> deleteProduct(String productId) async {
    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.deleteProductEndpoint,
        {'id': productId},
      );
      final response = await _api.delete(endpoint);
      return response.isSuccess;
    } catch (e) {
      return false;
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

  ProductDetailResult({required this.success, this.message, this.product});
}

/// 📋 Category Result
class CategoryResult {
  final bool success;
  final String? message;
  final List<Category> categories;

  CategoryResult(
      {required this.success, this.message, this.categories = const []});
}
