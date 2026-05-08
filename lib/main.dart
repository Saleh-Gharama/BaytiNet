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
  @override
  _BaytiNetAppState createState() => _BaytiNetAppState();
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
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'BaytiNet',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF2196F3),
        brightness: Brightness.light,
        fontFamily: 'Cairo', // Assuming common Arabic font or default
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF2196F3),
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: _hasPermission!
          ? DashboardScreen()
          : PermissionScreen(onGranted: () {
              setState(() => _hasPermission = true);
              NativeService.startForegroundService();
            }),
    );
  }
}
