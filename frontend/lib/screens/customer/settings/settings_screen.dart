import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../profile/change_password_screen.dart'; // Import change password screen
// ThemeProvider import removed - dark mode feature disabled

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          _buildSection(
            title: 'Preferences',
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: ' Receive updates about your orders',
                value: _notificationsEnabled,
                icon: Icons.notifications_outlined,
                iconColor: Colors.purple,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: 'Email Updates',
                subtitle: 'Receive promotional emails and newsletters',
                value: _emailUpdates,
                icon: Icons.email_outlined,
                iconColor: Colors.orange,
                onChanged: (value) {
                  setState(() {
                    _emailUpdates = value;
                  });
                },
              ),
              // Dark Mode toggle removed - app uses light theme only
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Account',
            children: [
              _buildListTile(
                title: 'Change Password',
                icon: Icons.lock_outline,
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/privacy-policy');
                },
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Terms of Service',
                icon: Icons.description_outlined,
                iconColor: Colors.teal,
                onTap: () {
                  Navigator.pushNamed(context, '/terms-of-service');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              onTap: _showDeleteAccountDialog,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
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
              color: AppColors.textPrimary,
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
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70, right: 20),
      child: Divider(
        height: 1,
        color: Colors.grey.withOpacity(0.1),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary.withOpacity(0.8),
        ),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            )
          : null,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password',
                hintText: 'Confirm your password to delete',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) => ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your password'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final success = await authProvider.deleteAccount(
                        password: passwordController.text,
                      );

                      Navigator.pop(context); // Close dialog

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account deleted successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        // Navigate to login screen
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/role-selection',
                          (route) => false,
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              authProvider.errorMessage ??
                                  'Failed to delete account',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ),
        ],
      ),
    );
  }
}
