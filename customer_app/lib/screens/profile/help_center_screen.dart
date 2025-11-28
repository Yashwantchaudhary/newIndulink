import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';

/// Production-level Help Center Screen
class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: AppConstants.paddingAll16,
              child: SearchBarWidget(
                controller: _searchController,
                hintText: 'Search for help...',
                showVoiceIcon: false,
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Quick Actions',
                    icon: Icons.bolt,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Live Chat',
                          Icons.chat_bubble,
                          AppColors.primaryGradient,
                          () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Call Us',
                          Icons.phone,
                          AppColors.accentGradient,
                          () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Email',
                          Icons.email,
                          AppColors.secondaryGradient,
                          () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Submit Ticket',
                          Icons.confirmation_number,
                          AppColors.successGradient,
                          () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),

          // FAQ Sections
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(
                title: 'Frequently Asked Questions',
                icon: Icons.help_outline,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _buildCategoryChips(),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              ...getFaqsByCategory(_selectedCategory)
                  .map((faq) => _buildFaqItem(context, faq)),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return GradientCard(
      gradient: gradient,
      onTap: onTap,
      padding: AppConstants.paddingAll16,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Orders', 'Payments', 'Returns', 'Account'];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              selectedColor: AppColors.primaryBlue,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, _FaqItem faq) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: AppConstants.paddingAll16,
            child: Text(
              faq.answer,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  List<_FaqItem> getFaqsByCategory(String category) {
    final allFaqs = [
      _FaqItem(
        'Orders',
        'How do I track my order?',
        'You can track your order by going to My Orders section and clicking on the specific order. You will see real-time tracking information.',
      ),
      _FaqItem(
        'Orders',
        'Can I cancel my order?',
        'Yes, you can cancel your order before it is shipped. Go to Order Details and click Cancel Order button.',
      ),
      _FaqItem(
        'Payments',
        'What payment methods do you accept?',
        'We accept Credit/Debit Cards, UPI, Net Banking, and Cash on Delivery for eligible orders.',
      ),
      _FaqItem(
        'Payments',
        'Is my payment information secure?',
        'Yes, we use industry-standard encryption to protect all payment information. We do not store your card details.',
      ),
      _FaqItem(
        'Returns',
        'What is your return policy?',
        'We offer 7-day returns on most products. Items must be unused and in original packaging with tags attached.',
      ),
      _FaqItem(
        'Returns',
        'How do I initiate a return?',
        'Go to Order Details and click Return Items. Follow the instructions to complete your return request.',
      ),
      _FaqItem(
        'Account',
        'How do I reset my password?',
        'Click on Forgot Password on the login screen. Enter your email and we will send you a reset link.',
      ),
      _FaqItem(
        'Account',
        'How do I update my profile information?',
        'Go to Profile > Personal Information and update your details. Click Save to apply changes.',
      ),
    ];

    if (category == 'All') return allFaqs;
    return allFaqs.where((faq) => faq.category == category).toList();
  }
}

class _FaqItem {
  final String category;
  final String question;
  final String answer;

  _FaqItem(this.category, this.question, this.answer);
}
