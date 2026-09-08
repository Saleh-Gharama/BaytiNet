import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/native_service.dart';
import '../services/database_helper.dart';
import '../models/usage_data.dart';
import '../models/wifi_session.dart';

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
  StreamSubscription? _networkSub;
  String? _currentSsid;

  UsageProvider() {
    _init();
  }

  Future<void> _init() async {
    _listenToNetworkChanges();
    await syncAndHandleCurrentNetwork();
    await collectAndStoreData();
    await refreshData();
    _startPeriodicTask();
  }

  void _listenToNetworkChanges() {
    _networkSub = NativeService.networkChangeStream.listen((ssid) async {
      await handleNetworkChange(ssid);
    }, onError: (e) {
      debugPrint("Network stream error: $e");
    });
  }

  Future<void> syncAndHandleCurrentNetwork() async {
    final currentSsid = await NativeService.getSsid();
    await handleNetworkChange(currentSsid);
  }

  Future<void> handleNetworkChange(String newSsid) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final activeSession = await _dbHelper.getActiveWifiSession();
    final isDisconnected = newSsid == 'DISCONNECTED' || newSsid.isEmpty;
    final isSpecialStatus = newSsid == 'إذن الموقع مطلوب';

    if (activeSession != null) {
      if (activeSession.ssid != newSsid || isDisconnected) {
        // Close previous session
        final usage = await NativeService.getWifiUsage(activeSession.startTime, now);
        await _dbHelper.closeWifiSession(activeSession.id!, now, usage);
        
        final dateStr = DateTime.fromMillisecondsSinceEpoch(now).toIso8601String().substring(0, 10);
        await _dbHelper.upsertDailySummary(dateStr, activeSession.ssid, usage);

        _currentSsid = null;
      } else {
        // Same network, update live bytes
        final liveUsage = await NativeService.getWifiUsage(activeSession.startTime, now);
        await _dbHelper.updateWifiSessionBytes(activeSession.id!, liveUsage);
        _currentSsid = newSsid;
        await refreshData();
        return;
      }
    }

    if (!isDisconnected && !isSpecialStatus && newSsid != _currentSsid) {
      // Start new session
      _currentSsid = newSsid;
      await _dbHelper.insertWifiSession(WifiSession(
        ssid: newSsid,
        startTime: now,
        bytesUsed: 0,
        isSynced: false,
      ));
    }

    await refreshData();
  }

  void _startPeriodicTask() {
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      await syncActiveSession();
      await collectAndStoreData();
      await refreshData();
    });
  }

  Future<void> syncActiveSession() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final activeSession = await _dbHelper.getActiveWifiSession();
    if (activeSession != null && activeSession.id != null) {
      final usage = await NativeService.getWifiUsage(activeSession.startTime, now);
      await _dbHelper.updateWifiSessionBytes(activeSession.id!, usage);
    }

    // Catch-up sync any past unsynced sessions
    final unsynced = await _dbHelper.getUnsyncedSessions();
    for (var session in unsynced) {
      if (session.id != null && session.endTime != null) {
        final usage = await NativeService.getWifiUsage(session.startTime, session.endTime!);
        await _dbHelper.closeWifiSession(session.id!, session.endTime!, usage);
      }
    }
  }

  Future<void> collectAndStoreData() async {
    final now = DateTime.now();
    final startOfCurrentHour = DateTime(now.year, now.month, now.day, now.hour);

    final lastRecordTimeMs = await _dbHelper.getLastUsageTimestamp();
    final lastRecordTime = lastRecordTimeMs > 0 
        ? DateTime.fromMillisecondsSinceEpoch(lastRecordTimeMs) 
        : now.subtract(const Duration(hours: 24));
    
    DateTime currentCheckHour = DateTime(lastRecordTime.year, lastRecordTime.month, lastRecordTime.day, lastRecordTime.hour);
    if (lastRecordTimeMs > 0) {
      currentCheckHour = currentCheckHour.add(const Duration(hours: 1));
    }

    final currentSsid = await NativeService.getSsid();

    while (currentCheckHour.isBefore(startOfCurrentHour) || currentCheckHour.isAtSameMomentAs(startOfCurrentHour)) {
      final endOfCheckHour = currentCheckHour.isAtSameMomentAs(startOfCurrentHour) ? now : currentCheckHour.add(const Duration(hours: 1, milliseconds: -1));
      
      final usage = await NativeService.getWifiUsage(
        currentCheckHour.millisecondsSinceEpoch,
        endOfCheckHour.millisecondsSinceEpoch
      );

      // Associate with session overlapping this hour if available
      final sessions = await _dbHelper.getSessionsInRange(
        currentCheckHour.millisecondsSinceEpoch,
        endOfCheckHour.millisecondsSinceEpoch,
      );
      final hourSsid = sessions.isNotEmpty ? sessions.last.ssid : currentSsid;

      await _dbHelper.insertUsage(UsageData(
        timestamp: endOfCheckHour.millisecondsSinceEpoch,
        usageBytes: usage,
        ssid: hourSsid,
      ));

      final dateStr = "${endOfCheckHour.year}-${endOfCheckHour.month.toString().padLeft(2, '0')}-${endOfCheckHour.day.toString().padLeft(2, '0')}";
      await _dbHelper.upsertDailySummary(dateStr, hourSsid, usage);
      
      currentCheckHour = currentCheckHour.add(const Duration(hours: 1));
    }

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
      DateTime earliestStart = startOfDay;
      if (startOfWeek.isBefore(earliestStart)) earliestStart = startOfWeek;
      if (startOfMonth.isBefore(earliestStart)) earliestStart = startOfMonth;

      final results = await Future.wait([
        NativeService.getWifiUsage(startOfDayMs, nowMs),
        NativeService.getWifiUsage(startOfWeek.millisecondsSinceEpoch, nowMs),
        NativeService.getWifiUsage(startOfMonth.millisecondsSinceEpoch, nowMs),
        _dbHelper.getUsageInRange(earliestStart.millisecondsSinceEpoch, nowMs),
        _dbHelper.getUsageBySsidFromSessionsInRange(startOfMonth.millisecondsSinceEpoch, nowMs),
      ]);

      _totalDailyUsage = results[0] as int;
      _totalWeeklyUsage = results[1] as int;
      _totalMonthlyUsage = results[2] as int;
      final List<UsageData> allData = results[3] as List<UsageData>;
      final Map<String, int> sessionSsidUsage = results[4] as Map<String, int>;

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
        }
      }

      // If we have accurate session-based tracking, use it for per-SSID breakdown
      if (sessionSsidUsage.isNotEmpty) {
        _usageBySsid = Map.from(sessionSsidUsage);
      } else {
        // Fallback to legacy hourly-aggregated SSID data
        for (var data in _monthlyUsage) {
          _usageBySsid[data.ssid] = (_usageBySsid[data.ssid] ?? 0) + data.usageBytes;
        }
      }

      var sortedEntries = _usageBySsid.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _usageBySsid = Map.fromEntries(sortedEntries);
    } catch (e) {
      debugPrint("Error in refreshData: $e");
      _totalDailyUsage = -1;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _networkSub?.cancel();
    super.dispose();
  }
}
