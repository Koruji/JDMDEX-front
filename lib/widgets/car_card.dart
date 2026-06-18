import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/car.dart';
import '../services/favorites_service.dart';
import '../theme.dart';

const _kGold = Color(0xFFD4AF37);

class CarCard extends StatelessWidget {
  final Car car;
  final int index;
  final VoidCallback onTap;

  const CarCard({super.key, required this.car, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = car.primaryPhotoOrNull;
    final num = (index + 1).toString().padLeft(3, '0');

    return ValueListenableBuilder<Set<int>>(
      valueListenable: FavoritesService.instance.notifier,
      builder: (_, favorites, __) {
        final isFav = favorites.contains(car.id);
        return GestureDetector(
          onTap: onTap,
          child: SizedBox.expand(
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isFav ? _kGold : kBorder, width: isFav ? 1.5 : 1),
                boxShadow: isFav ? [BoxShadow(color: _kGold.withOpacity(0.25), blurRadius: 6, spreadRadius: 0)] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(num),
                  Expanded(child: _buildImageZone(photo, isFav)),
                  _buildStats(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String num) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              car.name,
              style: const TextStyle(color: kText, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (car.horsepower != null)
            Text('${car.horsepower} CV', style: const TextStyle(color: kRed, fontSize: 8, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildImageZone(Photo? photo, bool isFav) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            photo != null
                ? CachedNetworkImage(
                    imageUrl: '$kUploadsBase/${photo.filename}',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ColoredBox(color: kBgElevated),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
            if (car.year != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('${car.year}', style: const TextStyle(color: kText, fontSize: 8, fontWeight: FontWeight.w700)),
                ),
              ),
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => FavoritesService.instance.toggle(car.id),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? _kGold : Colors.white70, size: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marque + lieu
          Row(
            children: [
              if (car.brand != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(3)),
                  child: Text(
                    car.brand!,
                    style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  ),
                ),
              const Spacer(),
              if (car.location != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: kRed.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: kRed, size: 7),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(car.location!, style: const TextStyle(color: kRed, fontSize: 7, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Specs en évidence
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: BoxDecoration(color: kBgElevated, borderRadius: BorderRadius.circular(5)),
            child: Row(
              children: [
                Expanded(child: _specChip(car.horsepower != null ? '${car.horsepower}' : '—', 'CV')),
                const SizedBox(width: 4),
                Expanded(child: _specChip(car.engine ?? '—', 'moteur')),
                const SizedBox(width: 4),
                Expanded(child: _specChip(car.mileage != null ? _fmt(car.mileage!) : '—', 'km')),
              ],
            ),
          ),
          // Proprio en bas à droite
          if (car.owner != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.person_outline, color: kTextMuted, size: 8),
                const SizedBox(width: 2),
                Flexible(child: Text(car.owner!, style: const TextStyle(color: kTextMuted, fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _specChip(String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: kText, fontSize: 9, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(color: kTextMuted, fontSize: 7)),
        ],
      );

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _placeholder() => const ColoredBox(
        color: kBgElevated,
        child: Center(child: Icon(Icons.directions_car_outlined, color: kTextMuted, size: 28)),
      );
}
