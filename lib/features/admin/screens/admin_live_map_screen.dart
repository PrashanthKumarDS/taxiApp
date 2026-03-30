import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/constants/feature_flags.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/features/map/widgets/taxi_google_map.dart';
import 'package:taxi_app/models/geo_lat_lng.dart';
import 'package:taxi_app/models/ride_model.dart';
import 'package:taxi_app/providers/admin_provider.dart';

class AdminLiveMapScreen extends StatefulWidget {
  const AdminLiveMapScreen({super.key});

  @override
  State<AdminLiveMapScreen> createState() => _AdminLiveMapScreenState();
}

class _AdminLiveMapScreenState extends State<AdminLiveMapScreen> {
  LatLng _toLatLng(GeoLatLng g) => LatLng(g.latitude, g.longitude);

  Set<Marker> _buildMarkers(List<RideModel> rides) {
    final m = <Marker>{};
    var i = 0;
    for (final r in rides) {
      m.add(Marker(
        markerId: MarkerId('r$i'),
        position: _toLatLng(r.pickup.position),
        infoWindow: InfoWindow(title: r.status.name, snippet: r.rideId),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange + (i * 25.0 % 80),
        ),
      ));
      i++;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.googleMapsEnabled) {
      return Consumer<AdminProvider>(
        builder: (context, a, _) {
          final rides = a.liveRides;
          if (rides.isEmpty) {
            return Center(
              child: Text(
                'No active rides',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rides[i];
              return Card(
                color: AppTheme.cardDark,
                child: ListTile(
                  title: Text('${r.status.name} · ${r.rideId}'),
                  subtitle: Text(
                    'Pickup ${r.pickup.latitude.toStringAsFixed(5)}, ${r.pickup.longitude.toStringAsFixed(5)}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      );
    }

    return Consumer<AdminProvider>(
      builder: (context, a, _) {
        final rides = a.liveRides;
        final first = rides.isNotEmpty
            ? rides.first.pickup.position
            : const GeoLatLng(20.5937, 78.9629);
        return TaxiGoogleMap(
          initialTarget: _toLatLng(first),
          markers: _buildMarkers(rides),
          polylines: const {},
          padding: const EdgeInsets.only(bottom: 24),
          onMapCreated: (_) {},
        );
      },
    );
  }
}
