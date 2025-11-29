import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../widgets/common/premium_widgets.dart';

/// Premium Supplier Notification Center - Send Push Notifications to Customers
class SupplierNotificationCenterScreen extends ConsumerStatefulWidget {
  const SupplierNotificationCenterScreen({super.key});

  @override
  ConsumerState<SupplierNotificationCenterScreen> createState() =>
      _SupplierNotificationCenterScreenState();
}

class _SupplierNotificationCenterScreenState
    extends ConsumerState<SupplierNotificationCenterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedAudience = 'All Customers';
  String _selectedType = 'Promotional';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1e3c72),
                        Color(0xFF2a5298),
                        Color(0xFF7e22ce),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_active,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Notification Center',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 28 : 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Send notifications to your customers',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                tabs: const [
                  Tab(text: 'Send New'),
                  Tab(text: 'Scheduled'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSendNewTab(isDark, theme, isTablet),
            _buildScheduledTab(isDark, theme, isTablet),
            _buildHistoryTab(isDark, theme, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildSendNewTab(bool isDark, ThemeData theme, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          _buildQuickStats(isDark, theme, isTablet),
          const SizedBox(height: 24),

          // Notification Form
          const SectionHeader(
            title: 'Compose Notification',
            icon: Icons.edit_notifications,
          ),
          const SizedBox(height: 16),

          // Audience Selector
          _buildAudienceSelector(isDark, theme, isTablet),
          const SizedBox(height: 16),

          // Notification Type
          _buildTypeSelector(isDark, theme, isTablet),
          const SizedBox(height: 16),

          // Title Input
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Notification Title',
              hintText: 'Enter a catchy title',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '${_titleController.text.length}/50',
            ),
            maxLength: 50,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Message Input
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'Message',
              hintText: 'Describe your offer or update...',
              prefixIcon: const Icon(Icons.message),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '${_messageController.text.length}/200',
            ),
            maxLines: 4,
            maxLength: 200,
            onChanged: (value) => setState(() {})),
          const SizedBox(height: 16),

          // Preview
          _buildPreview(isDark, theme, isTablet),
          const SizedBox(height: 24),

          // Send Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.schedule),
                  label: const Text('Schedule'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 16 : 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AnimatedButton(
                  text: 'Send Now',
                  icon: Icons.send,
                  onPressed: _sendNotification,
                  gradient: AppColors.primaryGradient,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, ThemeData theme, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isTablet ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isTablet ? 1.5 : 1.3,
          children: [
            _buildStatCard('Active Users', '2,450', Icons.people,
                AppColors.success, isDark),
            _buildStatCard('Sent Today', '12', Icons.send,
                AppColors.primaryBlue, isDark),
            _buildStatCard('Open Rate', '68%', Icons.mark_email_read,
                AppColors.accentOrange, isDark),
            _buildStatCard('Click Rate', '45%', Icons.touch_app,
                AppColors.secondaryPurple, isDark),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceSelector(bool isDark, ThemeData theme, bool isTablet) {
    final audiences = [
      'All Customers',
      'Active Buyers',
      'New Customers',
      'Inactive Users',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Audience', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: audiences.map((audience) {
            final isSelected = _selectedAudience == audience;
            return FilterChip(
              selected: isSelected,
              label: Text(audience),
              onSelected: (selected) {
                setState(() => _selectedAudience = audience);
              },
              selectedColor: AppColors.primaryBlue,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontSize: isTablet ? 14 : 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(bool isDark, ThemeData theme, bool isTablet) {
    final types = [
      {'name': 'Promotional', 'icon': Icons.local_offer, 'color': AppColors.accentOrange},
      {'name': 'Order Update', 'icon': Icons.shopping_bag, 'color': AppColors.primaryBlue},
      {'name': 'New Product', 'icon': Icons.new_releases, 'color': AppColors.success},
      {'name': 'Announcement', 'icon': Icons.campaign, 'color': AppColors.secondaryPurple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notification Type', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((type) {
                final isSelected = _selectedType == type['name'];
                return ChoiceChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : (type['color'] as Color),
                      ),
                      const SizedBox(width: 6),
                      Text(type['name'] as String),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedType = type['name'] as String);
                  },
                  selectedColor: type['color'] as Color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: isTablet ? 14 : 13,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreview(bool isDark, ThemeData theme, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.secondaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_android, size: 20),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Store Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'now',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _titleController.text.isEmpty
                      ? 'Your notification title appears here'
                      : _titleController.text,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _messageController.text.isEmpty
                      ? 'Your message will be displayed here. Keep it short and engaging!'
                      : _messageController.text,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledTab(bool isDark, ThemeData theme, bool isTablet) {
    return ListView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      children: const [
        EmptyStateWidget(
          icon: Icons.schedule_send,
          title: 'No Scheduled Notifications',
          message: 'Schedule notifications to send automatically',
        ),
      ],
    );
  }

  Widget _buildHistoryTab(bool isDark, ThemeData theme, bool isTablet) {
    final history = List.generate(
      10,
      (index) => {
        'title': 'Flash Sale: 50% Off Cement!',
        'message': 'Limited time offer on all cement products',
        'sent': DateTime.now().subtract(Duration(hours: index * 2)),
        'recipients': 2450 - (index * 100),
        'opened': (2450 - (index * 100)) * 0.68,
      },
    );

    return ListView.builder(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isTablet ? 16 : 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['title'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sent',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['message'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: isTablet ? 16 : 12,
                runSpacing: 8,
                children: [
                  _buildHistoryStat(Icons.people, '${item['recipients']} sent'),
                  _buildHistoryStat(Icons.mark_email_read,
                      '${(item['opened'] as double).toInt()} opened'),
                  _buildHistoryStat(
                    Icons.access_time,
                    _formatTime(item['sent'] as DateTime),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.lightTextSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _sendNotification() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and message'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // TODO: Implement actual push notification sending
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: Text(
          'Notification sent to $_selectedAudience\n\nTitle: ${_titleController.text}\nType: $_selectedType',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _titleController.clear();
              _messageController.clear();
              setState(() {});
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
