import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../widgets/common/language_selector.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../config/firebase_config.dart';

/// Production-level Profile Screen with organized sections
class ProfileScreenNew extends ConsumerWidget {
  const ProfileScreenNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final languageState = ref.watch(languageNotifierProvider);
    final themeState = ref.watch(themeProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Profile Header with Gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Profile Picture
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              user?.name.substring(0, 1).toUpperCase() ?? 'U',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'User Name',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? 'user@example.com',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Menu Sections
          SliverToBoxAdapter(
            child: Padding(
              padding: AppConstants.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Account Section
                  _buildSectionHeader(context, 'Account', Icons.person),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    subtitle: 'Update your details',
                    iconColor: AppColors.primaryBlue,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Saved Addresses',
                    subtitle: 'Manage delivery addresses',
                    iconColor: AppColors.accentOrange,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    subtitle: 'Cards, UPI, and more',
                    iconColor: AppColors.accentGreen,
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  // My Activity Section
                  _buildSectionHeader(context, 'My Activity', Icons.history),
                  _buildMenuItem(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    subtitle: 'View order history',
                    iconColor: AppColors.primaryBlue,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite_outline,
                    title: 'Wishlist',
                    subtitle: '12 items',
                    iconColor: AppColors.error,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.star_outline,
                    title: 'My Reviews',
                    subtitle: 'Products you reviewed',
                    iconColor: AppColors.accentYellow,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.visibility_outlined,
                    title: 'Recently Viewed',
                    subtitle: 'Your browsing history',
                    iconColor: AppColors.secondaryPurple,
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  // Preferences Section
                  _buildSectionHeader(context, 'Preferences', Icons.settings),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage notification settings',
                    iconColor: AppColors.accentCyan,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.language_outlined,
                    title: l10n.language,
                    subtitle: languageState.value?.locale.languageCode == 'en'
                        ? l10n.english
                        : languageState.value?.locale.languageCode == 'hi'
                            ? l10n.hindi
                            : languageState.value?.locale.languageCode == 'ne'
                                ? l10n.nepali
                                : l10n.spanish,
                    iconColor: AppColors.primaryBlue,
                    onTap: () => LanguageSelectorBottomSheet.show(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: themeState.themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : themeState.themeMode == ThemeMode.light
                            ? Icons.dark_mode_outlined
                            : Icons.brightness_auto_outlined,
                    title: 'Theme',
                    subtitle: themeState.themeMode == ThemeMode.dark
                        ? 'Dark Mode'
                        : themeState.themeMode == ThemeMode.light
                            ? 'Light Mode'
                            : 'System Default',
                    iconColor: themeState.themeMode == ThemeMode.dark
                        ? AppColors.accentYellow
                        : themeState.themeMode == ThemeMode.light
                            ? AppColors.secondaryPurple
                            : AppColors.primaryBlue,
                    onTap: () => _showThemeDialog(context, ref),
                    trailing: Switch(
                      value: themeState.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                      activeThumbColor: AppColors.primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Support Section
                  _buildSectionHeader(context, 'Support', Icons.support_agent),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    subtitle: 'FAQs and support',
                    iconColor: AppColors.accentGreen,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Contact Us',
                    subtitle: 'Get in touch',
                    iconColor: AppColors.primaryBlue,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.rate_review_outlined,
                    title: 'Rate Us',
                    subtitle: 'Share your feedback',
                    iconColor: AppColors.accentYellow,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.developer_mode_outlined,
                    title: 'Debug Info',
                    subtitle: 'FCM Token & Device Info',
                    iconColor: AppColors.secondaryPurple,
                    onTap: () => _showDebugInfo(context),
                  ),

                  const SizedBox(height: 24),

                  // Legal Section
                  _buildSectionHeader(context, 'Legal', Icons.gavel),
                  _buildMenuItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    subtitle: 'Read our terms',
                    iconColor: AppColors.lightTextTertiary,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we protect your data',
                    iconColor: AppColors.lightTextTertiary,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About Us',
                    subtitle: 'Version 1.0.0',
                    iconColor: AppColors.lightTextTertiary,
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  AnimatedButton(
                    text: 'Logout',
                    icon: Icons.logout,
                    onPressed: () {
                      _showLogoutConfirmation(context, ref);
                    },
                    backgroundColor: AppColors.error,
                    width: double.infinity,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: AppConstants.borderRadiusSmall,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeProvider).themeMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Follow system settings'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
              // Navigate to login screen
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo(BuildContext context) async {
    final fcmToken = await FirebaseConfig.fcmService.getFCMToken();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'FCM Token:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                fcmToken ?? 'Not available',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Device Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Platform: ${Theme.of(context).platform}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
