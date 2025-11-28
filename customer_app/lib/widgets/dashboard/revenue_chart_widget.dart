import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/dashboard_models.dart';

/// Interactive revenue line chart widget
class RevenueChartWidget extends StatefulWidget {
  final List<RevenueOverTime> data;
  final bool showTitle;
  final double? height;

  const RevenueChartWidget({
    super.key,
    required this.data,
    this.showTitle = true,
    this.height,
  });

  @override
  State<RevenueChartWidget> createState() => _RevenueChartWidgetState();
}

class _RevenueChartWidgetState extends State<RevenueChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.data.isEmpty) {
      return Container(
        height: widget.height ?? AppConstants.chartHeight,
        alignment: Alignment.center,
        child: Text(
          'No data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
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
                'Revenue Trend',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacing16),
            ],
            SizedBox(
              height: widget.height ?? AppConstants.chartHeight,
              child: LineChart(
                _buildChartData(isDark),
                duration: AppConstants.durationChart,
                curve: Curves.easeInOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(bool isDark) {
    final maxRevenue =
        widget.data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final minRevenue =
        widget.data.map((e) => e.revenue).reduce((a, b) => a < b ? a : b);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxRevenue - minRevenue) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.5),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (widget.data.length / 5).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.data.length) {
                return const Text('');
              }
              final date = DateTime.tryParse(widget.data[index].date);
              if (date == null) return const Text('');

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat('MMM dd').format(date),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: (maxRevenue - minRevenue) / 4,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatCurrency(value),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      minX: 0,
      maxX: (widget.data.length - 1).toDouble(),
      minY: minRevenue * 0.9,
      maxY: maxRevenue * 1.1,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= widget.data.length) {
                return null;
              }
              final dataPoint = widget.data[index];
              final date = DateTime.tryParse(dataPoint.date);

              return LineTooltipItem(
                '${date != null ? DateFormat('MMM dd').format(date) : 'N/A'}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: 'Rs ${dataPoint.revenue.toStringAsFixed(2)}\n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        '${dataPoint.orders} order${dataPoint.orders > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              const FlLine(
                color: AppColors.primaryBlue,
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: AppColors.primaryBlue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
      lineBarsData: [
        LineChartBarData(
          spots: widget.data
              .asMap()
              .entries
              .map((entry) => FlSpot(
                    entry.key.toDouble(),
                    entry.value.revenue,
                  ))
              .toList(),
          isCurved: true,
          gradient: AppColors.primaryGradient,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.primaryBlue,
                strokeWidth: 2,
                strokeColor: isDark ? AppColors.darkSurface : Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withValues(alpha: 0.2),
                AppColors.primaryBlue.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
