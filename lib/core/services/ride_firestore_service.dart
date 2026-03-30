import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi_app/core/constants/firestore_paths.dart';
import 'package:taxi_app/core/utils/ride_status.dart';
import 'package:taxi_app/models/ride_model.dart';
import 'package:uuid/uuid.dart';

class RideFirestoreService {
  RideFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _rides =>
      _db.collection(FirestorePaths.rides);

  Stream<List<RideModel>> watchSearchingRides({int limit = 20}) {
    return _rides
        .where('status', isEqualTo: RideStatus.searching.firestoreValue)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RideModel.fromSnapshot(d.id, d.data()))
            .whereType<RideModel>()
            .toList());
  }

  Stream<RideModel?> watchRide(String rideId) {
    return _rides.doc(rideId).snapshots().map((s) {
      if (!s.exists || s.data() == null) return null;
      return RideModel.fromSnapshot(s.id, s.data()!);
    });
  }

  Stream<List<RideModel>> watchUserRides(String userId, {int limit = 30}) {
    return _rides
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RideModel.fromSnapshot(d.id, d.data()))
            .whereType<RideModel>()
            .toList());
  }

  Stream<List<RideModel>> watchDriverRides(String driverId, {int limit = 30}) {
    return _rides
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RideModel.fromSnapshot(d.id, d.data()))
            .whereType<RideModel>()
            .toList());
  }

  Stream<List<RideModel>> watchActiveRides({int limit = 50}) {
    final statuses = [
      RideStatus.searching,
      RideStatus.accepted,
      RideStatus.arrived,
      RideStatus.started,
    ].map((e) => e.firestoreValue).toList();
    return _rides
        .where('status', whereIn: statuses)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RideModel.fromSnapshot(d.id, d.data()))
            .whereType<RideModel>()
            .toList());
  }

  Future<String> createRide(RideModel ride) async {
    final id = ride.rideId.isNotEmpty ? ride.rideId : _uuid.v4();
    final data = ride.toCreateMap();
    data['rideId'] = id;
    await _rides.doc(id).set(data);
    return id;
  }

  Future<void> updateStatus(String rideId, RideStatus status) async {
    await _rides.doc(rideId).update({
      'status': status.firestoreValue,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> acceptRide({
    required String rideId,
    required String driverId,
    required String otp,
  }) async {
    final ref = _rides.doc(rideId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw Exception('Ride not found');
      final status = snap.data()?['status'] as String?;
      if (status != RideStatus.searching.firestoreValue) {
        throw Exception('Ride already assigned');
      }
      txn.update(ref, {
        'driverId': driverId,
        'status': RideStatus.accepted.firestoreValue,
        'otp': otp,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  Future<void> setArrived(String rideId) async {
    await updateStatus(rideId, RideStatus.arrived);
  }

  Future<void> startTrip(String rideId) async {
    await updateStatus(rideId, RideStatus.started);
  }

  Future<void> completeRide(String rideId, double finalPrice) async {
    await _rides.doc(rideId).update({
      'status': RideStatus.completed.firestoreValue,
      'finalPrice': finalPrice,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> cancelRide(String rideId) async {
    await updateStatus(rideId, RideStatus.cancelled);
  }

  /// Clears driver and returns ride to searching (driver rejected).
  Future<void> rejectAssignment(String rideId) async {
    await _rides.doc(rideId).update({
      'driverId': FieldValue.delete(),
      'otp': FieldValue.delete(),
      'status': RideStatus.searching.firestoreValue,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  String generateOtp({int digits = 4}) {
    final r = Random.secure();
    final max = pow(10, digits).toInt();
    final n = r.nextInt(max);
    return n.toString().padLeft(digits, '0');
  }
}
