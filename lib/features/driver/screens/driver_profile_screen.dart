import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/providers/auth_provider.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.appUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Driver profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.local_taxi)),
            title: Text(u?.name ?? u?.email ?? 'Driver'),
            subtitle: Text(
              u?.phone != null && u!.phone.isNotEmpty
                  ? u.phone
                  : u?.email ?? '',
            ),
          ),
          ListTile(
            leading: Icon(
              u?.isApproved == true ? Icons.verified : Icons.hourglass_top,
              color: u?.isApproved == true ? Colors.greenAccent : Colors.orange,
            ),
            title: Text(
              u?.isApproved == true ? 'Approved' : 'Pending approval',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
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
