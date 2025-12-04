import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../services/cached_api_service.dart';

/// 🛜 Offline Indicator Widget
/// Shows connectivity status and sync progress
class OfflineIndicatorWidget extends StatefulWidget {
  final bool showText;
  final double size;

  const OfflineIndicatorWidget({
    super.key,
    this.showText = true,
    this.size = 16,
  });

  @override
  State<OfflineIndicatorWidget> createState() => _OfflineIndicatorWidgetState();
}

class _OfflineIndicatorWidgetState extends State<OfflineIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  CachedApiService? _cachedApiService;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Get cached API service instance
    _cachedApiService = CachedApiService();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedApiService == null || !_cachedApiService!.isInitialized) {
      return const SizedBox.shrink();
    }

    final isOnline = _cachedApiService!.isOnline;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOnline
                ? AppColors.success.withOpacity(0.1)
                : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOnline
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.warning.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.success : AppColors.warning,
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? AppColors.success : AppColors.warning)
                          .withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: _pulseController.value * 2,
                    ),
                  ],
                ),
                child: Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: widget.size * 0.6,
                ),
              ),

              if (widget.showText) ...[
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppTypography.bodySmall.copyWith(
                    color: isOnline ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 🔄 Sync Progress Indicator
/// Shows background sync progress
class SyncProgressIndicator extends StatefulWidget {
  final double size;

  const SyncProgressIndicator({
    super.key,
    this.size = 20,
  });

  @override
  State<SyncProgressIndicator> createState() => _SyncProgressIndicatorState();
}

class _SyncProgressIndicatorState extends State<SyncProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  CachedApiService? _cachedApiService;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _cachedApiService = CachedApiService();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedApiService == null || !_cachedApiService!.isInitialized) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * 3.14159,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Icon(
              Icons.sync,
              color: Colors.white,
              size: widget.size * 0.6,
            ),
          ),
        );
      },
    );
  }
}

/// 📊 Cache Status Widget
/// Shows cache statistics and management options
class CacheStatusWidget extends StatefulWidget {
  const CacheStatusWidget({super.key});

  @override
  State<CacheStatusWidget> createState() => _CacheStatusWidgetState();
}

class _CacheStatusWidgetState extends State<CacheStatusWidget> {
  CachedApiService? _cachedApiService;
  Map<String, dynamic>? _cacheStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cachedApiService = CachedApiService();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    if (_cachedApiService == null) return;

    setState(() => _isLoading = true);
    try {
      final stats = await _cachedApiService!.getCacheStats();
      setState(() => _cacheStats = stats);
    } catch (error) {
      debugPrint('Failed to load cache stats: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    if (_cachedApiService == null) return;

    setState(() => _isLoading = true);
    try {
      final cleared = await _cachedApiService!.clearAllCache();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleared $cleared cached items')),
      );
      await _loadCacheStats();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear cache')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedApiService == null || !_cachedApiService!.isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Cache Status',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _loadCacheStats,
                  icon: const Icon(Icons.refresh, size: 20),
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_cacheStats != null) ...[
            _buildStatRow('Status', _cacheStats!['online'] ? 'Online' : 'Offline'),
            _buildStatRow('Initialized', _cacheStats!['initialized'] ? 'Yes' : 'No'),

            if (_cacheStats!['cache'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cache Statistics:',
                style: AppTypography.bodySmall,
              ),
              _buildStatRow('Total Entries', _cacheStats!['cache']['total_entries']?.toString() ?? '0'),
              _buildStatRow('Total Size', _formatBytes(_cacheStats!['cache']['total_size'] ?? 0)),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _clearCache,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Clear All Cache'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ] else ...[
            const Text('Unable to load cache statistics'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}