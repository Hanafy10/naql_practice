import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;
  ApiUser? _user;
  bool _isLoading = false;
  String? _lastError;

  String? get token => _token;
  ApiUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  String? get lastError => _lastError;

  Future<void> restoreSession() async {
    _token = await _authService.getToken();
    if (_token != null) {
      _user = await _authService.currentUser(_token!);
      if (_user == null) _token = null;
    }
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      _token = await _authService.login(identifier, password);
      _user = _token == null ? null : await _authService.currentUser(_token!);
      if (_user == null) _token = null;
    } catch (e) {
      _lastError = e.toString();
      _token = null;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return isAuthenticated;
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final result = await _authService.register(
        username: username,
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ApiUser?> updatePhone(String phone) async {
    if (_token == null) return null;
    final updated = await _authService.updateProfile(_token!, phone: phone);
    if (updated != null) {
      _user = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _user = null;
    notifyListeners();
  }
}
