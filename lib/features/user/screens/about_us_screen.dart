import 'package:flutter/material.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/features/user/screens/terms_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Image.asset(
            'assets/images/logo.png',
            height: 100,
          ),
          const SizedBox(height: 16),
          Text(
            'MyTown Cabs',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.5), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Text(
            'MyTown Cabs is your trusted local ride-hailing service. '
            'We connect riders with nearby drivers for safe, affordable, '
            'and convenient trips across town.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.accent.withValues(alpha: 0.7),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _InfoTile(
            icon: Icons.shield_outlined,
            title: 'Safe Rides',
            subtitle: 'OTP-verified trips for your security.',
          ),
          _InfoTile(
            icon: Icons.currency_rupee,
            title: 'Fair Pricing',
            subtitle: 'Transparent fares with no hidden charges.',
          ),
          _InfoTile(
            icon: Icons.support_agent,
            title: 'Support',
            subtitle: 'Call us at +91 74063 29777',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermsScreen()),
                ),
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('·', style: TextStyle(color: AppTheme.accent, fontSize: 16)),
              ),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://doc-hosting.flycricket.io/my-town-cabs-privacy-policy/d81cc37c-1cc0-486d-9e31-45fbd280c891/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Made with love in India',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
            child: Icon(icon, color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
        ],
      ),
    );
  }
}
