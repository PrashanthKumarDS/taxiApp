import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/app.dart';
import 'package:taxi_app/core/services/auth_service.dart';
import 'package:taxi_app/core/services/directions_service.dart';
import 'package:taxi_app/core/services/geocoding_service.dart';
import 'package:taxi_app/core/services/fcm_background.dart';
import 'package:taxi_app/core/services/fcm_service.dart';
import 'package:taxi_app/core/services/location_service.dart';
import 'package:taxi_app/core/services/places_service.dart';
import 'package:taxi_app/core/services/ride_firestore_service.dart';
import 'package:taxi_app/core/services/user_firestore_service.dart';
import 'package:taxi_app/core/firebase/firebase_bootstrap.dart';
import 'package:taxi_app/providers/admin_provider.dart';
import 'package:taxi_app/providers/auth_provider.dart';
import 'package:taxi_app/providers/driver_provider.dart';
import 'package:taxi_app/providers/map_provider.dart';
import 'package:taxi_app/providers/ride_provider.dart';
import 'package:taxi_app/providers/vehicle_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final authService = AuthService();
  final userFs = UserFirestoreService();
  final rideFs = RideFirestoreService();
  final directions = DirectionsService();
  final geocoding = GeocodingService();
  final location = LocationService();
  final places = PlacesService();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<UserFirestoreService>.value(value: userFs),
        Provider<RideFirestoreService>.value(value: rideFs),
        Provider<DirectionsService>.value(value: directions),
        Provider<GeocodingService>.value(value: geocoding),
        Provider<LocationService>.value(value: location),
        Provider<PlacesService>.value(value: places),
        ChangeNotifierProvider(
          create: (c) => AuthProvider(c.read<AuthService>(), c.read<UserFirestoreService>()),
        ),
        ChangeNotifierProvider(
          create: (c) => MapProvider(c.read<LocationService>(), c.read<DirectionsService>()),
        ),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProxyProvider<AuthProvider, RideProvider>(
          create: (c) => RideProvider(c.read<RideFirestoreService>()),
          update: (context, auth, prev) {
            final p = prev ?? RideProvider(context.read<RideFirestoreService>());
            p.bindUser(auth.appUser);
            return p;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, DriverProvider>(
          create: (c) => DriverProvider(
            c.read<UserFirestoreService>(),
            c.read<RideFirestoreService>(),
            c.read<LocationService>(),
          ),
          update: (context, auth, prev) {
            final p = prev ??
                DriverProvider(
                  context.read<UserFirestoreService>(),
                  context.read<RideFirestoreService>(),
                  context.read<LocationService>(),
                );
            p.bindUser(auth.appUser);
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (c) => AdminProvider(c.read<UserFirestoreService>()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return const _FcmBootstrap(child: TaxiApp());
        },
      ),
    ),
  );
}

class _FcmBootstrap extends StatefulWidget {
  const _FcmBootstrap({required this.child});

  final Widget child;

  @override
  State<_FcmBootstrap> createState() => _FcmBootstrapState();
}

class _FcmBootstrapState extends State<_FcmBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final auth = context.read<AuthProvider>();
      final users = context.read<UserFirestoreService>();
      await FcmService.instance.init(
        users: users,
        currentUid: () async => auth.firebaseUser?.uid,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
