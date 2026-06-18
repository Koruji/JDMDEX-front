import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const _key = 'favorites';

  final ValueNotifier<Set<int>> notifier = ValueNotifier({});

  Set<int> get favorites => notifier.value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    notifier.value = ids.map(int.parse).toSet();
  }

  Future<void> toggle(int carId) async {
    final updated = Set<int>.from(notifier.value);
    if (updated.contains(carId)) {
      updated.remove(carId);
    } else {
      updated.add(carId);
    }
    notifier.value = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.map((id) => id.toString()).toList());
  }

  bool isFavorite(int carId) => notifier.value.contains(carId);
}
