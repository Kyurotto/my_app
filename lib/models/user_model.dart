class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String role; // 'admin' or 'employee'
  final String employeeCode;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    required this.employeeCode,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isEmployee => role.toLowerCase() == 'employee';

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'U';

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? role,
    String? employeeCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      employeeCode: employeeCode ?? this.employeeCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'role': role,
      'employeeCode': employeeCode,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id']?.toString();
    final effectiveId = (rawId != null && rawId.isNotEmpty)
        ? rawId
        : (map['_id'] != null ? map['_id'].toString() : '');

    return UserModel(
      id: effectiveId,
      name: map['name'] ?? map['username'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      role: map['role'] ?? 'employee',
      employeeCode: map['employeeCode'] ?? 'EMP001',
    );
  }
}
