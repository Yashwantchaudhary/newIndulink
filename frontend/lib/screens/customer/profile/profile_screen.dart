import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/login_screen.dart';
import '../orders/orders_screen.dart';
import '../wishlist/customer_wishlist_screen.dart';
import 'address_screen.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../data/customer_data_management_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(selectedRole: UserRole.customer),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;

          if (user == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen(selectedRole: UserRole.customer),
                    ),
                  );
                },
                child: const Text('Login to View Profile'),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Premium Header with Gradient
                Stack(
                  children: [
                    Container(
                      height: 240,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingL),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'My Profile',
                                  style: AppTypography.h5.copyWith(
                                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Profile Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor:
                                          AppColors.primaryLightest,
                                      backgroundImage: user.profileImage != null
                                          ? NetworkImage(user.profileImage!)
                                          : null,
                                      child: user.profileImage == null
                                          ? Text(
                                              user.firstName.isNotEmpty
                                                  ? user.firstName[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 28,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.fullName,
                                          style: AppTypography.h6.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            user.role.displayName,
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Menu Items
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM),
                  child: Column(
                    children: [
                      _buildMenuSection(
                        context,
                        title: 'Shopping',
                        items: [
                          _MenuItem(
                            icon: Icons.shopping_bag_outlined,
                            title: 'My Orders',
                            color: AppColors.secondary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OrdersScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.location_on_outlined,
                            title: 'Shipping Addresses',
                            color: AppColors.warning,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddressScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.favorite_border,
                            title: 'Wishlist',
                            color: AppColors.error,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CustomerWishlistScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.storage_outlined,
                            title: 'My Data',
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CustomerDataManagementScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildMenuSection(
                        context,
                        title: 'Preferences',
                        items: [
                          _MenuItem(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            color: Colors.purple,
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            color: Colors.grey,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            color: Colors.blue,
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 32),
                        child: ElevatedButton.icon(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error.withOpacity(0.1),
                            foregroundColor: AppColors.error,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Version 1.0.0',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textTertiary,
                    ),
                    onTap: item.onTap,
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 70, right: 20),
                      child: Divider(
                        height: 1,
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.dividerDark.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
  });
}
