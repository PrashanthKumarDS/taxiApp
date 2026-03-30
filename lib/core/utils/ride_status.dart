enum RideStatus {
  searching,
  accepted,
  arrived,
  started,
  completed,
  cancelled;

  String get firestoreValue => name;

  static RideStatus? fromString(String? v) {
    if (v == null) return null;
    for (final s in RideStatus.values) {
      if (s.name == v) return s;
    }
    return null;
  }
}
