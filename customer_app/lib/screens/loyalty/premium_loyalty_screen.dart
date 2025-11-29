import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';

/// Premium Loyalty & Rewards Screen - Gamification System
class PremiumLoyaltyScreen extends ConsumerStatefulWidget {
  const PremiumLoyaltyScreen({super.key});

  @override
  ConsumerState<PremiumLoyaltyScreen> createState() =>
      _PremiumLoyaltyScreenState();
}

class _PremiumLoyaltyScreenState extends ConsumerState<PremiumLoyaltyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pointsController;
  late Animation<double> _pointsAnimation;

  @override
  void initState() {
    super.initState();
    _pointsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pointsAnimation = Tween<double>(begin: 0, end: 2450).animate(
      CurvedAnimation(parent: _pointsController, curve: Curves.easeOutCubic),
    );
    _pointsController.forward();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Premium Gradient Header
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6B3FA0),
                      Color(0xFF9C3FE4),
                      Color(0xFFE91E63),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: AppConstants.paddingAll20,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Points Display with Animation
                        AnimatedBuilder(
                          animation: _pointsAnimation,
                          builder: (context, child) {
                            return Text(
                              '${_pointsAnimation.value.toInt()}',
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 20,
                                    color: Colors.black26,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Text(
                          'Loyalty Points',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tier Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber[300], size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Gold Member',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: AppConstants.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress to Next Tier
                  _buildTierProgress(theme, isDark),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const SectionHeader(title: 'Earn More Points', icon: Icons.add_circle),
                  const SizedBox(height: 12),
                  _buildQuickActions(isDark),
                  const SizedBox(height: 24),

                  // Achievements/Badges
                  const SectionHeader(title: 'Your Achievements', icon: Icons.emoji_events),
                  const SizedBox(height: 12),
                  _buildAchievements(isDark, theme),
                  const SizedBox(height: 24),

                  // Rewards Catalog
                  SectionHeader(
                    title: 'Redeem Rewards',
                    icon: Icons.card_giftcard,
                    actionText: 'View All',
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildRewardsCatalog(isDark, theme),
                  const SizedBox(height: 24),

                  // Points History
                  const SectionHeader(title: 'Recent Activity', icon: Icons.history),
                  const SizedBox(height: 12),
                  _buildPointsHistory(isDark, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgress(ThemeData theme, bool isDark) {
    const currentPoints = 2450;
    const nextTierPoints = 5000;
    const progress = currentPoints / nextTierPoints;

    return Container(
      padding: AppConstants.paddingAll20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.secondaryPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: AppConstants.borderRadiusLarge,
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to Platinum',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${((1 - progress) * nextTierPoints).toInt()} points to go',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMilestoneBadge('Gold', Icons.star, Colors.amber, true),
              _buildMilestoneBadge(
                  'Platinum', Icons.diamond, Colors.grey[300]!, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneBadge(
      String label, IconData icon, Color color, bool achieved) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: achieved ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: achieved ? color : Colors.grey,
              width: 2,
            ),
          ),
          child: Icon(icon, color: achieved ? color : Colors.grey, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: achieved ? color : Colors.grey,
            fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'icon': Icons.shopping_cart, 'label': 'Shop Now', 'points': '+10'},
      {'icon': Icons.share, 'label': 'Refer Friend', 'points': '+100'},
      {'icon': Icons.rate_review, 'label': 'Write Review', 'points': '+20'},
      {'icon': Icons.event, 'label': 'Daily Check-in', 'points': '+5'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withOpacity(0.1),
                AppColors.accentOrange.withOpacity(0.05),
              ],
            ),
            borderRadius: AppConstants.borderRadiusMedium,
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: AppConstants.borderRadiusMedium,
              child: Padding(
                padding: AppConstants.paddingAll12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: AppColors.primaryBlue,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      action['points'] as String,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievements(bool isDark, ThemeData theme) {
    final achievements = [
      {
        'icon': Icons.shopping_bag,
        'title': 'First Purchase',
        'subtitle': 'Made your first order',
        'earned': true,
        'color': AppColors.success,
      },
      {
        'icon': Icons.local_fire_department,
        'title': '7-Day Streak',
        'subtitle': 'Logged in for 7 days',
        'earned': true,
        'color': AppColors.accentOrange,
      },
      {
        'icon': Icons.people,
        'title': 'Social Butterfly',
        'subtitle': 'Referred 5 friends',
        'earned': true,
        'color': AppColors.secondaryPurple,
      },
      {
        'icon': Icons.star,
        'title': 'Super Reviewer',
        'subtitle': 'Write 10 reviews',
        'earned': false,
        'color': Colors.grey,
      },
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          final earned = achievement['earned'] as bool;
          final color = achievement['color'] as Color;

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppConstants.borderRadiusMedium,
              border: Border.all(
                color: earned ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: earned ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement['icon'] as IconData,
                    color: earned ? color : Colors.grey,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement['title'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: earned ? null : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['subtitle'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardsCatalog(bool isDark, ThemeData theme) {
    final rewards = [
      {'title': '10% Off Coupon', 'points': 500, 'icon': Icons.local_offer},
      {'title': 'Free Shipping', 'points': 200, 'icon': Icons.local_shipping},
      {'title': 'Rs 100 Voucher', 'points': 1000, 'icon': Icons.card_giftcard},
    ];

    return Column(
      children: rewards.map((reward) {
        final canRedeem = 2450 >= (reward['points'] as int);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: AppConstants.paddingAll16,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppConstants.borderRadiusMedium,
            border: Border.all(
              color: canRedeem
                  ? AppColors.success.withOpacity(0.3)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: canRedeem
                      ? AppColors.successGradient
                      : LinearGradient(colors: [Colors.grey, Colors.grey.shade400]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  reward['icon'] as IconData,
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
                      reward['title'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${reward['points']} points',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: canRedeem ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Redeem'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPointsHistory(bool isDark, ThemeData theme) {
    final history = [
      {'action': 'Purchase Order #1234', 'points': '+50', 'date': '2 hours ago'},
      {'action': 'Daily Check-in', 'points': '+5', 'date': 'Today'},
      {'action': 'Product Review', 'points': '+20', 'date': 'Yesterday'},
      {'action': 'Redeemed Coupon', 'points': '-500', 'date': '3 days ago'},
    ];

    return Column(
      children: history.map((item) {
        final isEarned = (item['points'] as String).startsWith('+');
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: AppConstants.paddingAll12,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppConstants.borderRadiusSmall,
          ),
          child: Row(
            children: [
              Icon(
                isEarned ? Icons.add_circle : Icons.remove_circle,
                color: isEarned ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['action'] as String,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      item['date'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item['points'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEarned ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
