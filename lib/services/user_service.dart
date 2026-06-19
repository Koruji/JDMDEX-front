import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../theme.dart';
import 'auth_service.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final ValueNotifier<AppUser?> notifier = ValueNotifier(null);
  AppUser? get user => notifier.value;

  Future<void> load() async {
    try {
      if (!AuthService.instance.isLoggedIn) return;
      final res = await http.get(
        Uri.parse('$kApiBase/users/me'),
        headers: AuthService.instance.bearerHeaders,
      );
      if (res.statusCode != 200) return;
      notifier.value = AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[UserService] load error: $e');
    }
  }

  Future<void> save(AppUser user, {Uint8List? photoBytes, String? photoName}) async {
    notifier.value = user;
    try {
      final req = http.MultipartRequest('PUT', Uri.parse('$kApiBase/users/me'));
      req.headers.addAll(AuthService.instance.bearerHeaders);
      req.fields['username'] = user.username;
      req.fields['email'] = user.email;
      if (user.socialMedia != null && user.socialMedia!.isNotEmpty) {
        req.fields['social_media'] = user.socialMedia!;
      }
      if (photoBytes != null && photoName != null) {
        req.files.add(http.MultipartFile.fromBytes('profil_img', photoBytes, filename: photoName));
      }
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        notifier.value = AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        debugPrint('[UserService] save error: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[UserService] save error: $e');
    }
  }
}
