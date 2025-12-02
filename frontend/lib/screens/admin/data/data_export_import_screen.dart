import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/export_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/admin_layout.dart';

/// 📊 Data Export/Import Screen
/// Comprehensive interface for data export and import operations
class DataExportImportScreen extends StatefulWidget {
  const DataExportImportScreen({super.key});

  @override
  State<DataExportImportScreen> createState() => _DataExportImportScreenState();
}

class _DataExportImportScreenState extends State<DataExportImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFormat = 'json';
  String _selectedCollection = 'products';
  bool _includeProfile = true;
  bool _includeOrders = true;
  bool _includeProducts = true;
  bool _includeMessages = true;
  bool _validateData = true;
  bool _skipDuplicates = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load supported formats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exportProvider = Provider.of<ExportProvider>(context, listen: false);
      exportProvider.loadSupportedFormats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final exportProvider = Provider.of<ExportProvider>(context);

    return AdminLayout(
      title: 'Data Export/Import',
      currentIndex: 0, // Custom index for export/import
      child: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textPrimary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.download_rounded),
                  text: 'Export',
                ),
                Tab(
                  icon: Icon(Icons.upload_rounded),
                  text: 'Import',
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Export Tab
                _buildExportTab(exportProvider, authProvider),

                // Import Tab
                _buildImportTab(exportProvider, authProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab(ExportProvider exportProvider, AuthProvider authProvider) {
    return RefreshIndicator(
      onRefresh: exportProvider.loadSupportedFormats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Data Export (GDPR)
            if (authProvider.isAuthenticated) ...[
              _buildSectionHeader('Personal Data Export (GDPR Compliant)'),
              _buildUserDataExportCard(exportProvider),
              const SizedBox(height: 24),
            ],

            // Collection Export
            _buildSectionHeader('Collection Data Export'),
            _buildCollectionExportCard(exportProvider),

            // Supported Formats
            if (exportProvider.supportedFormats != null) ...[
              const SizedBox(height: 24),
              _buildSupportedFormatsCard(exportProvider),
            ],

            // Export History (Admin only)
            if (authProvider.isAdmin) ...[
              const SizedBox(height: 24),
              _buildExportHistoryCard(exportProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImportTab(ExportProvider exportProvider, AuthProvider authProvider) {
    // Only admins can import data
    if (!authProvider.isAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Admin Access Required',
              style: AppTypography.h4.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Only administrators can import data',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Data Import'),
          _buildImportCard(exportProvider),

          if (exportProvider.supportedFormats != null) ...[
            const SizedBox(height: 24),
            _buildSupportedFormatsCard(exportProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.h5.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildUserDataExportCard(ExportProvider exportProvider) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                'Export My Data',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Format Selection
          _buildFormatSelector(),

          const SizedBox(height: 16),

          // Data Options
          _buildDataOptions(),

          const SizedBox(height: 20),

          // Export Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: exportProvider.isLoading
                  ? null
                  : () => _exportUserData(exportProvider),
              icon: const Icon(Icons.download),
              label: Text(
                exportProvider.isLoading ? 'Exporting...' : 'Export My Data',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Error Message
          if (exportProvider.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              exportProvider.errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollectionExportCard(ExportProvider exportProvider) {
    final collections = exportProvider.supportedFormats?['data']?['collections'] ?? [];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, color: AppColors.secondary),
              const SizedBox(width: 12),
              Text(
                'Export Collection Data',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Collection Selection
          DropdownButtonFormField<String>(
            value: _selectedCollection,
            decoration: const InputDecoration(
              labelText: 'Collection',
              border: OutlineInputBorder(),
            ),
            items: collections.map<DropdownMenuItem<String>>((collection) {
              return DropdownMenuItem<String>(
                value: collection,
                child: Text(collection),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCollection = value!);
            },
          ),

          const SizedBox(height: 16),

          // Format Selection
          _buildFormatSelector(),

          const SizedBox(height: 20),

          // Export Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: exportProvider.isLoading
                  ? null
                  : () => _exportCollection(exportProvider),
              icon: const Icon(Icons.download),
              label: Text(
                exportProvider.isLoading ? 'Exporting...' : 'Export Collection',
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.secondary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard(ExportProvider exportProvider) {
    final collections = exportProvider.supportedFormats?['data']?['collections'] ?? [];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file, color: AppColors.warning),
              const SizedBox(width: 12),
              Text(
                'Import Data',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Collection Selection
          DropdownButtonFormField<String>(
            value: _selectedCollection,
            decoration: const InputDecoration(
              labelText: 'Target Collection',
              border: OutlineInputBorder(),
            ),
            items: collections.map<DropdownMenuItem<String>>((collection) {
              return DropdownMenuItem<String>(
                value: collection,
                child: Text(collection),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCollection = value!);
            },
          ),

          const SizedBox(height: 16),

          // Import Options
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Validate Data'),
                  value: _validateData,
                  onChanged: (value) => setState(() => _validateData = value!),
                  dense: true,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Skip Duplicates'),
                  value: _skipDuplicates,
                  onChanged: (value) => setState(() => _skipDuplicates = value!),
                  dense: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Import Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: exportProvider.isLoading
                  ? null
                  : () => _importData(exportProvider),
              icon: const Icon(Icons.upload),
              label: Text(
                exportProvider.isLoading ? 'Importing...' : 'Select & Import File',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Error Message
          if (exportProvider.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              exportProvider.errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportedFormatsCard(ExportProvider exportProvider) {
    final formats = exportProvider.supportedFormats;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(width: 12),
              Text(
                'Supported Formats',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Export Formats
          _buildFormatList('Export Formats', formats?['export'] ?? []),

          const SizedBox(height: 16),

          // Import Formats
          _buildFormatList('Import Formats', formats?['import'] ?? []),

          const SizedBox(height: 16),

          // Collections
          Text(
            'Available Collections:',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: (formats?['collections'] ?? []).map<Widget>((collection) {
              return Chip(
                label: Text(collection),
                backgroundColor: AppColors.primaryLightest,
                labelStyle: TextStyle(color: AppColors.primary, fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExportHistoryCard(ExportProvider exportProvider) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                'Export History',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => exportProvider.loadExportHistory(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (exportProvider.exportHistory == null) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (exportProvider.exportHistory!['data'].isEmpty) ...[
            Center(
              child: Text(
                'No export history',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exportProvider.exportHistory!['data'].length,
              itemBuilder: (context, index) {
                final file = exportProvider.exportHistory!['data'][index];
                return ListTile(
                  leading: Icon(
                    _getFormatIcon(file['format']),
                    color: AppColors.primary,
                  ),
                  title: Text(file['filename']),
                  subtitle: Text(
                    'Size: ${_formatFileSize(file['size'])} • ${_formatDate(file['createdAt'])}',
                  ),
                  trailing: IconButton(
                    onPressed: () => _deleteExportFile(exportProvider, file['filename']),
                    icon: const Icon(Icons.delete, color: AppColors.error),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    final formats = ['json', 'csv', 'pdf'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Format',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: formats.map((format) {
            return Expanded(
              child: RadioListTile<String>(
                title: Text(format.toUpperCase()),
                value: format,
                groupValue: _selectedFormat,
                onChanged: (value) => setState(() => _selectedFormat = value!),
                dense: true,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Include Data',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Profile Information'),
          value: _includeProfile,
          onChanged: (value) => setState(() => _includeProfile = value!),
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Order History'),
          value: _includeOrders,
          onChanged: (value) => setState(() => _includeOrders = value!),
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Product Data'),
          value: _includeProducts,
          onChanged: (value) => setState(() => _includeProducts = value!),
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Messages'),
          value: _includeMessages,
          onChanged: (value) => setState(() => _includeMessages = value!),
          dense: true,
        ),
      ],
    );
  }

  Widget _buildFormatList(String title, List formats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: formats.map<Widget>((format) {
            return Chip(
              label: Text(format.toUpperCase()),
              backgroundColor: AppColors.successLight,
              labelStyle: TextStyle(color: AppColors.success, fontSize: 12),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Action Methods
  Future<void> _exportUserData(ExportProvider exportProvider) async {
    final success = await exportProvider.exportUserData(
      format: _selectedFormat,
      includeProfile: _includeProfile,
      includeOrders: _includeOrders,
      includeProducts: _includeProducts,
      includeMessages: _includeMessages,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported successfully')),
      );
    }
  }

  Future<void> _exportCollection(ExportProvider exportProvider) async {
    final success = await exportProvider.exportCollection(
      collection: _selectedCollection,
      format: _selectedFormat,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection exported successfully')),
      );
    }
  }

  Future<void> _importData(ExportProvider exportProvider) async {
    // Show dialog for JSON input
    final jsonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your JSON data below:'),
            const SizedBox(height: 16),
            TextField(
              controller: jsonController,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '[{"field": "value"}, ...]',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result == true && jsonController.text.isNotEmpty) {
      try {
        final importResult = await exportProvider.importFromJson(
          collection: _selectedCollection,
          jsonData: jsonController.text,
          validateData: _validateData,
          skipDuplicates: _skipDuplicates,
        );

        if (importResult != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Import completed: ${importResult['imported']} imported, ${importResult['skipped']} skipped',
              ),
            ),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $error')),
        );
      }
    }
  }

  Future<void> _deleteExportFile(ExportProvider exportProvider, String filename) async {
    final success = await exportProvider.deleteExportFile(filename);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export file deleted')),
      );
    }
  }

  // Helper Methods
  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'json':
        return Icons.data_object;
      case 'csv':
        return Icons.table_chart;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}