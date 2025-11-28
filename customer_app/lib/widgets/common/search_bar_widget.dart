import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final VoidCallback? onTap;
  final VoidCallback? onVoiceSearch;
  final VoidCallback? onScan;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool showVoiceSearch;
  final bool showScanButton;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.hintText = 'Search products...',
    this.onTap,
    this.onVoiceSearch,
    this.onScan,
    this.onChanged,
    this.readOnly = false,
    this.showVoiceSearch = true,
    this.showScanButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.search_rounded,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),

          // Search input
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),

          // Voice search button
          if (showVoiceSearch)
            IconButton(
              icon: const Icon(
                Icons.mic_rounded,
                color: AppColors.primaryBlue,
              ),
              onPressed: onVoiceSearch,
            ),

          // Scan button
          if (showScanButton)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                ),
                onPressed: onScan,
              ),
            ),
        ],
      ),
    );
  }
}
