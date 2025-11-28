import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  final List<Map<String, dynamic>> typingUsers;
  final String currentUserId;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
    required this.currentUserId,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _dot1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _dot2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeInOut),
      ),
    );

    _dot3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter out current user from typing users
    final otherTypingUsers = widget.typingUsers
        .where((user) => user['userId'] != widget.currentUserId)
        .toList();

    if (otherTypingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final typingUserNames =
        otherTypingUsers.map((user) => user['userId']).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated dots
          SizedBox(
            width: 40,
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(_dot1Animation),
                const SizedBox(width: 4),
                _buildDot(_dot2Animation),
                const SizedBox(width: 4),
                _buildDot(_dot3Animation),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Typing text
          Text(
            otherTypingUsers.length == 1
                ? 'Someone is typing...'
                : '$typingUserNames are typing...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primaryBlue,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -animation.value * 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
