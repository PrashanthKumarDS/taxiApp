import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/core/utils/user_role.dart';
import 'package:taxi_app/providers/auth_provider.dart';
import 'package:taxi_app/shared/widgets/primary_button.dart';

class EmailPasswordScreen extends StatefulWidget {
  const EmailPasswordScreen({super.key});

  @override
  State<EmailPasswordScreen> createState() => _EmailPasswordScreenState();
}

class _EmailPasswordScreenState extends State<EmailPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Sign In'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      _isSignUp
                          ? 'Create your account'
                          : 'Welcome back to MyTown Cabs',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? 'Sign up to book rides or become a driver'
                          : 'Sign in with your email and password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.accent.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Role selection for signup
                    if (_isSignUp) ...[
                      Text(
                        'I am signing up as',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Rider'),
                            selected: auth.signupRole == UserRole.user,
                            onSelected: (_) =>
                                auth.setSignupRole(UserRole.user),
                            selectedColor: AppTheme.accent.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Driver'),
                            selected: auth.signupRole == UserRole.driver,
                            onSelected: (_) =>
                                auth.setSignupRole(UserRole.driver),
                            selectedColor: AppTheme.accent.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Email field
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !auth.isBusy,
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        hintText: 'you@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password field
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      enabled: !auth.isBusy,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    // Confirm password field (for signup)
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirmPassword,
                        enabled: !auth.isBusy,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          hintText: 'Re-enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                    // Error message
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          auth.errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Sign In/Up button
                    PrimaryButton(
                      label: _isSignUp ? 'Create account' : 'Sign in',
                      loading: auth.isBusy,
                      onPressed: auth.isBusy
                          ? null
                          : () {
                              if (_isSignUp) {
                                auth.signUpWithEmailPassword(
                                  email: _emailCtrl.text,
                                  password: _passwordCtrl.text,
                                  confirmPassword: _confirmPasswordCtrl.text,
                                );
                              } else {
                                auth.signInWithEmailPassword(
                                  email: _emailCtrl.text,
                                  password: _passwordCtrl.text,
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    // Toggle sign in/up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp
                              ? 'Already have an account? '
                              : 'Don\'t have an account? ',
                          style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.6)),
                        ),
                        TextButton(
                          onPressed: auth.isBusy
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _passwordCtrl.clear();
                                    _confirmPasswordCtrl.clear();
                                  });
                                },
                          child: Text(
                            _isSignUp ? 'Sign in' : 'Sign up',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
