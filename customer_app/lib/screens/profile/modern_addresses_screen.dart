import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../providers/address_provider.dart';
import '../../models/address.dart';

/// Modern Saved Addresses Management Screen
class ModernAddressesScreen extends ConsumerStatefulWidget {
  const ModernAddressesScreen({super.key});

  @override
  ConsumerState<ModernAddressesScreen> createState() =>
      _ModernAddressesScreenState();
}

class _ModernAddressesScreenState extends ConsumerState<ModernAddressesScreen> {
  final String _defaultAddressId = '1';

  @override
  void initState() {
    super.initState();
    // Load addresses when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addressProvider.notifier).loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final addressState = ref.watch(addressProvider);
    final addresses = addressState.addresses;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: () => _showAddAddressDialog(),
          ),
        ],
      ),
      body: addressState.isLoading && addresses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
          ? EmptyStateWidget(
              icon: Icons.location_off,
              title: 'No Addresses Saved',
              message: 'Add a delivery address to continue',
              actionText: 'Add Address',
              onAction: _showAddAddressDialog,
            )
          : ListView.builder(
              padding: AppConstants.paddingAll16,
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                return _buildAddressCard(addresses[index], isDark, theme);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildAddressCard(Address address, bool isDark, ThemeData theme) {
    final isDefault = address.isDefault;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isDefault
            ? LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.secondaryPurple.withOpacity(0.05),
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
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: AppConstants.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: _getAddressTypeGradient(address.label),
                    borderRadius: AppConstants.borderRadiusSmall,
                    boxShadow: [
                      BoxShadow(
                        color: _getAddressTypeColor(address.label)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getAddressTypeIcon(address.label),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.label.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
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
                        address.fullName,
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
            const Divider(),
            const SizedBox(height: 12),

            // Address Details
            _buildAddressDetailRow(
              Icons.location_on_outlined,
              '${address.addressLine1}${address.addressLine2 != null ? ', ${address.addressLine2}' : ''}, ${address.city}, ${address.state} - ${address.postalCode}',
              theme,
            ),
            if (address.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildAddressDetailRow(
                Icons.phone_outlined,
                address.phone,
                theme,
              ),
            ],
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                if (!isDefault)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await ref
                            .read(addressProvider.notifier)
                            .setDefaultAddress(address.id!);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Default address updated'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
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
                    onPressed: () => _showEditAddressDialog(address),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showDeleteConfirmation(address),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildAddressDetailRow(IconData icon, String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  IconData _getAddressTypeIcon(String label) {
    final type = label.toLowerCase();
    switch (type) {
      case 'home':
        return Icons.home;
      case 'office':
      case 'work':
        return Icons.business;
      default:
        return Icons.location_pin;
    }
  }

  Color _getAddressTypeColor(String label) {
    final type = label.toLowerCase();
    switch (type) {
      case 'home':
        return AppColors.primaryBlue;
      case 'office':
      case 'work':
        return AppColors.accentOrange;
      default:
        return AppColors.secondaryPurple;
    }
  }

  LinearGradient _getAddressTypeGradient(String label) {
    final type = label.toLowerCase();
    switch (type) {
      case 'home':
        return AppColors.primaryGradient;
      case 'office':
        return AppColors.accentGradient;
      case 'other':
        return AppColors.secondaryGradient;
      default:
        return AppColors.primaryGradient;
    }
  }

  void _showAddAddressDialog() {
    _showAddressForm(null);
  }

  void _showEditAddressDialog(Address address) {
    _showAddressForm(address);
  }

  void _showAddressForm(Address? address) {
    final isEdit = address != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
                isEdit ? 'Edit Address' : 'Add New Address',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              // Add form fields here
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Label (Home, Office, etc.)',
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedButton(
                text: isEdit ? 'Update Address' : 'Save Address',
                icon: Icons.check,
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit ? 'Address updated' : 'Address added successfully',
                      ),
                    ),
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

  void _showDeleteConfirmation(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Remove ${address.label} address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(addressProvider.notifier)
                  .deleteAddress(address.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }


}

