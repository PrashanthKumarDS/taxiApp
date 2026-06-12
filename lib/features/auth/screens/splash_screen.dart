import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/features/auth/screens/intro_screen.dart';
import 'package:taxi_app/shared/widgets/role_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _navigate();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = 'v${info.version}');
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('seen_intro') ?? false;

    final Widget destination;
    if (!seenIntro) {
      await prefs.setBool('seen_intro', true);
      destination = const IntroScreen();
    } else {
      destination = const RoleRouter();
    }

    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 140,
                ),
                const SizedBox(height: 16),
                Text(
                  'MyTown Cabs',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: Text(
              _version,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.accent.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
