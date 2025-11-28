import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';

class FileUploadService {
  final ApiClient _apiClient = ApiClient();

  /// Upload files for RFQ attachments
  /// Returns list of attachment objects with URLs
  Future<List<Map<String, dynamic>>> uploadRFQAttachments(
    List<File> files,
  ) async {
    try {
      final token = await _apiClient.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${ApiClient.baseUrl}/rfq/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add files to request
      for (var file in files) {
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        final filename = file.path.split('/').last;

        final multipartFile = http.MultipartFile(
          'attachments',
          stream,
          length,
          filename: filename,
        );

        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Error uploading files: ${e.toString()}');
    }
  }

  /// Upload files for message attachments
  Future<List<Map<String, dynamic>>> uploadMessageAttachments(
    List<File> files,
  ) async {
    try {
      final token = await _apiClient.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${ApiClient.baseUrl}/messages/upload');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      for (var file in files) {
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        final filename = file.path.split('/').last;

        final multipartFile = http.MultipartFile(
          'attachments',
          stream,
          length,
          filename: filename,
        );

        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Error uploading files: ${e.toString()}');
    }
  }

  /// Upload single product image
  Future<String> uploadProductImage(File file) async {
    try {
      final token = await _apiClient.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${ApiClient.baseUrl}/products/upload');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final filename = file.path.split('/').last;

      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: filename,
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['url'] ?? '';
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Error uploading image: ${e.toString()}');
    }
  }

  /// Get file size in human-readable format
  String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if file size is within limit (10MB)
  bool isFileSizeValid(int bytes) {
    const maxSize = 10 * 1024 * 1024; // 10MB
    return bytes <= maxSize;
  }

  /// Get file extension
  String getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  /// Check if file is an image
  bool isImage(String path) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return imageExtensions.contains(getFileExtension(path));
  }

  /// Check if file is a document
  bool isDocument(String path) {
    const docExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'];
    return docExtensions.contains(getFileExtension(path));
  }
}
