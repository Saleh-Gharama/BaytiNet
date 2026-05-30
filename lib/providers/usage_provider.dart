import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/native_service.dart';
import '../services/database_helper.dart';
import '../models/usage_data.dart';

class UsageProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<UsageData> _dailyUsage = [];
  List<UsageData> _weeklyUsage = [];
  List<UsageData> _monthlyUsage = [];
  Map<String, int> _usageBySsid = {};

  int _totalDailyUsage = 0;
  int _totalWeeklyUsage = 0;
  int _totalMonthlyUsage = 0;

  List<UsageData> get dailyUsage => _dailyUsage;
  List<UsageData> get weeklyUsage => _weeklyUsage;
  List<UsageData> get monthlyUsage => _monthlyUsage;
  Map<String, int> get usageBySsid => _usageBySsid;

  int get totalDailyUsage => _totalDailyUsage;
  int get totalWeeklyUsage => _totalWeeklyUsage;
  int get totalMonthlyUsage => _totalMonthlyUsage;

  Timer? _timer;

  UsageProvider() {
    _init();
  }

  Future<void> _init() async {
    await collectAndStoreData();
    await refreshData();
    _startPeriodicTask();
  }

  void _startPeriodicTask() {
    _timer = Timer.periodic(Duration(minutes: 30), (timer) async {
      await collectAndStoreData();
      refreshData();
    });
  }

  Future<void> collectAndStoreData() async {
    final now = DateTime.now();
    final startOfCurrentHour = DateTime(now.year, now.month, now.day, now.hour);

    final lastRecordTimeMs = await _dbHelper.getLastUsageTimestamp();
    // If no records, start from 24 hours ago, otherwise start from the next hour after the last record
    final lastRecordTime = lastRecordTimeMs > 0 
        ? DateTime.fromMillisecondsSinceEpoch(lastRecordTimeMs) 
        : now.subtract(const Duration(hours: 24));
    
    DateTime currentCheckHour = DateTime(lastRecordTime.year, lastRecordTime.month, lastRecordTime.day, lastRecordTime.hour);
    if (lastRecordTimeMs > 0) {
      currentCheckHour = currentCheckHour.add(const Duration(hours: 1));
    }

    final ssid = await NativeService.getSsid();

    while (currentCheckHour.isBefore(startOfCurrentHour) || currentCheckHour.isAtSameMomentAs(startOfCurrentHour)) {
      final endOfCheckHour = currentCheckHour.isAtSameMomentAs(startOfCurrentHour) ? now : currentCheckHour.add(const Duration(hours: 1, milliseconds: -1));
      
      final usage = await NativeService.getWifiUsage(
        currentCheckHour.millisecondsSinceEpoch,
        endOfCheckHour.millisecondsSinceEpoch
      );

      await _dbHelper.insertUsage(UsageData(
        timestamp: endOfCheckHour.millisecondsSinceEpoch,
        usageBytes: usage,
        ssid: ssid,
      ));

      // Sync with daily summary table
      final dateStr = "${endOfCheckHour.year}-${endOfCheckHour.month.toString().padLeft(2, '0')}-${endOfCheckHour.day.toString().padLeft(2, '0')}";
      await _dbHelper.upsertDailySummary(dateStr, ssid, usage);
      
      currentCheckHour = currentCheckHour.add(const Duration(hours: 1));
    }

    // Cleanup old high-resolution hourly data (older than 2 months)
    final twoMonthsAgo = now.subtract(const Duration(days: 60)).millisecondsSinceEpoch;
    await _dbHelper.deleteOldData(twoMonthsAgo);
  }

  // Get historical daily data for a specific month (YYYY-MM)
  Future<List<Map<String, dynamic>>> getHistoryForMonth(String yearMonth) async {
    return await _dbHelper.getDailySummaryForMonth(yearMonth);
  }

  // Get historical daily data for a specific date range
  Future<List<Map<String, dynamic>>> getCustomRangeHistory(String startDate, String endDate) async {
    return await _dbHelper.getDailySummaryInRange(startDate, endDate);
  }

  // Get historical hourly data for a specific day
  Future<List<Map<String, dynamic>>> getHourlyHistoryForDay(String date) async {
    return await _dbHelper.getHourlySummaryForDay(date);
  }

  // Get list of months with usage and their totals
  Future<List<Map<String, dynamic>>> getHistoryMonths() async {
    return await _dbHelper.getMonthlyUsageHistory();
  }

  Future<void> refreshData() async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final startOfMonth = DateTime(now.year, now.month, 1);

    try {
      final startOfDayMs = startOfDay.millisecondsSinceEpoch;
      // Find the earliest start time to fetch all needed data in one query
      DateTime earliestStart = startOfDay;
      if (startOfWeek.isBefore(earliestStart)) earliestStart = startOfWeek;
      if (startOfMonth.isBefore(earliestStart)) earliestStart = startOfMonth;

      // Optimization: Parallelize native calls and database query
      final results = await Future.wait([
        NativeService.getWifiUsage(startOfDayMs, nowMs),
        NativeService.getWifiUsage(startOfWeek.millisecondsSinceEpoch, nowMs),
        NativeService.getWifiUsage(startOfMonth.millisecondsSinceEpoch, nowMs),
        _dbHelper.getUsageInRange(earliestStart.millisecondsSinceEpoch, nowMs),
      ]);

      _totalDailyUsage = results[0] as int;
      _totalWeeklyUsage = results[1] as int;
      _totalMonthlyUsage = results[2] as int;
      final List<UsageData> allData = results[3] as List<UsageData>;

      // Optimization: Filter and aggregate in-memory instead of multiple DB queries
      final startOfWeekMs = startOfWeek.millisecondsSinceEpoch;
      final startOfMonthMs = startOfMonth.millisecondsSinceEpoch;

      _dailyUsage = [];
      _weeklyUsage = [];
      _monthlyUsage = [];
      _usageBySsid = {};

      for (var data in allData) {
        if (data.timestamp >= startOfDayMs) {
          _dailyUsage.add(data);
        }
        if (data.timestamp >= startOfWeekMs) {
          _weeklyUsage.add(data);
        }
        if (data.timestamp >= startOfMonthMs) {
          _monthlyUsage.add(data);
          // Aggregate SSID usage for the month
          _usageBySsid[data.ssid] = (_usageBySsid[data.ssid] ?? 0) + data.usageBytes;
        }
      }

      // Sort SSID usage by volume (to match DB order)
      var sortedEntries = _usageBySsid.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _usageBySsid = Map.fromEntries(sortedEntries);
    } catch (e) {
      debugPrint("Error in refreshData: $e");
      // Optionally store the error in a variable to show in UI, but for now just prevent crashing
      // and maybe let's add a dummy value to dailyUsage so we know it hit the catch block
      _totalDailyUsage = -1; // -1 to indicate error visually
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
