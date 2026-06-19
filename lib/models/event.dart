enum EventType { rasso, expo, autre }

extension EventTypeLabel on EventType {
  String get label => switch (this) {
        EventType.rasso => 'Rasso',
        EventType.expo => 'Expo',
        EventType.autre => 'Autre',
      };
}

class EventComment {
  final String id;
  final String text;
  final DateTime createdAt;

  const EventComment({required this.id, required this.text, required this.createdAt});

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'createdAt': createdAt.toIso8601String()};

  factory EventComment.fromJson(Map<String, dynamic> j) => EventComment(
        id: j['id'].toString(),
        text: j['text'] as String,
        createdAt: DateTime.parse((j['created_at'] ?? j['createdAt']) as String),
      );
}

class CarEvent {
  final String id;
  final String name;
  final DateTime dateStart;
  final DateTime dateEnd;
  final String? location;
  final EventType type;
  final String? notes;
  final List<EventComment> comments;

  const CarEvent({
    required this.id,
    required this.name,
    required this.dateStart,
    required this.dateEnd,
    this.location,
    required this.type,
    this.notes,
    this.comments = const [],
  });

  bool get isPast => dateEnd.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(dateStart.year, dateStart.month, dateStart.day);
    final end = DateTime(dateEnd.year, dateEnd.month, dateEnd.day);
    return !start.isAfter(today) && !end.isBefore(today);
  }
  bool get isMultiDay => !_sameDay(dateStart, dateEnd);

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  CarEvent copyWith({List<EventComment>? comments}) => CarEvent(
        id: id, name: name, dateStart: dateStart, dateEnd: dateEnd,
        location: location, type: type, notes: notes,
        comments: comments ?? this.comments,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateStart': dateStart.toIso8601String(),
        'dateEnd': dateEnd.toIso8601String(),
        'location': location,
        'type': type.name,
        'notes': notes,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  factory CarEvent.fromJson(Map<String, dynamic> j) {
    // Backend list uses date_start/date_end, detail uses dateStart/dateEnd
    final start = DateTime.parse(
      (j['date_start'] ?? j['dateStart'] ?? j['date']) as String,
    );
    final rawEnd = j['date_end'] ?? j['dateEnd'];
    final end = rawEnd != null ? DateTime.parse(rawEnd as String) : start;
    return CarEvent(
      id: j['id'].toString(),
      name: j['name'] as String,
      dateStart: start,
      dateEnd: end,
      location: j['location'] as String?,
      type: EventType.values.firstWhere((e) => e.name == j['type'], orElse: () => EventType.autre),
      notes: j['notes'] as String?,
      comments: (j['comments'] as List<dynamic>? ?? [])
          .map((c) => EventComment.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
