import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/usage_provider.dart';
import 'providers/theme_provider.dart';
import 'views/dashboard_screen.dart';
import 'views/permission_screen.dart';
import 'views/splash_screen.dart'; // استيراد شاشة البداية الجديدة
import 'services/native_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UsageProvider()),
      ],
      child: const BaytiNetApp(),
    ),
  );
}

class BaytiNetApp extends StatefulWidget {
  const BaytiNetApp({super.key});

  @override
  State<BaytiNetApp> createState() => _BaytiNetAppState();
}

class _BaytiNetAppState extends State<BaytiNetApp> {
  bool? _hasPermission;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    // Request location permission to fetch Wi-Fi SSID accurately
    await Permission.locationWhenInUse.request();

    bool hasPermission = await NativeService.hasUsagePermission();
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
      });
    }
    if (hasPermission) {
      NativeService.startForegroundService();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // نحدد الشاشة التالية المناسبة بناءً على الصلاحيات
    Widget getNextScreen() {
      if (_hasPermission == null) {
        return const Scaffold(
          backgroundColor: Color(0xFF0C0D12),
          body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
        );
      }
      return _hasPermission!
          ? const DashboardScreen()
          : PermissionScreen(
              onGranted: () {
                setState(() => _hasPermission = true);
                NativeService.startForegroundService();
              },
            );
    }

    return MaterialApp(
      title: 'BaytiNet',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      // نجعل الشاشة الافتتاحية هي أول شاشة تظهر للتطبيق
      home: SplashScreen(nextScreen: getNextScreen()),
    );
  }
}
