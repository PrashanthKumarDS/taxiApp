import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/constants/app_constants.dart';
import 'package:taxi_app/core/services/location_service.dart';
import 'package:taxi_app/core/services/ride_firestore_service.dart';
import 'package:taxi_app/core/services/user_firestore_service.dart';
import 'package:taxi_app/models/app_user.dart';
import 'package:taxi_app/models/ride_model.dart';

class DriverProvider extends ChangeNotifier {
  DriverProvider(
    this._users,
    this._rides,
    this._location,
  );

  final UserFirestoreService _users;
  final RideFirestoreService _rides;
  final LocationService _location;

  AppUser? _user;
  bool _online = false;
  bool _busy = false;
  String? _error;
  List<RideModel> _offers = [];
  RideModel? _assignedRide;
  StreamSubscription<List<RideModel>>? _searchingSub;
  StreamSubscription<RideModel?>? _assignedSub;
  Timer? _locationTimer;

  bool get isOnline => _online;
  bool get busy => _busy;
  String? get error => _error;
  List<RideModel> get offers => List.unmodifiable(_offers);
  RideModel? get assignedRide => _assignedRide;

  void bindUser(AppUser? user) {
    if (_user?.id == user?.id) return;
    _stopAll();
    _user = user;
    notifyListeners();
  }

  void _stopAll() {
    _searchingSub?.cancel();
    _searchingSub = null;
    _assignedSub?.cancel();
    _assignedSub = null;
    _locationTimer?.cancel();
    _locationTimer = null;
    _online = false;
    _offers = [];
    _assignedRide = null;
  }

  Future<void> setOnline(bool value) async {
    final u = _user;
    if (u == null) return;
    if (!u.canDriveOnline) {
      _error = 'Driver not approved yet.';
      notifyListeners();
      return;
    }
    if (value) {
      final ok = await _location.ensurePermission();
      if (!ok) {
        _error = 'Location permission required';
        notifyListeners();
        return;
      }
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _online = value;
      await _users.setDriverOnline(
        u.id,
        online: value,
      );
      if (value) {
        await _pulseLocation();
        _locationTimer = Timer.periodic(
          AppConstants.driverLocationInterval,
          (_) => _pulseLocation(),
        );
        _listenSearching();
      } else {
        _searchingSub?.cancel();
        _searchingSub = null;
        _locationTimer?.cancel();
        _locationTimer = null;
        _offers = [];
      }
    } catch (e) {
      _error = e.toString();
      _online = false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _pulseLocation() async {
    final u = _user;
    if (u == null || !_online) return;
    final ll = await _location.getCurrentLatLng();
    if (ll == null) return;
    await _users.updateDriverLocation(u.id, ll.latitude, ll.longitude);
  }

  void _listenSearching() {
    _searchingSub?.cancel();
    _searchingSub = _rides.watchSearchingRides().listen((list) {
      _offers = list;
      notifyListeners();
    });
  }

  void watchAssignedRide(String rideId) {
    _assignedSub?.cancel();
    _assignedSub = _rides.watchRide(rideId).listen((r) {
      _assignedRide = r;
      notifyListeners();
    });
  }

  void clearAssignedRide() {
    _assignedSub?.cancel();
    _assignedSub = null;
    _assignedRide = null;
    notifyListeners();
  }

  Future<void> acceptRide(String rideId) async {
    final uid = _user?.id;
    if (uid == null) return;
    _busy = true;
    notifyListeners();
    try {
      final otp = _rides.generateOtp(digits: AppConstants.otpLength);
      await _rides.acceptRide(rideId: rideId, driverId: uid, otp: otp);
      watchAssignedRide(rideId);
      _offers = _offers.where((r) => r.rideId != rideId).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void dismissOffer(String rideId) {
    _offers = _offers.where((r) => r.rideId != rideId).toList();
    notifyListeners();
  }

  /// Returns ride to searching (e.g. driver cancels after accepting).
  Future<void> releaseRide(String rideId) async {
    try {
      await _rides.rejectAssignment(rideId);
      clearAssignedRide();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> verifyOtpAndStart(String rideId, String input) async {
    final ride = _assignedRide;
    if (ride == null || ride.rideId != rideId) return false;
    if (ride.otp == null || ride.otp != input.trim()) {
      _error = 'Invalid OTP';
      notifyListeners();
      return false;
    }
    await _rides.startTrip(rideId);
    return true;
  }

  Future<void> endTrip(String rideId, double finalPrice) async {
    await _rides.completeRide(rideId, finalPrice);
    clearAssignedRide();
  }

  Future<void> markArrived(String rideId) => _rides.setArrived(rideId);

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }
}
