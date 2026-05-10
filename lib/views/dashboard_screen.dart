import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/usage_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/usage_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "BaytiNet",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: themeProvider.isDarkMode ? ThemeProvider.primaryNeon : Colors.black87,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeProvider.primaryNeon.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 120, 20, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1200),
                      child: isWide
                          ? _buildWideLayout(totalUsage, filterText, dataForChart, usageProvider, themeProvider)
                          : _buildMobileLayout(totalUsage, filterText, dataForChart, usageProvider, themeProvider),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(int totalUsage, String filterText, List dataForChart, UsageProvider usageProvider, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUsageHeader(totalUsage, filterText),
        const SizedBox(height: 32),
        _buildSectionHeader("التحليلات"),
        const SizedBox(height: 20),
        _buildChartCard(dataForChart, themeProvider),
        const SizedBox(height: 32),
        _buildSectionHeader("نظرة عامة"),
        const SizedBox(height: 16),
        _buildSummaryGrid(usageProvider),
      ],
    );
  }

  Widget _buildWideLayout(int totalUsage, String filterText, List dataForChart, UsageProvider usageProvider, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUsageHeader(totalUsage, filterText),
                  const SizedBox(height: 32),
                  _buildSectionHeader("التحليلات"),
                  const SizedBox(height: 20),
                  _buildChartCard(dataForChart, themeProvider),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("نظرة عامة"),
                  const SizedBox(height: 16),
                  _buildSummaryGrid(usageProvider, crossAxisCount: 1),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (title == "التحليلات") _buildFilterSelector(),
      ],
    );
  }

  Widget _buildChartCard(List dataForChart, ThemeProvider themeProvider) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "مخطط الاستهلاك",
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8, bottom: 8),
              child: UsageChart(
                data: dataForChart.cast(),
                filter: _activeFilter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageHeader(int totalUsage, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ThemeProvider.primaryNeon, Color(0xFFA6CC00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: ThemeProvider.primaryNeon.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "إجمالي الاستهلاك",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            FormatUtils.formatBytes(totalUsage),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterTab("يوم", 'day'),
          _filterTab("أسبوع", 'week'),
          _filterTab("شهر", 'month'),
        ],
      ),
    );
  }

  Widget _filterTab(String label, String value) {
    bool isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ThemeProvider.primaryNeon : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(UsageProvider provider, {int crossAxisCount = 2}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.5,
      children: [
        _buildMiniCard("اليوم", FormatUtils.formatBytes(provider.totalDailyUsage), Icons.today_rounded, Colors.orange),
        _buildMiniCard("الأسبوع", FormatUtils.formatBytes(provider.totalWeeklyUsage), Icons.date_range_rounded, Colors.blue),
        _buildMiniCard("الشهر", FormatUtils.formatBytes(provider.totalMonthlyUsage), Icons.calendar_month_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildMiniCard(String title, String value, IconData icon, Color color) {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
