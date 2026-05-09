import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/usage_data.dart';
import '../utils/format_utils.dart';

class UsageChart extends StatelessWidget {
  final List<UsageData> data;
  final String filter; // 'day', 'week', 'month'

  const UsageChart({Key? key, required this.data, required this.filter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "لا توجد بيانات كافية لعرض الرسم البياني",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                String text = "";
                if (filter == 'day') {
                  if (value % 4 == 0) text = "${value.toInt()}س";
                } else if (filter == 'week') {
                  text = "ي${value.toInt() + 1}";
                } else {
                  if (value % 5 == 0) text = "${value.toInt()}";
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(text, style: TextStyle(color: Colors.white60, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.5)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueAccent.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final textStyle = TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                return LineTooltipItem(
                  FormatUtils.formatBytes(touchedSpot.y.toInt()),
                  textStyle,
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getSpots() {
    if (data.isEmpty) return [];

    if (filter == 'day') {
      List<double> buckets = List.filled(12, 0.0);
      final now = DateTime.now();
      final dayAgo = now.subtract(Duration(hours: 24));

      for (var entry in data) {
        final entryTime = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
        if (entryTime.isAfter(dayAgo)) {
          int hourDiff = now.difference(entryTime).inHours;
          int bucketIndex = 11 - (hourDiff ~/ 2);
          if (bucketIndex >= 0 && bucketIndex < 12) {
            buckets[bucketIndex] += entry.usageBytes.toDouble();
          }
        }
      }
      return List.generate(12, (i) => FlSpot(i.toDouble() * 2, buckets[i]));
    } else if (filter == 'week') {
      List<double> buckets = List.filled(7, 0.0);
      final now = DateTime.now();
      for (var entry in data) {
        final entryTime = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
        int dayDiff = now.difference(entryTime).inDays;
        int bucketIndex = 6 - dayDiff;
        if (bucketIndex >= 0 && bucketIndex < 7) {
          buckets[bucketIndex] += entry.usageBytes.toDouble();
        }
      }
      return List.generate(7, (i) => FlSpot(i.toDouble(), buckets[i]));
    } else {
      return List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].usageBytes.toDouble()));
    }
  }
}
