import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/websocket_provider.dart';
import '../constants/app_colors.dart';

/// 🌐 Real-time Update Indicator Widget
/// Shows connection status and real-time update notifications
class RealtimeIndicator extends StatelessWidget {
  final VoidCallback? onTap;

  const RealtimeIndicator({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        final isConnected = webSocketProvider.isConnected;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isConnected ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? 'Live' : 'Offline',
                  style: TextStyle(
                    color: isConnected ? AppColors.success : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 📊 Real-time Update Banner
/// Shows when data has been updated in real-time
class RealtimeUpdateBanner extends StatefulWidget {
  final String message;
  final Duration duration;

  const RealtimeUpdateBanner({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<RealtimeUpdateBanner> createState() => _RealtimeUpdateBannerState();
}

class _RealtimeUpdateBannerState extends State<RealtimeUpdateBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _controller.reverse(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 🔄 Real-time Data Refresher
/// Wraps content and shows refresh indicators
class RealtimeDataRefresher extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String refreshMessage;

  const RealtimeDataRefresher({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshMessage = 'Data refreshed',
  });

  @override
  State<RealtimeDataRefresher> createState() => _RealtimeDataRefresherState();
}

class _RealtimeDataRefresherState extends State<RealtimeDataRefresher> {
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    // Listen for real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webSocketProvider = Provider.of<WebSocketProvider>(context, listen: false);
      webSocketProvider.setCallbacks(
        onDataChanged: _handleDataChange,
        onUserDataChanged: _handleUserDataChange,
      );
    });
  }

  void _handleDataChange(Map<String, dynamic> data) {
    // Trigger refresh and show banner
    widget.onRefresh().then((_) {
      setState(() => _showBanner = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showBanner = false);
        }
      });
    });
  }

  void _handleUserDataChange(Map<String, dynamic> data) {
    // Trigger refresh and show banner
    widget.onRefresh().then((_) {
      setState(() => _showBanner = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showBanner = false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RealtimeUpdateBanner(message: widget.refreshMessage),
          ),
      ],
    );
  }
}