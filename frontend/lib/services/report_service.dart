import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _apiService = ApiService();

  /// Submit a report (product, user, review, etc.)
  Future<bool> submitReport({
    required String targetId,
    required String targetType, // 'product', 'user', 'review', 'order'
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        '/reports', // Ensure this endpoint exists in backend or AppConfig
        body: {
          'targetId': targetId,
          'targetType': targetType,
          'reason': reason,
          'description': description,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.isSuccess;
    } catch (e) {
      debugPrint('Error submitting report: $e');
      return false;
    }
  }
}
