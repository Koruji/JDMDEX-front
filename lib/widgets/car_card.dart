import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/car.dart';
import '../theme.dart';

class CarCard extends StatelessWidget {
  final Car car;
  final int index;
  final VoidCallback onTap;

  const CarCard({super.key, required this.car, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = car.primaryPhotoOrNull;
    final num = (index + 1).toString().padLeft(3, '0');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
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
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            border: Border.all(color: kRed),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${car.year}',
                            style: const TextStyle(color: kRed, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#$num', style: const TextStyle(color: kRed, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    car.name,
                    style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    car.brand ?? '—',
                    style: const TextStyle(color: kTextDim, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => const ColoredBox(
        color: kBgElevated,
        child: Center(
          child: Icon(Icons.directions_car_outlined, color: kTextMuted, size: 32),
        ),
      );
}
