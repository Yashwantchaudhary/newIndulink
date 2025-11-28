import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class MessageReactions extends StatelessWidget {
  final Map<String, int> reactionCounts;
  final Map<String, String> userReactions;
  final String currentUserId;
  final String conversationId;
  final String messageId;
  final Function(String emoji) onReactionTap;

  const MessageReactions({
    super.key,
    required this.reactionCounts,
    required this.userReactions,
    required this.currentUserId,
    required this.conversationId,
    required this.messageId,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (reactionCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactionCounts.entries.map((entry) {
          final emoji = entry.key;
          final count = entry.value;
          final isUserReacted = userReactions[currentUserId] == emoji;

          return GestureDetector(
            onTap: () => onReactionTap(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUserReacted
                    ? AppColors.primaryBlue.withValues(alpha: 0.2)
                    : (isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUserReacted
                      ? AppColors.primaryBlue.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isUserReacted ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isUserReacted ? FontWeight.bold : FontWeight.normal,
                      color: isUserReacted
                          ? AppColors.primaryBlue
                          : (isDark
                              ? AppColors.lightTextSecondary
                              : AppColors.darkTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
  });

  static const List<String> commonEmojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '🎉',
    '🔥',
    '👏',
    '🙏',
    '💯',
    '✨',
    '💪',
    '🤔',
    '😅',
    '🥺',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text(
                'React to message',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Emoji grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: commonEmojis.length,
            itemBuilder: (context, index) {
              final emoji = commonEmojis[index];
              return GestureDetector(
                onTap: () {
                  onEmojiSelected(emoji);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
