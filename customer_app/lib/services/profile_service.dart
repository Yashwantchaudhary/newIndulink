import '../models/user.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _apiService = ApiService();

  // Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await _apiService.get('/users/me');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return User.fromJson(response.data['data']);
      }
      throw Exception('Failed to get profile');
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? businessName,
  }) async {
    try {
      final response = await _apiService.put(
        '/users/me',
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (phone != null) 'phone': phone,
          if (businessName != null) 'businessName': businessName,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return User.fromJson(response.data['data']);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      rethrow;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(String filePath) async {
    try {
      final response = await _apiService.uploadFile(
        '/users/me/avatar',
        filePath,
        fieldName: 'avatar',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['profileImage'];
      }
      throw Exception('Failed to upload profile image');
    } catch (e) {
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await _apiService.delete('/users/me');
    } catch (e) {
      rethrow;
    }
  }
}
