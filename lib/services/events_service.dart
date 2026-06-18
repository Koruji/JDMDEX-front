import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

class EventsService {
  EventsService._();
  static final EventsService instance = EventsService._();

  static const _key = 'events';

  final ValueNotifier<List<CarEvent>> notifier = ValueNotifier([]);

  List<CarEvent> get events => notifier.value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final list = raw.map((s) => CarEvent.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    list.sort((a, b) => a.dateStart.compareTo(b.dateStart));
    notifier.value = list;
  }

  Future<void> save(CarEvent event) async {
    final updated = List<CarEvent>.from(notifier.value);
    final idx = updated.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      updated[idx] = event;
    } else {
      updated.add(event);
    }
    updated.sort((a, b) => a.dateStart.compareTo(b.dateStart));
    notifier.value = updated;
    await _persist();
  }

  Future<void> delete(String id) async {
    notifier.value = notifier.value.where((e) => e.id != id).toList();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, notifier.value.map((e) => jsonEncode(e.toJson())).toList());
  }
}
