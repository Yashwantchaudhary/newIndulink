import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';

/// 🔔 Notification Settings Screen
/// Allows users to manage push notification preferences
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _orderUpdates = true;
  bool _newMessages = true;
  bool _productUpdates = true;
  bool _promotions = false;
  bool _systemAlerts = true;
  bool _isLoading = false;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _notificationService.getNotificationSettings();
      setState(() {
        _notificationsEnabled = settings['enabled'] ?? true;
      });
    } catch (error) {
      debugPrint('Failed to load notification settings: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() => _isLoading = true);

    try {
      await _notificationService.setNotificationsEnabled(enabled);
      setState(() {
        _notificationsEnabled = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled
              ? 'Push notifications enabled'
              : 'Push notifications disabled'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update notification settings'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isLoading = true);

    try {
      await context.read<NotificationProvider>().sendTestNotification(
            title: 'Test Notification',
            body: 'This is a test push notification from INDULINK',
            type: 'test',
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send test notification'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Push Notifications Toggle
                  _buildSectionHeader('Push Notifications'),
                  _buildSettingCard(
                    title: 'Enable Push Notifications',
                    subtitle: 'Receive notifications on your device',
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                  ),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Notification Types
                  _buildSectionHeader('Notification Types'),
                  _buildSettingCard(
                    title: 'Order Updates',
                    subtitle: 'Status changes and order updates',
                    value: _orderUpdates,
                    onChanged: (value) => setState(() => _orderUpdates = value),
                    enabled: _notificationsEnabled,
                  ),
                  _buildSettingCard(
                    title: 'New Messages',
                    subtitle: 'Messages from suppliers and customers',
                    value: _newMessages,
                    onChanged: (value) => setState(() => _newMessages = value),
                    enabled: _notificationsEnabled,
                  ),
                  _buildSettingCard(
                    title: 'Product Updates',
                    subtitle: 'Back in stock and price changes',
                    value: _productUpdates,
                    onChanged: (value) =>
                        setState(() => _productUpdates = value),
                    enabled: _notificationsEnabled,
                  ),
                  _buildSettingCard(
                    title: 'Promotions & Offers',
                    subtitle: 'Special deals and promotional content',
                    value: _promotions,
                    onChanged: (value) => setState(() => _promotions = value),
                    enabled: _notificationsEnabled,
                  ),
                  _buildSettingCard(
                    title: 'System Alerts',
                    subtitle: 'Maintenance and important system updates',
                    value: _systemAlerts,
                    onChanged: (value) => setState(() => _systemAlerts = value),
                    enabled: _notificationsEnabled,
                  ),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Test Notification
                  _buildSectionHeader('Testing'),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Notification',
                          style: AppTypography.labelLarge
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a test notification to verify your settings',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _notificationsEnabled
                                ? _sendTestNotification
                                : null,
                            icon: const Icon(Icons.send),
                            label: const Text('Send Test Notification'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Information
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About Notifications',
                              style: AppTypography.labelLarge
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Push notifications help you stay updated with order status, new messages, and important updates. You can customize which types of notifications you want to receive.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Note: Some notifications (like order updates) are important for your account security and cannot be disabled.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Text(
        title,
        style: AppTypography.h6.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: enabled ? AppColors.border : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
