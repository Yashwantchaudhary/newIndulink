import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';

/// Modern Payment Methods Management Screen
class ModernPaymentMethodsScreen extends ConsumerStatefulWidget {
  const ModernPaymentMethodsScreen({super.key});

  @override
  ConsumerState<ModernPaymentMethodsScreen> createState() =>
      _ModernPaymentMethodsScreenState();
}

class _ModernPaymentMethodsScreenState
    extends ConsumerState<ModernPaymentMethodsScreen> {
  String _defaultPaymentId = '1';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final paymentMethods = _getMockPaymentMethods();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            onPressed: () => _showAddPaymentDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppConstants.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Digital Wallets Section
            const SectionHeader(title: 'Digital Wallets'),
            const SizedBox(height: 12),
            _buildWalletCard('eSewa', Icons.account_balance_wallet,
                AppColors.successGradient, '+977 9812345678', isDark),
            const SizedBox(height: 12),
            _buildWalletCard('Khalti', Icons.paypal, AppColors.purpleGradient,
                '+977 9876543210', isDark),
            const SizedBox(height: 24),

            // Saved Cards Section
            SectionHeader(
              title: 'Saved Cards',
              actionText: 'Add Card',
              onSeeAll: _showAddCardDialog,
            ),
            const SizedBox(height: 12),
            ...paymentMethods.map((pm) => _buildPaymentCard(pm, isDark, theme)),
            const SizedBox(height: 24),

            // Cash on Delivery
            const SectionHeader(title: 'Other Methods'),
            const SizedBox(height: 12),
            _buildCODCard(isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(
    String name,
    IconData icon,
    LinearGradient? gradient,
    String phone,
    bool isDark,
  ) {
    final LinearGradient g = gradient!;
    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        gradient: g,
        borderRadius: AppConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: g.colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Connected',
              style: TextStyle(
                color: g.colors.first,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
      _PaymentMethod method, bool isDark, ThemeData theme) {
    final isDefault = _defaultPaymentId == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isDefault
            ? LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.1),
                  AppColors.secondaryPurple.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isDefault
            ? null
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: AppConstants.borderRadiusLarge,
        border: Border.all(
          color: isDefault
              ? AppColors.primaryBlue
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: AppConstants.paddingAll16,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _getCardGradient(method.type),
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                  child: Icon(
                    _getCardIcon(method.type),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method.type.toUpperCase(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '•••• •••• •••• ${method.lastFourDigits}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Expires ${method.expiryMonth}/${method.expiryYear}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isDefault)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _defaultPaymentId = method.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Default payment method updated'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Set Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                if (!isDefault) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditCardDialog(method),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showDeleteConfirmation(method),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCODCard(bool isDark, ThemeData theme) {
    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusLarge,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: const Icon(
              Icons.money,
              color: AppColors.accentOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash on Delivery',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pay when you receive your order',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success),
        ],
      ),
    );
  }

  IconData _getCardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  LinearGradient _getCardGradient(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return AppColors.primaryGradient;
      case 'mastercard':
        return AppColors.accentGradient;
      default:
        return AppColors.secondaryGradient;
    }
  }

  void _showAddPaymentDialog() {
    _showAddCardDialog();
  }

  void _showAddCardDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: AppConstants.paddingAll20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightTextTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Card',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        hintText: '12/25',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedButton(
                text: 'Add Card',
                icon: Icons.add,
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card added successfully')),
                  );
                },
                gradient: AppColors.primaryGradient,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCardDialog(_PaymentMethod method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${method.type} card')),
    );
  }

  void _showDeleteConfirmation(_PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content:
            Text('Remove ${method.type} ending in ${method.lastFourDigits}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card removed')),
              );
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  List<_PaymentMethod> _getMockPaymentMethods() {
    return [
      _PaymentMethod(
        id: '1',
        type: 'Visa',
        lastFourDigits: '4242',
        expiryMonth: '12',
        expiryYear: '25',
      ),
      _PaymentMethod(
        id: '2',
        type: 'Mastercard',
        lastFourDigits: '8888',
        expiryMonth: '06',
        expiryYear: '26',
      ),
    ];
  }
}

class _PaymentMethod {
  final String id;
  final String type;
  final String lastFourDigits;
  final String expiryMonth;
  final String expiryYear;

  _PaymentMethod({
    required this.id,
    required this.type,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
  });
}
