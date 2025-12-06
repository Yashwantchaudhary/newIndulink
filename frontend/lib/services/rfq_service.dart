import '../models/rfq.dart';
import 'api_service.dart';

/// 📋 RFQ Service
/// Handles Request for Quotation operations
class RFQService {
  static final RFQService _instance = RFQService._internal();
  factory RFQService() => _instance;
  RFQService._internal();

  final ApiService _api = ApiService();

  // ==================== RFQ Operations ====================

  /// Create a new RFQ
  Future<RFQResult> createRFQ({
    required String title,
    required String description,
    required List<RFQItem> items,
    required DateTime deadline,
    String? category,
    List<String>? attachments,
  }) async {
    try {
      final response = await _api.post(
        '/rfq',
        body: {
          'title': title,
          'description': description,
          'items': items.map((item) => item.toJson()).toList(),
          'deadline': deadline.toIso8601String(),
          if (category != null) 'category': category,
          if (attachments != null) 'attachments': attachments,
        },
      );

      if (response.isSuccess && response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;
        final actualData = dataMap.containsKey('data')
            ? Map<String, dynamic>.from(dataMap['data'] as Map)
            : dataMap;

        final rfq = RFQ.fromJson(actualData);
        return RFQResult(
          success: true,
          rfq: rfq,
          message: 'RFQ created successfully',
        );
      } else {
        return RFQResult(
          success: false,
          message: response.message ?? 'Failed to create RFQ',
        );
      }
    } catch (e) {
      return RFQResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Get all RFQs for current user
  Future<RFQListResult> getRFQs() async {
    try {
      final response = await _api.get('/rfq');

      if (response.isSuccess && response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;
        List<dynamic> rfqsJson = [];

        if (dataMap.containsKey('data') && dataMap['data'] is List) {
          rfqsJson = dataMap['data'] as List;
        } else if (dataMap.containsKey('data') && dataMap['data'] is Map) {
          // Handle case where data is wrapped in another object like { data: { rfqs: [] } }
          final innerData = dataMap['data'] as Map;
          rfqsJson = innerData['rfqs'] ?? innerData['data'] ?? [];
        } else {
          rfqsJson = dataMap['rfqs'] ?? [];
        }

        final rfqs = (rfqsJson)
            .map((json) => RFQ.fromJson(json as Map<String, dynamic>))
            .toList();

        return RFQListResult(
          success: true,
          rfqs: rfqs,
        );
      } else {
        return RFQListResult(
          success: false,
          message: response.message ?? 'Failed to fetch RFQs',
        );
      }
    } catch (e) {
      return RFQListResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Get RFQ by ID
  Future<RFQResult> getRFQById(String id) async {
    try {
      final response = await _api.get('/rfq/$id');

      if (response.isSuccess && response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;
        final actualData = dataMap.containsKey('data')
            ? Map<String, dynamic>.from(dataMap['data'] as Map)
            : dataMap;

        final rfq = RFQ.fromJson(actualData);
        return RFQResult(
          success: true,
          rfq: rfq,
        );
      } else {
        return RFQResult(
          success: false,
          message: response.message ?? 'Failed to fetch RFQ',
        );
      }
    } catch (e) {
      return RFQResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Submit a quote for an RFQ
  Future<RFQResult> submitQuote({
    required String rfqId,
    required double totalPrice,
    required String notes,
    String? validUntil,
  }) async {
    try {
      final response = await _api.post(
        '/rfq/$rfqId/quote',
        body: {
          'totalPrice': totalPrice,
          'notes': notes,
          if (validUntil != null) 'validUntil': validUntil,
        },
      );

      if (response.isSuccess && response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;
        final actualData = dataMap.containsKey('data')
            ? Map<String, dynamic>.from(dataMap['data'] as Map)
            : dataMap;

        final rfq = RFQ.fromJson(actualData);
        return RFQResult(
          success: true,
          rfq: rfq,
          message: 'Quote submitted successfully',
        );
      } else {
        return RFQResult(
          success: false,
          message: response.message ?? 'Failed to submit quote',
        );
      }
    } catch (e) {
      return RFQResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Delete RFQ
  Future<bool> deleteRFQ(String id) async {
    try {
      final response = await _api.delete('/rfq/$id');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }
}

/// 📋 RFQ Result Model
class RFQResult {
  final bool success;
  final String? message;
  final RFQ? rfq;

  RFQResult({
    required this.success,
    this.message,
    this.rfq,
  });
}

/// 📋 RFQ List Result Model
class RFQListResult {
  final bool success;
  final String? message;
  final List<RFQ> rfqs;

  RFQListResult({
    required this.success,
    this.message,
    this.rfqs = const [],
  });
}
