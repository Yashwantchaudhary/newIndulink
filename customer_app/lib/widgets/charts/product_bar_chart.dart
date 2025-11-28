import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';

class ProductBarChart extends StatelessWidget {
  final List<TopProduct> products;
  final Color barColor;

  const ProductBarChart({
    super.key,
    required this.products,
    this.barColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Take top 10 products
    final topProducts = products.take(10).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxRevenue(topProducts) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final product = topProducts[group.x.toInt()];
                return BarTooltipItem(
                  '${product.product.title}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: 'Revenue: \$${rod.toY.toStringAsFixed(0)}\n',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    TextSpan(
                      text: 'Units: ${product.totalQuantity}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < topProducts.length) {
                    final productName =
                        topProducts[value.toInt()].product.title;
                    final shortName = productName.length > 10
                        ? '${productName.substring(0, 10)}...'
                        : productName;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          shortName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxRevenue(topProducts) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          barGroups: topProducts.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.totalRevenue,
                  color: barColor,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: _getMaxRevenue(topProducts) * 1.2,
                    color: Colors.grey[200],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getMaxRevenue(List<TopProduct> products) {
    return products.map((e) => e.totalRevenue).reduce((a, b) => a > b ? a : b);
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}
