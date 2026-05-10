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
      return const Center(child: Text("لا توجد بيانات كافية لعرض الرسم البياني"));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.05),
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
              interval: 1,
              getTitlesWidget: (value, meta) {
                String text = '';
                if (filter == 'day') {
                  if (value.toInt() % 6 == 0) text = '${value.toInt()}س';
                } else if (filter == 'week') {
                  text = 'ي${value.toInt() + 1}';
                } else {
                  if (value.toInt() % 5 == 0) text = '${value.toInt()}';
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10)),
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
            gradient: const LinearGradient(
              colors: [ThemeProvider.primaryNeon, ThemeProvider.secondaryNeon],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  ThemeProvider.primaryNeon.withOpacity(0.2),
                  ThemeProvider.primaryNeon.withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxX() {
    if (filter == 'day') return 23;
    if (filter == 'week') return 6;
    return 30;
  }

  List<FlSpot> _getSpots() {
    if (data.isEmpty) return [];

    // Sort data by timestamp just in case
    final sortedData = List<UsageData>.from(data)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (filter == 'day') {
      // Map timestamps to hour of day (0-23)
      Map<int, double> hourUsage = {};
      for (var d in sortedData) {
        int hour = DateTime.fromMillisecondsSinceEpoch(d.timestamp).hour;
        hourUsage[hour] = (hourUsage[hour] ?? 0) + d.usageBytes.toDouble();
      }
      return List.generate(24, (i) => FlSpot(i.toDouble(), hourUsage[i] ?? 0));
    } else if (filter == 'week') {
      // Map to day of week (assuming data is for last 7 days)
      return List.generate(
        sortedData.length.clamp(0, 7),
        (i) => FlSpot(i.toDouble(), sortedData[i].usageBytes.toDouble()),
      );
    } else {
      return List.generate(
        sortedData.length,
        (i) => FlSpot(i.toDouble(), sortedData[i].usageBytes.toDouble()),
      );
    }
  }
}
