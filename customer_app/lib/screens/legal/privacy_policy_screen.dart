import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Privacy Policy Screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppConstants.paddingAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INDULINK Privacy Policy',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().substring(0, 10)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Information We Collect',
              '''We collect information that you provide directly to us, including:
• Account information (name, email, phone number)
• Business information for suppliers
• Order and transaction history
• Product reviews and ratings
• Messages and communications''',
            ),
            _buildSection(
              context,
              'How We Use Your Information',
              '''We use the information we collect to:
• Provide and improve our services
• Process your orders and payments
• Send you updates and notifications
• Respond to your requests and support inquiries
• Analyze usage patterns to enhance user experience''',
            ),
            _buildSection(
              context,
              'Information Sharing',
              '''We do not sell your personal information. We may share your information with:
• Suppliers to fulfill your orders
• Service providers who assist our operations
• Legal authorities when required by law''',
            ),
            _buildSection(
              context,
              'Data Security',
              '''We implement industry-standard security measures to protect your data:
• Encrypted data transmission (SSL/TLS)
• Secure data storage
• Regular security audits
• Access controls and authentication''',
            ),
            _buildSection(
              context,
              'Your Rights',
              '''You have the right to:
• Access your personal data
• Correct inaccurate information
• Request deletion of your data
• Opt-out of marketing communications
• Export your data''',
            ),
            _buildSection(
              context,
              'Cookies and Tracking',
              '''We use cookies and similar technologies to:
• Remember your preferences
• Analyze site traffic
• Personalize content
• Improve our services''',
            ),
            _buildSection(
              context,
              'Contact Us',
              '''If you have questions about this Privacy Policy, contact us at:
• Email: privacy@indulink.com
• Phone: +977-1-XXXXXXX
• Address: Kathmandu, Nepal''',
            ),
            const SizedBox(height: 24),
            Container(
              padding: AppConstants.paddingAll16,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusMedium,
                border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This policy may be updated periodically. We will notify you of significant changes.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
