import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/usage_provider.dart';
import '../providers/theme_provider.dart';
import '../models/usage_data.dart';
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
    List<UsageData> dataForChart = [];

    if (_activeFilter == 'day') {
      totalUsage = usageProvider.totalDailyUsage;
      dataForChart = usageProvider.dailyUsage;
    } else if (_activeFilter == 'week') {
      totalUsage = usageProvider.totalWeeklyUsage;
      dataForChart = usageProvider.weeklyUsage;
    } else {
      totalUsage = usageProvider.totalMonthlyUsage;
      dataForChart = usageProvider.monthlyUsage;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlowCircle(Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), 250),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: _buildGlowCircle(Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15), 300),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  "BaytiNet",
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: themeProvider.isDarkMode ? Theme.of(context).colorScheme.primary : Colors.black87,
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 800;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
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
                                          _buildUsageHeader(totalUsage),
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
                                    _buildUsageHeader(totalUsage),
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
                    );
                  },
                ),
              ),
            ],
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
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(ThemeProvider themeProvider, List<UsageData> dataForChart) {
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
                    data: dataForChart,
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

  Widget _buildUsageHeader(int totalUsage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).brightness == Brightness.dark ? const Color(0xFFA6CC00) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_tethering_rounded, color: Colors.black.withValues(alpha: 0.5), size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            "إجمالي الاستهلاك",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            FormatUtils.formatBytes(totalUsage),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 54,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
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
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              width: 2.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(UsageProvider provider, {required bool isWide}) {
    if (isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMiniCard("اليوم", FormatUtils.formatBytes(provider.totalDailyUsage), Icons.bolt_rounded, Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          _buildMiniCard("الأسبوع", FormatUtils.formatBytes(provider.totalWeeklyUsage), Icons.auto_graph_rounded, Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 20),
          _buildMiniCard("الشهر", FormatUtils.formatBytes(provider.totalMonthlyUsage), Icons.calendar_month_rounded, Theme.of(context).colorScheme.tertiary),
          const SizedBox(height: 20),
          _buildNetworksCard(provider),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMiniCard("اليوم", FormatUtils.formatBytes(provider.totalDailyUsage), Icons.bolt_rounded, Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMiniCard("الأسبوع", FormatUtils.formatBytes(provider.totalWeeklyUsage), Icons.auto_graph_rounded, Theme.of(context).colorScheme.secondary)),
              const SizedBox(width: 20),
              Expanded(child: _buildMiniCard("الشهر", FormatUtils.formatBytes(provider.totalMonthlyUsage), Icons.calendar_month_rounded, Theme.of(context).colorScheme.tertiary)),
            ],
          ),
          const SizedBox(height: 20),
          _buildNetworksCard(provider),
        ],
      );
    }
  }

  Widget _buildNetworksCard(UsageProvider provider) {
    final networks = provider.usageBySsid.entries.toList();
    final topNetworks = networks.take(3).toList();
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NetworksScreen()),
        );
      },
      child: _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.wifi_find_rounded, color: Colors.greenAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "الشبكات",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.withValues(alpha: 0.5), size: 14),
                ],
              ),
              const SizedBox(height: 20),
              if (networks.isEmpty)
                const Text("لا توجد شبكات مسجلة", style: TextStyle(color: Colors.grey))
              else
                ...topNetworks.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            FormatUtils.formatBytes(entry.value),
                            style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, fontSize: 16),
                          ),
                        ],
                      ),
                    )),
              if (networks.length > 3)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "عرض الكل (${networks.length})",
                      style: TextStyle(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 22,
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
