import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import 'package:intl/intl.dart';

class SalesLineChart extends StatelessWidget {
  final List<TrendData> data;
  final Color lineColor;
  final bool showDots;

  const SalesLineChart({
    super.key,
    required this.data,
    this.lineColor = Colors.blue,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCurrency(value),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _calculateBottomInterval(),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _formatDate(data[value.toInt()].date),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxRevenue() * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.revenue,
                );
              }).toList(),
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = data[spot.x.toInt()].date;
                  final revenue = spot.y;
                  final orders = data[spot.x.toInt()].orders;

                  return LineTooltipItem(
                    '${_formatDateFull(date)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'Revenue: ${_formatCurrencyFull(revenue)}\n',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: 'Orders: $orders',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxRevenue() {
    return data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
  }

  double _calculateInterval() {
    final max = _getMaxRevenue();
    return max / 5;
  }

  double _calculateBottomInterval() {
    if (data.length <= 7) return 1;
    if (data.length <= 14) return 2;
    if (data.length <= 30) return 5;
    return 10;
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  String _formatCurrencyFull(double value) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(value);
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('MMM d').format(dateTime);
    } catch (e) {
      return date.split('-').last;
    }
  }

  String _formatDateFull(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }
}
