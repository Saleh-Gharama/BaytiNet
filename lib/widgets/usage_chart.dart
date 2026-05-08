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
    if (filter == 'day') {
      // Map to 12 points (every 2 hours)
      List<FlSpot> spots = [];
      for (int i = 0; i < 12; i++) {
        // Mocking logic or real logic to aggregate from data
        double val = 0;
        if (i < data.length) val = data[i].usageBytes.toDouble();
        spots.add(FlSpot(i.toDouble() * 2, val));
      }
      return spots;
    } else if (filter == 'week') {
      return List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].usageBytes.toDouble()));
    } else {
      // Month
      return List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].usageBytes.toDouble()));
    }
  }
}
