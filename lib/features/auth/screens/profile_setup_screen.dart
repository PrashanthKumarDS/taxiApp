import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
// import 'package:taxi_app/core/utils/user_role.dart';
import 'package:taxi_app/providers/auth_provider.dart';
import 'package:taxi_app/shared/widgets/primary_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;

  const ProfileSetupScreen({required this.phoneNumber, super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        elevation: 0,
        automaticallyImplyLeading: false,
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
                    SizedBox(
                      height: 180,
                      child: DotLottieLoader.fromAsset(
                        'assets/animations/profile_creation.lottie',
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
                      'Complete Your Profile',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your details to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.accent.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Phone number display
                    ListTile(
                      leading: const Icon(Icons.phone, color: AppTheme.accent),
                      title: Text(widget.phoneNumber),
                      subtitle: Text(
                        'Signed in as',
                        style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.5)),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    // Username/Name field
                    TextField(
                      controller: _nameCtrl,
                      enabled: !auth.isBusy,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    // // Role selection
                    // const SizedBox(height: 16),
                    // Text(
                    //   'What do you want to do?',
                    //   style: TextStyle(
                    //     color: Colors.grey.shade700,
                    //     fontWeight: FontWeight.w500,
                    //     fontSize: 14,
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    // Wrap(
                    //   spacing: 8,
                    //   children: [
                    //     ChoiceChip(
                    //       label: const Text('Book Rides'),
                    //       selected: auth.signupRole == UserRole.user,
                    //       onSelected: auth.isBusy
                    //           ? null
                    //           : (_) => auth.setSignupRole(UserRole.user),
                    //       selectedColor: AppTheme.accent.withValues(alpha: 0.3),
                    //     ),
                    //     ChoiceChip(
                    //       label: const Text('Drive'),
                    //       selected: auth.signupRole == UserRole.driver,
                    //       onSelected: auth.isBusy
                    //           ? null
                    //           : (_) => auth.setSignupRole(UserRole.driver),
                    //       selectedColor: AppTheme.accent.withValues(alpha: 0.3),
                    //     ),
                    //   ],
                    // ),
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
                    const SizedBox(height: 32),
                    // Continue button
                    PrimaryButton(
                      label: 'Create Profile',
                      loading: auth.isBusy,
                      onPressed: auth.isBusy
                          ? null
                          : () async {
                              final name = _nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter your full name',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              await auth.completeProfileAfterSignIn(
                                displayName: name,
                              );
                              if (context.mounted &&
                                  auth.errorMessage == null) {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              }
                            },
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
