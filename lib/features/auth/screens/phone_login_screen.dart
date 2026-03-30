import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/constants/feature_flags.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/core/utils/user_role.dart';
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

  @override
  void initState() {
    super.initState();
    // Don't pre-fill - let user type the full number or it auto-converts
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
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
                  const SizedBox(height: 32),
                  Text(
                    'MyTown Cabs',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preview the rider experience — phone OTP can be wired up later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Continue as rider (preview)',
                    loading: false,
                    onPressed: () => auth.startUserPreview(),
                  ),
                  const SizedBox(height: 20),
                  if (FeatureFlags.phoneOtpEnabled) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      _otpStep
                          ? 'Enter the code we sent'
                          : 'Sign in with phone',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400),
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
                    const Spacer(),
                    if (!_otpStep)
                      PrimaryButton(
                        label: 'Send code',
                        loading: auth.isBusy,
                        onPressed: () async {
                          final p = _normalizePhone(_phoneCtrl.text);
                          if (p.length < 13)
                            return; // +91 + 10 digits = 13 characters
                          await auth.requestOtp(p);
                          if (!context.mounted) return;
                          if (auth.verificationId != null) {
                            setState(() => _otpStep = true);
                          }
                        },
                      )
                    else ...[
                      PrimaryButton(
                        label: 'Verify & continue',
                        loading: auth.isBusy,
                        onPressed: () async {
                          await auth.verifyOtp(_otpCtrl.text);
                          if (!context.mounted) return;
                          // Navigate to profile setup if authentication successful
                          if (auth.firebaseUser != null &&
                              auth.errorMessage == null) {
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => ProfileSetupScreen(
                                  phoneNumber: _normalizePhone(_phoneCtrl.text),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      TextButton(
                        onPressed: auth.isBusy
                            ? null
                            : () {
                                setState(() => _otpStep = false);
                              },
                        child: const Text('Change number'),
                      ),
                    ],
                  ] else ...[
                    const Spacer(),
                    Text(
                      'Phone OTP is turned off in code (see lib/core/constants/feature_flags.dart).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
