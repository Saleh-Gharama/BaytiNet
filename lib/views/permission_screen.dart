import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/native_service.dart';
import '../providers/theme_provider.dart';

class PermissionScreen extends StatelessWidget {
  final VoidCallback onGranted;

  const PermissionScreen({super.key, required this.onGranted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlowCircle(ThemeProvider.primaryNeon.withValues(alpha: 0.15), 400),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildGlowCircle(ThemeProvider.secondaryNeon.withValues(alpha: 0.1), 350),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildAnimatedIcon(),
                  const SizedBox(height: 60),
                  Text(
                    "نحتاج إلى إذنك",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 34,
                          letterSpacing: -1,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "لكي نتمكن من تتبع استهلاك الواي فاي وعرضه بشكل جميل، نحتاج إلى إذن الوصول إلى بيانات الاستخدام.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                          height: 1.6,
                        ),
                  ),
                  const Spacer(),
                  _buildGlassButton(
                    context: context,
                    label: "ابدأ الآن",
                    onPressed: () async {
                      await NativeService.requestUsagePermission();
                      if (!context.mounted) return;
                      _checkPermission(context);
                    },
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "لماذا نحتاج هذا الإذن؟",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            ThemeProvider.primaryNeon.withValues(alpha: 0.2),
            ThemeProvider.primaryNeon.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: ThemeProvider.primaryNeon.withValues(alpha: 0.2), width: 2),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeProvider.primaryNeon.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: ThemeProvider.primaryNeon.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ],
              ),
            ),
            const Icon(
              Icons.analytics_rounded,
              size: 70,
              color: ThemeProvider.primaryNeon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ThemeProvider.primaryNeon.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeProvider.primaryNeon,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  void _checkPermission(BuildContext context) async {
    bool hasPermission = await NativeService.hasUsagePermission();
    if (!context.mounted) return;
    if (hasPermission) {
      onGranted();
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) _checkPermission(context);
      });
    }
  }
}
