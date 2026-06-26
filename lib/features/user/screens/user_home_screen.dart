import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_app/core/constants/feature_flags.dart';
import 'package:taxi_app/core/services/geocoding_service.dart';
import 'package:taxi_app/core/services/location_service.dart';
import 'package:taxi_app/core/services/user_firestore_service.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/core/utils/ride_status.dart';
import 'package:taxi_app/features/map/widgets/taxi_google_map.dart';
import 'package:taxi_app/features/user/screens/location_search_screen.dart';
import 'package:taxi_app/features/user/screens/packages_screen.dart';
import 'package:taxi_app/features/user/screens/user_history_screen.dart';
import 'package:taxi_app/features/user/screens/user_profile_screen.dart';
import 'package:taxi_app/models/geo_lat_lng.dart';
import 'package:taxi_app/models/lat_lng_address.dart';
import 'package:taxi_app/models/ride_model.dart';
import 'package:taxi_app/models/vehicle_type.dart';
import 'package:taxi_app/providers/map_provider.dart';
import 'package:taxi_app/providers/ride_provider.dart';
import 'package:taxi_app/providers/vehicle_provider.dart';
import 'package:taxi_app/shared/widgets/primary_button.dart';

String _formatDuration(int seconds) {
  final mins = (seconds / 60).ceil();
  if (mins < 60) return '$mins min';
  final h = mins ~/ 60;
  final m = mins % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool _permissionGranted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermission());
  }

  Future<void> _checkPermission() async {
    final location = context.read<LocationService>();
    final granted = await location.ensurePermission();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _checking = false;
    });
    if (granted) {
      context.read<MapProvider>().refreshMyLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            height: 120,
            width: 120,
            child: DotLottieLoader.fromAsset(
              'assets/animations/car_loading.lottie',
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
        ),
      );
    }

    if (!_permissionGranted) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: DotLottieLoader.fromAsset(
                      'assets/animations/car_loading.lottie',
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
                  const SizedBox(height: 24),
                  Text(
                    'Location Required',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MyTown Cabs needs your location to find nearby drivers and calculate routes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.accent.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Allow Location',
                    onPressed: _checkPermission,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (FeatureFlags.googleMapsEnabled) {
      return const _UserHomeMapBody();
    }
    return const _UserHomeManualBody();
  }
}

// --- Manual location (no map) ---

class _UserHomeManualBody extends StatefulWidget {
  const _UserHomeManualBody();

  @override
  State<_UserHomeManualBody> createState() => _UserHomeManualBodyState();
}

