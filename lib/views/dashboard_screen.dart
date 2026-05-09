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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("BaytiNet", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () => themeProvider.toggleTheme(),
          )
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: themeProvider.isDarkMode
              ? [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]
              : [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.1),
                ),
              ),
            ),
            SafeArea(
              child: AnimationLimiter(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
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
                          _buildGlassCard(
                            child: Column(
                              children: [
                                Text(
                                  "إجمالي استهلاك الواي فاي",
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  FormatUtils.formatBytes(totalUsage),
                                  style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  filterText,
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),
                          Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                "إحصائيات الاستهلاك",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildGlassCard(
                            padding: EdgeInsets.only(top: 30, right: 10, left: 10, bottom: 10),
                            child: Container(
                              height: 250,
                              child: UsageChart(data: dataForChart.cast(), filter: _activeFilter),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterButton("يوم", 'day'),
          _filterButton("أسبوع", 'week'),
          _filterButton("شهر", 'month'),
        ],
      ),
    );
  }

  Widget _filterButton(String label, String value) {
    bool isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: padding ?? EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      ),
    );
  }
}
