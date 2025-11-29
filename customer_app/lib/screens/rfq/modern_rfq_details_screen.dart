import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../providers/rfq_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/rfq.dart';

/// Modern RFQ Details Screen with Quote Management
class ModernRFQDetailsScreen extends ConsumerStatefulWidget {
  final String rfqId;

  const ModernRFQDetailsScreen({
    super.key,
    required this.rfqId,
  });

  @override
  ConsumerState<ModernRFQDetailsScreen> createState() =>
      _ModernRFQDetailsScreenState();
}

class _ModernRFQDetailsScreenState
    extends ConsumerState<ModernRFQDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(rfqProvider.notifier).getRFQById(widget.rfqId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness ==Brightness.dark;
    final rfqState = ref.watch(rfqProvider);
    final authState = ref.watch(authProvider);
    final rfq = rfqState.selectedRFQ;

    if (rfqState.isLoading || rfq == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RFQ Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');
    final isBuyer = authState.user?.role == 'buyer';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('RFQ #${rfq.id.substring(0, 8)}'),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: AppConstants.paddingAll20,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusBadge(status: rfq.status, isSmall: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppConstants.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // RFQ Information Card
                  Card(
                    child: Padding(
                      padding: AppConstants.paddingAll16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description,
                                  color: AppColors.primaryBlue),
                              const SizedBox(width: 12),
                              Text(
                                'RFQ Information',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Description',
                            rfq.description ?? 'No description',
                            theme,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Quantity',
                            '${rfq.quantity}',
                            theme,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Ideal Price',
                            rfq.idealPrice != null ? '\$${rfq.idealPrice!.toStringAsFixed(2)}' : 'Not specified',
                            theme,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Delivery Date',
                            rfq.deliveryDate != null ? dateFormat.format(rfq.deliveryDate!) : 'Not specified',
                            theme,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Created',
                            dateFormat.format(rfq.createdAt),
                            theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Products Card
                  if (rfq.products.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: AppConstants.paddingAll16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.inventory_2,
                                    color: AppColors.primaryBlue),
                                const SizedBox(width: 12),
                                Text(
                                  'Products (${rfq.products.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...rfq.products.map((productId) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceVariant
                                          : AppColors.lightSurfaceVariant,
                                      borderRadius:
                                          AppConstants.borderRadiusSmall,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.shopping_bag,
                                            size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text('Product ID: $productId'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Quotes Section
                  Card(
                    child: Padding(
                      padding: AppConstants.paddingAll16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_offer,
                                      color: AppColors.success),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Quotes (${rfq.quotes.length})',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isBuyer && rfq.status == 'pending')
                                ElevatedButton.icon(
                                  onPressed: () => _showSubmitQuoteDialog(rfq),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Submit Quote'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (rfq.quotes.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: AppColors.lightTextTertiary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No quotes yet',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                        color: AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...rfq.quotes.map((quote) =>
                                _buildQuoteCard(quote, rfq, isBuyer, theme)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard(
      Quote quote, RFQ rfq, bool isBuyer, ThemeData theme) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isAccepted = quote.status == 'accepted';
    final isRejected = quote.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isAccepted
            ? AppColors.success.withValues(alpha: 0.1)
            : isRejected
                ? AppColors.error.withValues(alpha: 0.1)
                : null,
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(
          color: isAccepted
              ? AppColors.success
              : isRejected
                  ? AppColors.error
                  : AppColors.lightTextTertiary.withValues(alpha: 0.3),
          width: isAccepted || isRejected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.price != null ? '\$${quote.price!.toStringAsFixed(2)}' : 'Price not specified',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    quote.supplier != null ? 'Supplier ID: ${quote.supplier!.substring(0, 8)}...' : 'Supplier ID: Unknown',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              if (isAccepted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACCEPTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (isRejected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'REJECTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quote.description ?? 'No description provided',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 16, color: AppColors.lightTextSecondary),
              const SizedBox(width: 4),
              Text(
                'Delivery in ${quote.deliveryTime} days',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today,
                  size: 16, color: AppColors.lightTextSecondary),
              const SizedBox(width: 4),
              Text(
                quote.validUntil != null ? 'Valid until ${dateFormat.format(quote.validUntil!)}' : 'Validity not specified',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          if (isBuyer && !isAccepted && !isRejected && rfq.status != 'awarded')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Reject quote
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ref.read(rfqProvider.notifier).acceptQuote(
                                rfqId: rfq.id,
                                quoteId: quote.id!,
                              );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quote accepted successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showSubmitQuoteDialog(RFQ rfq) {
    final priceController = TextEditingController();
    final deliveryTimeController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightTextTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Submit Quote',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your Price',
                  hintText: 'Enter your quoted price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: deliveryTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Delivery Time (days)',
                  hintText: 'How many days for delivery?',
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Additional Details',
                  hintText: 'Any additional information about your quote',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedButton(
                text: 'Submit Quote',
                icon: Icons.send,
                onPressed: () async {
                  // Validate price
                  final price = double.tryParse(priceController.text);
                  if (priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Price is required'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  if (price == null || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid price greater than 0'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  // Validate delivery time
                  final deliveryTime = int.tryParse(deliveryTimeController.text);
                  if (deliveryTimeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery time is required'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  if (deliveryTime == null || deliveryTime < 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery time must be at least 1 day'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  if (deliveryTime > 365) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery time cannot exceed 365 days'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  // Validate description
                  if (descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Description is required'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  if (descriptionController.text.trim().length < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Description must be at least 10 characters long'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  if (descriptionController.text.trim().length > 1000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Description must be less than 1000 characters'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  try {
                    await ref.read(rfqProvider.notifier).submitQuote(
                          rfqId: rfq.id,
                          price: double.parse(priceController.text),
                          deliveryTime: int.parse(deliveryTimeController.text),
                          description: descriptionController.text,
                          validUntil:
                              DateTime.now().add(const Duration(days: 30)),
                        );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quote submitted successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                gradient: AppColors.primaryGradient,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
