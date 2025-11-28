import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';

// Search State
class SearchState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final String? lastQuery;
  final bool hasMore;
  final int currentPage;

  SearchState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.lastQuery,
    this.hasMore = true,
    this.currentPage = 1,
  });

  SearchState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    String? lastQuery,
    bool? hasMore,
    int? currentPage,
  }) {
    return SearchState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastQuery: lastQuery ?? this.lastQuery,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isEmpty => products.isEmpty;
  bool get hasProducts => products.isNotEmpty;
}

// Search Notifier with debouncing and caching
class SearchNotifier extends StateNotifier<SearchState> {
  final ApiService _apiService = ApiService();
  Timer? _debounceTimer;
  final Map<String, List<Product>> _cache = {}; // Simple in-memory cache

  SearchNotifier() : super(SearchState());

  // Debounced search function
  void searchProducts(String query, {bool loadMore = false}) {
    if (query.trim().isEmpty) {
      state = SearchState(); // Clear results for empty query
      return;
    }

    // Validate search query
    final validationError = _validateSearchQuery(query);
    if (validationError != null) {
      state = state.copyWith(
        isLoading: false,
        error: validationError,
      );
      return;
    }

    // Cancel previous timer
    _debounceTimer?.cancel();

    // If loading more, don't debounce
    if (loadMore) {
      _performSearch(query, loadMore: true);
      return;
    }

    // Set loading state immediately for new searches
    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    // Debounce the search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query, loadMore: loadMore);
    });
  }

  Future<void> _performSearch(String query, {bool loadMore = false}) async {
    if (state.isLoading && !loadMore) return;

    // Check cache first for new searches
    if (!loadMore && _cache.containsKey(query)) {
      state = SearchState(
        products: _cache[query]!,
        isLoading: false,
        lastQuery: query,
        hasMore: false, // Cached results don't support pagination
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        'q': query,
        'page': loadMore ? (state.currentPage + 1).toString() : '1',
        'limit': '20',
      };

      final response = await _apiService.get('/products/search',
          queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<Product> newProducts = (response.data['products'] as List)
            .map((json) => Product.fromJson(json))
            .toList();

        final allProducts =
            loadMore ? [...state.products, ...newProducts] : newProducts;

        // Cache the results for new searches
        if (!loadMore) {
          _cache[query] = allProducts;
        }

        state = state.copyWith(
          products: allProducts,
          isLoading: false,
          lastQuery: query,
          currentPage: loadMore ? state.currentPage + 1 : 1,
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

  // Load more results
  void loadMore() {
    if (state.lastQuery != null && !state.isLoading && state.hasMore) {
      searchProducts(state.lastQuery!, loadMore: true);
    }
  }

  // Clear search results
  void clearSearch() {
    _debounceTimer?.cancel();
    state = SearchState();
  }

  // Clear cache (useful for memory management)
  void clearCache() {
    _cache.clear();
  }

  // Validate search query
  String? _validateSearchQuery(String query) {
    if (query.trim().isEmpty) {
      return 'Please enter a search term';
    }

    if (query.trim().length < 2) {
      return 'Search term must be at least 2 characters';
    }

    if (query.trim().length > 100) {
      return 'Search term must be less than 100 characters';
    }

    // Check for potentially harmful characters
    final harmfulRegex = RegExp(r'[<>]');
    if (harmfulRegex.hasMatch(query)) {
      return 'Search term contains invalid characters';
    }

    return null;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Search Provider
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});
