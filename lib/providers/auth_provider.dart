import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinguin/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();
  bool _isAuthenticated = false;
  String? _token;
  int? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  int? get userId => _userId;

  Future<void> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      _token = response['token'] as String;
      _userId = int.parse(response['userId'].toString());
      _isAuthenticated = true;
      
      // Store credentials securely
      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'userId', value: _userId.toString());
      
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _token = null;
      _userId = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register(String username, String password, String phoneNumber) async {
    try {
      final response = await _apiService.register(username, password, phoneNumber);
      _token = response['token'] as String;
      _userId = int.parse(response['userId'].toString());
      _isAuthenticated = true;
      
      // Store credentials securely
      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'userId', value: _userId.toString());
      
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _token = null;
      _userId = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _userId = null;
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'userId');
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _token = await _storage.read(key: 'token');
    final storedUserId = await _storage.read(key: 'userId');
    _userId = storedUserId != null ? int.parse(storedUserId) : null;
    _isAuthenticated = _token != null && _userId != null;
    notifyListeners();
  }
} 