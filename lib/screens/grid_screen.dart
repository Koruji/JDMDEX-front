import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/car.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../widgets/car_card.dart';
import '../theme.dart';
import 'detail_screen.dart';
import 'form_screen.dart';

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  List<Car> _cars = [];
  List<Car> _filtered = [];
  bool _loading = true;
  String _query = '';
  bool _favOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cars = await ApiService.getCars();
      if (mounted) {
        setState(() {
          _cars = cars;
          _filtered = _applyFilter(cars, _query);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Car> _applyFilter(List<Car> cars, String q) {
    var result = cars;
    if (_favOnly) {
      final favs = FavoritesService.instance.favorites;
      result = result.where((c) => favs.contains(c.id)).toList();
    }
    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      result = result.where((c) =>
        c.name.toLowerCase().contains(lower) ||
        (c.brand?.toLowerCase().contains(lower) ?? false) ||
        (c.year?.toString().contains(lower) ?? false)
      ).toList();
    }
    return result;
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      _filtered = _applyFilter(_cars, q);
    });
  }

  void _toggleFavFilter() {
    setState(() {
      _favOnly = !_favOnly;
      _filtered = _applyFilter(_cars, _query);
    });
  }

  Future<void> _openDetail(Car car) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(carId: car.id)));
    _load();
  }

  Future<void> _openForm() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kRed))
                  : _cars.isEmpty
                      ? _buildEmpty()
                      : _buildGrid(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNav(),
      floatingActionButton: _buildCameraFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: kCream,
          border: Border(
            bottom: BorderSide(color: kRed.withOpacity(0.4), width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              'JDMDex',
              style: const TextStyle(
                fontFamily: 'GozaruDemo',
                color: kBg,
                fontSize: 30,
              ),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _cars.length.toString().padLeft(3, '0'),
                  style: const TextStyle(color: kRed, fontSize: 22, fontWeight: FontWeight.w800, height: 1),
                ),
                const Text('entries', style: TextStyle(color: kBg, fontSize: 10, letterSpacing: 1)),
              ],
            ),
          ],
        ),
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: _onSearch,
                style: const TextStyle(color: kBg, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une JDM…',
                  prefixIcon: Icon(Icons.search, color: kTextDim, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggleFavFilter,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _favOnly ? const Color(0xFFD4AF37) : kBgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _favOnly ? const Color(0xFFD4AF37) : kBorder),
                ),
                child: Icon(
                  _favOnly ? Icons.star : Icons.star_border,
                  color: _favOnly ? kBg : kTextMuted,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildGrid() => RefreshIndicator(
        color: kRed,
        backgroundColor: kBgCard,
        onRefresh: _load,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => CarCard(
            car: _filtered[i],
            index: _cars.indexOf(_filtered[i]),
            onTap: () => _openDetail(_filtered[i]),
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, color: kTextMuted, size: 64),
            const SizedBox(height: 16),
            const Text('Collection vide', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Scanne ta première JDM ou\najoute-la manuellement.',
              style: TextStyle(color: kTextDim, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openForm,
              style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter une voiture'),
            ),
          ],
        ),
      );

  Widget _buildNav() => BottomAppBar(
        color: kCream,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.grid_view_rounded, label: 'Collection', active: true, onTap: () {}),
            const SizedBox(width: 56),
            _NavItem(icon: Icons.add_box_outlined, label: 'Manuel', onTap: _openForm),
          ],
        ),
      );

  Widget _buildCameraFab() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kRed,
          boxShadow: [BoxShadow(color: kRedGlow, blurRadius: 20, spreadRadius: 2)],
        ),
        child: IconButton(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen(openCamera: true)));
            _load();
          },
          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
        ),
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? kRed : kTextMuted, size: 22),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: active ? kRed : kTextMuted, fontSize: 10)),
            ],
          ),
        ),
      );
}
