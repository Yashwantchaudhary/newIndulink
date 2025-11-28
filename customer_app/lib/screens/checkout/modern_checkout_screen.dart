import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../providers/cart_provider.dart';

/// Modern Multi-Step Checkout Screen
class ModernCheckoutScreen extends ConsumerStatefulWidget {
  const ModernCheckoutScreen({super.key});

  @override
  ConsumerState<ModernCheckoutScreen> createState() =>
      _ModernCheckoutScreenState();
}

class _ModernCheckoutScreenState extends ConsumerState<ModernCheckoutScreen> {
  int _currentStep = 0;
  String _selectedAddress = '';
  String _selectedPayment = '';

  final _addressOptions = [
    {'id': '1', 'label': 'Home', 'address': '123 Main St, Kathmandu'},
    {'id': '2', 'label': 'Office', 'address': '456 Business Ave, Lalitpur'},
  ];

  final _paymentOptions = [
    {'id': 'card', 'label': 'Credit/Debit Card', 'icon': Icons.credit_card},
    {'id': 'esewa', 'label': 'eSewa', 'icon': Icons.account_balance_wallet},
    {'id': 'khalti', 'label': 'Khalti', 'icon': Icons.paypal},
    {'id': 'cod', 'label': 'Cash on Delivery', 'icon': Icons.money},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(theme, isDark),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: AppConstants.paddingAll20,
              child: _buildStepContent(),
            ),
          ),

          // Bottom Bar
          _buildBottomBar(context, cartState, isDark),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, bool isDark) {
    final steps = ['Address', 'Payment', 'Review'];

    return Container(
      padding: AppConstants.paddingAll20,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: isCompleted || isCurrent
                              ? AppColors.primaryGradient
                              : null,
                          color: isCompleted || isCurrent
                              ? null
                              : AppColors.lightTextTertiary,
                          shape: BoxShape.circle,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          color: Colors.white,
                          size: isCompleted ? 24 : 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index],
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? AppColors.primaryBlue : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 40,
                    height: 2,
                    color: isCompleted
                        ? AppColors.primaryBlue
                        : AppColors.lightTextTertiary,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildAddressStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAddressStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Delivery Address',
          icon: Icons.location_on,
        ),
        const SizedBox(height: 16),
        ..._addressOptions.map((address) {
          final isSelected = _selectedAddress == address['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedAddress = address['id']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: AppConstants.paddingAll16,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withValues(alpha: 0.1),
                          AppColors.primaryBlue.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: AppConstants.borderRadiusMedium,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.home,
                    color: isSelected ? AppColors.primaryBlue : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address['label']!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primaryBlue : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address['address']!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryBlue,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add New Address'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Payment Method',
          icon: Icons.payment,
        ),
        const SizedBox(height: 16),
        ..._paymentOptions.map((payment) {
          final isSelected = _selectedPayment == payment['id'];

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedPayment = payment['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: AppConstants.paddingAll16,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withValues(alpha: 0.1),
                          AppColors.primaryBlue.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: AppConstants.borderRadiusMedium,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.lightSurfaceVariant,
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                    child: Icon(
                      payment['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      payment['label'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primaryBlue : null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryBlue,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(cartProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Order Summary',
          icon: Icons.receipt_long,
        ),
        const SizedBox(height: 16),
        // Order Items
        Container(
          padding: AppConstants.paddingAll16,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          child: Column(
            children: [
              _buildSummaryRow('Items', '3 products', theme),
              const Divider(height: 24),
              _buildSummaryRow('Subtotal',
                  'Rs ${cartState.subtotal.toStringAsFixed(2)}', theme),
              const SizedBox(height: 8),
              _buildSummaryRow('Shipping', 'Rs 150.00', theme),
              const SizedBox(height: 8),
              _buildSummaryRow(
                  'Tax (13%)',
                  'Rs ${(cartState.subtotal * 0.13).toStringAsFixed(2)}',
                  theme),
              const Divider(height: 24),
              _buildSummaryRow(
                'Total',
                'Rs ${(cartState.subtotal + 150 + (cartState.subtotal * 0.13)).toStringAsFixed(2)}',
                theme,
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Delivery Info
        Container(
          padding: AppConstants.paddingAll16,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: AppConstants.borderRadiusMedium,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_shipping, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Delivery',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      '3-5 business days',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                )
              : theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, dynamic cartState, bool isDark) {
    return Container(
      padding: AppConstants.paddingAll20,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: AnimatedButton(
              text: _currentStep == 2 ? 'Place Order' : 'Continue',
              onPressed: () {
                if (_currentStep == 2) {
                  _placeOrder(context);
                } else {
                  setState(() => _currentStep++);
                }
              },
              gradient: AppColors.primaryGradient,
            ),
          ),
        ],
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed!'),
        content: const Text('Your order has been successfully placed.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
