import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/services/ride_firestore_service.dart';
import 'package:taxi_app/core/utils/ride_status.dart';
import 'package:taxi_app/models/app_user.dart';
import 'package:taxi_app/models/lat_lng_address.dart';
import 'package:taxi_app/models/ride_model.dart';
import 'package:taxi_app/models/vehicle_type.dart';

class RideProvider extends ChangeNotifier {
  RideProvider(this._rides);

  final RideFirestoreService _rides;

  AppUser? _user;
  RideModel? _activeRide;
  String? _watchedRideId;
  StreamSubscription<RideModel?>? _rideSub;
  String? _error;
  bool _busy = false;

  RideModel? get activeRide => _activeRide;
  String? get error => _error;
  bool get busy => _busy;

  void bindUser(AppUser? user) {
    if (_user?.id == user?.id) return;
    _user = user;
    notifyListeners();
  }

  void _attachRideListener() {
    final rideId = _watchedRideId ?? _activeRide?.rideId;
    if (rideId == null || rideId.isEmpty) {
      _rideSub?.cancel();
      _rideSub = null;
      return;
    }
    _rideSub?.cancel();
    _rideSub = _rides.watchRide(rideId).listen((r) {
      _activeRide = r;
      notifyListeners();
    });
  }

  Future<void> createRideRequest({
    required LatLngAddress pickup,
    required LatLngAddress drop,
    required VehicleType vehicle,
    required double estimatedPrice,
    int? distanceMeters,
    int? durationSeconds,
    String? polyline,
  }) async {
    final uid = _user?.id;
    if (uid == null) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final draft = RideModel(
        rideId: '',
        userId: uid,
        pickup: pickup,
        drop: drop,
        status: RideStatus.searching,
        estimatedPrice: estimatedPrice,
        vehicleType: vehicle,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        polyline: polyline,
      );
      final id = await _rides.createRide(draft);
      _watchedRideId = id;
      _attachRideListener();
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void watchRideId(String rideId) {
    _watchedRideId = rideId;
    _attachRideListener();
  }

  Future<void> cancelActiveRide() async {
    final id = _activeRide?.rideId ?? _watchedRideId;
    if (id == null) return;
    await _rides.cancelRide(id);
    _rideSub?.cancel();
    _rideSub = null;
    _activeRide = null;
    _watchedRideId = null;
    notifyListeners();
  }

  void clearLocalRide() {
    _rideSub?.cancel();
    _rideSub = null;
    _activeRide = null;
    _watchedRideId = null;
    notifyListeners();
  }

  Future<void> markArrived(String rideId) => _rides.setArrived(rideId);

  Future<void> startTrip(String rideId) => _rides.startTrip(rideId);

  Future<void> completeTrip(String rideId, double finalPrice) =>
      _rides.completeRide(rideId, finalPrice);

  @override
  void dispose() {
    _rideSub?.cancel();
    super.dispose();
  }
}
