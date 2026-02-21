class FleetModel {
  FleetModel({
    required this.id,
    required this.name,
    this.description,
    required this.vehicleCount,
    required this.onlineCount,
  });

  final String id;
  final String name;
  final String? description;
  final int vehicleCount;
  final int onlineCount;

  factory FleetModel.fromJson(Map<String, dynamic> json) {
    return FleetModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      vehicleCount: (json['vehicle_count'] as num?)?.toInt() ?? 0,
      onlineCount: (json['online_count'] as num?)?.toInt() ?? 0,
    );
  }
}
