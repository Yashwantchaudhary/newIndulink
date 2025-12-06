import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../../services/report_service.dart';

/// 📋 Report Dialog Widget
/// Allows users to report inappropriate content with reasons
class ReportDialog extends StatefulWidget {
  final String contentType; // 'review', 'product', 'user', etc.
  final String contentId;
  final String? contentTitle;

  const ReportDialog({
    super.key,
    required this.contentType,
    required this.contentId,
    this.contentTitle,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();

  static Future<bool?> show(
    BuildContext context, {
    required String contentType,
    required String contentId,
    String? contentTitle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        contentType: contentType,
        contentId: contentId,
        contentTitle: contentTitle,
      ),
    );
  }
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, String>> _reportReasons = [
    {'value': 'spam', 'label': 'Spam or misleading'},
    {'value': 'inappropriate', 'label': 'Inappropriate content'},
    {'value': 'harassment', 'label': 'Harassment or bullying'},
    {'value': 'offensive', 'label': 'Offensive language'},
    {'value': 'fake', 'label': 'Fake or scam'},
    {'value': 'copyright', 'label': 'Copyright violation'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.report_problem,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report ${widget.contentType}',
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.contentTitle != null)
                        Text(
                          widget.contentTitle!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space24),

            // Reason Selection
            Text(
              'Why are you reporting this?',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ..._reportReasons.map((reason) => _buildReasonOption(reason)),

            const SizedBox(height: AppDimensions.space24),

            // Additional Details
            Text(
              'Additional details (optional)',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Provide more details about your report...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: AppDimensions.space24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _selectedReason == null
                        ? null
                        : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption(Map<String, String> reason) {
    final isSelected = _selectedReason == reason['value'];
    return InkWell(
      onTap: () {
        setState(() => _selectedReason = reason['value']);
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          color: isSelected ? AppColors.primaryLightest : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason['label']!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Use ReportService to submit
      final success = await ReportService().submitReport(
        targetId: widget.contentId,
        targetType: widget.contentType,
        reason: _selectedReason!,
        description: _detailsController.text,
      );

      if (!success) {
        throw Exception('Server returned error');
      }

      // Simulate success
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Report submitted successfully. Thank you for helping keep our community safe.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
