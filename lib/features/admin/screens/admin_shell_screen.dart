import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/features/admin/screens/admin_live_map_screen.dart';
import 'package:taxi_app/providers/admin_provider.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _index = 0;
  AdminProvider? _admin;
  bool _listeningStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listeningStarted) {
      _listeningStarted = true;
      _admin = context.read<AdminProvider>();
      _admin!.startListening();
    }
  }

  @override
  void dispose() {
    _admin?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _UsersTab(),
          _DriversTab(),
          _RidesTab(),
          AdminLiveMapScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.local_taxi_outlined), label: 'Drivers'),
          NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Rides'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Live'),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, a, _) {
        if (a.loading && a.usersList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: a.usersList.length,
          itemBuilder: (context, i) {
            final u = a.usersList[i];
            return ListTile(
              title: Text(u.name ?? u.phone),
              subtitle: Text(u.phone),
            );
          },
        );
      },
    );
  }
}

class _DriversTab extends StatelessWidget {
  const _DriversTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, a, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: a.driversList.length,
          itemBuilder: (context, i) {
            final d = a.driversList[i];
            return Card(
              child: ListTile(
                title: Text(d.name ?? d.phone),
                subtitle: Text(
                  d.isApproved ? 'Approved' : 'Pending',
                ),
                trailing: d.isApproved
                    ? TextButton(
                        onPressed: () => a.setDriverApproved(d.id, false),
                        child: const Text('Revoke'),
                      )
                    : FilledButton(
                        onPressed: () => a.setDriverApproved(d.id, true),
                        child: const Text('Approve'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RidesTab extends StatelessWidget {
  const _RidesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, a, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: a.ridesList.length,
          itemBuilder: (context, i) {
            final r = a.ridesList[i];
            return ListTile(
              title: Text(r.status.name),
              subtitle: Text(
                'User ${r.userId.substring(0, 6)}… · ${r.estimatedPrice.toStringAsFixed(0)}',
              ),
            );
          },
        );
      },
    );
  }
}
