import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/order.dart';
import '../checkout/checkout_payment_screen.dart';

/// Checkout address screen
class CheckoutAddressScreen extends ConsumerStatefulWidget {
  const CheckoutAddressScreen({super.key});

  @override
  ConsumerState<CheckoutAddressScreen> createState() =>
      _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends ConsumerState<CheckoutAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.paddingPage,
          children: [
            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }

                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters long';
                }

                if (value.trim().length > 50) {
                  return 'Name must be less than 50 characters';
                }

                // Check for valid characters (letters, spaces, hyphens, apostrophes)
                final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
                if (!nameRegex.hasMatch(value.trim())) {
                  return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                }

                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppConstants.spacing16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }

                // Remove all non-digit characters for validation
                final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');

                if (cleanPhone.length < 10) {
                  return 'Phone number must be at least 10 digits';
                }

                if (cleanPhone.length > 15) {
                  return 'Phone number must be less than 15 digits';
                }

                // Check if it starts with valid country codes (optional, can be customized)
                if (cleanPhone.length >= 10 &&
                    !RegExp(r'^[1-9]').hasMatch(cleanPhone)) {
                  return 'Please enter a valid phone number';
                }

                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppConstants.spacing16),

            // Address Line 1
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1',
                hintText: 'House number, street name',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Address is required';
                }

                if (value.trim().length < 5) {
                  return 'Address must be at least 5 characters long';
                }

                if (value.trim().length > 100) {
                  return 'Address must be less than 100 characters';
                }

                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppConstants.spacing16),

            // Address Line 2
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2 (Optional)',
                hintText: 'Apartment, suite, unit, etc.',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppConstants.spacing16),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Enter city',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'City is required';
                }

                if (value.trim().length < 2) {
                  return 'City name must be at least 2 characters long';
                }

                if (value.trim().length > 50) {
                  return 'City name must be less than 50 characters';
                }

                // Check for valid characters (letters, spaces, hyphens, apostrophes)
                final cityRegex = RegExp(r"^[a-zA-Z\s\-']+$");
                if (!cityRegex.hasMatch(value.trim())) {
                  return 'City name can only contain letters, spaces, hyphens, and apostrophes';
                }

                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppConstants.spacing16),

            // State/Province
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State/Province',
                hintText: 'Enter state or province',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your state/province';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppConstants.spacing16),

            // Postal Code
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Postal Code',
                hintText: 'Enter postal code',
                prefixIcon: Icon(Icons.markunread_mailbox_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Postal code is required';
                }

                final cleanPostal = value.replaceAll(RegExp(r'[^\d]'), '');

                if (cleanPostal.length < 5) {
                  return 'Postal code must be at least 5 digits';
                }

                if (cleanPostal.length > 10) {
                  return 'Postal code must be less than 10 digits';
                }

                return null;
              },
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppConstants.spacing32),

            // Continue Button
            ElevatedButton(
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Continue to Payment',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacing16),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      final address = ShippingAddress(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isNotEmpty
            ? _addressLine2Controller.text.trim()
            : null,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPaymentScreen(
            shippingAddress: address,
          ),
        ),
      );
    }
  }
}
