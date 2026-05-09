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

  int _totalDailyUsage = 0;
  int _totalWeeklyUsage = 0;
  int _totalMonthlyUsage = 0;

  List<UsageData> get dailyUsage => _dailyUsage;
  List<UsageData> get weeklyUsage => _weeklyUsage;
  List<UsageData> get monthlyUsage => _monthlyUsage;

  int get totalDailyUsage => _totalDailyUsage;
  int get totalWeeklyUsage => _totalWeeklyUsage;
  int get totalMonthlyUsage => _totalMonthlyUsage;

  Timer? _timer;

  UsageProvider() {
    refreshData();
    _startPeriodicTask();
  }

  void _startPeriodicTask() {
    _timer = Timer.periodic(Duration(minutes: 5), (timer) async {
      await collectAndStoreData();
      refreshData();
    });
  }

  Future<void> collectAndStoreData() async {
    final now = DateTime.now();

    // Get the timestamp of the last recorded entry
    final lastUsage = await _dbHelper.getUsageInRange(
      now.subtract(Duration(minutes: 10)).millisecondsSinceEpoch,
      now.millisecondsSinceEpoch
    );

    int startTime;
    if (lastUsage.isNotEmpty) {
      startTime = lastUsage.last.timestamp + 1; // Start right after the last entry
    } else {
      startTime = now.subtract(Duration(minutes: 5)).millisecondsSinceEpoch;
    }

    final usage = await NativeService.getWifiUsage(
      startTime,
      now.millisecondsSinceEpoch
    );

    // Only insert if there's actual usage to keep DB clean
    if (usage > 0) {
      await _dbHelper.insertUsage(UsageData(
        timestamp: now.millisecondsSinceEpoch,
        usageBytes: usage
      ));
    }

    // Cleanup old data (older than 2 months)
    final twoMonthsAgo = now.subtract(Duration(days: 60)).millisecondsSinceEpoch;
    await _dbHelper.deleteOldData(twoMonthsAgo);
  }

  Future<void> refreshData() async {
    final now = DateTime.now();

    // Daily (Last 24 hours)
    final startOfDay = DateTime(now.year, now.month, now.day);
    _totalDailyUsage = await NativeService.getWifiUsage(
      startOfDay.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch
    );

    final dayAgo = now.subtract(Duration(hours: 24));
    _dailyUsage = await _dbHelper.getUsageInRange(
      dayAgo.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch
    );

    // Weekly (Last 7 days)
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6));
    _totalWeeklyUsage = await NativeService.getWifiUsage(
      startOfWeek.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch
    );

    _weeklyUsage = await _dbHelper.getUsageInRange(
      startOfWeek.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch
    );

    // Monthly (Current month)
    final startOfMonth = DateTime(now.year, now.month, 1);
    _totalMonthlyUsage = await NativeService.getWifiUsage(
      startOfMonth.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch
    );

    _monthlyUsage = await _dbHelper.getUsageInRange(
      startOfMonth.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
