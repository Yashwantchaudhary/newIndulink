import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';

// Product State
class ProductState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  ProductState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  ProductState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isEmpty => products.isEmpty;
  bool get hasProducts => products.isNotEmpty;
}

// Product Notifier
class ProductNotifier extends StateNotifier<ProductState> {
  final ApiService _apiService = ApiService();

  ProductNotifier() : super(ProductState());

  // Fetch products
  Future<void> fetchProducts({
    int page = 1,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? supplierId,
    bool loadMore = false,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': '20',
        if (category != null) 'category': category,
        if (search != null) 'search': search,
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
        if (sort != null) 'sort': sort,
        if (supplierId != null) 'supplierId': supplierId,
      };

      final response =
          await _apiService.get('/products', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<Product> newProducts = (response.data['data'] as List)
            .map((json) => Product.fromJson(json))
            .toList();

        state = state.copyWith(
          products:
              loadMore ? [...state.products, ...newProducts] : newProducts,
          isLoading: false,
          currentPage: page,
          hasMore: newProducts.length >= 20,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Fetch products by category
  Future<void> fetchProductsByCategory(String categoryId) async {
    // Reset state for new category
    state = ProductState();
    await fetchProducts(category: categoryId, page: 1);
  }

  // Refresh products
  Future<void> refreshProducts() async {
    state = ProductState();
    await fetchProducts();
  }

  // Load more products
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await fetchProducts(page: state.currentPage + 1, loadMore: true);
  }

  // Load products for supplier
  Future<void> loadProducts(String supplierId) async {
    await fetchProducts(supplierId: supplierId);
  }
}

// Product Provider
final productProvider =
    StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier();
});

// Single Product Provider
final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  final apiService = ApiService();
  try {
    final response = await apiService.get('/products/$productId');
    if (response.statusCode == 200) {
      return Product.fromJson(response.data['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

// Supplier Product State
class SupplierProductState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  SupplierProductState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  SupplierProductState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return SupplierProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isEmpty => products.isEmpty;
  bool get hasProducts => products.isNotEmpty;
}

// Supplier Product Notifier
class SupplierProductNotifier extends StateNotifier<SupplierProductState> {
  final ApiService _apiService = ApiService();

  SupplierProductNotifier() : super(SupplierProductState());

  // Fetch supplier's own products
  Future<void> fetchMyProducts({
    int page = 1,
    bool loadMore = false,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': '20',
      };

      final response = await _apiService.get('/products/supplier/me',
          queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<Product> newProducts = (response.data['products'] as List)
            .map((json) => Product.fromJson(json))
            .toList();

        state = state.copyWith(
          products:
              loadMore ? [...state.products, ...newProducts] : newProducts,
          isLoading: false,
          currentPage: page,
          hasMore: newProducts.length >= 20,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Refresh products
  Future<void> refreshProducts() async {
    state = SupplierProductState();
    await fetchMyProducts();
  }

  // Load more products
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await fetchMyProducts(page: state.currentPage + 1, loadMore: true);
  }

  // Add product to local state
  void addProduct(Product product) {
    state = state.copyWith(products: [product, ...state.products]);
  }

  // Update product in local state
  void updateProduct(Product updatedProduct) {
    final updatedProducts = state.products.map((product) {
      return product.id == updatedProduct.id ? updatedProduct : product;
    }).toList();
    state = state.copyWith(products: updatedProducts);
  }

  // Remove product from local state
  void removeProduct(String productId) {
    final updatedProducts =
        state.products.where((product) => product.id != productId).toList();
    state = state.copyWith(products: updatedProducts);
  }

  // Delete product from backend and local state
  Future<bool> deleteProduct(String productId) async {
    try {
      final response = await _apiService.delete('/products/$productId');
      if (response.statusCode == 200) {
        removeProduct(productId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Update product active status
  Future<bool> toggleProductActive(String productId, bool isActive) async {
    try {
      final response = await _apiService
          .put('/products/$productId', data: {'isActive': isActive});
      if (response.statusCode == 200) {
        final updatedProduct = Product.fromJson(response.data['data']);
        updateProduct(updatedProduct);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Supplier Product Provider
final supplierProductProvider =
    StateNotifierProvider<SupplierProductNotifier, SupplierProductState>((ref) {
  return SupplierProductNotifier();
});
