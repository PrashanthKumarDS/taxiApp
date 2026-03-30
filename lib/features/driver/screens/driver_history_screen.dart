import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/services/ride_firestore_service.dart';
import 'package:taxi_app/core/utils/ride_status.dart';
import 'package:taxi_app/models/ride_model.dart';
import 'package:taxi_app/providers/auth_provider.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().appUser?.id;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final rides = context.read<RideFirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Driver history')),
      body: StreamBuilder<List<RideModel>>(
        stream: rides.watchDriverRides(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No completed rides yet'));
          }
          final df = DateFormat.yMMMd().add_jm();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = list[i];
              final t = r.createdAt != null ? df.format(r.createdAt!) : '';
              return Card(
                child: ListTile(
                  title: Text(r.status.name.toUpperCase()),
                  subtitle: Text(
                    '$t · Fare ${r.finalPrice?.toStringAsFixed(0) ?? r.estimatedPrice.toStringAsFixed(0)}',
                  ),
                  trailing: r.status == RideStatus.completed
                      ? const Icon(Icons.payments_outlined)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
