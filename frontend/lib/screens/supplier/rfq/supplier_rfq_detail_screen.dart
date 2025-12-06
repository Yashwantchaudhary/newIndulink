import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widgets.dart';
import '../../../services/api_service.dart';

/// 📝 Supplier RFQ Detail & Quote Screen
/// Shows RFQ details and allows supplier to submit a quote
class SupplierRFQDetailScreen extends StatefulWidget {
  final String rfqId;

  const SupplierRFQDetailScreen({super.key, required this.rfqId});

  @override
  State<SupplierRFQDetailScreen> createState() =>
      _SupplierRFQDetailScreenState();
}

class _SupplierRFQDetailScreenState extends State<SupplierRFQDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _rfq;
  bool _submitting = false;

  final _quoteController = TextEditingController();
  final _notesController = TextEditingController();
  final _validityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRFQ();
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _notesController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  Future<void> _loadRFQ() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endpoint = '${AppConfig.rfqEndpoint}/${widget.rfqId}';
      final response = await _apiService.get(endpoint);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _rfq = response.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load RFQ';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitQuote() async {
    if (_quoteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quote amount')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final endpoint = '${AppConfig.rfqEndpoint}/${widget.rfqId}/quote';
      // Based on typical backend expectation:
      final data = {
        'price': double.tryParse(_quoteController.text) ?? 0,
        'notes': _notesController.text,
        'validUntil': _validityController
            .text, // Optional handled by backend? or standard
      };

      final response = await _apiService.post(endpoint, body: data);

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quote submitted successfully!')),
          );
          Navigator.pop(context); // Go back to list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response.message ?? 'Failed to submit quote')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: LoadingSpinner()));

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RFQ Details')),
        body: ErrorStateWidget(message: _error!, onRetry: _loadRFQ),
      );
    }

    if (_rfq == null)
      return const Scaffold(body: Center(child: Text('RFQ not found')));

    final rfq = _rfq!;
    final isPending = rfq['status'] == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text('RFQ #${rfq['rfqNumber'] ?? widget.rfqId.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(rfq),
            const SizedBox(height: 16),
            _buildItemsList(rfq),
            const SizedBox(height: 24),
            if (isPending) _buildQuoteForm(),
            if (!isPending)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('This RFQ is no longer accepting quotes.')),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> rfq) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: AppTypography.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                ),
                _buildStatusBadge(rfq['status']),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Posted on ${_formatDate(rfq['createdAt'] as String?)}',
              style: AppTypography.bodySmall,
            ),
            if (rfq['notes'] != null) ...[
              const SizedBox(height: 8),
              Text('Notes: ${rfq['notes']}', style: AppTypography.bodyMedium),
            ],
            // TODO: Hide buyer info until quote accepted? Or show basics?
            // Usually hidden in RFQ platforms until match.
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(Map<String, dynamic> rfq) {
    final items = rfq['items'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Requested Items',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            final productSnapshot =
                item['productSnapshot'] as Map<String, dynamic>?;

            return Card(
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.inventory_2),
                ),
                title: Text(productSnapshot?['name'] ?? 'Product'),
                subtitle: Text('Qty: ${item['quantity']}'),
                trailing: item['specifications'] != null
                    ? const Icon(Icons.info_outline)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuoteForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit Final Quote',
                style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _quoteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Price (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes / Terms',
                hintText: 'Includes shipping, valid for 7 days...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitQuote,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Quote'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        (status ?? 'Unknown').toUpperCase(),
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
