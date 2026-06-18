import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi_app/core/constants/firestore_paths.dart';
import 'package:taxi_app/models/tour_package.dart';

class PackageFirestoreService {
  PackageFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// All active tour packages.
  ///
  /// Each document in `tour_packages` represents a starting point
  /// (e.g. `murudeshwar`). Inside it, every string field is one package
  /// stored as a JSON string; the field name is used as the package id.
  Stream<List<TourPackage>> watchActivePackages() {
    return _db
        .collection(FirestorePaths.tourPackages)
        .snapshots()
        .map((snap) {
      final out = <TourPackage>[];
      for (final doc in snap.docs) {
        doc.data().forEach((fieldKey, value) {
          final json = _decode(value);
          if (json == null) return;
          final pkg = TourPackage.fromSnapshot(fieldKey, json);
          if (pkg != null && pkg.isActive) out.add(pkg);
        });
      }
      return out;
    });
  }

  /// Decodes a stored JSON-string field into a map, or returns null if the
  /// field isn't a package (e.g. a stray plain-text field).
  Map<String, dynamic>? _decode(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is! String) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }
}
