import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/dashboard_models.dart';

/// Pie chart widget for order status distribution
class OrderStatusChart extends StatefulWidget {
  final List<OrderStatusData> data;
  final bool showTitle;
  final double? size;

  const OrderStatusChart({
    super.key,
    required this.data,
    this.showTitle = true,
    this.size,
  });

  @override
  State<OrderStatusChart> createState() => _OrderStatusChartState();
}

class _OrderStatusChartState extends State<OrderStatusChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.data.isEmpty) {
      return Container(
        height: widget.size ?? AppConstants.pieChartSize,
        alignment: Alignment.center,
        child: Text(
          'No data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.lightTextTertiary,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: AppConstants.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle) ...[
              Text(
                'Orders by Status',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacing16),
            ],
            Row(
              children: [
                // Pie chart
                SizedBox(
                  width: widget.size ?? AppConstants.pieChartSize,
                  height: widget.size ?? AppConstants.pieChartSize,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildSections(),
                    ),
                    swapAnimationDuration: AppConstants.durationChart,
                    swapAnimationCurve: Curves.easeInOutCubic,
                  ),
                ),

                const SizedBox(width: AppConstants.spacing24),

                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.data
                        .asMap()
                        .entries
                        .map((entry) => _buildLegendItem(
                              entry.key,
                              entry.value,
                              theme,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total = widget.data.fold<int>(0, (sum, item) => sum + item.count);

    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 16.0 : 12.0;
      final percentage = (data.count / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: _getStatusColor(data.status),
        value: data.count.toDouble(),
        title: '$percentage%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  Widget _buildLegendItem(int index, OrderStatusData data, ThemeData theme) {
    final isTouched = index == touchedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _getStatusColor(data.status),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isTouched
                  ? [
                      BoxShadow(
                        color:
                            _getStatusColor(data.status).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatStatus(data.status),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            data.count.toString(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getStatusColor(data.status),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return AppColors.getStatusColor(status);
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
