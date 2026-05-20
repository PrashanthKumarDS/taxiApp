import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: DotLottieLoader.fromAsset(
              'assets/animations/walking.lottie',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.accent,
                  child: Text(
                    (u?.name ?? 'R').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  u?.name ?? u?.email ?? 'Rider',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  u?.phone != null && u!.phone.isNotEmpty
                      ? u.phone
                      : u?.email ?? '',
                  style: TextStyle(
                    color: AppTheme.accent.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ProfileTile(
            icon: Icons.history,
            title: 'My Rides',
            subtitle: 'View your ride history',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserHistoryScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ProfileTile(
            icon: Icons.info_outline,
            title: 'About Us',
            subtitle: 'Learn more about MyTown Cabs',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutUsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ProfileTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            isDestructive: true,
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.2)
                  : AppTheme.accent.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDestructive
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppTheme.accent.withValues(alpha: 0.1),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? Colors.red : AppTheme.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.accent.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
