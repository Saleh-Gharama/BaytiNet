import 'package:flutter/material.dart';
import '../services/native_service.dart';

class PermissionScreen extends StatelessWidget {
  final VoidCallback onGranted;

  const PermissionScreen({super.key, required this.onGranted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 32),
            Text(
              "تحتاج BaytiNet إلى إذن الوصول إلى بيانات الاستخدام",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "هذا الإذن ضروري لكي يتمكن التطبيق من قراءة كمية استهلاك الواي فاي في هاتفك. لن نقوم بالوصول إلى أي بيانات شخصية.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {
                await NativeService.requestUsagePermission();
                // Check periodically or wait for return
                _checkPermission(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text("منح الإذن الآن"),
            ),
          ],
        ),
      ),
    );
  }

  void _checkPermission(BuildContext context) async {
    bool hasPermission = await NativeService.hasUsagePermission();
    if (hasPermission) {
      onGranted();
    } else {
      // Re-check after some delay or user action
      Future.delayed(Duration(seconds: 2), () => _checkPermission(context));
    }
  }
}
