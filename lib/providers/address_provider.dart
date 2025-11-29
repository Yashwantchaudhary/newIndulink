import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// 📍 Address Provider
/// Manages user addresses for delivery and billing
class AddressProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  List<Address> _addresses = [];
  String? _defaultAddressId;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Address> get addresses => _addresses;
  Address? get defaultAddress =>
      _addresses.where((a) => a.id == _defaultAddressId).firstOrNull;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasAddresses => _addresses.isNotEmpty;

  /// Initialize address provider
  Future<void> init() async {
    await fetchAddresses();
  }

  /// Fetch all addresses
  Future<void> fetchAddresses() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/addresses');

      if (response.success) {
        final List<dynamic> items = response.data['addresses'] ?? [];
        _addresses = items.map((item) => Address.fromJson(item)).toList();
        _defaultAddressId = response.data['defaultAddressId'];
      } else {
        _setError(response.message ?? 'Failed to load addresses');
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Fetch addresses error: $e');
    }

    _setLoading(false);
  }

  /// Add new address
  Future<bool> addAddress(Address address) async {
    _clearError();

    try {
      final response = await _apiService.post(
        '/addresses',
        body: address.toJson(),
      );

      if (response.success) {
        await fetchAddresses(); // Refresh list
        return true;
      } else {
        _setError(response.message ?? 'Failed to add address');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Add address error: $e');
      return false;
    }
  }

  /// Update existing address
  Future<bool> updateAddress(Address address) async {
    _clearError();

    try {
      final response = await _apiService.put(
        '/addresses/${address.id}',
        body: address.toJson(),
      );

      if (response.success) {
        await fetchAddresses(); // Refresh list
        return true;
      } else {
        _setError(response.message ?? 'Failed to update address');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Update address error: $e');
      return false;
    }
  }

  /// Delete address
  Future<bool> deleteAddress(String addressId) async {
    _clearError();

    try {
      final response = await _apiService.delete('/addresses/$addressId');

      if (response.success) {
        _addresses.removeWhere((a) => a.id == addressId);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete address');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Delete address error: $e');
      return false;
    }
  }

  /// Set default address
  Future<bool> setDefaultAddress(String addressId) async {
    _clearError();

    try {
      final response = await _apiService.put(
        '/addresses/$addressId/set-default',
      );

      if (response.success) {
        _defaultAddressId = addressId;
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to set default address');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Set default address error: $e');
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

/// Address model
class Address {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;

  Address({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'Nepal',
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      country: json['country'] ?? 'Nepal',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'isDefault': isDefault,
    };
  }

  String get formattedAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null) addressLine2,
      city,
      state,
      zipCode,
    ];
    return parts.join(', ');
  }
}
