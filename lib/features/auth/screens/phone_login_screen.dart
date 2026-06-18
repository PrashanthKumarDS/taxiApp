import 'dart:async';

import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/constants/feature_flags.dart';
import 'package:taxi_app/core/services/user_firestore_service.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/features/auth/screens/profile_setup_screen.dart';
import 'package:taxi_app/providers/auth_provider.dart';
import 'package:taxi_app/shared/widgets/primary_button.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpStep = false;
  int _resendCountdown = 0;
  int _otpExpiryCountdown = 0;
  Timer? _resendTimer;
  Timer? _otpExpiryTimer;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _resendTimer?.cancel();
    _otpExpiryTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 15;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  void _startOtpExpiryTimer() {
    _otpExpiryCountdown = 60;
    _otpExpiryTimer?.cancel();
    _otpExpiryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _otpExpiryCountdown--;
        if (_otpExpiryCountdown <= 0) {
          t.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SMS code expired. Please request a new one.'),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      });
    });
  }

  String _normalizePhone(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'\s'), '');
    // Already has +91
    if (s.startsWith('+91')) {
      if (s.length >= 13) return s; // +91 + 10 digits
      return s; // Return as is, let Firebase validate
    }
    // Has +
    if (s.startsWith('+')) return s;
    // Has 00 prefix
    if (s.startsWith('00')) return '+${s.substring(2)}';
    // Has 0 prefix (remove it and add +91)
    if (s.startsWith('0')) return '+91${s.substring(1)}';
    // Just 10 digits
    if (s.length == 10) return '+91$s';
    return '+91$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (FeatureFlags.phoneOtpEnabled) ...[
                    Expanded(
                      child: DotLottieLoader.fromAsset(
                        _otpStep
                            ? 'assets/animations/otp_verification.lottie'
                            : 'assets/animations/login.lottie',
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
                    const SizedBox(height: 16),
                    Text(
                      _otpStep
                          ? 'Enter the code we sent'
                          : 'Sign in with phone',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 24),
                    if (!_otpStep) ...[
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter 10-digit number',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('🇮🇳', style: TextStyle(fontSize: 20)),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'SMS code',
                          prefixIcon: Icon(Icons.sms_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Code expires in: ${_otpExpiryCountdown}s',
                        style: TextStyle(
                          fontSize: 12,
                          color: _otpExpiryCountdown < 30
                            ? Colors.redAccent
                            : AppTheme.accent.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        auth.errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (!_otpStep)
                      PrimaryButton(
                        label: 'Send code',
                        loading: auth.isBusy,
                        onPressed: () async {
                          final p = _normalizePhone(_phoneCtrl.text);
                          if (p.length < 13) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid 10-digit phone number'),
                              ),
                            );
                            return;
                          }
                          await auth.logout();
                          await auth.requestOtp(p);
                          if (!context.mounted) return;
                          if (auth.verificationId != null) {
                            _startResendTimer();
                            _startOtpExpiryTimer();
                            setState(() => _otpStep = true);
                          }
                        },
                      )
                    else ...[
                      PrimaryButton(
                        label: 'Verify & continue',
                        loading: auth.isBusy,
                        onPressed: _otpExpiryCountdown <= 0
                            ? null
                            : () async {
                          await auth.verifyOtp(_otpCtrl.text);
                          if (!context.mounted) return;
                          if (auth.firebaseUser != null &&
                              auth.errorMessage == null) {
                            // Check if returning user already has a profile.
                            final users =
                                context.read<UserFirestoreService>();
                            final existing = await users
                                .fetchUser(auth.firebaseUser!.uid);
                            if (!context.mounted) return;
                            if (existing != null) {
                              // Returning user — let RoleRouter handle it.
                              await auth.completeProfileAfterSignIn();
                              if (context.mounted) {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              }
                            } else {
                              // New user — go to profile setup.
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => ProfileSetupScreen(
                                    phoneNumber:
                                        _normalizePhone(_phoneCtrl.text),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: auth.isBusy
                                ? null
                                : () {
                                    _otpCtrl.clear();
                                    auth.clearError();
                                    _resendTimer?.cancel();
                                    _otpExpiryTimer?.cancel();
                                    setState(() {
                                      _otpStep = false;
                                      _resendCountdown = 0;
                                      _otpExpiryCountdown = 0;
                                    });
                                  },
                            child: const Text('Change number'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: (auth.isBusy || _resendCountdown > 0)
                                ? null
                                : () async {
                                    final p = _normalizePhone(_phoneCtrl.text);
                                    await auth.requestOtp(p);
                                    if (!context.mounted) return;
                                    if (auth.verificationId != null) {
                                      _startResendTimer();
                                      _startOtpExpiryTimer();
                                    }
                                  },
                            child: Text(
                              _resendCountdown > 0
                                  ? 'Resend (${_resendCountdown}s)'
                                  : 'Resend OTP',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    const Spacer(),
                    Text(
                      'Phone OTP is turned off in code (see lib/core/constants/feature_flags.dart).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
