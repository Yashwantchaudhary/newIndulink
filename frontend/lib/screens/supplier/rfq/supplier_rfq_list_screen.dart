import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_config.dart';
import '../../../services/api_service.dart';
import 'supplier_rfq_detail_screen.dart';

/// 📋 Supplier RFQ List Screen
/// Allows suppliers to view and manage Request for Quotes
class SupplierRFQListScreen extends StatefulWidget {
  const SupplierRFQListScreen({super.key});

  @override
  State<SupplierRFQListScreen> createState() => _SupplierRFQListScreenState();
}

class _SupplierRFQListScreenState extends State<SupplierRFQListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _rfqs = [];
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadRFQs();
  }

  Future<void> _loadRFQs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(AppConfig.rfqEndpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data['data'] as List<dynamic>;
        setState(() {
          _rfqs = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load RFQs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading RFQs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredRFQs {
    if (_filterStatus == 'all') return _rfqs;
    return _rfqs.where((rfq) => rfq['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRFQs,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRFQs,
              child: _buildRFQList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'label': 'All', 'value': 'all', 'count': _rfqs.length},
      {
        'label': 'Open',
        'value': 'pending',
        'count': _rfqs.where((r) => r['status'] == 'pending').length
      },
      {
        'label': 'Quoted',
        'value': 'quoted',
        'count': _rfqs.where((r) => r['status'] == 'quoted').length
      },
      {
        'label': 'Awarded',
        'value': 'awarded',
        'count': _rfqs.where((r) => r['status'] == 'awarded').length
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
        vertical: 12,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _filterStatus == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  children: [
                    Text(filter['label'] as String),
                    const SizedBox(width: 4),
                    Text(
                      '${filter['count']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _filterStatus = filter['value'] as String);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRFQList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRFQs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredRFQs;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No RFQs found',
              style: AppTypography.h6.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildRFQCard(filtered[index]);
      },
    );
  }

  Widget _buildRFQCard(Map<String, dynamic> rfq) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SupplierRFQDetailScreen(rfqId: rfq['_id']),
            ),
          );
          _loadRFQs(); // Refresh after returning
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Request for ${rfq['quantity'] ?? 0} Items',
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(rfq['status'] ?? 'unknown'),
                ],
              ),
              const SizedBox(height: 8),
              if (rfq['description'] != null) ...[
                Text(
                  rfq['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (rfq['idealPrice'] != null)
                    Text(
                      'Target: ₹${rfq['idealPrice']}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    _formatDate(rfq['createdAt']),
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        break;
      case 'quoted':
        color = AppColors.info;
        break;
      case 'awarded':
        color = AppColors.success;
        break;
      case 'closed':
        color = AppColors.textSecondary;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }
}
