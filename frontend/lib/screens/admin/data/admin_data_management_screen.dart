import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_config.dart';
import '../../../routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../../../core/widgets/realtime_indicator.dart';
import '../widgets/admin_layout.dart';
import 'data_export_import_screen.dart';

/// 📊 Admin Data Management Screen
/// Central hub for managing all data collections in the system
class AdminDataManagementScreen extends StatefulWidget {
  const AdminDataManagementScreen({super.key});

  @override
  State<AdminDataManagementScreen> createState() => _AdminDataManagementScreenState();
}

class _AdminDataManagementScreenState extends State<AdminDataManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDataStats();
  }

  Future<void> _loadDataStats() async {
    setState(() => _isLoading = true);
    try {
      // Load comprehensive stats from admin stats endpoint
      final response = await _apiService.get(AppConfig.adminDashboardEndpoint);

      if (response.isSuccess && response.data != null) {
        final statsData = response.data;

        setState(() {
          _stats = {
            'users': {'count': statsData['totalUsers'] ?? 0},
            'products': {'count': statsData['totalProducts'] ?? 0},
            'categories': {'count': 0}, // Categories count not available in current stats
            'orders': {'count': statsData['totalOrders'] ?? 0},
            'reviews': {'count': 0}, // Reviews count not available in current stats
            'rfqs': {'count': 0}, // RFQs count not available in current stats
            'messages': {'count': 0}, // Messages count not available in current stats
            'notifications': {'count': 0}, // Notifications count not available in current stats
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Data Management',
      currentIndex: 0, // Custom index for data management
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RealtimeDataRefresher(
              onRefresh: _loadDataStats,
              refreshMessage: 'Data statistics updated',
              child: RefreshIndicator(
                onRefresh: _loadDataStats,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildDataCollectionsGrid(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Management Hub',
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all system data collections',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard('Total Records',
                  '${_stats.values.fold<int>(0, (sum, stat) => sum + ((stat?['count'] ?? 0) as int))}'),
              const SizedBox(width: 16),
              _buildStatCard('Collections', '${_stats.length}'),
              const Spacer(),
              const RealtimeIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.h5.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCollectionsGrid() {
    final collections = [
      {
        'title': 'Users',
        'icon': Icons.people,
        'color': AppColors.primary,
        'route': AppRoutes.adminDataUsers,
        'stats': _stats['users'],
        'description': 'Manage user accounts and roles',
      },
      {
        'title': 'Products',
        'icon': Icons.inventory,
        'color': AppColors.secondary,
        'route': AppRoutes.adminDataProducts,
        'stats': _stats['products'],
        'description': 'Manage product catalog',
      },
      {
        'title': 'Categories',
        'icon': Icons.category,
        'color': AppColors.success,
        'route': AppRoutes.adminDataCategories,
        'stats': _stats['categories'],
        'description': 'Manage product categories',
      },
      {
        'title': 'Orders',
        'icon': Icons.receipt_long,
        'color': AppColors.warning,
        'route': AppRoutes.adminDataOrders,
        'stats': _stats['orders'],
        'description': 'Manage customer orders',
      },
      {
        'title': 'Reviews',
        'icon': Icons.star,
        'color': AppColors.info,
        'route': AppRoutes.adminDataReviews,
        'stats': _stats['reviews'],
        'description': 'Manage product reviews',
      },
      {
        'title': 'RFQs',
        'icon': Icons.assignment,
        'color': AppColors.primaryLight,
        'route': AppRoutes.adminDataRfqs,
        'stats': _stats['rfqs'],
        'description': 'Manage quote requests',
      },
      {
        'title': 'Messages',
        'icon': Icons.message,
        'color': AppColors.secondaryLight,
        'route': AppRoutes.adminDataMessages,
        'stats': _stats['messages'],
        'description': 'Manage conversations',
      },
      {
        'title': 'Notifications',
        'icon': Icons.notifications,
        'color': AppColors.error,
        'route': AppRoutes.adminDataNotifications,
        'stats': _stats['notifications'],
        'description': 'Manage system notifications',
      },
      {
        'title': 'Badges',
        'icon': Icons.badge,
        'color': AppColors.successLight,
        'route': AppRoutes.adminDataBadges,
        'stats': {'count': 0}, // Placeholder
        'description': 'Manage user badges',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Collections',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            return _buildCollectionCard(collection);
          },
        ),
      ],
    );
  }

  Widget _buildCollectionCard(Map<String, dynamic> collection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: collection['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  collection['icon'],
                  color: collection['color'],
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                '${collection['stats']?['count'] ?? 0}',
                style: AppTypography.labelLarge.copyWith(
                  color: collection['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            collection['title'],
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            collection['description'],
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, collection['route']),
              style: ElevatedButton.styleFrom(
                backgroundColor: collection['color'],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Manage'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Export Data',
                Icons.download,
                AppColors.primary,
                () => _exportData(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Import Data',
                Icons.upload,
                AppColors.secondary,
                () => _importData(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Backup',
                Icons.backup,
                AppColors.success,
                () => _createBackup(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).asGestureDetector(onTap: onTap);
  }

  void _exportData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DataExportImportScreen()),
    );
  }

  void _importData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DataExportImportScreen()),
    );
  }

  void _createBackup() {
    // TODO: Implement backup functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup functionality coming soon')),
    );
  }
}

extension GestureDetectorExtension on Widget {
  Widget asGestureDetector({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: this,
    );
  }
}