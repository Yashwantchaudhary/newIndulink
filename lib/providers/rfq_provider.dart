import 'package:flutter/foundation.dart';
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
        final List<dynamic> items = response.data['rfqs'] ?? [];
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
    required String productName,
    required String description,
    required int quantity,
    String? targetPrice,
    DateTime? requiredBy,
  }) async {
    _clearError();

    try {
      final response = await _apiService.post(
        '/rfq',
        body: {
          'productName': productName,
          'description': description,
          'quantity': quantity,
          if (targetPrice != null) 'targetPrice': targetPrice,
          if (requiredBy != null) 'requiredBy': requiredBy.toIso8601String(),
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
    required double price,
    required int deliveryDays,
    String? notes,
  }) async {
    _clearError();

    try {
      final response = await _apiService.post(
        '/rfq/$rfqId/quote',
        body: {
          'price': price,
          'deliveryDays': deliveryDays,
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
  Future<bool> acceptQuote(String rfqId) async {
    _clearError();

    try {
      final response = await _apiService.put('/rfq/$rfqId/accept');

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

/// RFQ model
class RFQ {
  final String id;
  final String productName;
  final String description;
  final int quantity;
  final String? targetPrice;
  final DateTime? requiredBy;
  final String status; // pending, quoted, accepted, rejected
  final Quote? quote;
  final DateTime createdAt;

  RFQ({
    required this.id,
    required this.productName,
    required this.description,
    required this.quantity,
    this.targetPrice,
    this.requiredBy,
    this.status = 'pending',
    this.quote,
    required this.createdAt,
  });

  factory RFQ.fromJson(Map<String, dynamic> json) {
    return RFQ(
      id: json['_id'] ?? json['id'] ?? '',
      productName: json['productName'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      targetPrice: json['targetPrice'],
      requiredBy: json['requiredBy'] != null
          ? DateTime.parse(json['requiredBy'])
          : null,
      status: json['status'] ?? 'pending',
      quote: json['quote'] != null ? Quote.fromJson(json['quote']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Quote model (supplier's response to RFQ)
class Quote {
  final String id;
  final String supplierId;
  final String? supplierName;
  final double price;
  final int deliveryDays;
  final String? notes;
  final DateTime createdAt;

  Quote({
    required this.id,
    required this.supplierId,
    this.supplierName,
    required this.price,
    required this.deliveryDays,
    this.notes,
    required this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['_id'] ?? json['id'] ?? '',
      supplierId: json['supplier'] is String
          ? json['supplier']
          : json['supplier']?['_id'] ?? '',
      supplierName: json['supplier'] is Map<String, dynamic>
          ? json['supplier']['name']
          : null,
      price: (json['price'] ?? 0).toDouble(),
      deliveryDays: json['deliveryDays'] ?? 0,
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