class _UserHomeManualBodyState extends State<_UserHomeManualBody> {
  final _pickQuery = TextEditingController();
  final _dropQuery = TextEditingController();
  final _pickLat = TextEditingController();
  final _pickLng = TextEditingController();
  final _pickAddr = TextEditingController();
  final _dropLat = TextEditingController();
  final _dropLng = TextEditingController();
  final _dropAddr = TextEditingController();
  bool _pickLookupBusy = false;
  bool _dropLookupBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromProvider());
  }

  void _hydrateFromProvider() {
    if (!mounted) return;
    final map = context.read<MapProvider>();
    final p = map.pickup;
    final d = map.drop;
    if (p != null) {
      _pickLat.text = p.latitude.toString();
      _pickLng.text = p.longitude.toString();
      _pickQuery.text = p.address ?? '';
      _pickAddr.text = '';
    }
    if (d != null) {
      _dropLat.text = d.latitude.toString();
      _dropLng.text = d.longitude.toString();
      _dropQuery.text = d.address ?? '';
      _dropAddr.text = '';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _pickQuery.dispose();
    _dropQuery.dispose();
    _pickLat.dispose();
    _pickLng.dispose();
    _pickAddr.dispose();
    _dropLat.dispose();
    _dropLng.dispose();
    _dropAddr.dispose();
    super.dispose();
  }

  double? _parseCoord(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _lookupPickup() async {
    final map = context.read<MapProvider>();
    final geo = context.read<GeocodingService>();
    setState(() => _pickLookupBusy = true);
    try {
      final r = await geo.resolvePlace(_pickQuery.text);
      if (!mounted) return;
      if (r == null) {
        _toast(
          'Could not find that place. Try "Udupi, Karnataka" or use coordinates below.',
        );
        return;
      }
      final note = _pickAddr.text.trim();
      final addr =
          note.isEmpty ? (r.address ?? _pickQuery.text) : '${r.address} · $note';
      _pickLat.text = r.latitude.toString();
      _pickLng.text = r.longitude.toString();
      map.setPickup(LatLngAddress(
        latitude: r.latitude,
        longitude: r.longitude,
        address: addr,
      ));
      await map.fetchRoute();
    } finally {
      if (mounted) setState(() => _pickLookupBusy = false);
    }
  }

  Future<void> _lookupDrop() async {
    final map = context.read<MapProvider>();
    final geo = context.read<GeocodingService>();
    setState(() => _dropLookupBusy = true);
    try {
      final r = await geo.resolvePlace(_dropQuery.text);
      if (!mounted) return;
      if (r == null) {
        _toast(
          'Could not find that place. Try "Mangaluru, Karnataka" or coordinates below.',
        );
        return;
      }
      final note = _dropAddr.text.trim();
      final addr =
          note.isEmpty ? (r.address ?? _dropQuery.text) : '${r.address} · $note';
      _dropLat.text = r.latitude.toString();
      _dropLng.text = r.longitude.toString();
      map.setDrop(LatLngAddress(
        latitude: r.latitude,
        longitude: r.longitude,
        address: addr,
      ));
      await map.fetchRoute();
    } finally {
      if (mounted) setState(() => _dropLookupBusy = false);
    }
  }

  Future<void> _applyPickup() async {
    final lat = _parseCoord(_pickLat.text);
    final lng = _parseCoord(_pickLng.text);
    if (lat == null || lng == null) {
      _toast('Enter valid pickup latitude and longitude');
      return;
    }
    final map = context.read<MapProvider>();
    final addr = _pickAddr.text.trim();
    map.setPickup(LatLngAddress(
      latitude: lat,
      longitude: lng,
      address: addr.isEmpty ? null : addr,
    ));
    await map.fetchRoute();
  }

  Future<void> _applyDrop() async {
    final lat = _parseCoord(_dropLat.text);
    final lng = _parseCoord(_dropLng.text);
    if (lat == null || lng == null) {
      _toast('Enter valid drop latitude and longitude');
      return;
    }
    final map = context.read<MapProvider>();
    final addr = _dropAddr.text.trim();
    map.setDrop(LatLngAddress(
      latitude: lat,
      longitude: lng,
      address: addr.isEmpty ? null : addr,
    ));
    await map.fetchRoute();
  }

  Future<void> _useGpsPickup() async {
    final map = context.read<MapProvider>();
    await map.refreshMyLocation();
    if (!mounted) return;
    final ll = map.currentLatLng;
    if (ll == null) {
      _toast('Location permission or GPS unavailable');
      return;
    }
    _pickQuery.text = 'Current location';
    _pickLat.text = ll.latitude.toString();
    _pickLng.text = ll.longitude.toString();
    map.setPickup(LatLngAddress(
      latitude: ll.latitude,
      longitude: ll.longitude,
      address: 'Current location',
    ));
    await map.fetchRoute();
    setState(() {});
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.cardColor,
                    AppTheme.accent.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_location_alt_outlined,
                        size: 72, color: AppTheme.accent.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'Where to?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.accent,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Type place names like Udupi or Mangaluru, Karnataka — we look them up. Fine‑tune with coordinates if needed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.accent,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const UserHistoryScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.history),
                ),
                const Spacer(),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.accent,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const UserProfileScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.person_outline),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.88,
            builder: (context, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      offset: Offset(0, -4),
                      color: Color(0x1A2D3B96),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Selector<RideProvider, RideModel?>(
                      selector: (_, r) => r.activeRide,
                      builder: (context, ride, _) {
                        if (ride != null) {
                          return _ActiveRideCard(
                            ride: ride,
                            onCancel: () =>
                                context.read<RideProvider>().cancelActiveRide(),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Plan trip',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _useGpsPickup,
                              icon: const Icon(Icons.my_location, size: 20),
                              label: const Text('Use device location as pickup'),
                            ),
                            const SizedBox(height: 8),
                            Text('Pickup',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _pickQuery,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Place name',
                                hintText: 'e.g. Udupi, Karnataka',
                                isDense: true,
                              ),
                            ),
                            TextField(
                              controller: _pickAddr,
                              decoration: const InputDecoration(
                                labelText: 'Landmark (optional)',
                                hintText: 'e.g. near City bus stand',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed:
                                  _pickLookupBusy ? null : () => _lookupPickup(),
                              child: _pickLookupBusy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Find pickup'),
                            ),
                            const SizedBox(height: 8),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text(
                                'Latitude & longitude',
                                style: TextStyle(
                                  color: AppTheme.accent.withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                              ),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _pickLat,
                                        decoration: const InputDecoration(
                                          labelText: 'Latitude',
                                          isDense: true,
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true, signed: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[-0-9.,]')),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _pickLng,
                                        decoration: const InputDecoration(
                                          labelText: 'Longitude',
                                          isDense: true,
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true, signed: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[-0-9.,]')),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _applyPickup,
                                    child: const Text('Apply coordinates'),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text('Drop',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _dropQuery,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Place name',
                                hintText: 'e.g. Mangaluru, Karnataka',
                                isDense: true,
                              ),
                            ),
                            TextField(
                              controller: _dropAddr,
                              decoration: const InputDecoration(
                                labelText: 'Landmark (optional)',
                                hintText: 'e.g. KSRTC stand',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed:
                                  _dropLookupBusy ? null : () => _lookupDrop(),
                              child: _dropLookupBusy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Find drop-off'),
                            ),
                            const SizedBox(height: 8),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text(
                                'Latitude & longitude',
                                style: TextStyle(
                                  color: AppTheme.accent.withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                              ),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _dropLat,
                                        decoration: const InputDecoration(
                                          labelText: 'Latitude',
                                          isDense: true,
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true, signed: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[-0-9.,]')),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _dropLng,
                                        decoration: const InputDecoration(
                                          labelText: 'Longitude',
                                          isDense: true,
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true, signed: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[-0-9.,]')),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _applyDrop,
                                    child: const Text('Apply coordinates'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Consumer<MapProvider>(
                              builder: (context, map, _) {
                                return Text(
                                  map.routeLoading
                                      ? 'Calculating route…'
                                      : 'Distance ${(map.distanceMeters / 1000).toStringAsFixed(1)} km · '
                                          '${_formatDuration(map.durationSeconds)}',
                                  style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.5)),
                                );
                              },
                            ),
                            SizedBox(height: 16 + bottomInset * 0.25),
                            PrimaryButton(
                              label: 'Choose vehicle & price',
                              onPressed: () =>
                                  _openVehicleSheet(context, manualMode: true),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- Google Map mode ---

class _UserHomeMapBody extends StatefulWidget {
  const _UserHomeMapBody();

  @override
  State<_UserHomeMapBody> createState() => _UserHomeMapBodyState();
}

class _UserHomeMapBodyState extends State<_UserHomeMapBody> {
  GoogleMapController? _mapCtrl;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToCurrentLocation());
  }

  Future<void> _goToCurrentLocation() async {
    final map = context.read<MapProvider>();
    await map.refreshMyLocation();
    if (!mounted) return;
    final ll = map.currentLatLng;
    if (ll != null) {
      await _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(ll.latitude, ll.longitude), 15),
      );
    }
  }

  Future<void> _animateTo(LatLng t) async {
    await _mapCtrl?.animateCamera(
      CameraUpdate.newLatLngZoom(t, 15),
    );
  }

  LatLng _toLatLng(GeoLatLng g) => LatLng(g.latitude, g.longitude);

  Set<Marker> _markers({
    required MapProvider map,
    GeoLatLng? driver,
    RideModel? ride,
  }) {
    final m = <Marker>{};
    final p = map.pickup;
    final d = map.drop;
    if (p != null) {
      m.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _toLatLng(p.position),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: p.address),
      ));
    }
    if (d != null) {
      m.add(Marker(
        markerId: const MarkerId('drop'),
        position: _toLatLng(d.position),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Drop', snippet: d.address),
      ));
    }
    final did = ride?.driverId;
    if (driver != null && did != null) {
      m.add(Marker(
        markerId: MarkerId('drv_$did'),
        position: _toLatLng(driver),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your driver'),
      ));
    }
    return m;
  }

  Set<Polyline> _polylines(MapProvider map) {
    if (map.routePoints.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        color: AppTheme.accent,
        width: 5,
        points: map.routePoints.map(_toLatLng).toList(),
      ),
    };
  }

  Future<void> _openSearch(
    BuildContext context, {
    required String title,
    required bool isPickup,
  }) async {
    final map = context.read<MapProvider>();
    final result = await LocationSearchScreen.open(
      context,
      title: title,
      biasLocation: map.currentLatLng,
    );
    if (result == null || !context.mounted) return;
    if (isPickup) {
      map.setPickup(result);
    } else {
      map.setDrop(result);
    }
    await map.fetchRoute();
    final ll = LatLng(result.latitude, result.longitude);
    _animateTo(ll);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          Selector<RideProvider, RideModel?>(
            selector: (_, r) => r.activeRide,
            builder: (context, activeRide, __) {
              return Consumer<MapProvider>(
                builder: (context, map, _) {
                  final target = map.currentLatLng ??
                      map.pickup?.position ??
                      const GeoLatLng(13.3409, 74.7421);
                  final driverId = activeRide?.driverId;

                  Widget mapChild = TaxiGoogleMap(
                    initialTarget: _toLatLng(target),
                    markers: _markers(map: map, driver: null, ride: activeRide),
                    polylines: _polylines(map),
                    padding: EdgeInsets.only(bottom: 200 + bottomInset),
                    onMapCreated: (c) => _mapCtrl = c,
                    onTap: (ll) {
                      final addr = LatLngAddress(
                        latitude: ll.latitude,
                        longitude: ll.longitude,
                        address:
                            '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}',
                      );
                      if (map.pickup == null) {
                        map.setPickup(addr);
                      } else {
                        map.setDrop(addr);
                      }
                      map.fetchRoute();
                      _animateTo(ll);
                    },
                  );

                  if (driverId != null && driverId.isNotEmpty) {
                    mapChild = StreamBuilder<GeoLatLng?>(
                      stream: context
                          .read<UserFirestoreService>()
                          .watchDriverLatLng(driverId),
                      builder: (context, snap) {
                        final drv = snap.data;
                        return TaxiGoogleMap(
                          initialTarget: _toLatLng(target),
                          markers: _markers(
                            map: map,
                            driver: drv,
                            ride: activeRide,
                          ),
                          polylines: _polylines(map),
                          padding: EdgeInsets.only(bottom: 200 + bottomInset),
                          onMapCreated: (c) => _mapCtrl = c,
                          onTap: (ll) {
                            final addr = LatLngAddress(
                              latitude: ll.latitude,
                              longitude: ll.longitude,
                              address:
                                  '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}',
                            );
                            if (map.pickup == null) {
                              map.setPickup(addr);
                            } else {
                              map.setDrop(addr);
                            }
                            map.fetchRoute();
                            _animateTo(ll);
                          },
                        );
                      },
                    );
                  }

                  return mapChild;
                },
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.accent,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const UserHistoryScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.history),
                ),
                const Spacer(),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.accent,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const UserProfileScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.person_outline),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 220 + bottomInset,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'loc',
                  onPressed: () async {
                    final map = context.read<MapProvider>();
                    await map.refreshMyLocation();
                    if (!context.mounted) return;
                    final ll = map.currentLatLng;
                    if (ll != null) await _animateTo(_toLatLng(ll));
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.22,
            maxChildSize: 0.55,
            builder: (context, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      offset: Offset(0, -4),
                      color: Color(0x1A2D3B96),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Selector<RideProvider, RideModel?>(
                      selector: (_, r) => r.activeRide,
                      builder: (context, ride, _) {
                        if (ride != null) {
                          return _ActiveRideCard(
                            ride: ride,
                            onCancel: () =>
                                context.read<RideProvider>().cancelActiveRide(),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BookPackageCard(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const PackagesScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Where to?',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Consumer<MapProvider>(
                              builder: (context, map, _) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _SearchField(
                                      icon: Icons.circle,
                                      iconColor: Colors.green,
                                      hint: 'Search pickup location',
                                      value: map.pickup?.address,
                                      onTap: () => _openSearch(
                                        context,
                                        title: 'Search pickup',
                                        isPickup: true,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _SearchField(
                                      icon: Icons.circle,
                                      iconColor: Colors.red,
                                      hint: 'Search drop-off location',
                                      value: map.drop?.address,
                                      onTap: () => _openSearch(
                                        context,
                                        title: 'Search drop-off',
                                        isPickup: false,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (map.pickup != null &&
                                        map.drop != null)
                                      Text(
                                        map.routeLoading
                                            ? 'Calculating route…'
                                            : '${(map.distanceMeters / 1000).toStringAsFixed(1)} km · '
                                                '${_formatDuration(map.durationSeconds)}',
                                        style: TextStyle(
                                            color: AppTheme.accent.withValues(alpha: 0.5)),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Choose vehicle & price',
                              onPressed: () =>
                                  _openVehicleSheet(context, manualMode: false),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

void _openVehicleSheet(BuildContext context, {required bool manualMode}) {
  final map = context.read<MapProvider>();
  final ride = context.read<RideProvider>();
  if (map.pickup == null || map.drop == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          manualMode
              ? 'Set pickup and drop (place name or coordinates) first'
              : 'Choose pickup and drop on the map',
        ),
      ),
    );
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer<VehicleProvider>(
              builder: (context, v, _) {
                final est = v.estimatePrice(
                  distanceMeters: map.distanceMeters,
                  durationSeconds: map.durationSeconds,
                );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose ride',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ...VehicleType.values.map((t) {
                      final sel = v.selected == t;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: sel
                              ? AppTheme.accent.withValues(alpha: 0.15)
                              : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              v.select(t);
                              setModalState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      t.imagePath,
                                      width: 100,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.directions_car,
                                              size: 40, color: AppTheme.accent.withValues(alpha: 0.4)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${t.description} · ${t.seats} seater',
                                          style: TextStyle(
                                            color: AppTheme.accent.withValues(alpha: 0.5),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (sel)
                                    const Icon(Icons.check_circle,
                                        color: AppTheme.accent, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Conditions Apply',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sedan / Mini Car – ₹11 per km',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SUV Car – ₹15 per km',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Minimum Billing: 300 km per day',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Additional Charges:',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Toll Charges – Extra',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Driver Batta – ₹1000 per day',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Fuel charges included. Parking charges, if any, will be extra.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.accent.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text(
                                '📞 For Customized Trips or One Way Trips: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              InkWell(
                                onTap: () => launchUrl(
                                  Uri.parse('tel:7829975777'),
                                  mode: LaunchMode.externalApplication,
                                ),
                                child: const Text(
                                  '7829975777',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: ride.busy ? 'Requesting…' : 'Request ride',
                      loading: ride.busy,
                      onPressed: ride.busy
                          ? null
                          : () async {
                              await ride.createRideRequest(
                                pickup: map.pickup!,
                                drop: map.drop!,
                                vehicle: v.selected,
                                estimatedPrice: est,
                                distanceMeters: map.distanceMeters,
                                durationSeconds: map.durationSeconds,
                                polyline: map.encodedPolyline,
                              );
                              if (!ctx.mounted) return;
                              if (ride.error != null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(ride.error!)),
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              if (!ctx.mounted) return;
                              final code = ride.lastSecretCode ?? '----';
                              showDialog<void>(
                                context: ctx,
                                builder: (c) => AlertDialog(
                                  title: const Text('Ride Requested!'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Our driver will call you shortly for more details.',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Your Secret Code',
                                              style: TextStyle(
                                                color: AppTheme.accent.withValues(alpha: 0.5),
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              code,
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 6,
                                                color: AppTheme.accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Share this code with the driver to verify your ride. Thank you!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppTheme.accent.withValues(alpha: 0.5),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    },
  );
}

class _ActiveRideCard extends StatelessWidget {
  const _ActiveRideCard({required this.ride, required this.onCancel});

  final RideModel ride;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final st = ride.status;
    String title;
    switch (st) {
      case RideStatus.searching:
        title = 'Finding a driver…';
        break;
      case RideStatus.accepted:
        title = 'Driver on the way';
        break;
      case RideStatus.arrived:
        title = 'Driver has arrived';
        break;
      case RideStatus.started:
        title = 'Trip in progress';
        break;
      case RideStatus.completed:
        title =
            'Trip completed · Cash ${ride.finalPrice?.toStringAsFixed(0) ?? '-'}';
        break;
      case RideStatus.cancelled:
        title = 'Cancelled';
        break;
    }

    final secretCode = ride.otp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (secretCode != null &&
            (st == RideStatus.searching ||
             st == RideStatus.accepted ||
             st == RideStatus.arrived)) ...[
          const SizedBox(height: 8),
          if (st == RideStatus.searching)
            Text(
              'Our driver will call you shortly.',
              style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.5), fontSize: 13),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppTheme.accent),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Secret Code',
                      style:
                          TextStyle(color: AppTheme.accent.withValues(alpha: 0.5), fontSize: 12),
                    ),
                    Text(
                      secretCode,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share this code with the driver to verify your ride.',
            style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
        if (st == RideStatus.searching) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancel request'),
          ),
        ],
        if (st == RideStatus.completed || st == RideStatus.cancelled) ...[
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'New ride',
            onPressed: () {
              context.read<RideProvider>().clearLocalRide();
              context.read<MapProvider>().clearTripSelection();
            },
          ),
        ],
      ],
    );
  }
}

class _BookPackageCard extends StatelessWidget {
  const _BookPackageCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_travel, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Book a Package',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sightseeing & fixed-route tour packages',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.accent.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.icon,
    required this.iconColor,
    required this.hint,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value != null ? AppTheme.accent : AppTheme.accent.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
              ),
            ),
            if (value != null)
              const Icon(Icons.check_circle, size: 18, color: AppTheme.accent),
          ],
        ),
      ),
    );
  }
}
