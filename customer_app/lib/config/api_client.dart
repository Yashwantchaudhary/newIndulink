import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class ApiClient {
  final ApiService _apiService;

  ApiClient(this._apiService);

  /// GET request
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response =
        await _apiService.get(path, queryParameters: queryParameters);
    return response.data as Map<String, dynamic>;
  }

  /// Download file
  Future<File> downloadFile(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    // Create a temporary file path
    final tempDir = Directory.systemTemp;
    final fileName = 'export_${DateTime.now().millisecondsSinceEpoch}.tmp';
    final savePath = '${tempDir.path}/$fileName';

    await _apiService.downloadFile(path, savePath,
        queryParameters: queryParameters);
    return File(savePath);
  }
}

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final apiService = ApiService();
  return ApiClient(apiService);
});
