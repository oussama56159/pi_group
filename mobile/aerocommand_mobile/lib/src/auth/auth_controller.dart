import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../api/api_error.dart';
import '../app/app_mode.dart';
import '../config/app_config.dart';
import 'user_model.dart';

class AuthController extends ChangeNotifier {
  AuthController({String Function()? baseUrlProvider})
      : _baseUrlProvider = baseUrlProvider ?? (() => AppConfig.apiBaseUrl);

  static const _keyAccess = 'aero_access_token';
  static const _keyRefresh = 'aero_refresh_token';

  static const _keyRememberEnabled = 'aero_remember_enabled';
  static const _keyRememberEmail = 'aero_remember_email';
  static const _keyRememberPassword = 'aero_remember_password';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String Function() _baseUrlProvider;
  late final ApiClient _anonClient = HttpApiClient(
    tokenProvider: () => null,
    baseUrlProvider: _baseUrlProvider,
  );

  UserModel? user;
  String? accessToken;
  String? refreshToken;

  AppMode mode = AppMode.live;
  bool get isDemo => mode == AppMode.demo;

  bool isRestoring = true;
  bool isLoading = false;
  String? error;

  bool get isAuthenticated => user != null && (isDemo || (accessToken != null && accessToken!.isNotEmpty));
  String? get orgId => user?.organizationId;
  String get role => user?.role ?? 'viewer';

  Future<RememberedCredentials?> loadRememberedCredentials() async {
    final enabled = (await _storage.read(key: _keyRememberEnabled)) == '1';
    if (!enabled) return null;

    final email = await _storage.read(key: _keyRememberEmail);
    final password = await _storage.read(key: _keyRememberPassword);
    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return null;
    }

    return RememberedCredentials(email: email, password: password);
  }

  Future<void> rememberCredentials({required bool remember, required String email, required String password}) async {
    if (!remember) {
      await clearRememberedCredentials();
      return;
    }

    await _storage.write(key: _keyRememberEnabled, value: '1');
    await _storage.write(key: _keyRememberEmail, value: email);
    await _storage.write(key: _keyRememberPassword, value: password);
  }

  Future<void> clearRememberedCredentials() async {
    await _storage.write(key: _keyRememberEnabled, value: '0');
    await _storage.delete(key: _keyRememberEmail);
    await _storage.delete(key: _keyRememberPassword);
  }

  Future<void> restoreSession() async {
    final wasRestoring = isRestoring;
    isRestoring = true;
    if (!wasRestoring) {
      notifyListeners();
    }

    try {
      mode = AppMode.live;
      accessToken = await _storage.read(key: _keyAccess);
      refreshToken = await _storage.read(key: _keyRefresh);

      if (accessToken == null || accessToken!.isEmpty) {
        user = null;
        return;
      }

      final client = HttpApiClient(
        tokenProvider: () => accessToken,
        baseUrlProvider: _baseUrlProvider,
      );
      final me = await client.getJson('/auth/me');
      if (me is Map<String, dynamic>) {
        user = UserModel.fromJson(me);
      } else {
        user = null;
        accessToken = null;
        refreshToken = null;
      }
    } catch (_) {
      user = null;
      accessToken = null;
      refreshToken = null;
      await _storage.delete(key: _keyAccess);
      await _storage.delete(key: _keyRefresh);
    } finally {
      final wasRestoring = isRestoring;
      isRestoring = false;
      if (wasRestoring) {
        notifyListeners();
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      mode = AppMode.live;
      final res = await _anonClient.postJson('/auth/login', {'email': email, 'password': password});
      if (res is! Map<String, dynamic>) {
        throw ApiError(500, 'Unexpected login response');
      }

      final access = res['access_token']?.toString();
      final refresh = res['refresh_token']?.toString();
      final userJson = res['user'];
      if (access == null || refresh == null || userJson is! Map<String, dynamic>) {
        throw ApiError(500, 'Missing fields in login response');
      }

      accessToken = access;
      refreshToken = refresh;
      user = UserModel.fromJson(userJson);

      await _storage.write(key: _keyAccess, value: accessToken);
      await _storage.write(key: _keyRefresh, value: refreshToken);
    } on ApiError catch (e) {
      error = 'Login failed (${e.statusCode}): ${e.message}';
      rethrow;
    } catch (e) {
      // Network/TLS/DNS/etc.
      error = 'Could not reach backend (${_baseUrlProvider()}): ${e.toString()}';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginDemo() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      mode = AppMode.demo;
      accessToken = null;
      refreshToken = null;
      await _storage.delete(key: _keyAccess);
      await _storage.delete(key: _keyRefresh);

      user = UserModel.fromJson({
        'id': 'demo-user',
        'email': 'demo@aerocommand.local',
        'name': 'Demo Operator',
        'role': 'admin',
        'organization_id': 'demo-org',
      });
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    mode = AppMode.live;
    accessToken = null;
    refreshToken = null;
    user = null;
    error = null;
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
    notifyListeners();
  }
}

class RememberedCredentials {
  const RememberedCredentials({required this.email, required this.password});

  final String email;
  final String password;
}
