import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../config/endpoint_controller.dart';
import '../models/alert_model.dart';
import '../mock/demo_repository.dart';
import 'telemetry_summary.dart';

class RealtimeController extends ChangeNotifier {
  RealtimeController({required this.auth, required this.api, required this.endpoints});

  final AuthController auth;
  final ApiClient api;
  final EndpointController endpoints;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _demoTimer;
  bool _explicitlyStopped = false;

  String connectionState = 'disconnected';

  final Map<String, TelemetrySummary> latestTelemetry = {};
  final List<AlertModel> alerts = [];

  // In-memory time-series history for charts.
  // Capped to avoid unbounded memory growth.
  final Map<String, List<TelemetrySummary>> telemetryHistory = {};
  static const Duration _historyWindow = Duration(minutes: 16);
  static const int _historyMaxPointsPerVehicle = 2500;

  bool get isDemo => auth.isDemo;

  void _appendHistory(TelemetrySummary sample) {
    final id = sample.vehicleId;
    final list = telemetryHistory.putIfAbsent(id, () => <TelemetrySummary>[]);
    list.add(sample);

    final cutoff = DateTime.now().toUtc().subtract(_historyWindow);
    while (list.isNotEmpty && list.first.timestamp.isBefore(cutoff)) {
      list.removeAt(0);
    }
    if (list.length > _historyMaxPointsPerVehicle) {
      list.removeRange(0, list.length - _historyMaxPointsPerVehicle);
    }
  }

  Future<void> connectOrgStream() async {
    if (auth.isDemo) {
      await startDemo();
      return;
    }
    final orgId = auth.orgId;
    final token = auth.accessToken;
    if (orgId == null || token == null) return;
    await connect(channels: 'org:$orgId,alerts:$orgId', token: token);
  }

  Future<void> startDemo() async {
    _explicitlyStopped = false;
    await _disconnectInternal();
    _demoTimer?.cancel();
    _demoTimer = null;

    latestTelemetry.clear();
    alerts.clear();
    telemetryHistory.clear();

    connectionState = 'demo';
    notifyListeners();

    final repo = DemoRepository.instance;
    repo.ensureInitialized();

    void tick() {
      repo.tick(dtSeconds: 0.5);

      // Convert latest frames into the same TelemetrySummary the UI expects.
      for (final v in repo.listVehicles()) {
        final id = v['id']?.toString();
        if (id == null) continue;
        final frame = repo.getLatestSnapshot(id);
        if (frame == null) continue;
        final sample = TelemetrySummary.fromFrameJson(id, frame);
        latestTelemetry[id] = sample;
        _appendHistory(sample);
      }

      alerts
        ..clear()
        ..addAll(repo.listAlerts(limit: 200));

      notifyListeners();
    }

    tick();
    _demoTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => tick());
  }

  Future<void> connect({required String channels, required String token}) async {
    _explicitlyStopped = false;
    await _disconnectInternal();

    connectionState = 'connecting';
    notifyListeners();

    final uri = Uri.parse(endpoints.wsBaseUrl).replace(
      queryParameters: {
        'channels': channels,
        'token': token,
      },
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      connectionState = 'connected';
      notifyListeners();

      _sub = _channel!.stream.listen(
        (event) => _handleMessage(event),
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _explicitlyStopped = true;
    _demoTimer?.cancel();
    _demoTimer = null;
    await _disconnectInternal();
    connectionState = 'disconnected';
    telemetryHistory.clear();
    notifyListeners();
  }

  Future<void> _disconnectInternal() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void _scheduleReconnect() {
    if (_explicitlyStopped) return;
    if (!auth.isAuthenticated) return;
    if (auth.isDemo) return;
    if (_reconnectTimer != null) return;

    connectionState = 'disconnected';
    notifyListeners();

    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      _reconnectTimer = null;
      connectOrgStream();
    });
  }

  void _handleMessage(dynamic raw) {
    try {
      final text = raw is String ? raw : raw.toString();
      final msg = jsonDecode(text);
      if (msg is! Map<String, dynamic>) return;

      final type = msg['type']?.toString();
      if (type == 'telemetry') {
        final vehicleId = msg['vehicle_id']?.toString();
        final data = msg['data'];
        if (vehicleId != null && data is Map) {
          final sample = TelemetrySummary.fromFrameJson(vehicleId, data.cast<String, dynamic>());
          latestTelemetry[vehicleId] = sample;
          _appendHistory(sample);
          notifyListeners();
        }
      } else if (type == 'alert') {
        final data = msg['data'];
        if (data is Map) {
          final alert = AlertModel.fromJson(data.cast<String, dynamic>());
          alerts.insert(0, alert);
          if (alerts.length > 200) {
            alerts.removeRange(200, alerts.length);
          }
          notifyListeners();
        }
      }
    } catch (_) {
      // Ignore parse errors.
    }
  }

  Future<void> refreshAlerts() async {
    if (auth.isDemo) {
      // Demo updates are pushed by startDemo().
      return;
    }
    final res = await api.getJson('/alerts', query: {'limit': '100'});
    if (res is List) {
      alerts
        ..clear()
        ..addAll(res.whereType<Map>().map((e) => AlertModel.fromJson(e.cast<String, dynamic>())));
      notifyListeners();
    }
  }

  Future<void> acknowledgeAlert(String alertId) async {
    final res = await api.postJson('/alerts/$alertId/acknowledge', {});
    if (res is Map<String, dynamic>) {
      final updated = AlertModel.fromJson(res);
      final idx = alerts.indexWhere((a) => a.id == alertId);
      if (idx >= 0) {
        alerts[idx] = updated;
      } else {
        alerts.insert(0, updated);
      }
      notifyListeners();
    }
  }
}
