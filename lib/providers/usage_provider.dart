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
    final startOfHour = DateTime(now.year, now.month, now.day, now.hour);
    final endOfHour = now;

    final usage = await NativeService.getWifiUsage(
      startOfHour.millisecondsSinceEpoch,
      endOfHour.millisecondsSinceEpoch
    );

    final ssid = await NativeService.getSsid();

    await _dbHelper.insertUsage(UsageData(
      timestamp: now.millisecondsSinceEpoch,
      usageBytes: usage,
      ssid: ssid,
    ));

    // Cleanup old data (older than 2 months)
    final twoMonthsAgo = now.subtract(Duration(days: 60)).millisecondsSinceEpoch;
    await _dbHelper.deleteOldData(twoMonthsAgo);
  }

  Future<void> refreshData() async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final startOfDay = DateTime(now.year, now.month, now.day);
    final dayAgo = now.subtract(const Duration(hours: 24));
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Find the earliest start time to fetch all needed data in one query
    DateTime earliestStart = dayAgo;
    if (startOfWeek.isBefore(earliestStart)) earliestStart = startOfWeek;
    if (startOfMonth.isBefore(earliestStart)) earliestStart = startOfMonth;

    // Optimization: Parallelize native calls and database query
    final results = await Future.wait([
      NativeService.getWifiUsage(startOfDay.millisecondsSinceEpoch, nowMs),
      NativeService.getWifiUsage(startOfWeek.millisecondsSinceEpoch, nowMs),
      NativeService.getWifiUsage(startOfMonth.millisecondsSinceEpoch, nowMs),
      _dbHelper.getUsageInRange(earliestStart.millisecondsSinceEpoch, nowMs),
    ]);

    _totalDailyUsage = results[0] as int;
    _totalWeeklyUsage = results[1] as int;
    _totalMonthlyUsage = results[2] as int;
    final List<UsageData> allData = results[3] as List<UsageData>;

    // Optimization: Filter and aggregate in-memory instead of multiple DB queries
    final dayAgoMs = dayAgo.millisecondsSinceEpoch;
    final startOfWeekMs = startOfWeek.millisecondsSinceEpoch;
    final startOfMonthMs = startOfMonth.millisecondsSinceEpoch;

    _dailyUsage = [];
    _weeklyUsage = [];
    _monthlyUsage = [];
    _usageBySsid = {};

    for (var data in allData) {
      if (data.timestamp >= dayAgoMs) {
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

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
