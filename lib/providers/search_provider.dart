import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// 🔍 Search Provider
/// Manages product search state, filters, and search history
class SearchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // State
  List<Product> _searchResults = [];
  List<String> _recentSearches = [];
  String _query = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String? _selectedCategoryId;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String? _sortBy; // 'price_asc', 'price_desc', 'rating', 'newest'

  // Debounce timer for search
  Timer? _debounceTimer;

  // Getters
  List<Product> get searchResults => _searchResults;
  List<String> get recentSearches => _recentSearches;
  String get query => _query;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasResults => _searchResults.isNotEmpty;
  bool get hasQuery => _query.isNotEmpty;

  // Filter getters
  String? get selectedCategoryId => _selectedCategoryId;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  double? get minRating => _minRating;
  String? get sortBy => _sortBy;
  bool get hasActiveFilters =>
      _selectedCategoryId != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _minRating != null;

  /// Initialize search provider (load recent searches)
  Future<void> init() async {
    await _loadRecentSearches();
  }

  /// Search for products with debouncing
  void search(String query, {bool immediate = false}) {
    _query = query.trim();

    if (_query.isEmpty) {
      _searchResults.clear();
      _clearError();
      notifyListeners();
      return;
    }

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (immediate) {
      _performSearch();
    } else {
      // Debounce search by 500ms
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _performSearch();
      });
    }
  }

  /// Perform the actual search
  Future<void> _performSearch() async {
    if (_query.isEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      // Build query parameters
      final params = <String, String>{
        'q': _query,
        if (_selectedCategoryId != null) 'category': _selectedCategoryId!,
        if (_minPrice != null) 'minPrice': _minPrice.toString(),
        if (_maxPrice != null) 'maxPrice': _maxPrice.toString(),
        if (_minRating != null) 'minRating': _minRating.toString(),
        if (_sortBy != null) 'sort': _sortBy!,
      };

      final response = await _apiService.get(
        '/products/search',
        params: params,
      );

      if (response.success) {
        final List<dynamic> products = response.data['products'] ?? [];
        _searchResults = products.map((p) => Product.fromJson(p)).toList();

        // Save to recent searches
        await _saveRecentSearch(_query);
      } else {
        _setError(response.message ?? 'Search failed');
      }
    } catch (e) {
      _setError('An error occurred during search');
      debugPrint('Search error: $e');
    }

    _setLoading(false);
  }

  /// Apply filters and re-search
  Future<void> applyFilters({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
  }) async {
    _selectedCategoryId = categoryId;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minRating = minRating;
    _sortBy = sortBy;

    notifyListeners();

    if (_query.isNotEmpty) {
      await _performSearch();
    }
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategoryId = null;
    _minPrice = null;
    _maxPrice = null;
    _minRating = null;
    _sortBy = null;

    notifyListeners();

    if (_query.isNotEmpty) {
      _performSearch();
    }
  }

  /// Clear search and results
  void clearSearch() {
    _query = '';
    _searchResults.clear();
    _clearError();
    _debounceTimer?.cancel();
    notifyListeners();
  }

  /// Load recent searches from storage
  Future<void> _loadRecentSearches() async {
    try {
      final searches = await _storageService.getRecentSearches();
      _recentSearches = searches;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recent searches: $e');
    }
  }

  /// Save search query to recent searches
  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty) return;

    try {
      // Remove if already exists
      _recentSearches.remove(query);

      // Add to beginning
      _recentSearches.insert(0, query);

      // Keep only last 10 searches
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }

      await _storageService.saveRecentSearches(_recentSearches);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save recent search: $e');
    }
  }

  /// Remove item from recent searches
  Future<void> removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    await _storageService.saveRecentSearches(_recentSearches);
    notifyListeners();
  }

  /// Clear all recent searches
  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    await _storageService.clearRecentSearches();
    notifyListeners();
  }

  /// Search from recent search item
  void searchFromRecent(String query) {
    search(query, immediate: true);
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
