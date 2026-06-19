import 'dart:convert';
import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
import 'package:http/http.dart' as http;
import '../theme.dart';
import 'auth_service.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  final ValueNotifier<Set<int>> notifier = ValueNotifier({});
  Set<int> get favorites => notifier.value;

  Future<void> load() async {
    try {
      if (!AuthService.instance.isLoggedIn) return;
      final res = await http.get(
        Uri.parse('$kApiBase/cars'),
        headers: AuthService.instance.bearerHeaders,
      );
      if (res.statusCode != 200) {
        debugPrint('[FavoritesService] load failed: ${res.statusCode}');
        return;
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      final ids = list
          .where((j) => j['liked'] == true || j['liked'] == 1)
          .map<int>((j) => (j['id'] as num).toInt())
          .toSet();
      notifier.value = ids;
    } catch (e) {
      debugPrint('[FavoritesService] load error: $e');
    }
  }

  Future<void> toggle(int carId) async {
    final wasFav = notifier.value.contains(carId);
    // Optimistic update
    final updated = Set<int>.from(notifier.value);
    if (wasFav) updated.remove(carId); else updated.add(carId);
    notifier.value = updated;

    try {
      final res = await http.patch(
        Uri.parse('$kApiBase/cars/$carId'),
        headers: AuthService.instance.jsonHeaders,
        body: jsonEncode({'liked': !wasFav}),
      );
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('[FavoritesService] toggle error: $e');
      // Revert on error
      final reverted = Set<int>.from(notifier.value);
      if (wasFav) reverted.add(carId); else reverted.remove(carId);
      notifier.value = reverted;
    }
  }

  bool isFavorite(int carId) => notifier.value.contains(carId);
}
