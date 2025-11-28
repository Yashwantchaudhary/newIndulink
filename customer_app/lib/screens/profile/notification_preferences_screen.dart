import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../services/api_client.dart';

// Notification Preferences Provider
final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesState>((ref) {
  return NotificationPreferencesNotifier();
});

class NotificationPreferencesState {
  final bool orderUpdates;
  final bool promotions;
  final bool messages;
  final bool system;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool isLoading;
  final String? error;

  NotificationPreferencesState({
    this.orderUpdates = true,
    this.promotions = true,
    this.messages = true,
    this.system = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.isLoading = false,
    this.error,
  });

  NotificationPreferencesState copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? messages,
    bool? system,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationPreferencesState(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      messages: messages ?? this.messages,
      system: system ?? this.system,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  final ApiClient _apiClient = ApiClient();

  NotificationPreferencesNotifier() : super(NotificationPreferencesState());

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/users/notification-preferences');

      final prefs = response.data;
      state = state.copyWith(
        orderUpdates: prefs['orderUpdates'] ?? true,
        promotions: prefs['promotions'] ?? true,
        messages: prefs['messages'] ?? true,
        system: prefs['system'] ?? true,
        emailNotifications: prefs['emailNotifications'] ?? true,
        pushNotifications: prefs['pushNotifications'] ?? true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updatePreference(String key, bool value) async {
    // Update local state immediately for better UX
    state = state.copyWith(
      orderUpdates: key == 'orderUpdates' ? value : state.orderUpdates,
      promotions: key == 'promotions' ? value : state.promotions,
      messages: key == 'messages' ? value : state.messages,
      system: key == 'system' ? value : state.system,
      emailNotifications:
          key == 'emailNotifications' ? value : state.emailNotifications,
      pushNotifications:
          key == 'pushNotifications' ? value : state.pushNotifications,
    );

    try {
      await _apiClient.put('/users/notification-preferences', data: {
        'orderUpdates': state.orderUpdates,
        'promotions': state.promotions,
        'messages': state.messages,
        'system': state.system,
        'emailNotifications': state.emailNotifications,
        'pushNotifications': state.pushNotifications,
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Revert on error
      await loadPreferences();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Modern Notification Preferences Screen
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationPreferencesProvider.notifier).loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
      ),
      body: state.isLoading &&
              state.orderUpdates == true // Initial loading check
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppConstants.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: AppConstants.paddingAll16,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppConstants.borderRadiusMedium,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stay Updated',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose what notifications you want to receive',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Push Notifications Section
                  _buildSectionHeader(
                      'Push Notifications', Icons.phone_android),
                  _buildPreferenceTile(
                    'Order Updates',
                    'Get notified about your order status changes',
                    state.orderUpdates,
                    (value) => ref
                        .read(notificationPreferencesProvider.notifier)
                        .updatePreference('orderUpdates', value),
                    Icons.shopping_bag,
                  ),
                  _buildPreferenceTile(
                    'Promotions',
                    'Receive offers and promotional messages',
                    state.promotions,
                    (value) => ref
                        .read(notificationPreferencesProvider.notifier)
                        .updatePreference('promotions', value),
                    Icons.local_offer,
                  ),
                  _buildPreferenceTile(
                    'Messages',
                    'Notifications for new messages',
                    state.messages,
                    (value) => ref
                        .read(notificationPreferencesProvider.notifier)
                        .updatePreference('messages', value),
                    Icons.message,
                  ),
                  _buildPreferenceTile(
                    'System Updates',
                    'Important system announcements',
                    state.system,
                    (value) => ref
                        .read(notificationPreferencesProvider.notifier)
                        .updatePreference('system', value),
                    Icons.info,
                  ),

                  const SizedBox(height: 24),

                  // Email Notifications Section
                  _buildSectionHeader('Email Notifications', Icons.email),
                  Container(
                    padding: AppConstants.paddingAll16,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: AppConstants.borderRadiusMedium,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accentOrange.withValues(alpha: 0.1),
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: const Icon(
                            Icons.email,
                            color: AppColors.accentOrange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Notifications',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Receive notifications via email',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: state.emailNotifications,
                          onChanged: state.isLoading
                              ? null
                              : (value) => ref
                                  .read(
                                      notificationPreferencesProvider.notifier)
                                  .updatePreference(
                                      'emailNotifications', value),
                          activeThumbColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Push Notifications Master Switch
                  _buildSectionHeader('Master Controls', Icons.settings),
                  Container(
                    padding: AppConstants.paddingAll16,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: AppConstants.borderRadiusMedium,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Push Notifications',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enable or disable all push notifications',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: state.pushNotifications,
                          onChanged: state.isLoading
                              ? null
                              : (value) => ref
                                  .read(
                                      notificationPreferencesProvider.notifier)
                                  .updatePreference('pushNotifications', value),
                          activeThumbColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),

                  // Error message
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: AppConstants.paddingAll12,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppConstants.borderRadiusSmall,
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.error, size: 16),
                            onPressed: () => ref
                                .read(notificationPreferencesProvider.notifier)
                                .clearError(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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

  Widget _buildPreferenceTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getIconColor(icon).withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Icon(
              icon,
              color: _getIconColor(icon),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: ref.read(notificationPreferencesProvider).isLoading
                ? null
                : onChanged,
            activeThumbColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Color _getIconColor(IconData icon) {
    switch (icon) {
      case Icons.shopping_bag:
        return AppColors.primaryBlue;
      case Icons.local_offer:
        return AppColors.accentOrange;
      case Icons.message:
        return AppColors.secondaryPurple;
      case Icons.info:
        return AppColors.lightTextSecondary;
      default:
        return AppColors.primaryBlue;
    }
  }
}
