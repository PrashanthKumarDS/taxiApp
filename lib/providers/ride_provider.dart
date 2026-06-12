import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/services/ride_firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';
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

  String? _lastSecretCode;
  String? get lastSecretCode => _lastSecretCode;

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
      _lastSecretCode = (1000 + Random.secure().nextInt(9000)).toString();
      final code = _lastSecretCode!;
      final draft = RideModel(
        rideId: '',
        userId: uid,
        pickup: pickup,
        drop: drop,
        status: RideStatus.searching,
        otp: code,
        estimatedPrice: estimatedPrice,
        vehicleType: vehicle,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        polyline: polyline,
      );
      final id = await _rides.createRide(draft);
      _watchedRideId = id;
      _attachRideListener();
      await _sendWhatsAppNotification(draft, code);
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
    final rideSnapshot = _activeRide;
    await _rides.cancelRide(id);
    _rideSub?.cancel();
    _rideSub = null;
    _activeRide = null;
    _watchedRideId = null;
    notifyListeners();
    if (rideSnapshot != null) {
      await _sendCancelWhatsAppNotification(rideSnapshot);
    }
  }

  void clearLocalRide() {
    _rideSub?.cancel();
    _rideSub = null;
    _activeRide = null;
    _watchedRideId = null;
    notifyListeners();
  }

  static const _whatsappNumber = '917406329777';

  Future<void> _sendWhatsAppNotification(RideModel ride, String otp) async {
    final pickup = ride.pickup.address ?? '${ride.pickup.latitude}, ${ride.pickup.longitude}';
    final drop = ride.drop.address ?? '${ride.drop.latitude}, ${ride.drop.longitude}';
    final dist = ride.distanceMeters != null
        ? '${(ride.distanceMeters! / 1000).toStringAsFixed(1)} km'
        : 'N/A';
    final price = ride.estimatedPrice.toStringAsFixed(0);
    final vehicle = '${ride.vehicleType.label} (${ride.vehicleType.seats} seater)';
    final userName = _user?.name ?? 'A user';
    final userPhone = _user?.phone ?? '';

    final pickupMap = 'https://www.google.com/maps?q=${ride.pickup.latitude},${ride.pickup.longitude}';
    final dropMap = 'https://www.google.com/maps?q=${ride.drop.latitude},${ride.drop.longitude}';

    final message = '🚖 Hello MyTown Drivers!\n\n'
        'A customer has requested a ride. Please give them a call and confirm the details.\n\n'
        '👤 Name: $userName\n'
        '📞 Call: $userPhone\n\n'
        '📍 Pickup: $pickup\n'
        '🗺️ $pickupMap\n\n'
        '📍 Drop: $drop\n'
        '🗺️ $dropMap\n\n'
        '🚗 Vehicle: $vehicle\n'
        '📏 Distance: $dist\n'
        '💰 Est. Fare: ₹$price\n'
        '🔐 Verify Code: $otp\n\n'
        'Please verify this code with the customer before starting the trip.';

    final uri = Uri.parse(
      'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('WhatsApp launch failed: $e');
    }
  }

  Future<void> _sendCancelWhatsAppNotification(RideModel ride) async {
    final pickup = ride.pickup.address ?? '${ride.pickup.latitude}, ${ride.pickup.longitude}';
    final drop = ride.drop.address ?? '${ride.drop.latitude}, ${ride.drop.longitude}';
    final userName = _user?.name ?? 'A user';
    final userPhone = _user?.phone ?? '';

    final message = '❌ Ride Cancelled\n\n'
        '👤 Name: $userName\n'
        '📞 Phone: $userPhone\n\n'
        '📍 Pickup: $pickup\n'
        '📍 Drop: $drop\n\n'
        'The customer has cancelled this ride request.';

    final uri = Uri.parse(
      'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('WhatsApp cancel launch failed: $e');
    }
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
