import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

import '../../../providers/theme_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../models/user.dart';
import '../../auth/login_screen.dart';
import 'edit_supplier_profile_screen.dart';

/// 👤 Supplier Profile Screen
class SupplierProfileScreen extends StatefulWidget {
  const SupplierProfileScreen({super.key});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _notificationsEnabled = true;
  bool _emailAlertsEnabled = false;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    // No need to load separately - we'll use AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();

    // Show bottom sheet to choose source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: AppColors.secondary),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.uploadProfileImage(pickedFile);

      if (mounted) {
        setState(() => _isUploadingImage = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '✅ Profile photo updated successfully!'
                : '❌ Failed to update profile photo'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Initialize dark mode state from theme provider
          if (_darkModeEnabled != themeProvider.isDarkMode) {
            _darkModeEnabled = themeProvider.isDarkMode;
          }
          return _isLoading || user == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary,
                            child: _isUploadingImage
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : user.profileImage != null
                                    ? CircleAvatar(
                                        radius: 50,
                                        backgroundImage:
                                            NetworkImage(user.profileImage!),
                                      )
                                    : Text(
                                        user.businessName != null
                                            ? user.businessName![0]
                                                .toUpperCase()
                                            : user.initials,
                                        style: AppTypography.h3
                                            .copyWith(color: Colors.white),
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingImage
                                  ? null
                                  : _pickAndUploadImage,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: _isUploadingImage
                                      ? Colors.grey
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Business Info
                    _buildCard(
                      'Business Information',
                      Column(
                        children: [
                          _buildInfoTile(
                              'Business Name', user.businessName ?? 'Not set'),
                          _buildInfoTile('Contact Person', user.fullName),
                          _buildInfoTile('Email', user.email),
                          _buildInfoTile('Phone', user.phone ?? 'Not set'),
                          _buildInfoTile('Business Description',
                              user.businessDescription ?? 'Not set'),
                          _buildInfoTile('Business Address',
                              user.businessAddress ?? 'Not set'),
                          _buildInfoTile('Business License',
                              user.businessLicense ?? 'Not set'),
                          if (user.services != null &&
                              user.services!.isNotEmpty)
                            _buildInfoTile(
                                'Services', user.services!.join(', ')),
                          if (user.certifications != null &&
                              user.certifications!.isNotEmpty)
                            _buildInfoTile('Certifications',
                                user.certifications!.join(', ')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Settings
                    _buildCard(
                      'Settings',
                      Column(
                        children: [
                          _buildSettingTile(Icons.notifications,
                              'Notifications', _notificationsEnabled),
                          _buildSettingTile(
                              Icons.email, 'Email Alerts', _emailAlertsEnabled),
                          _buildSettingTile(
                              Icons.dark_mode, 'Dark Mode', _darkModeEnabled),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EditSupplierProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout?'),
                            content:
                                const Text('Are you sure you want to logout?'),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error),
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
                                builder: (context) => const LoginScreen(
                                    selectedRole: UserRole.supplier),
                              ),
                              (route) => false,
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildCard(String title, Widget child) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDarkMode ? AppColors.dividerDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              )),
          Text(value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, bool value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: (v) {
          if (title == 'Dark Mode') {
            setState(() {
              _darkModeEnabled = v;
            });
            // Connect to theme provider
            final themeProvider =
                Provider.of<ThemeProvider>(context, listen: false);
            if (v) {
              themeProvider.setDarkMode();
            } else {
              themeProvider.setLightMode();
            }
          } else if (title == 'Notifications') {
            setState(() {
              _notificationsEnabled = v;
            });
            // Connect to notification provider
            final notificationProvider =
                Provider.of<NotificationProvider>(context, listen: false);
            // Update notification settings
            if (v) {
              notificationProvider.requestPermissions();
            }
          } else if (title == 'Email Alerts') {
            setState(() {
              _emailAlertsEnabled = v;
            });
            // Update email notification settings
            // Note: Email notifications would typically be handled via API
          }
        },
        activeThumbColor: AppColors.primary,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
