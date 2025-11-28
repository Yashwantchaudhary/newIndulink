import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelector extends ConsumerWidget {
  final bool showTitle;

  const LanguageSelector({
    super.key,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageAsync = ref.watch(languageNotifierProvider);
    final theme = Theme.of(context);

    return languageAsync.when(
      data: (languageState) {
        final currentLocale = languageState.locale;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  (AppLocalizations.of(context) ??
                          AppLocalizations(const Locale('en')))
                      .selectLanguage,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ...AppLocalizations.supportedLocales.map((locale) {
              final isSelected =
                  currentLocale.languageCode == locale.languageCode;
              final languageNotifier =
                  ref.read(languageNotifierProvider.notifier);

              return _LanguageTile(
                languageCode: locale.languageCode,
                languageName:
                    languageNotifier.getLanguageName(locale.languageCode),
                languageFlag:
                    languageNotifier.getLanguageFlag(locale.languageCode),
                isSelected: isSelected,
                onTap: () {
                  ref
                      .read(languageNotifierProvider.notifier)
                      .changeLanguage(locale);
                },
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final String languageFlag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.languageCode,
    required this.languageName,
    required this.languageFlag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Flag
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  languageFlag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),

              const SizedBox(width: 16),

              // Language name and code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? theme.primaryColor : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      languageCode.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Selected indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for language selection
class LanguageSelectorBottomSheet extends StatelessWidget {
  const LanguageSelectorBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const LanguageSelectorBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Language selector
            const LanguageSelector(),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
