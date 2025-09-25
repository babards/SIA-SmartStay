class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.tenant,
      ),
      phoneNumber: map['phoneNumber'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

enum UserRole { tenant, landlord, admin }
