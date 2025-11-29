import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Chart widgets for analytics and dashboards
/// Includes revenue charts, pie charts, and bar charts with animations

// ===== REVENUE LINE CHART =====
class RevenueChart extends StatefulWidget {
  final List<FlSpot> data;
  final String title;
  final Color? lineColor;
  final  double maxY;
  final List<String> bottomTitles;

  const RevenueChart({
    super.key,
    required this.data,
    required this.title,
    this.lineColor,
    required this.maxY,
    required this.bottomTitles,
  });

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.durationChart,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacing16),
          SizedBox(
            height: AppConstants.chartHeight,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: widget.maxY / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withOpacity(0.5),
                          strokeWidth: 1,
                          dashArray: [5, 5],
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
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < widget.bottomTitles.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  widget.bottomTitles[value.toInt()],
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: widget.maxY / 5,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '\$${_formatNumber(value)}',
                              style: theme.textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (widget.data.length - 1).toDouble(),
                    minY: 0,
                    maxY: widget.maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: widget.data
                            .map((spot) => FlSpot(
                                  spot.x,
                                  spot.y * _animation.value,
                                ))
                            .toList(),
                        isCurved: true,
                        color: widget.lineColor ?? AppColors.primaryBlue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor:
                                  widget.lineColor ?? AppColors.primaryBlue,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              (widget.lineColor ?? AppColors.primaryBlue)
                                  .withOpacity(0.3),
                              (widget.lineColor ?? AppColors.primaryBlue)
                                  .withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '\$${spot.y.toStringAsFixed(2)}',
                              theme.textTheme.bodySmall!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                  duration: AppConstants.durationNormal,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

// ===== CATEGORY PIE CHART =====
class CategoryPieChart extends StatefulWidget {
   final List<PieChartSectionData> data;
   final String title;

   const CategoryPieChart({
     super.key,
     required this.data,
     required this.title,
   });

   @override
   State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart>
    with SingleTickerProviderStateMixin {
   late AnimationController _controller;
   late Animation<double> _animation;
   int touchedIndex = -1;

   @override
   void initState() {
     super.initState();
     _controller = AnimationController(
       duration: AppConstants.durationChart,
       vsync: this,
     );
     _animation = Tween<double>(begin: 0, end: 1).animate(
       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
     );
     _controller.forward();
   }

   @override
   void dispose() {
     _controller.dispose();
     super.dispose();
   }

   @override
   Widget build(BuildContext context) {
     final theme = Theme.of(context);
     final isDark = theme.brightness == Brightness.dark;

     return Container(
       padding: AppConstants.paddingAll16,
       decoration: BoxDecoration(
         color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
         borderRadius: AppConstants.borderRadiusMedium,
         boxShadow: [
           BoxShadow(
             color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
             blurRadius: 8,
             offset: const Offset(0, 2),
           ),
         ],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             widget.title,
             style: theme.textTheme.titleMedium?.copyWith(
               fontWeight: FontWeight.bold,
             ),
           ),
           const SizedBox(height: AppConstants.spacing16),
           Row(
             children: [
               // Pie Chart
               Expanded(
                 child: AspectRatio(
                   aspectRatio: 1,
                   child: AnimatedBuilder(
                     animation: _animation,
                     builder: (context, child) {
                       return PieChart(
                         PieChartData(
                           sections: _buildSections(),
                           sectionsSpace: 2,
                           centerSpaceRadius: 40,
                           pieTouchData: PieTouchData(
                             touchCallback:
                                 (FlTouchEvent event, pieTouchResponse) {
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
                         ),
                       );
                     },
                   ),
                 ),
               ),
               const SizedBox(width: AppConstants.spacing16),
               // Legend
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: widget.data
                       .asMap()
                       .entries
                       .map(
                         (entry) => Padding(
                           padding: const EdgeInsets.only(
                               bottom: AppConstants.spacing8),
                           child: Row(
                             children: [
                               Container(
                                 width: 12,
                                 height: 12,
                                 decoration: BoxDecoration(
                                   color: entry.value.color,
                                   shape: BoxShape.circle,
                                 ),
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: Text(
                                   entry.value.title,
                                   style: theme.textTheme.bodySmall,
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis,
                                 ),
                               ),
                               Text(
                                 '${entry.value.value.toStringAsFixed(1)}%',
                                 style: theme.textTheme.bodySmall?.copyWith(
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                             ],
                           ),
                         ),
                       )
                       .toList(),
                 ),
               ),
             ],
           ),
         ],
       ),
     );
   }

   List<PieChartSectionData> _buildSections() {
     return widget.data.asMap().entries.map((entry) {
       final isTouched = entry.key == touchedIndex;
       final radius = isTouched ? 60.0 : 50.0;
       final fontSize = isTouched ? 16.0 : 12.0;

       return PieChartSectionData(
         color: entry.value.color,
         value: entry.value.value * _animation.value,
         title: '${(entry.value.value * _animation.value).toStringAsFixed(0)}%',
         radius: radius,
         titleStyle: TextStyle(
           fontSize: fontSize,
           fontWeight: FontWeight.bold,
           color: Colors.white,
         ),
       );
     }).toList();
   }
}

// ===== BAR CHART =====
class CustomBarChart extends StatefulWidget {
   final List<BarChartGroupData> data;
   final String title;
   final double maxY;

   const CustomBarChart({
     super.key,
     required this.data,
     required this.title,
     required this.maxY,
   });

   @override
   State<CustomBarChart> createState() => _CustomBarChartState();
}

class _CustomBarChartState extends State<CustomBarChart>
    with SingleTickerProviderStateMixin {
   late AnimationController _controller;
   late Animation<double> _animation;

   @override
   void initState() {
     super.initState();
     _controller = AnimationController(
       duration: AppConstants.durationChart,
       vsync: this,
     );
     _animation = Tween<double>(begin: 0, end: 1).animate(
       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
     );
     _controller.forward();
   }

   @override
   void dispose() {
     _controller.dispose();
     super.dispose();
   }

   @override
   Widget build(BuildContext context) {
     final theme = Theme.of(context);
     final isDark = theme.brightness == Brightness.dark;

     return Container(
       padding: AppConstants.paddingAll16,
       decoration: BoxDecoration(
         color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
         borderRadius: AppConstants.borderRadiusMedium,
         boxShadow: [
           BoxShadow(
             color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
             blurRadius: 8,
             offset: const Offset(0, 2),
           ),
         ],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             widget.title,
             style: theme.textTheme.titleMedium?.copyWith(
               fontWeight: FontWeight.bold,
             ),
           ),
           const SizedBox(height: AppConstants.spacing16),
           SizedBox(
             height: AppConstants.chartHeight,
             child: AnimatedBuilder(
               animation: _animation,
               builder: (context, child) {
                 return BarChart(
                   BarChartData(
                     maxY: widget.maxY,
                     barTouchData: BarTouchData(
                       touchTooltipData: BarTouchTooltipData(
                         getTooltipItem: (group, groupIndex, rod, rodIndex) {
                           return BarTooltipItem(
                             '${group.x}\n',
                             theme.textTheme.bodySmall!.copyWith(
                               color: Colors.white,
                               fontWeight: FontWeight.bold,
                             ),
                             children: [
                               TextSpan(
                                 text: rod.toY.toStringAsFixed(0),
                                 style: theme.textTheme.bodyMedium!.copyWith(
                                   color: Colors.white,
                                 ),
                               ),
                             ],
                           );
                         },
                       ),
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
                           getTitlesWidget: (value, meta) {
                             if (value.toInt() >= 0 &&
                                 value.toInt() < widget.data.length) {
                               return Padding(
                                 padding: const EdgeInsets.only(top: 8.0),
                                 child: Text(
                                   'Item ${value.toInt() + 1}',
                                   style: theme.textTheme.bodySmall,
                                 ),
                               );
                             }
                             return const Text('');
                           },
                         ),
                       ),
                       leftTitles: AxisTitles(
                         sideTitles: SideTitles(
                           showTitles: true,
                           reservedSize: 40,
                           getTitlesWidget: (value, meta) {
                             return Text(
                               value.toInt().toString(),
                               style: theme.textTheme.bodySmall,
                             );
                           },
                         ),
                       ),
                     ),
                     borderData: FlBorderData(show: false),
                     gridData: FlGridData(
                       show: true,
                       drawVerticalLine: false,
                       horizontalInterval: widget.maxY / 5,
                       getDrawingHorizontalLine: (value) {
                         return FlLine(
                           color: (isDark
                                   ? AppColors.darkBorder
                                   : AppColors.lightBorder)
                               .withOpacity(0.5),
                           strokeWidth: 1,
                           dashArray: [5, 5],
                         );
                       },
                     ),
                     barGroups: widget.data
                         .map(
                           (groupData) => BarChartGroupData(
                             x: groupData.x,
                             barRods: groupData.barRods
                                 .map(
                                   (rod) => BarChartRodData(
                                     toY: rod.toY * _animation.value,
                                     gradient: LinearGradient(
                                       colors: [
                                         rod.color ?? AppColors.primaryBlue,
                                         (rod.color ?? AppColors.primaryBlue).withOpacity(0.7),
                                       ],
                                       begin: Alignment.topCenter,
                                       end: Alignment.bottomCenter,
                                     ),
                                     width: 24,
                                     borderRadius: const BorderRadius.vertical(
                                       top: Radius.circular(6),
                                     ),
                                   ),
                                 )
                                 .toList(),
                           ),
                         )
                         .toList(),
                   ),
                 );
               },
             ),
           ),
         ],
       ),
     );
   }
}

