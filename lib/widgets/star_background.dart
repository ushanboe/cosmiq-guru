// Step 1: Inventory
// This file DEFINES:
//   - StarBackground (StatefulWidget) — no constructor params, purely visual
//   - _StarBackgroundState — holds AnimationController, animation value
//   - StarPainter (CustomPainter) — draws 100 white circles with oscillating opacity
//   - _StarData helper class or inline star positions — 100 stars with fixed Random(42) seed
//
// This file USES from other files: NOTHING — purely self-contained widget
// Imports needed: flutter/material.dart, dart:math (for Random, sin, pi)
//
// Step 2: Connections
// - No screen navigates TO this widget directly; it's placed as first child in Stack
// - No navigation FROM this widget
// - No services or models used
//
// Step 3: User Journey Trace
// - Screen renders StarBackground as first child in Stack
// - StarBackground fills parent via SizedBox.expand
// - AnimationController runs 4s, repeats in reverse (oscillates 0.0 -> 1.0 -> 0.0)
// - Each repaint: StarPainter draws 100 circles at fixed positions (Random(42))
//   with opacity = star.baseOpacity * (0.3 + 0.7 * animationValue) or similar oscillation
// - Visual: twinkling star field effect
//
// Step 4: Layout Sanity
// - SizedBox.expand fills parent — correct
// - CustomPaint fills SizedBox.expand — correct
// - AnimationController with vsync, disposed properly
//
// Star positions: generate 100 stars at init using Random(42) for dx, dy (0.0-1.0 normalized)
// and a base radius (0.5-2.0) and phase offset (0.0-2*pi) for varied twinkling
// Opacity formula: baseOpacity * (0.3 + 0.7 * sin(animValue * pi + phaseOffset).abs())
// animValue oscillates 0->1->0 due to repeat(reverse: true)

import 'dart:math';
import 'package:flutter/material.dart';

class _StarData {
  final double x; // normalized 0.0 to 1.0
  final double y; // normalized 0.0 to 1.0
  final double radius;
  final double baseOpacity;
  final double phaseOffset;

  const _StarData({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseOpacity,
    required this.phaseOffset,
  });
}

class StarBackground extends StatefulWidget {
  const StarBackground({super.key});

  @override
  State<StarBackground> createState() => _StarBackgroundState();
}

class _StarBackgroundState extends State<StarBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final List<_StarData> _stars;

  @override
  void initState() {
    super.initState();

    // Build 100 stars with fixed seed for deterministic positions
    final rng = Random(42);
    _stars = List.generate(100, (_) {
      return _StarData(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.5 + rng.nextDouble() * 1.5, // 0.5 to 2.0
        baseOpacity: 0.4 + rng.nextDouble() * 0.6, // 0.4 to 1.0
        phaseOffset: rng.nextDouble() * 2 * pi,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(
            painter: StarPainter(
              stars: _stars,
              animationValue: _animation.value,
            ),
          );
        },
      ),
    );
  }
}

class StarPainter extends CustomPainter {
  final List<_StarData> stars;
  final double animationValue; // 0.0 to 1.0

  const StarPainter({
    required this.stars,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (final star in stars) {
      // Oscillating opacity: each star twinkles at its own phase
      final oscillation =
          sin(animationValue * pi + star.phaseOffset).abs();
      final opacity = star.baseOpacity * (0.3 + 0.7 * oscillation);

      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}