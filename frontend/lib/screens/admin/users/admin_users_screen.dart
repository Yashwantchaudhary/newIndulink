import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_config.dart';
import '../../../services/api_service.dart';
import '../widgets/admin_layout.dart';

/// 👥 Admin Users Screen
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(AppConfig.adminUsersEndpoint);
      if (response.isSuccess && response.data != null) {
        setState(() {
          final dataMap = response.data as Map<String, dynamic>;
          // Backend returns {success, message, data: {data: [...], pagination: {...}}}
          final actualData = dataMap.containsKey('data')
              ? Map<String, dynamic>.from(dataMap['data'] as Map)
              : dataMap;
          _users = List<Map<String, dynamic>>.from(actualData['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_filter == 'all') return _users;
    return _users.where((u) => u['role'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Users',
      currentIndex: 1,
      child: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Customers', 'customer'),
                _buildFilterChip('Suppliers', 'supplier'),
                _buildFilterChip('Admins', 'admin'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserCard(user);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _filter = value),
        selectedColor: AppColors.primary,
        labelStyle:
            TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              (user['name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'User', style: AppTypography.labelLarge),
                Text(user['email'] ?? '',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoleColor(user['role']).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              user['role'] ?? 'customer',
              style: TextStyle(
                color: _getRoleColor(user['role']),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return AppColors.error;
      case 'supplier':
        return AppColors.primary;
      default:
        return AppColors.success;
    }
  }
}
