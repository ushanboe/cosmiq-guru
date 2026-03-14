// Step 1: Inventory
// This file DEFINES:
//   - LuckGauge (StatefulWidget) — takes score: int, animationDuration: Duration
//   - _LuckGaugeState — holds AnimationController, CurvedAnimation, Animation<int> for score count-up
//   - LuckGaugePainter (CustomPainter) — draws background arc and gradient foreground arc
//
// This file USES from other files: NOTHING — purely self-contained widget
// Imports needed: flutter/material.dart, dart:math (for pi, sin), dart:ui (for gradient)
//
// Step 2: Connections
// - HomeScreen renders LuckGauge(score: _luckScore) — receives score as int prop
// - LuckGauge runs its own AnimationController internally
// - No navigation from this widget
// - No services used
//
// Step 3: User Journey Trace
// - LuckGauge receives score (e.g. 73) and animationDuration
// - On initState: AnimationController starts, CurvedAnimation wraps it
// - IntTween animates from 0 to score value
// - CustomPainter draws: dark background arc (270 degrees), gradient foreground arc (score/100 * 270 degrees)
// - Center text shows animated integer score value
// - Colors: 0-33 red, 34-66 yellow, 67-100 green (gradient blend)
// - Size: 200x200dp fixed
//
// Step 4: Layout Sanity
// - SizedBox(200, 200) wraps CustomPaint + Center text Stack
// - AnimationController disposed properly
// - Gradient arc: use Paint with shader from SweepGradient mapped to canvas
// - Background arc: grey/dark purple, full 270 degree arc
// - Foreground arc: gradient from red -> yellow -> green, sweeps to score fraction
// - Arc starts at 135 degrees (bottom-left), sweeps 270 degrees total (ends at bottom-right)
// - Score text: large white bold, subtitle "LUCK SCORE" below
//
// Color scheme per spec:
//   gaugeRed: Color(0xFFEF4444)
//   gaugeYellow: Color(0xFFF59E0B)
//   gaugeGreen: Color(0xFF10B981)
//   background arc: Color(0xFF241538) (surface color)
//
// Gradient approach: use ui.Gradient.sweep for the foreground arc shader
// The arc spans from 135° to 405° (135 + 270). In radians: startAngle = 3*pi/4, sweepAngle = 3*pi/2
// For gradient shader: create a SweepGradient aligned to the arc's angular range

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LuckGauge extends StatefulWidget {
  final int score;
  final Duration animationDuration;

  const LuckGauge({
    super.key,
    required this.score,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<LuckGauge> createState() => _LuckGaugeState();
}

class _LuckGaugeState extends State<LuckGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;
  late final Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scoreAnimation = IntTween(begin: 0, end: widget.score.clamp(0, 100))
        .animate(_curvedAnimation);

    _controller.forward();
  }

  @override
  void didUpdateWidget(LuckGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = IntTween(begin: 0, end: widget.score.clamp(0, 100))
          .animate(_curvedAnimation);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curvedAnimation,
      builder: (context, _) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 200),
                painter: LuckGaugePainter(
                  progress: _curvedAnimation.value,
                  score: _scoreAnimation.value,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_scoreAnimation.value}',
                    style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'LUCK SCORE',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class LuckGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final int score; // 0 to 100

  static const double _startAngle = 3 * pi / 4; // 135 degrees
  static const double _totalSweep = 3 * pi / 2; // 270 degrees
  static const double _strokeWidth = 16.0;

  static const Color _gaugeRed = Color(0xFFEF4444);
  static const Color _gaugeYellow = Color(0xFFF59E0B);
  static const Color _gaugeGreen = Color(0xFF10B981);
  static const Color _trackColor = Color(0xFF241538);

  const LuckGaugePainter({
    required this.progress,
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track arc
    final trackPaint = Paint()
      ..color = _trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _totalSweep, false, trackPaint);

    // Draw subtle track border
    final trackBorderPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth + 2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _totalSweep, false, trackBorderPaint);

    // Redraw track on top of border
    canvas.drawArc(rect, _startAngle, _totalSweep, false, trackPaint);

    if (progress <= 0) return;

    // Calculate the sweep for the foreground arc
    final foregroundSweep = _totalSweep * progress;

    // Build gradient shader across the arc
    // The gradient goes from red (start of arc) through yellow (middle) to green (end)
    // We use a SweepGradient centered at the arc center
    final gradientShader = ui.Gradient.sweep(
      center,
      [
        _gaugeRed,
        _gaugeYellow,
        _gaugeGreen,
        _gaugeGreen,
      ],
      [0.0, 0.5, 1.0, 1.0],
      TileMode.clamp,
      _startAngle,
      _startAngle + _totalSweep,
    );

    final foregroundPaint = Paint()
      ..shader = gradientShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, foregroundSweep, false, foregroundPaint);

    // Draw glow effect at the tip of the foreground arc
    final tipAngle = _startAngle + foregroundSweep;
    final tipX = center.dx + radius * cos(tipAngle);
    final tipY = center.dy + radius * sin(tipAngle);
    final tipOffset = Offset(tipX, tipY);

    // Determine tip color based on current progress
    final Color tipColor;
    if (progress < 0.5) {
      tipColor = Color.lerp(_gaugeRed, _gaugeYellow, progress * 2)!;
    } else {
      tipColor = Color.lerp(_gaugeYellow, _gaugeGreen, (progress - 0.5) * 2)!;
    }

    final glowPaint = Paint()
      ..color = tipColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(tipOffset, _strokeWidth / 2 + 2, glowPaint);

    final tipDotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(tipOffset, 4, tipDotPaint);
  }

  @override
  bool shouldRepaint(LuckGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.score != score;
  }
}