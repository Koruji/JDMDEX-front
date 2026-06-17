import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/car.dart';
import '../services/api_service.dart';
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
            style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, shadowColor: kRedGlow),
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
              if (car.location != null) SliverToBoxAdapter(child: _buildLocation(car)),
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
                decoration: BoxDecoration(
                  color: kBgElevated, shape: BoxShape.circle,
                  border: Border.all(color: kBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 14, color: kText),
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
            _IconBtn(icon: Icons.delete_outline, onTap: _confirmDelete, danger: true),
          ],
        ),
      );

  Widget _buildGallery(Car car) {
    final primary = car.primaryPhotoOrNull;
    final others = car.photos.where((p) => p.id != primary?.id).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 180,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            // Primary
            Container(
              width: 240,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
                color: kBgElevated,
              ),
              clipBehavior: Clip.hardEdge,
              child: primary != null
                  ? CachedNetworkImage(imageUrl: '$kUploadsBase/${primary.filename}', fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.directions_car_outlined, color: kTextMuted, size: 32)),
            ),
            // Others
            ...others.map((p) => _ThumbWithDelete(
              url: '$kUploadsBase/${p.filename}',
              onDelete: () => _deletePhoto(p),
            )),
            // Add button
            GestureDetector(
              onTap: _addPhotos,
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kTextMuted, style: BorderStyle.solid),
                  color: kBgElevated,
                ),
                child: const Center(child: Icon(Icons.add, color: kTextMuted, size: 28)),
              ),
            ),
          ],
        ),
      ),
    );
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
            _SpecCard(label: 'Moteur', value: car.engine, full: true),
            if (car.owner != null) ...[
              const SizedBox(height: 8),
              _SpecCard(label: 'Propriétaire', value: car.owner, full: true),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  const _IconBtn({required this.icon, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: kBgElevated, shape: BoxShape.circle,
            border: Border.all(color: danger ? kRed.withOpacity(0.4) : kBorder),
          ),
          child: Icon(icon, size: 16, color: danger ? kRed : kText),
        ),
      );
}
