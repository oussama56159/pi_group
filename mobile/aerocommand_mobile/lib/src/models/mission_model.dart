class MissionModel {
  MissionModel({
    required this.id,
    required this.name,
    required this.status,
    this.description,
  });

  final String id;
  final String name;
  final String status;
  final String? description;

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      description: json['description']?.toString(),
    );
  }
}
