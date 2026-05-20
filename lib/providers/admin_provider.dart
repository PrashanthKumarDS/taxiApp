import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/constants/firestore_paths.dart';
import 'package:taxi_app/core/utils/user_role.dart';
import 'package:taxi_app/models/app_user.dart';
import 'package:taxi_app/models/ride_model.dart';
import 'package:taxi_app/core/services/user_firestore_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider(this._users);

  final UserFirestoreService _users;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<AppUser> _usersList = [];
  // List<AppUser> _driversList = [];
  List<RideModel> _ridesList = [];
  List<RideModel> _liveRides = [];
  bool _loading = true;
  String? _error;

  List<AppUser> get usersList => List.unmodifiable(_usersList);
  // List<AppUser> get driversList => List.unmodifiable(_driversList);
  List<RideModel> get ridesList => List.unmodifiable(_ridesList);
  List<RideModel> get liveRides => List.unmodifiable(_liveRides);
  bool get loading => _loading;
  String? get error => _error;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _uSub;
  // StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _rSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _liveSub;

  void startListening() {
    _uSub?.cancel();
    _rSub?.cancel();
    _liveSub?.cancel();

    _uSub = _db
        .collection(FirestorePaths.users)
        .where('role', isEqualTo: UserRole.user.firestoreValue)
        .limit(100)
        .snapshots()
        .listen(_onUsers, onError: _onErr);

    // _dSub = _db
    //     .collection(FirestorePaths.users)
    //     .where('role', isEqualTo: UserRole.driver.firestoreValue)
    //     .limit(100)
    //     .snapshots()
    //     .listen(_onDrivers, onError: _onErr);

    _rSub = _db
        .collection(FirestorePaths.rides)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .listen(_onRides, onError: _onErr);

    _liveSub = _db
        .collection(FirestorePaths.rides)
        .where('status', whereIn: ['searching', 'accepted', 'arrived', 'started'])
        .limit(50)
        .snapshots()
        .listen(_onLive, onError: _onErr);

    _loading = false;
    notifyListeners();
  }

  void _onErr(Object e, StackTrace st) {
    _error = e.toString();
    notifyListeners();
  }

  void _onUsers(QuerySnapshot<Map<String, dynamic>> snap) {
    _usersList = snap.docs
        .map((d) => _usersMap(d.id, d.data()))
        .whereType<AppUser>()
        .toList();
    notifyListeners();
  }

  // void _onDrivers(QuerySnapshot<Map<String, dynamic>> snap) {
  //   _driversList = snap.docs
  //       .map((d) => _usersMap(d.id, d.data()))
  //       .whereType<AppUser>()
  //       .toList();
  //   notifyListeners();
  // }

  AppUser? _usersMap(String id, Map<String, dynamic> data) {
    try {
      return AppUser(
        id: id,
        phone: data['phone'] as String? ?? '',
        name: data['name'] as String?,
        role: UserRole.fromString(data['role'] as String?),
        isApproved: data['isApproved'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }

  void _onRides(QuerySnapshot<Map<String, dynamic>> snap) {
    _ridesList = snap.docs
        .map((d) => RideModel.fromSnapshot(d.id, d.data()))
        .whereType<RideModel>()
        .toList();
    notifyListeners();
  }

  void _onLive(QuerySnapshot<Map<String, dynamic>> snap) {
    _liveRides = snap.docs
        .map((d) => RideModel.fromSnapshot(d.id, d.data()))
        .whereType<RideModel>()
        .toList();
    notifyListeners();
  }

  // Future<void> setDriverApproved(String uid, bool approved) async {
  //   await _users.setApproved(uid, approved);
  // }

  void stopListening() {
    _uSub?.cancel();
    // _dSub?.cancel();
    _rSub?.cancel();
    _liveSub?.cancel();
    _uSub = null;
    // _dSub = null;
    _rSub = null;
    _liveSub = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
