import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../services/address_service.dart';

// Address State
class AddressState {
  final List<Address> addresses;
  final bool isLoading;
  final String? error;

  AddressState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
  });

  AddressState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    String? error,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  Address? get defaultAddress {
    try {
      return addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }
}

// Address Notifier
class AddressNotifier extends StateNotifier<AddressState> {
  final AddressService _addressService = AddressService();

  AddressNotifier() : super(AddressState());

  // Load all addresses
  Future<void> loadAddresses() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final addresses = await _addressService.getAddresses();
      state = state.copyWith(
        addresses: addresses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Add new address
  Future<bool> addAddress(Address address) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Service now returns updated addresses array
      final updatedAddresses = await _addressService.addAddress(address);
      state = state.copyWith(
        addresses: updatedAddresses,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Update address
  Future<bool> updateAddress(String addressId, Address address) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Service now returns updated addresses array
      final updatedAddresses =
          await _addressService.updateAddress(addressId, address);

      state = state.copyWith(
        addresses: updatedAddresses,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Delete address
  Future<bool> deleteAddress(String addressId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Service now returns updated addresses array
      final updatedAddresses = await _addressService.deleteAddress(addressId);

      state = state.copyWith(
        addresses: updatedAddresses,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Set default address
  Future<bool> setDefaultAddress(String addressId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Service now returns updated addresses array
      final updatedAddresses =
          await _addressService.setDefaultAddress(addressId);

      state = state.copyWith(
        addresses: updatedAddresses,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

// Provider
final addressProvider =
    StateNotifierProvider<AddressNotifier, AddressState>((ref) {
  return AddressNotifier();
});
