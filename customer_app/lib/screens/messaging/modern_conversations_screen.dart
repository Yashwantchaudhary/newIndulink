import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indulink/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../providers/message_provider.dart';
import '../../models/message.dart';
import 'modern_chat_screen.dart';

/// Modern Conversations/Chats List Screen - Integrated with Real Data
class ModernConversationsScreen extends ConsumerStatefulWidget {
  const ModernConversationsScreen({super.key});

  @override
  ConsumerState<ModernConversationsScreen> createState() =>
      _ModernConversationsScreenState();
}

class _ModernConversationsScreenState
    extends ConsumerState<ModernConversationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load conversations on init
    Future.microtask(() {
      ref.read(messageProvider.notifier).getConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messageState = ref.watch(messageProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchBar(),
          ),
        ],
      ),
      body: messageState.isLoading && messageState.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildConversationsList(isDark, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildConversationsList(bool isDark, ThemeData theme) {
    final messageState = ref.watch(messageProvider);
    final conversations = messageState.conversations;

    if (conversations.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.chat_bubble_outline,
        title: 'No Conversations',
        message: 'Start a new conversation with suppliers or buyers',
        actionText: 'New Chat',
        onAction: _showNewChatDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(messageProvider.notifier).getConversations();
      },
      child: ListView.builder(
        padding: AppConstants.paddingAll16,
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          return _buildConversationCard(
            conversations[index],
            isDark,
            theme,
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(
    Conversation conversation,
    bool isDark,
    ThemeData theme,
  ) {
    final unreadCount = conversation.unreadCount?['count'] ?? 0;
    final hasUnread = unreadCount > 0;
    final lastMessage = conversation.lastMessage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: hasUnread
            ? LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.05),
                  AppColors.secondaryPurple.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: hasUnread
            ? null
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: hasUnread
              ? AppColors.primaryBlue.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: hasUnread ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openConversation(conversation),
          borderRadius: AppConstants.borderRadiusMedium,
          child: Padding(
            padding: AppConstants.paddingAll16,
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getAvatarColor(conversation.id),
                        _getAvatarColor(conversation.id).withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getAvatarColor(conversation.id)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      conversation.id.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Conversation ${conversation.id.substring(0, 8)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (lastMessage != null)
                            Text(
                              _getTimeLabel(lastMessage.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: hasUnread
                                    ? AppColors.primaryBlue
                                    : AppColors.lightTextSecondary,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage?.text ?? 'No messages yet',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: hasUnread
                                    ? theme.textTheme.bodyMedium?.color
                                    : AppColors.lightTextSecondary,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      AppColors.primaryBlue,
      AppColors.secondaryPurple,
      AppColors.accentOrange,
      AppColors.success,
      AppColors.statusProcessing,
    ];
    final index = userId.hashCode % colors.length;
    return colors[index.abs()];
  }

  String _getTimeLabel(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }

  Future<void> _openConversation(Conversation conversation) async {
    // Mark messages as read
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      await ref.read(messageProvider.notifier).markAsRead(conversation.id, userId);
    }

    // Navigate to chat screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModernChatScreen(
            conversationId: conversation.id,
          ),
        ),
      );
    }
  }

  void _showSearchBar() {
    showSearch(
      context: context,
      delegate: _ChatSearchDelegate(ref),
    );
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Recipient ID',
                hintText: 'Enter user ID',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New conversation feature coming soon'),
                ),
              );
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }
}

class _ChatSearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  _ChatSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Enter search term'));
    }

    // TODO: Implement search with API
    ref.read(messageProvider.notifier).searchConversations(query);

    return const Center(
      child: Text('Search results will appear here'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Start typing to search conversations'),
    );
  }
}
