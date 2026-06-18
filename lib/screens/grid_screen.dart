import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../widgets/car_card.dart';
import '../theme.dart';
import 'detail_screen.dart';

class GridScreen extends StatefulWidget {
  final VoidCallback? onAddManual;
  const GridScreen({super.key, this.onAddManual});

  @override
  State<GridScreen> createState() => GridScreenState();
}

class GridScreenState extends State<GridScreen> {
  void reload() => _load();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // ignore: avoid_dynamic_calls
            crossAxisCount: MediaQuery.sizeOf(context).width < 400 ? 2 : 3,
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
              onPressed: widget.onAddManual,
              style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter une voiture'),
            ),
          ],
        ),
      );

}
