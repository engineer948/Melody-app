import 'dart:math';

import 'package:flutter/material.dart';

/// Large soft blobs of colour that drift slowly: the colourful background
/// of the player and of album and playlist pages.
///
/// [colors] are spread over the area; [animate] makes them move.
class ColorWash extends StatefulWidget {
  /// Creates the background.
  const ColorWash({
    required this.colors,
    this.base,
    this.animate = true,
    this.opacity = 1,
    super.key,
  });

  /// Turns the drifting off everywhere, e.g. in widget tests that wait for
  /// animations to end.
  static bool driftEnabled = true;

  /// Colours of the blobs, most important first.
  final List<Color> colors;

  /// Colour underneath, left visible between the blobs; black by default.
  final Color? base;

  /// Whether the blobs drift.
  final bool animate;

  /// Strength of the blobs, 0–1.
  final double opacity;

  @override
  State<ColorWash> createState() => _ColorWashState();
}

class _ColorWashState extends State<ColorWash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ColorWash old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final reduce = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (widget.animate && !reduce && ColorWash.driftEnabled) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors.isEmpty
        ? [Theme.of(context).colorScheme.primary]
        : widget.colors;
    final base = widget.base ?? Colors.black;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _WashPainter(
            colors: colors,
            base: base,
            t: _controller.value,
            opacity: widget.opacity,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _WashPainter extends CustomPainter {
  _WashPainter({
    required this.colors,
    required this.base,
    required this.t,
    required this.opacity,
  });

  final List<Color> colors;
  final Color base;
  final double t;
  final double opacity;

  // Where each blob circles around, as fractions of the size.
  static const _anchors = [
    Offset(0.15, 0.1),
    Offset(0.9, 0.3),
    Offset(0.25, 0.75),
    Offset(0.85, 0.95),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    // Blobs leave the base colour showing around them: ambient light, not
    // a coloured background.
    final radius = max(size.width, size.height) * 0.5;
    for (var i = 0; i < _anchors.length; i++) {
      final color = colors[i % colors.length];
      final angle = 2 * pi * (t + i / _anchors.length);
      final wobble =
          Offset(cos(angle), sin(angle * (i.isEven ? 1 : -1))) *
          (size.shortestSide * 0.12);
      final center =
          Offset(_anchors[i].dx * size.width, _anchors[i].dy * size.height) +
          wobble;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.55 * opacity),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.35, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_WashPainter old) =>
      old.t != t ||
      old.colors != colors ||
      old.base != base ||
      old.opacity != opacity;
}
