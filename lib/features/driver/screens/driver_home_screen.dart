import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/constants/feature_flags.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/core/utils/ride_status.dart';
import 'package:taxi_app/features/driver/screens/driver_history_screen.dart';
import 'package:taxi_app/features/driver/screens/driver_profile_screen.dart';
import 'package:taxi_app/features/map/widgets/taxi_google_map.dart';
import 'package:taxi_app/models/geo_lat_lng.dart';
import 'package:taxi_app/models/ride_model.dart';
import 'package:taxi_app/providers/driver_provider.dart';
import 'package:taxi_app/providers/map_provider.dart';
import 'package:taxi_app/shared/widgets/primary_button.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().refreshMyLocation();
    });
  }

  LatLng _toLatLng(GeoLatLng g) => LatLng(g.latitude, g.longitude);

  Set<Marker> _markers(RideModel? ride, MapProvider map) {
    final s = <Marker>{};
    if (ride != null) {
      s.add(Marker(
        markerId: const MarkerId('pu'),
        position: _toLatLng(ride.pickup.position),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ));
      s.add(Marker(
        markerId: const MarkerId('dr'),
        position: _toLatLng(ride.drop.position),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop'),
      ));
    }
    final me = map.currentLatLng;
    if (me != null) {
      s.add(Marker(
        markerId: const MarkerId('me'),
        position: _toLatLng(me),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ));
    }
    return s;
  }

  Future<void> _endTripDialog(String rideId) async {
    final ctrl = TextEditingController();
    final driver = context.read<DriverProvider>();
    try {
      final price = await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Final price (cash)'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Amount'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)),
              child: const Text('Complete'),
            ),
          ],
        ),
      );
      if (price == null) return;
      if (!mounted) return;
      await driver.endTrip(rideId, price);
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _otpDialog(String rideId) async {
    final ctrl = TextEditingController();
    final driver = context.read<DriverProvider>();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rider OTP'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(hintText: '4-digit code'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Start trip'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (!mounted) return;
      final v = await driver.verifyOtpAndStart(rideId, ctrl.text);
      if (!mounted) return;
      if (!v) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(driver.error ?? 'Invalid OTP')),
        );
      }
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      body: Stack(
        children: [
          if (FeatureFlags.googleMapsEnabled)
            Consumer2<DriverProvider, MapProvider>(
              builder: (context, drv, map, _) {
                final ride = drv.assignedRide;
                final target = ride?.pickup.position ??
                    map.currentLatLng ??
                    const GeoLatLng(20.5937, 78.9629);
                return TaxiGoogleMap(
                  initialTarget: _toLatLng(target),
                  markers: _markers(ride, map),
                  polylines: {},
                  padding: EdgeInsets.only(bottom: 220 + pad.bottom),
                  onMapCreated: (_) {},
                );
              },
            )
          else
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.cardDark,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Consumer<DriverProvider>(
                      builder: (context, drv, _) {
                        final ride = drv.assignedRide;
                        if (ride == null) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_taxi_outlined,
                                  size: 64, color: Colors.grey.shade600),
                              const SizedBox(height: 16),
                              Text(
                                'Map view off',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pickup and drop show as coordinates in ride cards below.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          );
                        }
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Active trip',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            _CoordRow(
                                label: 'Pickup',
                                lat: ride.pickup.latitude,
                                lng: ride.pickup.longitude),
                            const SizedBox(height: 12),
                            _CoordRow(
                                label: 'Drop',
                                lat: ride.drop.latitude,
                                lng: ride.drop.longitude),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: pad.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const DriverHistoryScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.history),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const DriverProfileScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.person_outline),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.22,
            maxChildSize: 0.65,
            builder: (context, sc) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Consumer<DriverProvider>(
                  builder: (context, drv, _) {
                    final ride = drv.assignedRide;
                    return ListView(
                      controller: sc,
                      padding: const EdgeInsets.all(20),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                drv.isOnline ? 'You are online' : 'You are offline',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Switch.adaptive(
                              value: drv.isOnline,
                              onChanged: drv.busy
                                  ? null
                                  : (v) => drv.setOnline(v),
                            ),
                          ],
                        ),
                        if (drv.error != null)
                          Text(
                            drv.error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        if (ride != null) ...[
                          const Divider(height: 24),
                          Text(
                            'Active ride',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(ride.status.name),
                            subtitle: Text(
                              'Est ${ride.estimatedPrice.toStringAsFixed(0)}',
                            ),
                          ),
                          if (!FeatureFlags.googleMapsEnabled) ...[
                            Text(
                              'Pickup: ${ride.pickup.latitude.toStringAsFixed(5)}, ${ride.pickup.longitude.toStringAsFixed(5)}',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12),
                            ),
                            Text(
                              'Drop: ${ride.drop.latitude.toStringAsFixed(5)}, ${ride.drop.longitude.toStringAsFixed(5)}',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (ride.status == RideStatus.accepted)
                            PrimaryButton(
                              label: 'Arrived at pickup',
                              onPressed: () => drv.markArrived(ride.rideId),
                            ),
                          if (ride.status == RideStatus.arrived) ...[
                            const SizedBox(height: 8),
                            PrimaryButton(
                              label: 'Enter OTP & start trip',
                              onPressed: () => _otpDialog(ride.rideId),
                            ),
                          ],
                          if (ride.status == RideStatus.started) ...[
                            const SizedBox(height: 8),
                            PrimaryButton(
                              label: 'End trip & set cash fare',
                              onPressed: () => _endTripDialog(ride.rideId),
                            ),
                          ],
                          if (ride.status == RideStatus.accepted ||
                              ride.status == RideStatus.arrived)
                            TextButton(
                              onPressed: () => drv.releaseRide(ride.rideId),
                              child: const Text('Release ride'),
                            ),
                        ] else if (drv.isOnline) ...[
                          const Divider(height: 24),
                          Text(
                            'Incoming requests',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ...drv.offers.map((o) {
                            return Card(
                              child: ListTile(
                                title: Text(
                                  '${o.vehicleType.label} · ${o.estimatedPrice.toStringAsFixed(0)}',
                                ),
                                subtitle: Text(
                                  'Pickup ${o.pickup.latitude.toStringAsFixed(4)}, ${o.pickup.longitude.toStringAsFixed(4)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => drv.dismissOffer(o.rideId),
                                    ),
                                    FilledButton(
                                      onPressed: drv.busy
                                          ? null
                                          : () => drv.acceptRide(o.rideId),
                                      child: const Text('Accept'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          if (drv.offers.isEmpty)
                            Text(
                              'Waiting for rides…',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                        ],
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          const SizedBox(height: 4),
          SelectableText(
            '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
