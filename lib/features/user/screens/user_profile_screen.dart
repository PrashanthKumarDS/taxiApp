import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/core/utils/user_role.dart';
import 'package:taxi_app/features/user/screens/about_us_screen.dart';
import 'package:taxi_app/features/user/screens/user_history_screen.dart';
import 'package:taxi_app/providers/auth_provider.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.appUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (auth.previewMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Preview mode: map and UI work locally. '
                          'Firestore rides and history need phone sign-in when you enable it.',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(u?.name ?? u?.email ?? 'Rider'),
            subtitle: Text(
              u?.phone != null && u!.phone.isNotEmpty
                  ? u.phone
                  : u?.email ?? '',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('My Rides'),
            subtitle: const Text('View your ride history'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UserHistoryScreen(),
                ),
              );
            },
          ),
          if (u?.role == UserRole.user)
            ListTile(
              leading: const Icon(Icons.local_taxi_outlined),
              title: const Text('Become a driver'),
              subtitle: Text(
                auth.previewMode
                    ? 'Sign in with phone when OTP is enabled.'
                    : 'Submit request — an admin must approve before you can go online.',
              ),
              onTap: auth.isBusy || auth.previewMode
                  ? null
                  : () async {
                      await auth.registerAsDriver();
                      if (!context.mounted) return;
                      final msg =
                          auth.errorMessage ??
                          'Driver profile submitted. Wait for admin approval.';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(msg)));
                    },
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AboutUsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(auth.previewMode ? 'Exit preview' : 'Sign out'),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}
