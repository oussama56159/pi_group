import 'api_client.dart';
import 'api_error.dart';
import '../mock/demo_repository.dart';

class MockApiClient implements ApiClient {
  MockApiClient({DemoRepository? repo}) : _repo = repo ?? DemoRepository.instance {
    _repo.ensureInitialized();
  }

  final DemoRepository _repo;

  @override
  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    final normalized = _normalize(path);

    if (normalized == '/fleet/fleets') {
      return _repo.listFleets();
    }

    if (normalized == '/fleet/vehicles') {
      final fleetId = query?['fleet_id'];
      return {
        'items': _repo.listVehicles(fleetId: fleetId),
        'page': int.tryParse(query?['page'] ?? '1') ?? 1,
        'page_size': int.tryParse(query?['page_size'] ?? '50') ?? 50,
        'total': _repo.listVehicles(fleetId: fleetId).length,
      };
    }

    final vehicleMatch = RegExp(r'^/fleet/vehicles/([^/]+)$').firstMatch(normalized);
    if (vehicleMatch != null) {
      final id = vehicleMatch.group(1)!;
      final v = _repo.getVehicle(id);
      if (v == null) throw ApiError(404, 'Vehicle not found');
      return v;
    }

    if (normalized == '/missions') {
      return _repo.listMissions();
    }

    final telemMatch = RegExp(r'^/telemetry/vehicles/([^/]+)/latest$').firstMatch(normalized);
    if (telemMatch != null) {
      final id = telemMatch.group(1)!;
      final snap = _repo.getLatestSnapshot(id);
      if (snap == null) throw ApiError(404, 'No telemetry data available');
      return snap;
    }

    if (normalized == '/alerts') {
      final limit = int.tryParse(query?['limit'] ?? '100') ?? 100;
      return _repo.listAlerts(limit: limit).map(_alertToJson).toList();
    }

    if (normalized == '/auth/me') {
      throw ApiError(401, 'Demo mode');
    }

    throw ApiError(404, 'Mock endpoint not implemented: $normalized');
  }

  @override
  Future<dynamic> postJson(String path, Object body) async {
    final normalized = _normalize(path);

    final ackMatch = RegExp(r'^/alerts/([^/]+)/acknowledge$').firstMatch(normalized);
    if (ackMatch != null) {
      final id = ackMatch.group(1)!;
      final updated = _repo.acknowledgeAlert(id);
      if (updated == null) throw ApiError(404, 'Alert not found');
      return _alertToJson(updated);
    }

    final assignMatch = RegExp(r'^/missions/([^/]+)/assign$').firstMatch(normalized);
    if (assignMatch != null) {
      final missionId = assignMatch.group(1)!;
      final map = body is Map ? body.cast<String, dynamic>() : const <String, dynamic>{};
      final vehicleIds = (map['vehicle_ids'] is List)
          ? (map['vehicle_ids'] as List).map((e) => e.toString()).toList()
          : <String>[];
      _repo.assignMission(missionId, vehicleIds);
      return {'ok': true};
    }

    if (normalized == '/missions/upload') {
      final map = body is Map ? body.cast<String, dynamic>() : const <String, dynamic>{};
      final missionId = map['mission_id']?.toString() ?? '';
      final vehicleId = map['vehicle_id']?.toString() ?? '';
      if (missionId.isNotEmpty && vehicleId.isNotEmpty) {
        _repo.uploadMission(missionId, vehicleId);
      }
      return {'ok': true};
    }

    if (normalized == '/command' || normalized == '/commands') {
      final map = body is Map ? body.cast<String, dynamic>() : const <String, dynamic>{};
      final vehicleId = map['vehicle_id']?.toString() ?? '';
      final command = map['command']?.toString() ?? '';
      final params = (map['params'] is Map) ? (map['params'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
      if (command == 'mission_start') {
        final missionId = params['mission_id']?.toString() ?? '';
        if (missionId.isNotEmpty && vehicleId.isNotEmpty) {
          _repo.startMission(missionId, vehicleId);
        }
      }
      return {'ok': true};
    }

    if (normalized == '/auth/login') {
      throw ApiError(400, 'Use Try Demo instead');
    }

    return {'ok': true};
  }

  @override
  Future<dynamic> patchJson(String path, Object body) async {
    final normalized = _normalize(path);
    throw ApiError(404, 'Mock endpoint not implemented: $normalized');
  }

  String _normalize(String path) {
    final p = path.trim();
    return p.startsWith('/') ? p : '/$p';
  }

  Map<String, dynamic> _alertToJson(dynamic alert) {
    if (alert is Map<String, dynamic>) return alert;

    // AlertModel
    final a = alert;
    return {
      'id': a.id,
      'vehicle_id': a.vehicleId,
      'severity': a.severity,
      'category': a.category,
      'title': a.title,
      'message': a.message,
      'acknowledged': a.acknowledged,
      'created_at': a.createdAt.toUtc().toIso8601String(),
    };
  }
}
