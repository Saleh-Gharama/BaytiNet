import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

    await _dbHelper.insertUsage(UsageData(
      timestamp: now.millisecondsSinceEpoch,
      usageBytes: usage
    ));

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
    _updateWidget();
  }

  Future<void> _updateWidget() async {
    const platform = MethodChannel('com.example.baytinet/usage');
    try {
      await platform.invokeMethod('updateWidget');
    } catch (e) {
      debugPrint("Failed to update widget: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
