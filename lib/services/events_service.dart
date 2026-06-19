import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../theme.dart';
import 'auth_service.dart';

class EventsService {
  EventsService._();
  static final EventsService instance = EventsService._();

  final ValueNotifier<List<CarEvent>> notifier = ValueNotifier([]);
  List<CarEvent> get events => notifier.value;

  static Map<String, String> get _get => AuthService.instance.bearerHeaders;
  static Map<String, String> get _post => AuthService.instance.jsonHeaders;

  Future<void> load() async {
    try {
      final res = await http.get(Uri.parse('$kApiBase/events'), headers: _get);
      if (res.statusCode != 200) {
        debugPrint('[EventsService] load failed: ${res.statusCode} ${res.body}');
        return;
      }
      final list = (jsonDecode(res.body) as List<dynamic>)
          .map((j) => CarEvent.fromJson(j as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.dateStart.compareTo(b.dateStart));
      notifier.value = list;
    } catch (e) {
      debugPrint('[EventsService] load error: $e');
    }
  }

  // ── Events CRUD ──

  Future<CarEvent> create({
    required String name,
    required DateTime dateStart,
    required DateTime dateEnd,
    String? location,
    required EventType type,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$kApiBase/events'),
      headers: _post,
      body: jsonEncode({
        'name': name,
        'dateStart': dateStart.toIso8601String(),
        'dateEnd': dateEnd.toIso8601String(),
        if (location != null && location.isNotEmpty) 'location': location,
        'type': type.name,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    if (res.statusCode != 201) throw Exception('Échec création évènement: ${res.statusCode} ${res.body}');
    final event = CarEvent.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    final updated = [...notifier.value, event];
    updated.sort((a, b) => a.dateStart.compareTo(b.dateStart));
    notifier.value = updated;
    return event;
  }

  Future<CarEvent> update(
    String id, {
    required String name,
    required DateTime dateStart,
    required DateTime dateEnd,
    String? location,
    required EventType type,
    String? notes,
  }) async {
    final res = await http.put(
      Uri.parse('$kApiBase/events/$id'),
      headers: _post,
      body: jsonEncode({
        'name': name,
        'dateStart': dateStart.toIso8601String(),
        'dateEnd': dateEnd.toIso8601String(),
        'location': location,
        'type': type.name,
        'notes': notes,
      }),
    );
    if (res.statusCode != 200) throw Exception('Échec mise à jour évènement: ${res.statusCode} ${res.body}');
    final event = CarEvent.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    notifier.value = notifier.value.map((e) => e.id == id ? event : e).toList();
    return event;
  }

  Future<void> delete(String id) async {
    final res = await http.delete(
      Uri.parse('$kApiBase/events/$id'),
      headers: _get,
    );
    if (res.statusCode != 204) throw Exception('Échec suppression évènement: ${res.statusCode} ${res.body}');
    notifier.value = notifier.value.where((e) => e.id != id).toList();
  }

  // ── Comments ──

  Future<List<EventComment>> loadComments(String eventId) async {
    final res = await http.get(Uri.parse('$kApiBase/events/$eventId/comments'));
    if (res.statusCode != 200) throw Exception('Échec chargement commentaires: ${res.statusCode} ${res.body}');
    return (jsonDecode(res.body) as List<dynamic>)
        .map((c) => EventComment.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<EventComment> addComment(String eventId, String text) async {
    final res = await http.post(
      Uri.parse('$kApiBase/events/$eventId/comments'),
      headers: _post,
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode != 201) throw Exception('Échec ajout commentaire: ${res.statusCode} ${res.body}');
    return EventComment.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<EventComment> editComment(String eventId, String commentId, String text) async {
    final res = await http.put(
      Uri.parse('$kApiBase/events/$eventId/comments/$commentId'),
      headers: _post,
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode != 200) throw Exception('Échec modification commentaire: ${res.statusCode} ${res.body}');
    return EventComment.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteComment(String eventId, String commentId) async {
    final res = await http.delete(
      Uri.parse('$kApiBase/events/$eventId/comments/$commentId'),
      headers: _get,
    );
    if (res.statusCode != 204) throw Exception('Échec suppression commentaire: ${res.statusCode} ${res.body}');
  }
}
