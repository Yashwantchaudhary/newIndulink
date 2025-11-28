import '../models/rfq.dart';
import 'api_service.dart';

class RFQService {
  final ApiService _apiClient = ApiService();

  // Create a new RFQ
  Future<RFQ> createRFQ({
    required List<String> products,
    required double idealPrice,
    required int quantity,
    required DateTime deliveryDate,
    required String description,
    List<String>? attachments,
  }) async {
    try {
      final response = await _apiClient.post('/rfq', data: {
        'products': products,
        'idealPrice': idealPrice,
        'quantity': quantity,
        'deliveryDate': deliveryDate.toIso8601String(),
        'description': description,
        if (attachments != null) 'attachments': attachments,
      });

      return RFQ.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create RFQ: $e');
    }
  }

  // Get all RFQs (filtered by status and paginated)
  Future<Map<String, dynamic>> getRFQs({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final response =
          await _apiClient.get('/rfq', queryParameters: queryParams);

      final rfqs = (response.data['data'] as List)
          .map((json) => RFQ.fromJson(json))
          .toList();

      return {
        'rfqs': rfqs,
        'pagination': response.data['pagination'],
      };
    } catch (e) {
      throw Exception('Failed to fetch RFQs: $e');
    }
  }

  // Get single RFQ by ID
  Future<RFQ> getRFQById(String id) async {
    try {
      final response = await _apiClient.get('/rfq/$id');
      return RFQ.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch RFQ: $e');
    }
  }

  // Submit quote for an RFQ (Supplier only)
  Future<RFQ> submitQuote({
    required String rfqId,
    required double price,
    required int deliveryTime,
    required String description,
    required DateTime validUntil,
  }) async {
    try {
      final response = await _apiClient.post(
        '/rfq/$rfqId/quote',
        data: {
          'price': price,
          'deliveryTime': deliveryTime,
          'description': description,
          'validUntil': validUntil.toIso8601String(),
        },
      );

      return RFQ.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to submit quote: $e');
    }
  }

  // Accept a quote (Buyer only)
  Future<RFQ> acceptQuote({
    required String rfqId,
    required String quoteId,
  }) async {
    try {
      final response = await _apiClient.put(
        '/rfq/$rfqId/accept/$quoteId',
        data: {},
      );

      return RFQ.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to accept quote: $e');
    }
  }

  // Update RFQ status (Buyer only)
  Future<RFQ> updateRFQStatus({
    required String rfqId,
    required String status,
  }) async {
    try {
      final response = await _apiClient.put(
        '/rfq/$rfqId/status',
        data: {'status': status},
      );

      return RFQ.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update RFQ status: $e');
    }
  }

  // Delete RFQ (Buyer only)
  Future<void> deleteRFQ(String rfqId) async {
    try {
      await _apiClient.delete('/rfq/$rfqId');
    } catch (e) {
      throw Exception('Failed to delete RFQ: $e');
    }
  }
}
