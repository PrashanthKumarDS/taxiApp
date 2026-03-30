enum UserRole {
  user,
  driver,
  admin;

  String get firestoreValue => name;

  static UserRole fromString(String? v) {
    for (final r in UserRole.values) {
      if (r.name == v) return r;
    }
    return UserRole.user;
  }
}
