import 'package:flutter/foundation.dart';
import '../models/rfq.dart';
import '../services/api_service.dart';

/// 📋 RFQ Provider
/// Manages Request for Quote functionality for customers and suppliers
class RFQProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  List<RFQ> _rfqs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<RFQ> get rfqs => _rfqs;
  List<RFQ> get pendingRFQs => _rfqs.where((r) => r.status == 'pending').toList();
  List<RFQ> get quotedRFQs => _rfqs.where((r) => r.status == 'quoted').toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize RFQ provider
  Future<void> init() async {
    await fetchRFQs();
  }

  /// Fetch all RFQs
  Future<void> fetchRFQs() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/rfq');

      if (response.success) {
        final List<dynamic> items = response.data['data'] ?? [];
        _rfqs = items.map((item) => RFQ.fromJson(item)).toList();
      } else {
        _setError(response.message ?? 'Failed to load RFQs');
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Fetch RFQs error: $e');
    }

    _setLoading(false);
  }

  /// Create new RFQ
  Future<bool> createRFQ({
    required List<RFQItem> items,
    required DeliveryAddress deliveryAddress,
    String? notes,
    required DateTime expiresAt,
  }) async {
    _clearError();

    try {
      final response = await _apiService.post(
        '/rfq',
        body: {
          'items': items.map((item) => item.toJson()).toList(),
          'deliveryAddress': deliveryAddress.toJson(),
          if (notes != null) 'notes': notes,
          'expiresAt': expiresAt.toIso8601String(),
        },
      );

      if (response.success) {
        await fetchRFQs(); // Refresh list
        return true;
      } else {
        _setError(response.message ?? 'Failed to create RFQ');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Create RFQ error: $e');
      return false;
    }
  }

  /// Submit quote for RFQ (supplier)
  Future<bool> submitQuote({
    required String rfqId,
    required List<QuoteItem> items,
    required double totalAmount,
    required DateTime validUntil,
    String? notes,
  }) async {
    _clearError();

    try {
      final response = await _apiService.post(
        '/rfq/$rfqId/quote',
        body: {
          'items': items.map((item) => item.toJson()).toList(),
          'totalAmount': totalAmount,
          'validUntil': validUntil.toIso8601String(),
          if (notes != null) 'notes': notes,
        },
      );

      if (response.success) {
        await fetchRFQs(); // Refresh list
        return true;
      } else {
        _setError(response.message ?? 'Failed to submit quote');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Submit quote error: $e');
      return false;
    }
  }

  /// Accept quote (customer)
  Future<bool> acceptQuote({
    required String rfqId,
    required String quoteId,
  }) async {
    _clearError();

    try {
      final response = await _apiService.put('/rfq/$rfqId/accept/$quoteId');

      if (response.success) {
        await fetchRFQs(); // Refresh list
        return true;
      } else {
        _setError(response.message ?? 'Failed to accept quote');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Accept quote error: $e');
      return false;
    }
  }

  /// Cancel RFQ
  Future<bool> cancelRFQ(String rfqId) async {
    _clearError();

    try {
      final response = await _apiService.delete('/rfq/$rfqId');

      if (response.success) {
        _rfqs.removeWhere((r) => r.id == rfqId);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to cancel RFQ');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Cancel RFQ error: $e');
      return false;
    }
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
