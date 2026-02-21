class AlertModel {
  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.acknowledged,
    required this.createdAt,
    this.vehicleId,
  });

  final String id;
  final String title;
  final String message;
  final String severity;
  final String category;
  final bool acknowledged;
  final DateTime createdAt;
  final String? vehicleId;

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at']?.toString();
    return AlertModel(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString(),
      severity: json['severity']?.toString() ?? 'info',
      category: json['category']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      acknowledged: json['acknowledged'] == true,
      createdAt: createdRaw != null ? DateTime.tryParse(createdRaw) ?? DateTime.now() : DateTime.now(),
    );
  }
}
