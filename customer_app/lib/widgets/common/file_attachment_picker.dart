import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../services/file_upload_service.dart';

class FileAttachmentPicker extends StatefulWidget {
  final Function(List<File> files) onFilesSelected;
  final int maxFiles;
  final bool allowDocuments;
  final bool allowImages;
  final String title;

  const FileAttachmentPicker({
    super.key,
    required this.onFilesSelected,
    this.maxFiles = 3,
    this.allowDocuments = true,
    this.allowImages = true,
    this.title = 'Attach Files',
  });

  @override
  State<FileAttachmentPicker> createState() => _FileAttachmentPickerState();
}

class _FileAttachmentPickerState extends State<FileAttachmentPicker> {
  final List<File> _selectedFiles = [];
  final FileUploadService _fileService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Selected Files List
        if (_selectedFiles.isNotEmpty) ...[
          ..._selectedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return _buildFileCard(file, index, isDark, theme);
          }),
          const SizedBox(height: 12),
        ],

        // Add Files Button
        if (_selectedFiles.length < widget.maxFiles)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: AppConstants.borderRadiusMedium,
              color: AppColors.primaryBlue.withOpacity(0.05),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showFileOptions(context),
                borderRadius: AppConstants.borderRadiusMedium,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.attach_file,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Attachment (${_selectedFiles.length}/${widget.maxFiles})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Helper Text
        const SizedBox(height: 8),
        Text(
          'Supported: Images (JPG, PNG) & Documents (PDF, DOC, XLS). Max 10MB each.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.lightTextSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(File file, int index, bool isDark, ThemeData theme) {
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();
    final isImage = _fileService.isImage(file.path);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isImage
                  ? AppColors.primaryBlue.withOpacity(0.1)
                  : AppColors.accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isImage ? Icons.image : Icons.description,
              color: isImage ? AppColors.primaryBlue : AppColors.accentOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _fileService.getFileSize(fileSize),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Remove Button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => _removeFile(index),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  void _showFileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppConstants.paddingAll20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.allowImages) ...[
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primaryBlue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
            if (widget.allowDocuments) ...[
              ListTile(
                leading: const Icon(Icons.description, color: AppColors.accentOrange),
                title: const Text('Choose Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (!_fileService.isFileSizeValid(fileSize)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles.add(file);
        });
        widget.onFilesSelected(_selectedFiles);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (!_fileService.isFileSizeValid(fileSize)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles.add(file);
        });
        widget.onFilesSelected(_selectedFiles);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking document: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    widget.onFilesSelected(_selectedFiles);
  }
}
