import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help and Support Screen
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppConstants.paddingAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'How can we help you?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickAction(
              context,
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@indulink.com',
              onTap: () => _launchEmail('support@indulink.com'),
            ),
            _buildQuickAction(
              context,
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+977-1-XXXXXXX',
              onTap: () => _launchPhone('+9771XXXXXXX'),
            ),
            _buildQuickAction(
              context,
              icon: Icons.chat_bubble_outline,
              title: 'Live Chat',
              subtitle: 'Chat with our support team',
              onTap: () => _showComingSoon(context),
            ),
            _buildQuickAction(
              context,
              icon: Icons.language,
              title: 'Visit Website',
              subtitle: 'www.indulink.com',
              onTap: () => _launchWebsite('https://www.indulink.com'),
            ),

            const SizedBox(height: 32),

            // FAQs Section
            Text(
              'Frequently Asked Questions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildFAQ(
              context,
              'How do I track my order?',
              'Go to Orders section and click on any order to view detailed tracking information.',
            ),
            _buildFAQ(
              context,
              'What payment methods do you accept?',
              'We accept Cash on Delivery, online payments, and digital wallet payments.',
            ),
            _buildFAQ(
              context,
              'How can I return a product?',
              'Contact the supplier directly through the Messages section within 7 days of delivery.',
            ),
            _buildFAQ(
              context,
              'How do I become a supplier?',
              'Register as a supplier during sign-up and complete your business verification.',
            ),
            _buildFAQ(
              context,
              'Is my data secure?',
              'Yes, we use industry-standard encryption and security measures to protect your data.',
            ),

            const SizedBox(height: 32),

            // Support Hours
            Container(
              padding: AppConstants.paddingAll16,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppConstants.borderRadiusMedium,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.primaryBlue),
                      const SizedBox(width: 12),
                      Text(
                        'Support Hours',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSupportHour('Monday - Friday', '9:00 AM - 6:00 PM'),
                  _buildSupportHour('Saturday', '10:00 AM - 4:00 PM'),
                  _buildSupportHour('Sunday', 'Closed'),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQ(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: AppConstants.paddingAll16,
          child: Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportHour(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day),
          Text(
            hours,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri webUri = Uri.parse(url);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live chat coming soon!')),
    );
  }
}
