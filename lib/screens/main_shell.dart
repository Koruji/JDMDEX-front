import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/events_service.dart';
import '../theme.dart';
import 'grid_screen.dart';
import 'event_screen.dart';
import 'form_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0; // 0 = Collection, 1 = Évènements

  void _switchTab(int i) => setState(() => _tab = i);

  Future<void> _openFormCamera() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen(openCamera: true)));
    if (_tab == 0) _reloadGrid();
  }

  Future<void> _openFormManual() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
    if (_tab == 0) _reloadGrid();
  }

  // Notify GridScreen to reload via a key
  final _gridKey = GlobalKey<GridScreenState>();

  void _reloadGrid() => _gridKey.currentState?.reload();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(
        index: _tab,
        children: [
          GridScreen(key: _gridKey, onAddManual: _openFormManual),
          const EventScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildNav(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  bool _hasEventToday(List<CarEvent> events) {
    final now = DateTime.now();
    return events.any((e) =>
      !e.dateStart.isAfter(DateTime(now.year, now.month, now.day, 23, 59)) &&
      !e.dateEnd.isBefore(DateTime(now.year, now.month, now.day)));
  }

  Widget _buildNav() => ValueListenableBuilder<List<CarEvent>>(
        valueListenable: EventsService.instance.notifier,
        builder: (_, events, __) {
          final todayBadge = _hasEventToday(events);
          return BottomAppBar(
            color: kCream,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(icon: Icons.grid_view_rounded, label: 'Collection', active: _tab == 0, onTap: () => _switchTab(0)),
                      _NavItem(icon: Icons.event_outlined, label: 'Évènements', active: _tab == 1, badge: todayBadge, onTap: () => _switchTab(1)),
                    ],
                  ),
                ),
                const SizedBox(width: 56),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(icon: Icons.add_box_outlined, label: 'Manuel', active: false, onTap: _openFormManual),
                      _NavItem(icon: Icons.person_outline, label: 'Profil', active: _tab == 2, onTap: () => _switchTab(2)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildFab() {
    if (_tab == 2) return const SizedBox.shrink();
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kRed,
        boxShadow: [BoxShadow(color: kRedGlow, blurRadius: 20, spreadRadius: 2)],
      ),
      child: _tab == 0
          ? IconButton(
              onPressed: _openFormCamera,
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
            )
          : IconButton(
              onPressed: () => EventScreen.openForm(context),
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool badge;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap, this.badge = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: active ? kRed : kTextMuted, size: 22),
                  if (badge)
                    Positioned(
                      top: -3,
                      right: -5,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: active ? kRed : kTextMuted, fontSize: 10)),
            ],
          ),
        ),
      );
}
