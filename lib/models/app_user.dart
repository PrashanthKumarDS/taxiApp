import 'package:taxi_app/core/utils/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.email,
    this.name,
    required this.role,
    required this.isApproved,
  });

  final String id;
  final String phone;
  final String? email;
  final String? name;
  final UserRole role;
  final bool isApproved;

  bool get canDriveOnline => role == UserRole.driver && isApproved;

  AppUser copyWith({
    String? id,
    String? phone,
    String? email,
    String? name,
    UserRole? role,
    bool? isApproved,
  }) {
    return AppUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
