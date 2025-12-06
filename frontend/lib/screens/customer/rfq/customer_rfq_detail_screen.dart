import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widgets.dart';

import '../../../providers/rfq_provider.dart';
import '../../../models/rfq.dart';

/// 📋 Customer RFQ Detail Screen
/// Shows detailed view of a specific RFQ with quotes
class CustomerRFQDetailScreen extends StatefulWidget {
  final String rfqId;

  const CustomerRFQDetailScreen({super.key, required this.rfqId});

  @override
  State<CustomerRFQDetailScreen> createState() =>
      _CustomerRFQDetailScreenState();
}

class _CustomerRFQDetailScreenState extends State<CustomerRFQDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRFQDetails();
    });
  }

  Future<void> _loadRFQDetails() async {
    final provider = context.read<RFQProvider>();
    await provider.fetchRFQs();
  }

  void _shareRFQ(RFQ rfq) {
    final String shareText = '''
🏗️ INDU LINK RFQ Request

📋 RFQ #${rfq.rfqNumber}
📅 Created: ${DateFormat('MMM dd, yyyy').format(rfq.createdAt)}
📦 Items: ${rfq.items.length} item(s) requested

${rfq.items.map((item) => '• ${item.productSnapshot?['name'] ?? 'Product'} - Qty: ${item.quantity}').join('\n')}

${rfq.notes != null && rfq.notes!.isNotEmpty ? '\n📝 Notes: ${rfq.notes}' : ''}

Get competitive quotes from suppliers on INDU LINK!
Download the app: https://indulink.com/rfq/${rfq.id}
''';

    Share.share(shareText.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFQ Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<RFQProvider>(
            builder: (context, provider, child) {
              RFQ? rfq;
              try {
                rfq = provider.rfqs.firstWhere((r) => r.id == widget.rfqId);
              } catch (e) {
                rfq = null;
              }
              return IconButton(
                onPressed: rfq != null ? () => _shareRFQ(rfq!) : null,
                icon: const Icon(Icons.share),
              );
            },
          ),
        ],
      ),
      body: Consumer<RFQProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingSpinner());
          }

          if (provider.errorMessage != null) {
            return ErrorStateWidget(
              message: provider.errorMessage!,
              onRetry: _loadRFQDetails,
            );
          }

          RFQ? rfq;
          try {
            rfq = provider.rfqs.firstWhere((r) => r.id == widget.rfqId);
          } catch (e) {
            rfq = null;
          }

          if (rfq == null) {
            return const ErrorStateWidget(message: 'RFQ not found');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRFQHeader(rfq),
                const SizedBox(height: 16),
                _buildRFQItems(rfq),
                const SizedBox(height: 16),
                _buildDeliveryAddress(rfq),
                const SizedBox(height: 24),
                if (rfq.quotes.isNotEmpty) ...[
                  _buildQuotesSection(rfq),
                ] else ...[
                  _buildNoQuotesSection(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRFQHeader(RFQ rfq) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RFQ #${rfq.rfqNumber}',
                style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
              ),
              _buildStatusBadge(rfq.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created on ${DateFormat('MMM dd, yyyy • hh:mm a').format(rfq.createdAt)}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (rfq.notes != null && rfq.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes: ${rfq.notes}',
              style: AppTypography.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRFQItems(RFQ rfq) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requested Items',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rfq.items.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = rfq.items[index];
              return Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productSnapshot?['name'] ??
                              'Product #${item.productId.substring(0, 8)}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quantity: ${item.quantity}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (item.specifications != null &&
                            item.specifications!.isNotEmpty)
                          Text(
                            item.specifications!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress(RFQ rfq) {
    if (rfq.deliveryAddress == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Address',
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'No delivery address specified',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            rfq.deliveryAddress!.fullName,
            style:
                AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${rfq.deliveryAddress!.addressLine1}${rfq.deliveryAddress!.addressLine2 != null ? ', ${rfq.deliveryAddress!.addressLine2}' : ''}, ${rfq.deliveryAddress!.city}, ${rfq.deliveryAddress!.state} ${rfq.deliveryAddress!.postalCode}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rfq.deliveryAddress!.phone,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesSection(RFQ rfq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supplier Quotes',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rfq.quotes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final quote = rfq.quotes[index];
            return _buildQuoteCard(quote, rfq.id);
          },
        ),
      ],
    );
  }

  Widget _buildQuoteCard(Quote quote, String rfqId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Supplier #${quote.supplierId.substring(0, 8)}',
                style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
              ),
              _buildQuoteStatusBadge(quote.status),
            ],
          ),
          const SizedBox(height: 8),

          // Optional notes/details line (safe Text usage)
          if (quote.notes != null && quote.notes!.isNotEmpty)
            Text(
              quote.notes!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),

          const SizedBox(height: 16),
          if (quote.status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _acceptQuote(rfqId, quote.supplierId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                    ),
                    child: const Text('Accept Quote'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectQuote(rfqId, quote.supplierId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoQuotesSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for Quotes',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Suppliers are reviewing your RFQ. Quotes will appear here once submitted.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // Replace deprecated withOpacity
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayStatus,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuoteStatusBadge(String status) {
    Color color;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'pending':
        color = AppColors.warning;
        displayStatus = 'Awaiting Response';
        break;
      case 'accepted':
        color = AppColors.success;
        displayStatus = 'Accepted';
        break;
      case 'rejected':
        color = AppColors.error;
        displayStatus = 'Rejected';
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

  Future<void> _acceptQuote(String rfqId, String quoteId) async {
    final provider = context.read<RFQProvider>();
    final success = await provider.acceptQuote(rfqId: rfqId, quoteId: quoteId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote accepted successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to accept quote')),
      );
    }
  }

  Future<void> _rejectQuote(String rfqId, String quoteId) async {
    // TODO: Implement reject quote functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reject quote functionality coming soon')),
    );
  }
}
