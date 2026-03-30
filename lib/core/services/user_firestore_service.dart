import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxi_app/core/constants/app_constants.dart';
import 'package:taxi_app/models/geo_lat_lng.dart';
import 'package:taxi_app/core/constants/firestore_paths.dart';
import 'package:taxi_app/core/utils/user_role.dart';
import 'package:taxi_app/models/app_user.dart';

class UserFirestoreService {
  UserFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid);

  Stream<AppUser?> watchUser(String uid) {
    return userRef(uid).snapshots().map((s) {
      if (!s.exists || s.data() == null) return null;
      return _mapUser(uid, s.data()!);
    });
  }

  Future<AppUser?> fetchUser(String uid) async {
    final s = await userRef(uid).get();
    if (!s.exists || s.data() == null) return null;
    return _mapUser(uid, s.data()!);
  }

  AppUser _mapUser(String uid, Map<String, dynamic> data) {
    final phone = data['phone'] as String? ?? '';
    final role = UserRole.fromString(data['role'] as String?);
    final approved = data['isApproved'] as bool? ?? true;
    return AppUser(
      id: uid,
      phone: phone,
      name: data['name'] as String?,
      role: role,
      isApproved: approved,
    );
  }

  /// Creates profile on first login. [desiredRole] used for new riders/drivers.
  Future<AppUser> ensureUserProfile({
    required User firebaseUser,
    required UserRole desiredRole,
    String? displayName,
  }) async {
    final ref = userRef(firebaseUser.uid);
    final snap = await ref.get();
    final phone = firebaseUser.phoneNumber ?? '';
    if (!snap.exists) {
      final isAdmin = AppConstants.adminPhoneNumbers.contains(phone);
      final role = isAdmin ? UserRole.admin : desiredRole;
      final isApproved = role != UserRole.driver;
      await ref.set({
        'phone': phone,
        'name': displayName ?? firebaseUser.displayName,
        'role': role.firestoreValue,
        'isApproved': isApproved,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final u = await fetchUser(firebaseUser.uid);
    return u!;
  }

  Future<void> updateFcmToken(String uid, String? token) async {
    await userRef(uid).set(
      {'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> setDriverOnline(
    String uid, {
    required bool online,
    double? lat,
    double? lng,
  }) async {
    final map = <String, dynamic>{
      'isOnline': online,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (lat != null) map['latitude'] = lat;
    if (lng != null) map['longitude'] = lng;
    await userRef(uid).set(map, SetOptions(merge: true));
  }

  Future<void> updateDriverLocation(String uid, double lat, double lng) async {
    await userRef(uid).set(
      {
        'latitude': lat,
        'longitude': lng,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setApproved(String uid, bool approved) async {
    await userRef(uid).update({'isApproved': approved});
  }

  Future<void> updateRole(String uid, UserRole role) async {
    await userRef(uid).update({'role': role.firestoreValue});
  }

  Stream<AppUser?> watchDriverLocation(String driverId) {
    return userRef(driverId).snapshots().map((s) {
      if (!s.exists || s.data() == null) return null;
      return _mapUser(driverId, s.data()!);
    });
  }

  Stream<GeoLatLng?> watchDriverLatLng(String driverId) {
    return userRef(driverId).snapshots().map((s) {
      final d = s.data();
      if (d == null) return null;
      final lat = (d['latitude'] as num?)?.toDouble();
      final lng = (d['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return GeoLatLng(lat, lng);
    });
  }

  Query<Map<String, dynamic>> usersQuery({UserRole? role}) {
    Query<Map<String, dynamic>> q =
        _db.collection(FirestorePaths.users);
    if (role != null) {
      q = q.where('role', isEqualTo: role.firestoreValue);
    }
    return q;
  }
}
