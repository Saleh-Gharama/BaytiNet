import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;

class NativeService {
  static const platform = MethodChannel('com.example.baytinet/usage');

  static bool get _isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  static Future<int> getWifiUsage(int startTime, int endTime) async {
    if (!_isAndroid) return 0;
    try {
      final int usage = await platform.invokeMethod('getWifiUsage', {
        'startTime': startTime,
        'endTime': endTime,
      });
      return usage;
    } on PlatformException catch (e) {
      debugPrint("Failed to get usage: '${e.message}'.");
      return 0;
    }
  }

  static Future<bool> hasUsagePermission() async {
    if (!_isAndroid) return true; // Assume true or handle differently for non-Android
    try {
      final bool hasPermission = await platform.invokeMethod('hasUsagePermission');
      return hasPermission;
    } on PlatformException catch (e) {
      debugPrint("Failed to check permission: '${e.message}'.");
      return false;
    }
  }

  static Future<void> requestUsagePermission() async {
    if (!_isAndroid) return;
    try {
      await platform.invokeMethod('requestUsagePermission');
    } on PlatformException catch (e) {
      debugPrint("Failed to request permission: '${e.message}'.");
    }
  }

  static Future<void> startForegroundService() async {
    if (!_isAndroid) return;
    try {
      await platform.invokeMethod('startForegroundService');
    } on PlatformException catch (e) {
      debugPrint("Failed to start foreground service: '${e.message}'.");
    }
  }
}

