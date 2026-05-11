import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/usage_data.dart';
import '../providers/theme_provider.dart';

class UsageChart extends StatelessWidget {
  final List<UsageData> data;
  final String filter; // 'day', 'week', 'month'

  const UsageChart({super.key, required this.data, required this.filter});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "لا توجد بيانات كافية لعرض الرسم البياني",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Theme.of(context).cardColor.withValues(alpha: 0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(1)} م.ب',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.03),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getBottomInterval(),
              getTitlesWidget: (value, meta) {
                String text = '';
                if (filter == 'day') {
                  text = '${value.toInt()}س';
                } else if (filter == 'week') {
                  text = 'ي${value.toInt() + 1}';
                } else {
                  text = '${value.toInt()}';
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: _getMaxX(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: true,
            curveSmoothness: 0.35,
            gradient: const LinearGradient(
              colors: [ThemeProvider.primaryNeon, ThemeProvider.secondaryNeon],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  ThemeProvider.primaryNeon.withValues(alpha: 0.3),
                  ThemeProvider.primaryNeon.withValues(alpha: 0.1),
                  ThemeProvider.primaryNeon.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            shadow: Shadow(
              color: ThemeProvider.primaryNeon.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  double _getBottomInterval() {
    if (filter == 'day') return 6;
    if (filter == 'week') return 1;
    return 5;
  }

  double _getMaxX() {
    if (filter == 'day') return 23;
    if (filter == 'week') return 6;
    return 30;
  }

  List<FlSpot> _getSpots() {
    if (data.isEmpty) return [const FlSpot(0, 0)];

    final sortedData = List<UsageData>.from(data)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (filter == 'day') {
      Map<int, double> hourUsage = {};
      for (var d in sortedData) {
        int hour = DateTime.fromMillisecondsSinceEpoch(d.timestamp).hour;
        // Convert to MB for visualization
        hourUsage[hour] = (hourUsage[hour] ?? 0) + (d.usageBytes / (1024 * 1024));
      }
      return List.generate(24, (i) => FlSpot(i.toDouble(), hourUsage[i] ?? 0));
    } else if (filter == 'week') {
      return List.generate(
        7,
        (i) {
          if (i < sortedData.length) {
            return FlSpot(i.toDouble(), sortedData[i].usageBytes / (1024 * 1024));
          }
          return FlSpot(i.toDouble(), 0);
        },
      );
    } else {
      return List.generate(
        31,
        (i) {
          if (i < sortedData.length) {
            return FlSpot(i.toDouble(), sortedData[i].usageBytes / (1024 * 1024));
          }
          return FlSpot(i.toDouble(), 0);
        },
      );
    }
  }
}
