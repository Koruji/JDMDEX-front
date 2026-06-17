import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'grid_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _carX;
  late final Animation<double> _carBob;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _linesOpacity;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 3400),
      vsync: this,
    );

    // -1.7 → 0 → 1.7  (unités : fraction de la largeur d'écran)
    _carX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: -1.7, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.7)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_ctrl);

    // légère oscillation au ralenti
    _carBob = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(
        tween: TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 25),
          TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -3.0), weight: 25),
          TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 25),
        ]),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
    ]).animate(_ctrl);

    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_ctrl);

    _linesOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 23),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 7,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 22),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (_, __, ___) => const GridScreen(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: kBg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          final isEntering = t < 0.35;
          final isExiting = t > 0.70;
          final isMoving = isEntering || isExiting;
          final carOffsetX = _carX.value * screenW;

          return Stack(
            children: [
              // ── Ligne de route ──
              Positioned(
                top: screenH * 0.5 + 30,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(height: 2, color: kRed.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Container(height: 1, color: kCream.withOpacity(0.08)),
                  ],
                ),
              ),

              // ── Lignes de vitesse ──
              if (isMoving)
                Positioned.fill(
                  child: Opacity(
                    opacity: _linesOpacity.value.clamp(0.0, 1.0),
                    child: CustomPaint(
                      painter: SpeedLinesPainter(
                        carOffsetX: carOffsetX,
                        isExiting: isExiting,
                      ),
                    ),
                  ),
                ),

              // ── Voiture ──
              Center(
                child: Transform.translate(
                  offset: Offset(carOffsetX, _carBob.value - 20),
                  child: Transform.scale(
                    // entre de gauche (face droite) = scaleX négatif pour retourner
                    scaleX: isExiting ? 1.0 : -1.0,
                    child: CustomPaint(
                      size: const Size(240, 110),
                      painter: CarPainter(),
                    ),
                  ),
                ),
              ),

              // ── Logo ──
              Center(
                child: Transform.translate(
                  offset: const Offset(0, 90),
                  child: Opacity(
                    opacity: _logoOpacity.value.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'JDMDex',
                          style: TextStyle(
                            fontFamily: 'GozaruDemo',
                            color: kCream,
                            fontSize: 52,
                            shadows: [
                              Shadow(
                                color: kRed.withOpacity(0.6),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────── Voiture ───────────────

class CarPainter extends CustomPainter {
  const CarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()
      ..color = kRed
      ..style = PaintingStyle.fill;
    final darkPaint = Paint()
      ..color = const Color(0xFF6B1818)
      ..style = PaintingStyle.fill;
    final windowPaint = Paint()
      ..color = kCream.withOpacity(0.65)
      ..style = PaintingStyle.fill;
    final wheelPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = kCream
      ..style = PaintingStyle.fill;
    final spokePaint = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final outlinePaint = Paint()
      ..color = const Color(0xFF5A1515)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final lightPaint = Paint()
      ..color = kCream
      ..style = PaintingStyle.fill;

    // ── Carrosserie ──
    final body = Path()
      ..moveTo(w * 0.08, h * 0.78)
      ..lineTo(w * 0.05, h * 0.65)
      ..lineTo(w * 0.08, h * 0.54)
      ..lineTo(w * 0.15, h * 0.50)
      ..lineTo(w * 0.27, h * 0.42)
      ..lineTo(w * 0.35, h * 0.28)
      ..lineTo(w * 0.43, h * 0.18)
      ..lineTo(w * 0.63, h * 0.16)
      ..lineTo(w * 0.74, h * 0.24)
      ..lineTo(w * 0.81, h * 0.38)
      ..lineTo(w * 0.89, h * 0.52)
      ..lineTo(w * 0.93, h * 0.60)
      ..lineTo(w * 0.95, h * 0.78)
      ..close();
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, outlinePaint);

    // Bas de caisse
    final sill = Path()
      ..moveTo(w * 0.15, h * 0.78)
      ..lineTo(w * 0.85, h * 0.78)
      ..lineTo(w * 0.85, h * 0.86)
      ..lineTo(w * 0.15, h * 0.86)
      ..close();
    canvas.drawPath(sill, darkPaint);

    // Aileron
    canvas.drawRect(Rect.fromLTWH(w * 0.78, h * 0.11, w * 0.11, h * 0.04), darkPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.81, h * 0.15, w * 0.02, h * 0.05), darkPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.85, h * 0.15, w * 0.02, h * 0.05), darkPaint);

    // Écope capot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.21, h * 0.41, w * 0.07, h * 0.05),
        const Radius.circular(2),
      ),
      darkPaint,
    );

    // ── Vitrages ──
    final windshield = Path()
      ..moveTo(w * 0.37, h * 0.30)
      ..lineTo(w * 0.44, h * 0.20)
      ..lineTo(w * 0.59, h * 0.19)
      ..lineTo(w * 0.57, h * 0.32)
      ..close();
    canvas.drawPath(windshield, windowPaint);

    final rearWindow = Path()
      ..moveTo(w * 0.61, h * 0.19)
      ..lineTo(w * 0.71, h * 0.20)
      ..lineTo(w * 0.75, h * 0.32)
      ..lineTo(w * 0.63, h * 0.33)
      ..close();
    canvas.drawPath(rearWindow, windowPaint);

    // ── Phare avant ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.07, h * 0.54, w * 0.07, h * 0.07),
        const Radius.circular(2),
      ),
      lightPaint,
    );

    // ── Feu arrière ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.88, h * 0.54, w * 0.05, h * 0.07),
        const Radius.circular(2),
      ),
      Paint()
        ..color = const Color(0xFFCC2222)
        ..style = PaintingStyle.fill,
    );

    // ── Roues ──
    final double wheelR = h * 0.17;
    final frontC = Offset(w * 0.24, h * 0.86);
    final rearC = Offset(w * 0.76, h * 0.86);

    for (final center in [frontC, rearC]) {
      canvas.drawCircle(center, wheelR, wheelPaint);
      canvas.drawCircle(center, wheelR * 0.65, rimPaint);
      for (int i = 0; i < 5; i++) {
        final angle = (i * 72.0 - 90.0) * pi / 180.0;
        canvas.drawLine(
          center,
          Offset(
            center.dx + wheelR * 0.60 * cos(angle),
            center.dy + wheelR * 0.60 * sin(angle),
          ),
          spokePaint,
        );
      }
      canvas.drawCircle(center, wheelR * 0.16, wheelPaint);
    }

    // ── Ligne de caractère ──
    canvas.drawLine(
      Offset(w * 0.11, h * 0.62),
      Offset(w * 0.88, h * 0.62),
      Paint()
        ..color = kCream.withOpacity(0.18)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // ── Pot d'échappement ──
    canvas.drawOval(
      Rect.fromLTWH(w * 0.89, h * 0.73, w * 0.04, h * 0.04),
      darkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────── Lignes de vitesse ───────────────

class SpeedLinesPainter extends CustomPainter {
  final double carOffsetX;
  final bool isExiting;

  const SpeedLinesPainter({
    required this.carOffsetX,
    required this.isExiting,
  });

  static const List<double> _offsets  = [-18, -8, 2, 12, 22, -28, 32];
  static const List<double> _lengths  = [90, 130, 110, 70, 95, 55, 60];
  static const List<double> _opacities = [0.35, 0.50, 0.40, 0.30, 0.35, 0.20, 0.20];

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2 + carOffsetX;
    final centerY = size.height / 2 - 20;

    for (int i = 0; i < _offsets.length; i++) {
      final paint = Paint()
        ..color = kCream.withOpacity(_opacities[i])
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final y = centerY + _offsets[i];

      if (isExiting) {
        final endX = centerX - 130.0;
        canvas.drawLine(
          Offset(endX - _lengths[i], y),
          Offset(endX, y),
          paint,
        );
      } else {
        final startX = centerX + 130.0;
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + _lengths[i], y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SpeedLinesPainter old) =>
      old.carOffsetX != carOffsetX || old.isExiting != isExiting;
}
