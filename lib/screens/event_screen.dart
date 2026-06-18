import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/events_service.dart';
import '../theme.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  static void openForm(BuildContext context, [CarEvent? event]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EventForm(event: event),
    );
  }

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  void initState() {
    super.initState();
    EventsService.instance.load();
  }

  void _openForm([CarEvent? event]) => EventScreen.openForm(context, event);

  void _openDetail(CarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EventDetail(event: event, onEdit: () { Navigator.pop(context); _openForm(event); }),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_outlined, color: kTextMuted, size: 52),
            SizedBox(height: 12),
            Text('Aucun évènement', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Ajoute un rasso ou une expo.', style: TextStyle(color: kTextDim, fontSize: 13)),
          ],
        ),
      );

  void _confirmDelete(CarEvent event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kBorder)),
        title: const Text('Supprimer cet évènement ?', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w800)),
        content: Text('"${event.name}" sera supprimé définitivement.', style: const TextStyle(color: kTextDim, fontSize: 13)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: kBorder), foregroundColor: kTextDim, padding: const EdgeInsets.symmetric(vertical: 12), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Annuler', maxLines: 1),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await EventsService.instance.delete(event.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Supprimer', maxLines: 1),
            )),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ValueListenableBuilder<List<CarEvent>>(
              valueListenable: EventsService.instance.notifier,
              builder: (_, events, __) {
                final today    = events.where((e) => e.isToday).toList();
                final upcoming = events.where((e) => !e.isToday && !e.isPast).toList();
                final past     = events.where((e) => !e.isToday && e.isPast).toList();
                if (events.isEmpty) return _buildEmpty();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (today.isNotEmpty) ...[
                      _sectionLabel("AUJOURD'HUI"),
                      const SizedBox(height: 8),
                      ...today.map((e) => _EventTile(event: e, onTap: () => _openDetail(e), onEdit: () => _openForm(e), onDelete: () => _confirmDelete(e))),
                      const SizedBox(height: 16),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      _sectionLabel('À VENIR'),
                      const SizedBox(height: 8),
                      ...upcoming.map((e) => _EventTile(event: e, onTap: () => _openDetail(e), onEdit: () => _openForm(e), onDelete: () => _confirmDelete(e))),
                      const SizedBox(height: 16),
                    ],
                    if (past.isNotEmpty) ...[
                      _sectionLabel('PASSÉS'),
                      const SizedBox(height: 8),
                      ...past.reversed.map((e) => _EventTile(event: e, onTap: () => _openDetail(e), onEdit: () => _openForm(e), onDelete: () => _confirmDelete(e))),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => ValueListenableBuilder<List<CarEvent>>(
        valueListenable: EventsService.instance.notifier,
        builder: (_, events, __) => Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: kCream,
            border: Border(bottom: BorderSide(color: kRed.withOpacity(0.4))),
          ),
          child: Row(
            children: [
              const Text('JDMDex', style: TextStyle(fontFamily: 'GozaruDemo', color: kBg, fontSize: 30)),
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    events.length.toString().padLeft(3, '0'),
                    style: const TextStyle(color: kRed, fontSize: 22, fontWeight: FontWeight.w800, height: 1),
                  ),
                  const Text('évènements', style: TextStyle(color: kBg, fontSize: 10, letterSpacing: 1)),
                ],
              ),
            ],
          ),
        ),
      );


  Widget _sectionLabel(String label) => Text(label, style: const TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700));
}

// ─── Tile ───

