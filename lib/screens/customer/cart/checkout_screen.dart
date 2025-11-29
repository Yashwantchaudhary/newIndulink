import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/loading_widgets.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../orders/orders_screen.dart';

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

  @override
  void initState() {
    super.initState();
    // Pre-select default address if available
    final user = context.read<AuthProvider>().user;
    if (user != null && user.addresses != null && user.addresses!.isNotEmpty) {
      try {
        _selectedAddress = user.addresses!.firstWhere((a) => a.isDefault);
      } catch (e) {
        _selectedAddress = user.addresses!.first;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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

    final order = await orderProvider.createOrder(
      shippingAddress: _selectedAddress!,
      paymentMethod: _selectedPaymentMethod,
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
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final addresses = auth.user?.addresses ?? [];

        if (addresses.isEmpty) {
          return Column(
            children: [
              const Icon(Icons.location_off,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              const Text('No addresses found'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to add address screen
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Address'),
              ),
            ],
          );
        }

        return Column(
          children: addresses.map((address) {
            return RadioListTile<Address>(
              value: address,
              groupValue: _selectedAddress,
              onChanged: (value) {
                setState(() {
                  _selectedAddress = value;
                });
              },
              title: Text(address.label.displayName),
              subtitle: Text(
                '${address.addressLine1}, ${address.city}, ${address.postalCode}\n${address.phone}',
              ),
              secondary: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Edit address
                },
              ),
              activeColor: AppColors.primary,
            );
          }).toList(),
        );
      },
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
