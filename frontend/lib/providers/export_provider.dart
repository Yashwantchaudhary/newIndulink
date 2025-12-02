import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../core/constants/app_config.dart';

/// 📊 Export/Import Provider
/// Manages data export and import operations
class ExportProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _exportHistory;
  Map<String, dynamic>? _supportedFormats;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get exportHistory => _exportHistory;
  Map<String, dynamic>? get supportedFormats => _supportedFormats;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Load supported formats
  Future<void> loadSupportedFormats() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.get('/export/formats');
      if (response.isSuccess && response.data != null) {
        _supportedFormats = response.data;
      }
    } catch (error) {
      _setError('Failed to load supported formats');
    } finally {
      _setLoading(false);
    }
  }

  /// Export user data (GDPR compliant)
  Future<bool> exportUserData({
    String format = 'json',
    bool includeProfile = true,
    bool includeOrders = true,
    bool includeProducts = true,
    bool includeMessages = true,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final queryParams = {
        'format': format,
        'includeProfile': includeProfile.toString(),
        'includeOrders': includeOrders.toString(),
        'includeProducts': includeProducts.toString(),
        'includeMessages': includeMessages.toString(),
      };

      final uri = Uri.parse('${AppConfig.baseUrl}/export/user-data')
          .replace(queryParameters: queryParams);

      final token = await _storage.getAccessToken();
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': _getMimeType(format),
        },
      );

      if (response.statusCode == 200) {
        final filename = 'user_data_${DateTime.now().millisecondsSinceEpoch}.$format';
        final file = await _saveFile(response.bodyBytes, filename);

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Your exported data',
        );

        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _setError(errorData['message'] ?? 'Export failed');
        return false;
      }
    } catch (error) {
      _setError('Export failed: ${error.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Export collection data
  Future<bool> exportCollection({
    required String collection,
    String format = 'json',
    int limit = 1000,
    int skip = 0,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final queryParams = {
        'format': format,
        'limit': limit.toString(),
        'skip': skip.toString(),
      };

      final uri = Uri.parse('${AppConfig.baseUrl}/export/collection/$collection')
          .replace(queryParameters: queryParams);

      final token = await _storage.getAccessToken();
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': _getMimeType(format),
        },
      );

      if (response.statusCode == 200) {
        final filename = '${collection}_export_${DateTime.now().millisecondsSinceEpoch}.$format';
        final file = await _saveFile(response.bodyBytes, filename);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Exported $collection data',
        );

        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _setError(errorData['message'] ?? 'Export failed');
        return false;
      }
    } catch (error) {
      _setError('Export failed: ${error.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Import data to collection (Admin only)
  Future<Map<String, dynamic>?> importCollection({
    required String collection,
    required File file,
    String format = 'json',
    bool validateData = true,
    bool skipDuplicates = true,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final uri = Uri.parse('${AppConfig.baseUrl}/export/collection/$collection')
          .replace(queryParameters: {
            'format': format,
            'validate': validateData.toString(),
            'skipDuplicates': skipDuplicates.toString(),
          });

      final token = await _storage.getAccessToken();

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'];
      } else {
        final errorData = jsonDecode(response.body);
        _setError(errorData['message'] ?? 'Import failed');
        return null;
      }
    } catch (error) {
      _setError('Import failed: ${error.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Import data from JSON string (Admin only)
  Future<Map<String, dynamic>?> importFromJson({
    required String collection,
    required String jsonData,
    bool validateData = true,
    bool skipDuplicates = true,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final token = await _storage.getAccessToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/export/collection/$collection')
            .replace(queryParameters: {
              'validate': validateData.toString(),
              'skipDuplicates': skipDuplicates.toString(),
            }),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'data': jsonDecode(jsonData)}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'];
      } else {
        final errorData = jsonDecode(response.body);
        _setError(errorData['message'] ?? 'Import failed');
        return null;
      }
    } catch (error) {
      _setError('Import failed: ${error.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Load export history (Admin only)
  Future<void> loadExportHistory() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.get('/export/history');
      if (response.isSuccess && response.data != null) {
        _exportHistory = response.data;
      }
    } catch (error) {
      _setError('Failed to load export history');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete export file (Admin only)
  Future<bool> deleteExportFile(String filename) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.delete('/export/file/$filename');
      if (response.isSuccess) {
        await loadExportHistory(); // Refresh history
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete file');
        return false;
      }
    } catch (error) {
      _setError('Failed to delete file');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Helper method to save file to device
  Future<File> _saveFile(List<int> bytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Helper method to get MIME type for format
  String _getMimeType(String format) {
    switch (format.toLowerCase()) {
      case 'json':
        return 'application/json';
      case 'csv':
        return 'text/csv';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Clear error message
  void clearError() {
    _setError(null);
  }
}