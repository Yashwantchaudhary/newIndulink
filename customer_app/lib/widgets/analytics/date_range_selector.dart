import 'package:flutter/material.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String selectedPreset;
  final Function(DateTime start, DateTime end, String preset) onRangeSelected;

  const DateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.selectedPreset,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PresetChip(
                label: 'Today',
                isSelected: selectedPreset == 'today',
                onTap: () => _selectPreset('today'),
              ),
              _PresetChip(
                label: 'Week',
                isSelected: selectedPreset == 'week',
                onTap: () => _selectPreset('week'),
              ),
              _PresetChip(
                label: 'Month',
                isSelected: selectedPreset == 'month',
                onTap: () => _selectPreset('month'),
              ),
              _PresetChip(
                label: 'Quarter',
                isSelected: selectedPreset == 'quarter',
                onTap: () => _selectPreset('quarter'),
              ),
              _PresetChip(
                label: 'Year',
                isSelected: selectedPreset == 'year',
                onTap: () => _selectPreset('year'),
              ),
              _PresetChip(
                label: 'Custom',
                isSelected: selectedPreset == 'custom',
                onTap: _showCustomDatePicker,
                icon: Icons.calendar_today,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Display selected range
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.date_range,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectPreset(String preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (preset) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'quarter':
        start = now.subtract(const Duration(days: 90));
        break;
      case 'year':
        start = now.subtract(const Duration(days: 365));
        break;
      default:
        start = now.subtract(const Duration(days: 30));
    }

    onRangeSelected(start, end, preset);
  }

  Future<void> _showCustomDatePicker() async {
    // This would open a date range picker dialog
    // For simplicity, we'll just select 'custom' preset for now
    onRangeSelected(startDate, endDate, 'custom');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey[100],
        selectedColor: theme.primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
