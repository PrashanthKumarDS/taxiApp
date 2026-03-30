import 'package:taxi_app/core/utils/ride_status.dart';
import 'package:taxi_app/models/lat_lng_address.dart';
import 'package:taxi_app/models/vehicle_type.dart';

class RideModel {
  const RideModel({
    required this.rideId,
    required this.userId,
    this.driverId,
    required this.pickup,
    required this.drop,
    required this.status,
    this.otp,
    required this.estimatedPrice,
    this.finalPrice,
    required this.vehicleType,
    this.distanceMeters,
    this.durationSeconds,
    this.polyline,
    this.createdAt,
  });

  final String rideId;
  final String userId;
  final String? driverId;
  final LatLngAddress pickup;
  final LatLngAddress drop;
  final RideStatus status;
  final String? otp;
  final double estimatedPrice;
  final double? finalPrice;
  final VehicleType vehicleType;
  final int? distanceMeters;
  final int? durationSeconds;
  final String? polyline;
  final DateTime? createdAt;

  Map<String, dynamic> toCreateMap() => {
        'rideId': rideId,
        'userId': userId,
        'pickup': pickup.toMap(),
        'drop': drop.toMap(),
        'status': status.firestoreValue,
        'estimatedPrice': estimatedPrice,
        'vehicleType': vehicleType.firestoreValue,
        if (distanceMeters != null) 'distanceMeters': distanceMeters,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (polyline != null) 'polyline': polyline,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

  static RideModel? fromSnapshot(String id, Map<String, dynamic> data) {
    final pickup = LatLngAddress.fromMap(
      Map<String, dynamic>.from(data['pickup'] as Map? ?? {}),
    );
    final drop = LatLngAddress.fromMap(
      Map<String, dynamic>.from(data['drop'] as Map? ?? {}),
    );
    if (pickup == null || drop == null) return null;
    final status = RideStatus.fromString(data['status'] as String?) ??
        RideStatus.searching;
    return RideModel(
      rideId: id,
      userId: data['userId'] as String? ?? '',
      driverId: data['driverId'] as String?,
      pickup: pickup,
      drop: drop,
      status: status,
      otp: data['otp'] as String?,
      estimatedPrice: (data['estimatedPrice'] as num?)?.toDouble() ?? 0,
      finalPrice: (data['finalPrice'] as num?)?.toDouble(),
      vehicleType: VehicleType.fromString(data['vehicleType'] as String?),
      distanceMeters: (data['distanceMeters'] as num?)?.toInt(),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt(),
      polyline: data['polyline'] as String?,
      createdAt: _msToDate(data['createdAt']),
    );
  }

  static DateTime? _msToDate(dynamic v) {
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