class _EventTile extends StatelessWidget {
  final CarEvent event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventTile({required this.event, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPast = event.isPast;
    final isToday = event.isToday;
    final typeColor = switch (event.type) {
      EventType.rasso => kGreen,
      EventType.expo  => const Color(0xFF7B8FF7),
      EventType.autre => kTextDim,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? kGreen : isPast ? kBorder : kRed.withOpacity(0.35),
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: isToday
              ? [BoxShadow(color: kGreen.withOpacity(0.25), blurRadius: 10, spreadRadius: 1)]
              : isPast ? null : [BoxShadow(color: kRedGlow, blurRadius: 6)],
        ),
        child: Row(
          children: [
            // Date block
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isPast ? kBgElevated : kRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    event.dateStart.day.toString(),
                    style: TextStyle(color: isPast ? kTextDim : Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1),
                  ),
                  if (event.isMultiDay)
                    Text(
                      '→ ${event.dateEnd.day}',
                      style: TextStyle(color: isPast ? kTextMuted : Colors.white70, fontSize: 9),
                    ),
                  Text(
                    _monthShort(event.dateStart.month),
                    style: TextStyle(color: isPast ? kTextMuted : Colors.white70, fontSize: 9, letterSpacing: 0.5),
                  ),
                  Text(
                    event.dateStart.year.toString(),
                    style: TextStyle(color: isPast ? kTextMuted : Colors.white70, fontSize: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
                        child: Text(event.type.label, style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(3)),
                          child: const Text("AUJOURD'HUI", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                        ),
                      ] else if (isPast) ...[
                        const SizedBox(width: 6),
                        const Text('passé', style: TextStyle(color: kTextMuted, fontSize: 9)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(event.name, style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (event.location != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: kTextMuted, size: 10),
                        const SizedBox(width: 2),
                        Expanded(child: Text(event.location!, style: const TextStyle(color: kTextMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, color: kTextMuted, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int m) => ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'][m - 1];
}

// ─── Form ───

class _EventForm extends StatefulWidget {
  final CarEvent? event;
  const _EventForm({this.event});

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _dateStart = DateTime.now();
  DateTime _dateEnd = DateTime.now();
  EventType _type = EventType.rasso;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      final e = widget.event!;
      _nameCtrl.text = e.name;
      _locationCtrl.text = e.location ?? '';
      _notesCtrl.text = e.notes ?? '';
      _dateStart = e.dateStart;
      _dateEnd = e.dateEnd;
      _type = e.type;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final result = await showDialog<(DateTime, DateTime)>(
      context: context,
      builder: (_) => _DateRangeDialog(start: _dateStart, end: _dateEnd),
    );
    if (result != null) setState(() { _dateStart = result.$1; _dateEnd = result.$2; });
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final event = CarEvent(
      id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      dateStart: _dateStart,
      dateEnd: _dateEnd,
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      type: _type,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await EventsService.instance.save(event);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sameDay = _dateStart.year == _dateEnd.year && _dateStart.month == _dateEnd.month && _dateStart.day == _dateEnd.day;
    final dateLabel = sameDay
        ? _fmt(_dateStart)
        : '${_fmt(_dateStart)}  →  ${_fmt(_dateEnd)}';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(widget.event == null ? 'Nouvel évènement' : 'Modifier', style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: kTextDim)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: EventType.values.map((t) {
                final selected = _type == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? kRed : kBgElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: selected ? kRed : kBorder),
                      ),
                      child: Text(t.label, style: TextStyle(color: selected ? Colors.white : kTextDim, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: kBg),
              decoration: const InputDecoration(labelText: 'Nom de l\'évènement'),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: kCream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: kRed, size: 16),
                    const SizedBox(width: 10),
                    Text(dateLabel, style: const TextStyle(color: kBg, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locationCtrl,
              style: const TextStyle(color: kBg),
              decoration: const InputDecoration(labelText: 'Lieu', prefixIcon: Icon(Icons.location_on_outlined, color: kRed, size: 16)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: kBg),
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(widget.event == null ? 'Ajouter' : 'Enregistrer', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Date range popup ───

class _DateRangeDialog extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  const _DateRangeDialog({required this.start, required this.end});

  @override
  State<_DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<_DateRangeDialog> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.start;
    _end = widget.end;
  }

  Future<void> _pick(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kRed, onPrimary: Colors.white, surface: kBgCard, onSurface: kText),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
        if (_end.isBefore(_start)) _start = _end;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kBorder)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Période', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _dateBtn('Début', _start, () => _pick(true))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('→', style: TextStyle(color: kTextMuted, fontSize: 16))),
                Expanded(child: _dateBtn('Fin', _end, () => _pick(false))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kBorder),
                      foregroundColor: kTextDim,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Annuler', maxLines: 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, (_start, _end)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Confirmer', maxLines: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateBtn(String label, DateTime date, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(color: kBgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: kTextMuted, fontSize: 10, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
}

// ─── Event Detail + Comments ───

class _EventDetail extends StatefulWidget {
  final CarEvent event;
  final VoidCallback onEdit;
  const _EventDetail({required this.event, required this.onEdit});

  @override
  State<_EventDetail> createState() => _EventDetailState();
}

class _EventDetailState extends State<_EventDetail> {
  final _commentCtrl = TextEditingController();
  late CarEvent _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final comment = EventComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
    );
    final updated = _event.copyWith(comments: [..._event.comments, comment]);
    await EventsService.instance.save(updated);
    setState(() { _event = updated; _commentCtrl.clear(); });
  }

  Future<void> _editComment(EventComment comment) async {
    final ctrl = TextEditingController(text: comment.text);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kBorder)),
        title: const Text('Modifier le commentaire', style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w800)),
        content: TextField(controller: ctrl, style: const TextStyle(color: kBg), autofocus: true, maxLines: 3, decoration: const InputDecoration(hintText: 'Commentaire')),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: kBorder), foregroundColor: kTextDim, padding: const EdgeInsets.symmetric(vertical: 12), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Annuler', maxLines: 1),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Enregistrer', maxLines: 1),
            )),
          ]),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return;
    final updatedComments = _event.comments.map((c) => c.id == comment.id ? EventComment(id: c.id, text: result, createdAt: c.createdAt) : c).toList();
    final updated = _event.copyWith(comments: updatedComments);
    await EventsService.instance.save(updated);
    setState(() => _event = updated);
  }

  Future<void> _deleteComment(EventComment comment) async {
    final updatedComments = _event.comments.where((c) => c.id != comment.id).toList();
    final updated = _event.copyWith(comments: updatedComments);
    await EventsService.instance.save(updated);
    setState(() => _event = updated);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = switch (_event.type) {
      EventType.rasso => kGreen,
      EventType.expo  => const Color(0xFF7B8FF7),
      EventType.autre => kTextDim,
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(_event.type.label, style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    if (_event.isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(4)),
                        child: const Text("AUJOURD'HUI", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: kBgElevated, borderRadius: BorderRadius.circular(6), border: Border.all(color: kBorder)),
                        child: const Icon(Icons.edit_outlined, color: kText, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_event.name, style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                // Dates
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: kTextMuted, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      _event.isMultiDay
                          ? '${_fmtDate(_event.dateStart)} → ${_fmtDate(_event.dateEnd)}'
                          : _fmtDate(_event.dateStart),
                      style: const TextStyle(color: kTextDim, fontSize: 12),
                    ),
                  ],
                ),
                if (_event.location != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: kTextMuted, size: 13),
                    const SizedBox(width: 6),
                    Text(_event.location!, style: const TextStyle(color: kTextDim, fontSize: 12)),
                  ]),
                ],
                if (_event.notes != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kBgElevated, borderRadius: BorderRadius.circular(8)),
                    child: Text(_event.notes!, style: const TextStyle(color: kTextDim, fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 20),
                // Comments section
                const Text('COMMENTAIRES', style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (_event.comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Aucun commentaire.', style: TextStyle(color: kTextMuted, fontSize: 12)),
                  ),
                ..._event.comments.reversed.map((c) => _CommentTile(comment: c, onEdit: () => _editComment(c), onDelete: () => _deleteComment(c))),
                const SizedBox(height: 12),
                // Add comment
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        style: const TextStyle(color: kBg, fontSize: 13),
                        decoration: const InputDecoration(hintText: 'Ajouter un commentaire…'),
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addComment,
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';
}

class _CommentTile extends StatelessWidget {
  final EventComment comment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CommentTile({required this.comment, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: kBgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.text, style: const TextStyle(color: kText, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_fmtDate(comment.createdAt), style: const TextStyle(color: kTextMuted, fontSize: 9)),
                ],
              ),
            ),
            GestureDetector(onTap: onEdit, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, color: kTextMuted, size: 14))),
            GestureDetector(onTap: onDelete, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, color: kTextMuted, size: 14))),
          ],
        ),
      );

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
