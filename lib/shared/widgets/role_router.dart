import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/utils/user_role.dart';
import 'package:taxi_app/features/admin/screens/admin_shell_screen.dart';
import 'package:taxi_app/features/auth/screens/login_options_screen.dart';
import 'package:taxi_app/features/driver/screens/driver_home_screen.dart';
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
        previewMode: a.previewMode,
      ),
      builder: (context, state, _) {
        if (state.hasFirebaseUser &&
            state.appUser == null &&
            !state.previewMode) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile…'),
                ],
              ),
            ),
          );
        }
        if (state.appUser == null) {
          return const LoginOptionsScreen();
        }
        switch (state.appUser!.role) {
          case UserRole.user:
            return const UserHomeScreen();
          case UserRole.driver:
            return const DriverHomeScreen();
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
    required this.previewMode,
  });

  final bool hasFirebaseUser;
  final AppUser? appUser;
  final bool previewMode;

  @override
  bool operator ==(Object other) =>
      other is _AuthRouteState &&
      other.hasFirebaseUser == hasFirebaseUser &&
      other.appUser == appUser &&
      other.previewMode == previewMode;

  @override
  int get hashCode => Object.hash(hasFirebaseUser, appUser, previewMode);
}
