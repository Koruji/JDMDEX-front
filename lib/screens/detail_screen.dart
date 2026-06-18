import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/car.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../theme.dart';
import 'form_screen.dart';

class DetailScreen extends StatefulWidget {
  final int carId;
  const DetailScreen({super.key, required this.carId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Car? _car;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final car = await ApiService.getCar(widget.carId);
      if (mounted) setState(() { _car = car; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPhotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return;

    final photos = await Future.wait(
      files.map((f) async => (bytes: await f.readAsBytes(), name: f.name)),
    );

    await ApiService.addPhotos(widget.carId, photos);
    _load();
  }

  Future<void> _deletePhoto(Photo photo) async {
    await ApiService.deletePhoto(widget.carId, photo.id);
    _load();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: kBorder)),
        title: const Text('Supprimer cette entrée ?', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('"${_car?.name}" sera supprimée définitivement.', style: const TextStyle(color: kTextDim, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: kTextDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, shadowColor: kRedGlow, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.deleteCar(widget.carId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kRed)),
      );
    }
    if (_car == null) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: Text('Voiture introuvable', style: TextStyle(color: kTextDim))),
      );
    }
    return _buildDetail(_car!);
  }

  Widget _buildDetail(Car car) => Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(car)),
              SliverToBoxAdapter(child: _buildGallery(car)),
              SliverToBoxAdapter(child: _buildSpecs(car)),
              SliverToBoxAdapter(child: _buildActions(car)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      );

  Widget _buildHeader(Car car) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: kCream, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, size: 14, color: kBg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('JDM', style: TextStyle(color: kRed, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  Text(car.name, style: const TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (car.brand != null) Text(car.brand!, style: const TextStyle(color: kTextDim, fontSize: 12)),
                ],
              ),
            ),
            ValueListenableBuilder<Set<int>>(
              valueListenable: FavoritesService.instance.notifier,
              builder: (_, favs, __) {
                final isFav = favs.contains(car.id);
                return _IconBtn(
                  icon: isFav ? Icons.star : Icons.star_border,
                  onTap: () => FavoritesService.instance.toggle(car.id),
                  gold: isFav,
                );
              },
            ),
            const SizedBox(width: 8),
            _IconBtn(icon: Icons.delete_outline, onTap: _confirmDelete, danger: true),
          ],
        ),
      );

  Widget _buildGallery(Car car) {
    if (car.photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: kBgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: const Center(
              child: Icon(Icons.directions_car_outlined, color: kTextMuted, size: 40),
            ),
          ),
        ),
      );
    }

    return _Carousel(photos: car.photos);
  }

  Widget _buildLocation(Car car) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: kGreen, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(car.location!, style: const TextStyle(color: kTextDim, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _buildSpecs(Car car) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FICHE TECHNIQUE', style: TextStyle(color: kTextDim, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              children: [
                _SpecCard(label: 'Marque', value: car.brand),
                _SpecCard(label: 'Année', value: car.year?.toString()),
                _SpecCard(label: 'Puissance', value: car.horsepower != null ? '${car.horsepower} ch' : null, highlight: true),
                _SpecCard(label: 'Kilométrage', value: car.mileage != null ? '${_fmtKm(car.mileage!)} km' : null),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _SpecCard(label: 'Moteur', value: car.engine)),
                if (car.owner != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _SpecCard(label: 'Propriétaire', value: car.owner)),
                ],
              ],
            ),
            if (car.location != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: kRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kRed.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: kRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(car.location!, style: const TextStyle(color: kRed, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildActions(Car car) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kBorder),
                  foregroundColor: kText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retour'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => FormScreen(car: car)));
                  _load();
                },
                style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
                child: const Text('Modifier'),
              ),
            ),
          ],
        ),
      );

  String _fmtKm(int km) {
    final s = km.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ThumbWithDelete extends StatelessWidget {
  final String url;
  final VoidCallback onDelete;
  const _ThumbWithDelete({required this.url, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: url, width: 90, height: 90, fit: BoxFit.cover),
            ),
            Positioned(
              top: -4, right: -4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
}

class _SpecCard extends StatelessWidget {
  final String label;
  final String? value;
  final bool highlight;
  final bool full;
  const _SpecCard({required this.label, this.value, this.highlight = false, this.full = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(
              value ?? '—',
              style: TextStyle(
                color: value == null ? kTextMuted : (highlight ? kRed : kText),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontStyle: value == null ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

// ─── Carousel ───

class _Carousel extends StatefulWidget {
  final List<Photo> photos;
  const _Carousel({required this.photos});

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _pageCtrl = PageController();
  int _current = 0;

  void _prev() {
    if (_current > 0) _pageCtrl.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void _next() {
    if (_current < widget.photos.length - 1) _pageCtrl.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.photos.length > 1;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                ScrollConfiguration(
                  behavior: _WebDragBehavior(),
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: widget.photos.length,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (_, i) {
                      final url = '$kUploadsBase/${widget.photos[i].filename}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ColoredBox(color: kBgElevated),
                            errorWidget: (_, __, ___) => const ColoredBox(
                              color: kBgElevated,
                              child: Center(child: Icon(Icons.broken_image_outlined, color: kTextMuted)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (multi && _current > 0)
                  Positioned(
                    left: 20, top: 0, bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _prev,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                if (multi && _current < widget.photos.length - 1)
                  Positioned(
                    right: 20, top: 0, bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _next,
                        child: Container(
                          width: 30, height: 30,
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (multi) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.photos.length, (i) {
                final active = i == _current;
                return GestureDetector(
                  onTap: () => _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? kRed : kTextMuted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _WebDragBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}

// ─── IconBtn ───

const _kGold = Color(0xFFD4AF37);

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  final bool gold;
  const _IconBtn({required this.icon, required this.onTap, this.danger = false, this.gold = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? kRed : gold ? _kGold : kText;
    final borderColor = danger ? kRed.withOpacity(0.4) : gold ? _kGold.withOpacity(0.5) : kBorder;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: kBgElevated, shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
