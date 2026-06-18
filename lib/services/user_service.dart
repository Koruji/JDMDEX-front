import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  static const _key = 'user_profile';

  final ValueNotifier<AppUser?> notifier = ValueNotifier(null);

  AppUser? get user => notifier.value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      notifier.value = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } else {
      notifier.value = const AppUser(
        userId: 1,
        username: 'jdm_driver',
        email: 'jdm@example.com',
        socialMedia: '@jdm_driver',
        profilImgUrl: null,
      );
    }
  }

  Future<void> save(AppUser user) async {
    notifier.value = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }
}
