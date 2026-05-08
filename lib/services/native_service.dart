import 'package:flutter/services.dart';
import 'dart:io';

class NativeService {
  static const platform = MethodChannel('com.example.baytinet/usage');

  static Future<int> getWifiUsage(int startTime, int endTime) async {
    if (!Platform.isAndroid) return 0;
    try {
      final int usage = await platform.invokeMethod('getWifiUsage', {
        'startTime': startTime,
        'endTime': endTime,
      });
      return usage;
    } on PlatformException catch (e) {
      print("Failed to get usage: '${e.message}'.");
      return 0;
    }
  }

  static Future<bool> hasUsagePermission() async {
    if (!Platform.isAndroid) return true; // Assume true or handle differently for non-Android
    try {
      final bool hasPermission = await platform.invokeMethod('hasUsagePermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print("Failed to check permission: '${e.message}'.");
      return false;
    }
  }

  static Future<void> requestUsagePermission() async {
    if (!Platform.isAndroid) return;
    try {
      await platform.invokeMethod('requestUsagePermission');
    } on PlatformException catch (e) {
      print("Failed to request permission: '${e.message}'.");
    }
  }

  static Future<void> startForegroundService() async {
    if (!Platform.isAndroid) return;
    try {
      await platform.invokeMethod('startForegroundService');
    } on PlatformException catch (e) {
      print("Failed to start foreground service: '${e.message}'.");
    }
  }
}

