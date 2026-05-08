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
      return Center(child: Text("لا توجد بيانات كافية لعرض الرسم البياني"));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (filter == 'day') {
                  // Show every 4 hours if Day
                  if (value % 4 == 0) return Text("${value.toInt()}س");
                } else if (filter == 'week') {
                  // Show days
                  return Text("ي${value.toInt()}");
                }
                return const Text("");
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
            isCurved: filter == 'month',
            color: Theme.of(context).primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: filter != 'month'),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots() {
    if (data.isEmpty) return [];

    if (filter == 'day') {
      // Aggregate into 12 buckets of 2 hours each
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
      // Aggregate into 7 buckets (days)
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
      // Month: Use raw points but spread them out
      return List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].usageBytes.toDouble()));
    }
  }
}
