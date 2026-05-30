import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed dart:ui import
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';
import '../providers/usage_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format_utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedPeriod = 'week'; // 'day', 'week', 'month'
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  bool _isLoading = true;
  List<Map<String, dynamic>> _chartData = [];
  double _maxY = 10.0;
  int _totalUsageBytes = 0;

  @override
  void initState() {
    super.initState();
    // Start by loading data for the default period (week)
    _loadData();
  }

  void _updatePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      DateTime now = DateTime.now();
      if (period == 'day') {
        _startDate = now;
        _endDate = now;
      } else if (period == 'week') {
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
      } else if (period == 'month') {
        _startDate = now.subtract(const Duration(days: 29));
        _endDate = now;
      }
    });
    _loadData();
  }

  void _navigate(int direction) {
    // direction: -1 (past) or 1 (future)
    setState(() {
      int days = 1;
      if (_selectedPeriod == 'week') days = 7;
      if (_selectedPeriod == 'month') days = 30;

      _startDate = _startDate.add(Duration(days: days * direction));
      _endDate = _endDate.add(Duration(days: days * direction));
      
      // Ensure we don't go into the future
      if (_endDate.isAfter(DateTime.now())) {
        _endDate = DateTime.now();
        _startDate = _endDate.subtract(Duration(days: days == 1 ? 0 : days - 1));
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final usageProvider = Provider.of<UsageProvider>(context, listen: false);

    String startStr = intl.DateFormat('yyyy-MM-dd').format(_startDate);
    String endStr = intl.DateFormat('yyyy-MM-dd').format(_endDate);

    List<Map<String, dynamic>> finalData = [];
    double maxY = 0.0;
    int totalBytes = 0;

    if (startStr == endStr) {
      // Single day: load hourly data
      final rawData = await usageProvider.getHourlyHistoryForDay(startStr);
      Map<String, int> hourlyTotals = {};
      for (var row in rawData) {
        final hour = row['hour'] as String; // '00' to '23'
        final bytes = row['usageBytes'] as int;
        hourlyTotals[hour] = bytes;
      }
      
      for (int i = 0; i < 24; i++) {
        String hStr = i.toString().padLeft(2, '0');
        int bytes = hourlyTotals[hStr] ?? 0;
        double val = bytes / (1024 * 1024 * 1024);
        if (val > maxY) maxY = val;
        totalBytes += bytes;
        
        finalData.add({
          'label': hStr,
          'value': val,
          'bytes': bytes,
          'isHour': true,
        });
      }
    } else {
      // Multiple days: load daily data
      final rawData = await usageProvider.getCustomRangeHistory(startStr, endStr);
      Map<String, int> dailyTotals = {};
      for (var row in rawData) {
        final date = row['date'] as String;
        final bytes = row['usageBytes'] as int;
        dailyTotals[date] = (dailyTotals[date] ?? 0) + bytes;
      }

      DateTime current = _startDate;
      while (!current.isAfter(_endDate)) {
        String dStr = intl.DateFormat('yyyy-MM-dd').format(current);
        int bytes = dailyTotals[dStr] ?? 0;
        double val = bytes / (1024 * 1024 * 1024); // Convert to GB for chart display
        
        if (val > maxY) maxY = val;
        totalBytes += bytes;

        finalData.add({
          'label': dStr,
          'dateObj': current,
          'value': val,
          'bytes': bytes,
          'isHour': false,
        });
        current = current.add(const Duration(days: 1));
      }
    }

    // Set max Y dynamically based on the highest value so the chart scales properly
    if (maxY == 0) {
      maxY = 1.0; // Default max if there's no data
    } else {
      maxY = maxY * 1.3; // Give a 30% padding at the top
    }

    if (mounted) {
      setState(() {
        _chartData = finalData;
        _maxY = maxY;
        _totalUsageBytes = totalBytes;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: ThemeProvider.primaryNeon,
              onPrimary: Colors.black,
              surface: Theme.of(context).cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
        _selectedPeriod = ''; // Custom period
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("BaytiNet", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, left: 4, top: 6, bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.light_mode_rounded, size: 20, color: ThemeProvider.primaryNeon),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: 0,
            right: 0,
            child: _buildGlowCircle(ThemeProvider.primaryNeon.withValues(alpha: 0.15), 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildGlowCircle(Colors.cyanAccent.withValues(alpha: 0.1), 350),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildChartCard(),
                  const SizedBox(height: 24),
                  _buildPeriodCard(),
                ],
              ),
            ),
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
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131418), // Dark color from the design
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: ThemeProvider.primaryNeon.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Title & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Usage column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "إجمالي الاستهلاك",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FormatUtils.formatBytes(_totalUsageBytes),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: ThemeProvider.primaryNeon),
                  ),
                ],
              ),
              // Title column
              Row(
                children: [
                  const Text(
                    "سجل الاستهلاك",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.history_rounded, color: ThemeProvider.primaryNeon, size: 24),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          // Chart
          SizedBox(
            height: 250,
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: ThemeProvider.primaryNeon))
                : _buildLineChart(),
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          
          // Period Selector & Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavButton(Icons.arrow_back_ios_rounded, () => _navigate(-1)),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1C22),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildSegmentButton('شهر', 'month'),
                    _buildSegmentButton('أسبوع', 'week'),
                    _buildSegmentButton('يوم', 'day'),
                  ],
                ),
              ),
              _buildNavButton(Icons.arrow_forward_ios_rounded, () => _navigate(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _chartData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _chartData[i]['value'] as double));
    }

    if (spots.isEmpty) {
      return const Center(child: Text("لا توجد بيانات"));
    }
    
    // If only one day is selected (or returned), add a dummy point to draw a line
    if (spots.length == 1) {
      spots = [
        FlSpot(0, spots[0].y),
        FlSpot(1, spots[0].y),
      ];
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: _maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= _chartData.length) {
                  return const SizedBox();
                }
                final dataPoint = _chartData[value.toInt()];
                String label = '';
                
                if (dataPoint['isHour'] == true) {
                   int hour = int.parse(dataPoint['label']);
                   if (hour % 6 == 0) {
                     label = '$hour:00';
                   }
                } else {
                   final dateObj = dataPoint['dateObj'] as DateTime;
                   if (_selectedPeriod == 'week' || _chartData.length <= 7) {
                     label = intl.DateFormat('EEEE', 'ar').format(dateObj);
                   } else if (_selectedPeriod == 'month' || _chartData.length <= 31) {
                     if (dateObj.day % 5 == 0 || dateObj.day == 1) {
                       label = dateObj.day.toString();
                     }
                   } else {
                     if (dateObj.day == 1) {
                       label = intl.DateFormat('MMM', 'ar').format(dateObj);
                     }
                   }
                }
                
                return Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: ThemeProvider.primaryNeon,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  ThemeProvider.primaryNeon.withValues(alpha: 0.4),
                  Colors.cyanAccent.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final dataPoint = _chartData[touchedSpot.x.toInt()];
                final isHour = dataPoint['isHour'] == true;
                final label = isHour ? '${dataPoint['label']}:00' : dataPoint['label'];
                final bytes = dataPoint['bytes'] as int;
                return LineTooltipItem(
                  '$label\n${FormatUtils.formatBytes(bytes)}',
                  const TextStyle(color: ThemeProvider.primaryNeon, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String title, String value) {
    bool isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => _updatePeriod(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ThemeProvider.primaryNeon : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: ThemeProvider.primaryNeon, size: 18),
      ),
    );
  }

  Widget _buildPeriodCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131418),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: ThemeProvider.primaryNeon.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "الفترة الزمنية",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Icon(Icons.calendar_month_rounded, color: ThemeProvider.primaryNeon, size: 22),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  title: "من تاريخ",
                  date: _startDate,
                  onTap: () => _pickDate(context, true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("-", style: TextStyle(color: Colors.grey, fontSize: 24)),
              ),
              Expanded(
                child: _buildDateSelector(
                  title: "إلى تاريخ",
                  date: _endDate,
                  onTap: () => _pickDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeProvider.primaryNeon,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "تطبيق",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({required String title, required DateTime date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  intl.DateFormat('yyyy-MM-dd').format(date),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
