import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_error.dart';

typedef TokenProvider = String? Function();

abstract class ApiClient {
  Future<dynamic> getJson(String path, {Map<String, String>? query});
  Future<dynamic> postJson(String path, Object body);
  Future<dynamic> patchJson(String path, Object body);
}

class HttpApiClient implements ApiClient {
  HttpApiClient({
    required TokenProvider tokenProvider,
    String Function()? baseUrlProvider,
    http.Client? client,
  })  : _tokenProvider = tokenProvider,
        _baseUrlProvider = baseUrlProvider ?? (() => AppConfig.apiBaseUrl),
        _client = client ?? http.Client();

  final TokenProvider _tokenProvider;
  final String Function() _baseUrlProvider;
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = _baseUrlProvider();
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final baseUri = Uri.parse(base);
    return baseUri.replace(
      path: '${baseUri.path.replaceAll(RegExp(r"/+$"), "")}/$normalizedPath',
      queryParameters: query,
    );
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    final token = _tokenProvider();
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    final res = await _client.get(_uri(path, query), headers: _headers());
    return _decode(res);
  }

  @override
  Future<dynamic> postJson(String path, Object body) async {
    final res = await _client.post(
      _uri(path),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  @override
  Future<dynamic> patchJson(String path, Object body) async {
    final res = await _client.patch(
      _uri(path),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final contentType = res.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json');

    dynamic body;
    if (res.body.isEmpty) {
      body = null;
    } else if (isJson) {
      body = jsonDecode(res.body);
    } else {
      body = res.body;
    }

    if (res.statusCode >= 400) {
      final msg = (body is Map && body['detail'] is String) ? body['detail'] as String : 'Request failed';
      throw ApiError(res.statusCode, msg);
    }
    return body;
  }
}
