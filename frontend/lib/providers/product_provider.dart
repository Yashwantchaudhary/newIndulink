import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as models;
import '../services/product_service.dart';

/// 📦 Product Provider
/// Manages product catalog state
class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  // State
  List<Product> _products = [];
  List<Product> _searchResults = [];
  List<Product> _featuredProducts = [];
  List<models.Category> _categories = [];
  Product? _selectedProduct;

  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool _isCategoriesLoading = false;

  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Filters
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  String? _sortBy;
  String? _searchQuery;

  // Getters
  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  List<Product> get featuredProducts => _featuredProducts;
  List<models.Category> get categories => _categories;
  Product? get selectedProduct => _selectedProduct;

  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;

  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  String? get selectedCategory => _selectedCategory;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get sortBy => _sortBy;

  /// Fetch products with filters
  Future<void> fetchProducts({bool loadMore = false}) async {
    if (_isLoading) return;

    if (!loadMore) {
      _currentPage = 1;
      _products = [];
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _productService.getProducts(
        page: _currentPage,
        limit: 20,
        category: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
      );

      if (result.success) {
        if (loadMore) {
          _products.addAll(result.products);
        } else {
          _products = result.products;
        }

        _totalPages = result.totalPages ?? 1;
        _hasMore = _currentPage < _totalPages;

        if (loadMore) {
          _currentPage++;
        }
      } else {
        _setError(result.message ?? 'Failed to load products');
      }
    } catch (e) {
      _setError('An error occurred');
    }

    _setLoading(false);
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_hasMore && !_isLoading) {
      _currentPage++;
      await fetchProducts(loadMore: true);
    }
  }

  /// Fetch featured products
  Future<void> fetchFeaturedProducts() async {
    _isFeaturedLoading = true;
    notifyListeners();

    try {
      final result = await _productService.getFeaturedProducts(limit: 10);

      if (result.success) {
        _featuredProducts = result.products;
      }
    } catch (e) {
      // Silently fail for featured products
    }

    _isFeaturedLoading = false;
    notifyListeners();
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    _searchResults = [];
    _setLoading(true);
    _clearError();

    try {
      final result = await _productService.searchProducts(
        query: query,
        page: 1, // Search usually doesn't need complex pagination for now
        category: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

      if (result.success) {
        _searchResults = result.products;
      } else {
        _setError(result.message ?? 'Search failed');
      }
    } catch (e) {
      _setError('An error occurred');
    }

    _setLoading(false);
  }

  /// Clear search results
  void clearSearch() {
    _searchQuery = null;
    _searchResults = [];
    notifyListeners();
  }

  /// Get product details
  Future<void> getProductDetails(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _productService.getProductDetails(productId);

      if (result.success && result.product != null) {
        _selectedProduct = result.product;
      } else {
        _setError(result.message ?? 'Product not found');
      }
    } catch (e) {
      _setError('An error occurred');
    }

    _setLoading(false);
  }

  /// Fetch categories
  Future<void> fetchCategories() async {
    _isCategoriesLoading = true;
    notifyListeners();

    try {
      final result = await _productService.getCategories();

      if (result.success) {
        _categories = result.categories;
      }
    } catch (e) {
      // Silently fail
    }

    _isCategoriesLoading = false;
    notifyListeners();
  }

  /// Set category filter
  void setCategory(String? category) {
    _selectedCategory = category;
    fetchProducts();
  }

  /// Set price range filter
  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    fetchProducts();
  }

  /// Set sort option
  void setSortBy(String? sort) {
    _sortBy = sort;
    fetchProducts();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _minPrice = null;
    _maxPrice = null;
    _sortBy = null;
    _searchQuery = null;
    fetchProducts();
  }

  /// Refresh products
  Future<void> refresh() async {
    _currentPage = 1;
    await fetchProducts();
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
