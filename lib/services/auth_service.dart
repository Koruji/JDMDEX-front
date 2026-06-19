import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'auth_token';

  String? _token;
  String? get token => _token;
  bool get isLoggedIn => _token != null;

  final ValueNotifier<bool> loggedInNotifier = ValueNotifier(false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    loggedInNotifier.value = _token != null;
  }

  // GET / DELETE : pas de Content-Type
  Map<String, String> get bearerHeaders => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // POST / PUT avec body JSON
  Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Alias conservé pour compatibilité
  Map<String, String> get authHeaders => jsonHeaders;

  Future<void> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$kApiBase/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Connexion échouée');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _persist(data['token'] as String);
  }

  Future<void> register(String username, String email, String password) async {
    final res = await http.post(
      Uri.parse('$kApiBase/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Inscription échouée');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _persist(data['token'] as String);
  }

  Future<void> logout() async {
    _token = null;
    loggedInNotifier.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> _persist(String token) async {
    _token = token;
    loggedInNotifier.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}
