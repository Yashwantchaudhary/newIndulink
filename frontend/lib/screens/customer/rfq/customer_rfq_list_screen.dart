import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widgets.dart';

import '../../../models/rfq.dart';
import '../../../providers/rfq_provider.dart';

/// 📋 Customer RFQ List Screen
/// Displays all RFQs created by the customer
class CustomerRFQListScreen extends StatefulWidget {
  const CustomerRFQListScreen({super.key});

  @override
  State<CustomerRFQListScreen> createState() => _CustomerRFQListScreenState();
}

class _CustomerRFQListScreenState extends State<CustomerRFQListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load RFQs when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RFQProvider>().fetchRFQs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My RFQs'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Quoted'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRFQList('all'),
          _buildRFQList('pending'),
          _buildRFQList('quoted'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/customer/rfq/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRFQList(String filter) {
    return Consumer<RFQProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.rfqs.isEmpty) {
          return const Center(child: LoadingSpinner());
        }

        if (provider.errorMessage != null && provider.rfqs.isEmpty) {
          return ErrorStateWidget(
            message: provider.errorMessage!,
            onRetry: () => provider.fetchRFQs(),
          );
        }

        final rfqs = _getFilteredRFQs(provider, filter);

        if (rfqs.isEmpty) {
          return _buildEmptyState(filter);
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchRFQs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: rfqs.length,
            itemBuilder: (context, index) {
              return _buildRFQCard(rfqs[index]);
            },
          ),
        );
      },
    );
  }

  List<RFQ> _getFilteredRFQs(RFQProvider provider, String filter) {
    switch (filter) {
      case 'pending':
        return provider.pendingRFQs;
      case 'quoted':
        return provider.quotedRFQs;
      default:
        return provider.rfqs;
    }
  }

  Widget _buildEmptyState(String filter) {
    String title;
    String message;

    switch (filter) {
      case 'pending':
        title = 'No Pending RFQs';
        message = 'RFQs waiting for supplier quotes will appear here';
        break;
      case 'quoted':
        title = 'No Quoted RFQs';
        message = 'RFQs with supplier quotes will appear here';
        break;
      default:
        title = 'No RFQs Yet';
        message = 'Create your first RFQ to get quotes from suppliers';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRFQCard(RFQ rfq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/customer/rfq/detail',
          arguments: rfq.id,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RFQ #${rfq.rfqNumber}',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(rfq.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${rfq.items.length} item${rfq.items.length == 1 ? '' : 's'} requested',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created ${DateFormat('MMM dd, yyyy').format(rfq.createdAt)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (rfq.status == 'quoted') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${rfq.quotes.length ?? 0} quote${rfq.quotes.length == 1 ? '' : 's'} received',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'pending':
        color = AppColors.warning;
        displayStatus = 'Pending';
        break;
      case 'quoted':
        color = AppColors.success;
        displayStatus = 'Quoted';
        break;
      case 'accepted':
        color = AppColors.primary;
        displayStatus = 'Accepted';
        break;
      case 'rejected':
        color = AppColors.error;
        displayStatus = 'Rejected';
        break;
      case 'closed':
        color = AppColors.textSecondary;
        displayStatus = 'Closed';
        break;
      default:
        color = AppColors.textSecondary;
        displayStatus = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayStatus,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}