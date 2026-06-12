import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/shared/widgets/role_router.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _IntroPage(
      animation: 'assets/animations/walking.lottie',
      title: 'Set Your Route',
      subtitle: 'Pick your pickup and drop-off locations, then choose your vehicle type.',
    ),
    _IntroPage(
      animation: 'assets/animations/car_loading.lottie',
      title: 'We Find Your Ride',
      subtitle: 'Your request goes to our team. We assign the best available driver for you.',
    ),
    _IntroPage(
      animation: 'assets/animations/login.lottie',
      title: 'Driver Calls You',
      subtitle: 'The assigned driver will call you to confirm pickup details. Pay by cash — simple!',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RoleRouter(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToLogin,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 260,
                          child: DotLottieLoader.fromAsset(
                            page.animation,
                            frameBuilder: (ctx, dotlottie) {
                              if (dotlottie != null) {
                                return Lottie.memory(
                                  dotlottie.animations.values.single,
                                  fit: BoxFit.contain,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.accent.withValues(alpha: 0.6),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: i == _currentPage ? 24 : 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? AppTheme.accent
                              : AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage {
  const _IntroPage({
    required this.animation,
    required this.title,
    required this.subtitle,
  });

  final String animation;
  final String title;
  final String subtitle;
}
