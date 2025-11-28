import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Terms and Conditions Screen
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppConstants.paddingAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INDULINK Terms & Conditions',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective date: ${DateTime.now().toString().substring(0, 10)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Acceptance of Terms',
              '''By accessing and using the INDULINK platform, you accept and agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.''',
            ),
            _buildSection(
              context,
              'User Accounts',
              '''• You must provide accurate and complete information
• You are responsible for maintaining account security
• You must notify us immediately of any unauthorized access
• You must be at least 18 years old to create an account
• One person or business may maintain only one account''',
            ),
            _buildSection(
              context,
              'Buyer Responsibilities',
              '''As a buyer, you agree to:
• Provide accurate shipping and payment information
• Complete payment for confirmed orders
• Review products promptly upon delivery
• Report any issues within the specified timeframe
• Communicate professionally with suppliers''',
            ),
            _buildSection(
              context,
              'Supplier Responsibilities',
              '''As a supplier, you agree to:
• Provide accurate product descriptions and pricing
• Maintain adequate stock levels
• Fulfill orders in a timely manner
• Respond to customer inquiries promptly
• Handle returns according to your stated policy''',
            ),
            _buildSection(
              context,
              'Orders and Payments',
              '''• All orders are subject to acceptance and availability
• Prices are in Nepali Rupees unless otherwise stated
• Payment must be completed before order processing
• We reserve the right to cancel fraudulent orders
• Refunds are processed according to our refund policy''',
            ),
            _buildSection(
              context,
              'Shipping and Delivery',
              '''• Delivery times are estimates and not guaranteed
• Risk of loss transfers upon delivery
• You must inspect products upon receipt
• Report damage or defects within 48 hours
• International shipping may incur customs fees''',
            ),
            _buildSection(
              context,
              'Intellectual Property',
              '''All content on INDULINK, including text, graphics, logos, and software, is our property or that of our licensors. You may not:
• Copy or reproduce content without permission
• Use our trademarks or branding
• Reverse engineer our software
• Create derivative works''',
            ),
            _buildSection(
              context,
              'Prohibited Activities',
              '''You agree not to:
• Violate any laws or regulations
• Infringe on intellectual property rights
• Post false or misleading information
• Engage in fraudulent activities
• Harass or abuse other users
• Attempt to hack or disrupt our services''',
            ),
            _buildSection(
              context,
              'Limitation of Liability',
              '''INDULINK is not liable for:
• Indirect or consequential damages
• Lost profits or business opportunities
• Supplier actions or product quality
• Service interruptions or data loss
• Third-party content or links''',
            ),
            _buildSection(
              context,
              'Dispute Resolution',
              '''Any disputes arising from these terms will be:
• Resolved through good faith negotiation
• Subject to arbitration if negotiation fails
• Governed by the laws of Nepal
• Handled in the courts of Kathmandu''',
            ),
            _buildSection(
              context,
              'Modifications',
              '''We reserve the right to modify these Terms at any time. Continued use of our services after changes constitutes acceptance of the new terms.''',
            ),
            _buildSection(
              context,
              'Contact Information',
              '''For questions about these Terms, contact us:
• Email: legal@indulink.com
• Phone: +977-1-XXXXXXX
• Address: Kathmandu, Nepal''',
            ),
            const SizedBox(height: 24),
            Container(
              padding: AppConstants.paddingAll16,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusMedium,
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using INDULINK, you acknowledge that you have read and understood these Terms and Conditions.',
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
