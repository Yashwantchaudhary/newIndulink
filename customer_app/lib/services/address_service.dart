import '../models/address.dart';
import 'api_service.dart';
import 'dart:developer' as developer;

class AddressService {
  final ApiService _apiService = ApiService();

  // Get all addresses for current user (from user profile)
  Future<List<Address>> getAddresses() async {
    try {
      developer.log('Fetching user addresses', name: 'AddressService');
      // Backend returns addresses as part of user profile
      final response = await _apiService.get('/users/profile');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data'];
        final addressesData = userData['addresses'] as List? ?? [];
        return addressesData.map((json) => Address.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error fetching addresses: $e',
          name: 'AddressService', error: e);
      rethrow;
    }
  }

  // Add new address
  Future<List<Address>> addAddress(Address address) async {
    try {
      developer.log('Adding new address', name: 'AddressService');
      final response = await _apiService.post(
        '/users/addresses',
        data: address.toJson(),
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        // Backend returns updated addresses array
        final addressesData = response.data['data'] as List;
        return addressesData.map((json) => Address.fromJson(json)).toList();
      }
      throw Exception('Failed to add address');
    } catch (e) {
      developer.log('Error adding address: $e',
          name: 'AddressService', error: e);
      rethrow;
    }
  }

  // Update address
  Future<List<Address>> updateAddress(String addressId, Address address) async {
    try {
      developer.log('Updating address: $addressId', name: 'AddressService');
      final response = await _apiService.put(
        '/users/addresses/$addressId',
        data: address.toJson(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Backend returns updated addresses array
        final addressesData = response.data['data'] as List;
        return addressesData.map((json) => Address.fromJson(json)).toList();
      }
      throw Exception('Failed to update address');
    } catch (e) {
      developer.log('Error updating address: $e',
          name: 'AddressService', error: e);
      rethrow;
    }
  }

  // Delete address
  Future<List<Address>> deleteAddress(String addressId) async {
    try {
      developer.log('Deleting address: $addressId', name: 'AddressService');
      final response = await _apiService.delete('/users/addresses/$addressId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Backend returns updated addresses array
        final addressesData = response.data['data'] as List;
        return addressesData.map((json) => Address.fromJson(json)).toList();
      }
      throw Exception('Failed to delete address');
    } catch (e) {
      developer.log('Error deleting address: $e',
          name: 'AddressService', error: e);
      rethrow;
    }
  }

  // Set default address
  Future<List<Address>> setDefaultAddress(String addressId) async {
    try {
      developer.log('Setting default address: $addressId',
          name: 'AddressService');
      // Update address with isDefault = true
      final response = await _apiService.put(
        '/users/addresses/$addressId',
        data: {'isDefault': true},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final addressesData = response.data['data'] as List;
        return addressesData.map((json) => Address.fromJson(json)).toList();
      }
      throw Exception('Failed to set default address');
    } catch (e) {
      developer.log('Error setting default address: $e',
          name: 'AddressService', error: e);
      rethrow;
    }
  }
}
