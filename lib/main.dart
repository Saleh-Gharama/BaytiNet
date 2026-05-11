import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/usage_provider.dart';
import 'providers/theme_provider.dart';
import 'views/dashboard_screen.dart';
import 'views/permission_screen.dart';
import 'services/native_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UsageProvider()),
      ],
      child: BaytiNetApp(),
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
    bool hasPermission = await NativeService.hasUsagePermission();
    setState(() {
      _hasPermission = hasPermission;
    });
    if (hasPermission) {
      NativeService.startForegroundService();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_hasPermission == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeProvider.currentTheme,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
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
      home: _hasPermission!
          ? DashboardScreen()
          : PermissionScreen(
              onGranted: () {
                setState(() => _hasPermission = true);
                NativeService.startForegroundService();
              },
            ),
    );
  }
}
