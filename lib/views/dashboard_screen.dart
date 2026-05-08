import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/usage_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/usage_chart.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeFilter = 'day';

  @override
  Widget build(BuildContext context) {
    final usageProvider = Provider.of<UsageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    int totalUsage = 0;
    List dataForChart = [];
    String filterText = "";

    if (_activeFilter == 'day') {
      totalUsage = usageProvider.totalDailyUsage;
      dataForChart = usageProvider.dailyUsage;
      filterText = "خلال الـ 24 ساعة الماضية";
    } else if (_activeFilter == 'week') {
      totalUsage = usageProvider.totalWeeklyUsage;
      dataForChart = usageProvider.weeklyUsage;
      filterText = "خلال الـ 7 أيام الماضية";
    } else {
      totalUsage = usageProvider.totalMonthlyUsage;
      dataForChart = usageProvider.monthlyUsage;
      filterText = "خلال هذا الشهر";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("BaytiNet", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          )
        ],
      ),
      body: AnimationLimiter(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildFilterSelector(),
                  SizedBox(height: 24),
                  _buildUsageCard(totalUsage, filterText),
                  SizedBox(height: 32),
                  Text(
                    "الإحصائيات",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 250,
                    padding: EdgeInsets.only(top: 20, right: 10, left: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: UsageChart(data: dataForChart.cast(), filter: _activeFilter),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _filterButton("يوم", 'day'),
        _filterButton("أسبوع", 'week'),
        _filterButton("شهر", 'month'),
      ],
    );
  }

  Widget _filterButton(String label, String value) {
    bool isActive = _activeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {
        if (selected) setState(() => _activeFilter = value);
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(color: isActive ? Colors.white : null),
    );
  }

  Widget _buildUsageCard(int totalUsage, String subtitle) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withBlue(255)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "إجمالي الاستهلاك",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            FormatUtils.formatBytes(totalUsage),
            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
