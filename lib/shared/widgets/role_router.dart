import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/core/utils/user_role.dart';
import 'package:taxi_app/features/admin/screens/admin_shell_screen.dart';
import 'package:taxi_app/features/auth/screens/login_options_screen.dart';
import 'package:taxi_app/features/auth/screens/profile_setup_screen.dart';
// import 'package:taxi_app/features/driver/screens/driver_home_screen.dart';
import 'package:taxi_app/features/user/screens/user_home_screen.dart';
import 'package:taxi_app/models/app_user.dart';
import 'package:taxi_app/providers/auth_provider.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, _AuthRouteState>(
      selector: (_, a) => _AuthRouteState(
        hasFirebaseUser: a.firebaseUser != null,
        appUser: a.appUser,
        phoneNumber: a.firebaseUser?.phoneNumber,
      ),
      builder: (context, state, _) {
        if (state.hasFirebaseUser &&
            state.appUser == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: DotLottieLoader.fromAsset(
                      'assets/animations/car_loading.lottie',
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
                    'Loading profile…',
                    style: TextStyle(color: AppTheme.accent),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.appUser == null) {
          return const LoginOptionsScreen();
        }
        // Incomplete profile — redirect to setup so user can enter their name.
        if (state.appUser!.name == null || state.appUser!.name!.isEmpty) {
          return ProfileSetupScreen(
            phoneNumber: state.phoneNumber ?? '',
          );
        }
        switch (state.appUser!.role) {
          case UserRole.user:
          case UserRole.driver:
            return const UserHomeScreen();
          // case UserRole.driver:
          //   return const DriverHomeScreen();
          case UserRole.admin:
            return const AdminShellScreen();
        }
      },
    );
  }
}

class _AuthRouteState {
  const _AuthRouteState({
    required this.hasFirebaseUser,
    required this.appUser,
    this.phoneNumber,
  });

  final bool hasFirebaseUser;
  final AppUser? appUser;
  final String? phoneNumber;

  @override
  bool operator ==(Object other) =>
      other is _AuthRouteState &&
      other.hasFirebaseUser == hasFirebaseUser &&
      other.appUser == appUser &&
      other.phoneNumber == phoneNumber;

  @override
  int get hashCode =>
      Object.hash(hasFirebaseUser, appUser, phoneNumber);
}
