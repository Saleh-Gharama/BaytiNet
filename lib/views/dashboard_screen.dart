import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/usage_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/usage_chart.dart';
import 'networks_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
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
        title: Text(
          "BaytiNet",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
          // Background Glows
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlowCircle(ThemeProvider.primaryNeon.withValues(alpha: 0.2), 250),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: _buildGlowCircle(ThemeProvider.secondaryNeon.withValues(alpha: 0.15), 300),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 120, 20, 40),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildUsageHeader(totalUsage, filterText),
                                      const SizedBox(height: 32),
                                      _buildAnalyticsSection(themeProvider, dataForChart),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "نظرة عامة",
                                        style: Theme.of(context).textTheme.displayMedium,
                                      ),
                                      const SizedBox(height: 24),
                                      _buildSummaryGrid(usageProvider, isWide: true),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildUsageHeader(totalUsage, filterText),
                                const SizedBox(height: 32),
                                _buildAnalyticsSection(themeProvider, dataForChart),
                                const SizedBox(height: 32),
                                Text(
                                  "نظرة عامة",
                                  style: Theme.of(context).textTheme.displayMedium,
                                ),
                                const SizedBox(height: 16),
                                _buildSummaryGrid(usageProvider, isWide: false),
                              ],
                            ),
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

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildAnalyticsSection(ThemeProvider themeProvider, List dataForChart) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "التحليلات",
              style: Theme.of(context).textTheme.displayMedium,
            ),
            _buildFilterSelector(),
          ],
        ),
        const SizedBox(height: 20),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ThemeProvider.primaryNeon,
                        boxShadow: [
                          BoxShadow(color: ThemeProvider.primaryNeon, blurRadius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "مخطط الاستهلاك",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 280,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, left: 10, bottom: 10),
                  child: UsageChart(
                    data: dataForChart.cast(),
                    filter: _activeFilter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsageHeader(int totalUsage, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeProvider.primaryNeon,
            ThemeProvider.primaryNeon.withValues(alpha: 0.8),
            const Color(0xFFA6CC00),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: ThemeProvider.primaryNeon.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "إجمالي الاستهلاك",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.wifi_tethering_rounded, color: Colors.black.withValues(alpha: 0.4)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            FormatUtils.formatBytes(totalUsage),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? ThemeProvider.primaryNeon : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: ThemeProvider.primaryNeon.withValues(alpha: 0.3),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: ThemeProvider.primaryNeon.withValues(alpha: 0.15),
              width: 2.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(UsageProvider provider, {required bool isWide}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 1 : 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: isWide ? 2.5 : 1.3,
      children: [
        _buildMiniCard("اليوم", FormatUtils.formatBytes(provider.totalDailyUsage), Icons.bolt_rounded, ThemeProvider.primaryNeon),
        _buildMiniCard("الأسبوع", FormatUtils.formatBytes(provider.totalWeeklyUsage), Icons.auto_graph_rounded, ThemeProvider.secondaryNeon),
        _buildMiniCard("الشهر", FormatUtils.formatBytes(provider.totalMonthlyUsage), Icons.calendar_month_rounded, ThemeProvider.accentPink),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NetworksScreen()),
            );
          },
          child: _buildMiniCard("الشبكات", "${provider.usageBySsid.length}", Icons.wifi_find_rounded, Colors.greenAccent),
        ),
      ],
    );
  }

  Widget _buildMiniCard(String title, String value, IconData icon, Color color) {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
