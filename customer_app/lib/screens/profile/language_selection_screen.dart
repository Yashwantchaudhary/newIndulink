import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageState = ref.watch(languageNotifierProvider);
    final languageNotifier = ref.read(languageNotifierProvider.notifier);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
      ),
      body: languageState.when(
        data: (state) =>
            _buildContent(context, state, languageNotifier, isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading languages: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LanguageState state,
    LanguageNotifier languageNotifier,
    bool isDark,
  ) {
    const supportedLocales = AppLocalizations.supportedLocales;

    return ListView(
      padding: AppConstants.paddingAll16,
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
                  Icons.language,
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
                      'Choose Language',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select your preferred language',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

        // Language Options
        ...supportedLocales.map((locale) => _buildLanguageOption(
              context,
              locale,
              state.locale,
              languageNotifier,
              isDark,
            )),
      ],
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    Locale locale,
    Locale currentLocale,
    LanguageNotifier languageNotifier,
    bool isDark,
  ) {
    final isSelected = locale.languageCode == currentLocale.languageCode;
    final languageName = languageNotifier.getLanguageName(locale.languageCode);
    final flag = languageNotifier.getLanguageFlag(locale.languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: isSelected
              ? AppColors.primaryBlue
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.1)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.1),
            borderRadius: AppConstants.borderRadiusSmall,
          ),
          child: Center(
            child: Text(
              flag,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          languageName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryBlue : null,
              ),
        ),
        subtitle: Text(
          locale.languageCode.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
              )
            : null,
        onTap: () async {
          await languageNotifier.changeLanguage(locale);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Language changed to $languageName'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        shape: const RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusMedium,
        ),
      ),
    );
  }
}
