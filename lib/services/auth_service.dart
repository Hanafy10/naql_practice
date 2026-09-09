import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import 'api_config.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<String?> login(String identifier, String password) async {
    final response = await http.post(
      ApiConfig.uri('auth/login'),
      body: {'username': identifier, 'password': password},
    );
    if (response.statusCode != 200) {
      final msg = _parseError(response);
      throw Exception(msg);
    }
    final token = (json.decode(response.body) as Map<String, dynamic>)['access_token'] as String;
    await _storage.write(key: 'jwt', value: token);
    return token;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      ApiConfig.uri('auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'email': email, 'password': password}),
    );
    if (response.statusCode != 201) {
      final msg = _parseError(response);
      throw Exception(msg);
    }
    return true;
  }

  Future<ApiUser?> currentUser(String token) async {
    final response = await http.get(
      ApiConfig.uri('auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return null;
    return ApiUser.fromJson(json.decode(response.body) as Map<String, dynamic>);
  }

  Future<ApiUser?> updateProfile(
    String token, {
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (phone != null) body['phone_number'] = phone;
    final response = await http.patch(
      ApiConfig.uri('auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    if (response.statusCode != 200) return null;
    return ApiUser.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  Future<String?> getToken() => _storage.read(key: 'jwt');
  Future<void> logout() => _storage.delete(key: 'jwt');

  String _parseError(http.Response response) {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is Map) return detail['msg'] ?? detail.toString();
      return detail.toString();
    } on Exception {
      return 'Error ${response.statusCode}: ${response.reasonPhrase}';
    }
  }
}
