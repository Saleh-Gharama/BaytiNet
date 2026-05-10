import 'package:flutter/material.dart';
import '../services/native_service.dart';
import '../providers/theme_provider.dart';

class PermissionScreen extends StatelessWidget {
  final VoidCallback onGranted;

  const PermissionScreen({super.key, required this.onGranted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              ThemeProvider.primaryNeon.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: ThemeProvider.primaryNeon.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  size: 80,
                  color: ThemeProvider.primaryNeon,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                "نحتاج إلى إذنك",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "لكي نتمكن من تتبع استهلاك الواي فاي وعرضه بشكل جميل، نحتاج إلى إذن الوصول إلى بيانات الاستخدام.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    await NativeService.requestUsagePermission();
                    _checkPermission(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeProvider.primaryNeon,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: ThemeProvider.primaryNeon.withOpacity(0.4),
                  ),
                  child: const Text(
                    "متابعة",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // Option to learn more or show a dialog
                },
                child: Text(
                  "لماذا نحتاج هذا الإذن؟",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkPermission(BuildContext context) async {
    bool hasPermission = await NativeService.hasUsagePermission();
    if (hasPermission) {
      onGranted();
    } else {
      Future.delayed(const Duration(seconds: 2), () => _checkPermission(context));
    }
  }
}
