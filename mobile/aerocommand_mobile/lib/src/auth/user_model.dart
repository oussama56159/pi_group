class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.organizationId,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? organizationId;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'viewer',
      organizationId: json['organization_id']?.toString(),
    );
  }
}
