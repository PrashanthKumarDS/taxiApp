import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/services/ride_firestore_service.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/core/utils/ride_status.dart';
import 'package:taxi_app/models/ride_model.dart';
import 'package:taxi_app/providers/auth_provider.dart';

class UserHistoryScreen extends StatelessWidget {
  const UserHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().appUser?.id;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final rides = context.read<RideFirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ride history')),
      body: StreamBuilder<List<RideModel>>(
        stream: rides.watchUserRides(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No rides yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = list[i];
              final df = DateFormat.yMMMd().add_jm();
              final t = r.createdAt != null ? df.format(r.createdAt!) : '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.status.name.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (r.status == RideStatus.completed)
                            const Icon(Icons.check_circle,
                                color: Colors.greenAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (r.pickup.address != null)
                        Text(
                          'Pickup: ${r.pickup.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppTheme.accent.withValues(alpha: 0.5), fontSize: 13),
                        ),
                      if (r.drop.address != null)
                        Text(
                          'Drop: ${r.drop.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppTheme.accent.withValues(alpha: 0.5), fontSize: 13),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        '$t · ${r.vehicleType.label} · Est ₹${r.estimatedPrice.toStringAsFixed(0)}'
                        '${r.finalPrice != null ? ' · Paid ₹${r.finalPrice!.toStringAsFixed(0)}' : ''}'
                        '${r.otp != null ? ' · Code: ${r.otp}' : ''}',
                        style: TextStyle(
                            color: AppTheme.accent.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
