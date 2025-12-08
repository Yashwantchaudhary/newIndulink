import 'package:flutter/foundation.dart';
import 'package:newindulink/models/category.dart' as models;
import '../services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<models.Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/categories');

      if (response.success) {
        // API returns { success: true, data: [...categories] }
        final List<dynamic> items = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data['categories'] ?? []);
        _categories =
            items.map((item) => models.Category.fromJson(item)).toList();
      } else {
        _setError(response.message ?? 'Failed to load categories');
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Fetch categories error: $e');
    }

    _setLoading(false);
  }

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
