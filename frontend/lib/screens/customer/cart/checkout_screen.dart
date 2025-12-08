import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:newindulink/core/constants/app_colors.dart';
import 'package:newindulink/core/constants/app_dimensions.dart';
import 'package:newindulink/core/widgets/loading_widgets.dart';
import 'package:newindulink/models/user.dart';
import 'package:newindulink/providers/auth_provider.dart';
import 'package:newindulink/providers/cart_provider.dart';
import 'package:newindulink/providers/order_provider.dart';
import 'package:newindulink/screens/customer/orders/orders_screen.dart';
import 'package:newindulink/routes/app_routes.dart';
import 'package:newindulink/services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  Address? _selectedAddress;
  String _selectedPaymentMethod = 'Cash on Delivery';
  final TextEditingController _notesController = TextEditingController();

  // Address state - fetched from /api/addresses
  List<Address> _addresses = [];
  bool _isLoadingAddresses = false;

  @override
  void initState() {
    super.initState();
    // Fetch addresses from API
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoadingAddresses = true);
    try {
      final apiService = ApiService();
      final response = await apiService.get('/addresses');

      if (response.isSuccess && response.data != null) {
        final addressList = response.data['data'] ?? response.data;
        if (addressList is List) {
          _addresses = addressList.map((a) => Address.fromJson(a)).toList();
          // Auto-select default or first address
          if (_addresses.isNotEmpty && _selectedAddress == null) {
            try {
              _selectedAddress = _addresses.firstWhere((a) => a.isDefault);
            } catch (e) {
              _selectedAddress = _addresses.first;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
    }
    if (mounted) setState(() => _isLoadingAddresses = false);
  }

  // Inline Address Form State
  bool _showAddressForm = false;
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController(text: 'Nepal');
  bool _isSavingAddress = false;

  @override
  void dispose() {
    _notesController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingAddress = true);

    try {
      final apiService = ApiService(); // Or use Provider
      final response = await apiService.post(
        '/addresses',
        body: {
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneController.text,
          'addressLine1': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zipCode': _zipController.text,
          'country': _countryController.text,
          'isDefault': false,
        },
      );

      if (response.isSuccess) {
        if (mounted) {
          // Refetch addresses from API
          await _fetchAddresses();

          // Select the newly added address (last in list)
          if (_addresses.isNotEmpty) {
            _selectedAddress = _addresses.last;
          }

          setState(() {
            _showAddressForm = false;
            _clearAddressForm();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address added and selected!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response.message ?? 'Failed to add address')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAddress = false);
    }
  }

  void _clearAddressForm() {
    _fullNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _zipController.clear();
    _countryController.text = 'Nepal';
  }

  void _handlePlaceOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    final orderProvider = context.read<OrderProvider>();
    final cartProvider = context.read<CartProvider>();

    // Map display string to backend enum value
    String backendPaymentMethod;
    if (_selectedPaymentMethod == 'Cash on Delivery') {
      backendPaymentMethod = 'cash_on_delivery';
    } else if (_selectedPaymentMethod == 'Credit/Debit Card') {
      backendPaymentMethod = 'online';
    } else {
      backendPaymentMethod = 'cash_on_delivery'; // Default fallback
    }

    final order = await orderProvider.createOrder(
      shippingAddress: _selectedAddress!,
      paymentMethod: backendPaymentMethod,
      notes: _notesController.text,
    );

    if (order != null) {
      // Clear cart
      await cartProvider.clearCart();

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 60),
                SizedBox(height: 16),
                Text('Order Placed!'),
              ],
            ),
            content: Text(
              'Your order #${order.orderNumber} has been placed successfully.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close checkout
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrdersScreen(),
                    ),
                  );
                },
                child: const Text('View Orders'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close checkout
                  Navigator.popUntil(
                      context, (route) => route.isFirst); // Go home
                },
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(orderProvider.errorMessage ?? 'Failed to place order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isCreatingOrder) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingSpinner(),
                  SizedBox(height: 16),
                  Text('Placing your order...'),
                ],
              ),
            );
          }

          return Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() {
                  _currentStep++;
                });
              } else {
                _handlePlaceOrder();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep--;
                });
              } else {
                Navigator.pop(context);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text(
                          _currentStep == 2 ? 'Place Order' : 'Continue',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                  ],
                ),
              );
            },
            steps: [
              // Step 1: Address
              Step(
                title: const Text('Address'),
                content: _buildAddressStep(),
                isActive: _currentStep >= 0,
                state:
                    _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),

              // Step 2: Payment
              Step(
                title: const Text('Payment'),
                content: _buildPaymentStep(),
                isActive: _currentStep >= 1,
                state:
                    _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),

              // Step 3: Review
              Step(
                title: const Text('Review'),
                content: _buildReviewStep(),
                isActive: _currentStep >= 2,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressStep() {
    if (_showAddressForm) {
      return _buildInlineAddressForm();
    }

    // Use locally fetched addresses instead of user.addresses
    if (_isLoadingAddresses) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_addresses.isEmpty)
          Column(
            children: [
              const Icon(Icons.location_off,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              const Text('No addresses found'),
              const SizedBox(height: 16),
            ],
          ),
        ..._addresses.map((address) {
          return RadioListTile<Address>(
            value: address,
            groupValue: _selectedAddress,
            onChanged: (value) {
              setState(() {
                _selectedAddress = value;
              });
            },
            title: Text(address.fullName ?? 'Address'),
            subtitle: Text(
              '${address.addressLine1}, ${address.city}${address.postalCode != null ? ", ${address.postalCode}" : ""}\n${address.phone ?? ""}',
            ),
            secondary: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.editAddress,
                  arguments: address,
                );
                if (result == true && context.mounted) {
                  await _fetchAddresses();
                }
              },
            ),
            activeColor: AppColors.primary,
          );
        }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _showAddressForm = true;
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Address'),
        ),
      ],
    );
  }

  Widget _buildInlineAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter full name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value!.isEmpty ? 'Please enter phone number' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address Line 1',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter address' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter city' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter state' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _zipController,
                  decoration: const InputDecoration(
                    labelText: 'Zip Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter zip code' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showAddressForm = false;
                      _clearAddressForm();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSavingAddress ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isSavingAddress
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Address'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      children: [
        RadioListTile<String>(
          value: 'Cash on Delivery',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
          title: const Text('Cash on Delivery'),
          subtitle: const Text('Pay when you receive your order'),
          secondary: const Icon(Icons.money),
          activeColor: AppColors.primary,
        ),
        RadioListTile<String>(
          value: 'Credit/Debit Card',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
          title: const Text('Credit/Debit Card'),
          subtitle: const Text('Pay securely with your card'),
          secondary: const Icon(Icons.credit_card),
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textTertiary),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Subtotal', cart.subtotal),
                  _buildSummaryRow('Tax', cart.tax),
                  _buildSummaryRow('Shipping', cart.shippingFee),
                  const Divider(),
                  _buildSummaryRow('Total', cart.total, isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Delivery Address Preview
            if (_selectedAddress != null) ...[
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textTertiary),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAddress!.label.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_selectedAddress!.fullAddress),
                    const SizedBox(height: 4),
                    Text(_selectedAddress!.phone),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Payment Method Preview
            const Text(
              'Payment Method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textTertiary),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(_selectedPaymentMethod),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Order Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Special instructions for delivery',
              ),
              maxLines: 3,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
