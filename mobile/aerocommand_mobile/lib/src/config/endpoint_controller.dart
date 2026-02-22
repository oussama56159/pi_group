import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

class EndpointController extends ChangeNotifier {
  static const _keyApiOverride = 'backend_api_base_url_override';

  String? _apiOverride;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Base REST API URL ending with /api/v1
  String get apiBaseUrl => _normalizeApiBase(_apiOverride) ?? _normalizeApiBase(AppConfig.apiBaseUrl)!;

  /// WebSocket base URL ending with /api/v1/telemetry/ws
  String get wsBaseUrl {
    final api = Uri.parse(apiBaseUrl);
    final wsScheme = api.scheme == 'https' ? 'wss' : 'ws';
    final basePath = api.path.replaceAll(RegExp(r'/+$'), '');
    return api
        .replace(
          scheme: wsScheme,
          path: '$basePath/telemetry/ws',
          query: null,
          fragment: null,
        )
        .toString();
  }

  /// Human-friendly display (host + path).
  String get display => Uri.tryParse(apiBaseUrl)?.toString() ?? apiBaseUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiOverride = prefs.getString(_keyApiOverride);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setApiBaseUrl(String input) async {
    final normalized = _normalizeApiBase(input);
    if (normalized == null) {
      throw FormatException('Invalid URL');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiOverride, normalized);
    _apiOverride = normalized;
    notifyListeners();
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiOverride);
    _apiOverride = null;
    notifyListeners();
  }

  static String? _normalizeApiBase(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    Uri uri;
    try {
      uri = Uri.parse(s);
    } catch (_) {
      return null;
    }

    if (!uri.hasScheme || uri.host.isEmpty) return null;

    final cleanedPath = uri.path.replaceAll(RegExp(r'/+$'), '');
    final needsApi = !cleanedPath.endsWith('/api/v1');
    final normalizedPath = needsApi
        ? (cleanedPath.isEmpty ? '/api/v1' : '$cleanedPath/api/v1')
        : cleanedPath;

    return uri
        .replace(
          path: normalizedPath,
          query: null,
          fragment: null,
        )
        .toString();
  }
}
