import 'dart:math';

import 'package:flutter/material.dart';

/// Label colours of cassettes.
const cassetteColors = [
  0xFFE8505B, // red
  0xFFF9A03F, // orange
  0xFF3DB2A0, // teal
  0xFF5B7FE8, // blue
  0xFFB05BE8, // purple
];

/// A cassette tape with a coloured label.
class Cassette extends StatelessWidget {
  /// Creates the cassette.
  const Cassette({
    required this.title,
    required this.color,
    this.from = '',
    this.turns,
    this.width = 220,
    this.progress,
    super.key,
  });

  /// How far the tape has played (0–1); `null` draws no tape.
  final double? progress;

  /// Text on the label.
  final String title;

  /// Who made it, under the title.
  final String from;

  /// Label colour.
  final Color color;

  /// Turns of the reels; `null` keeps them still.
  final Animation<double>? turns;

  /// Width; the height follows.
  final double width;

  @override
  Widget build(BuildContext context) {
    final w = width;
    final h = w * 0.63;
    Widget reel([double? wound]) {
      final r = RotationTransition(
        turns: turns ?? const AlwaysStoppedAnimation(0),
        child: CustomPaint(
          size: Size.square(w * 0.17),
          painter: _ReelPainter(),
        ),
      );
      if (wound == null) return r;
      // Tape wound on the reel: from a thin ring to a full spool.
      final tape = w * (0.11 + 0.13 * wound);
      return SizedBox.square(
        dimension: w * 0.17,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            OverflowBox(
              maxWidth: tape,
              maxHeight: tape,
              child: Container(
                width: tape,
                height: tape,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A3426),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            r,
          ],
        ),
      );
    }

    final played = progress;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF26262B),
        borderRadius: BorderRadius.circular(w * 0.05),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 10),
            color: Color(0x80000000),
          ),
        ],
      ),
      padding: EdgeInsets.all(w * 0.05),
      child: Column(
        children: [
          Container(
            height: h * 0.62,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.05, w * 0.05, 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(w * 0.025),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.065,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (from.isNotEmpty)
                  Text(
                    from,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: w * 0.045,
                    ),
                  ),
                const Spacer(),
                Container(
                  height: h * 0.26,
                  margin: EdgeInsets.symmetric(horizontal: w * 0.12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26262B),
                    borderRadius: BorderRadius.circular(h * 0.13),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      reel(played == null ? null : 1 - played),
                      reel(played),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.04),
              ],
            ),
          ),
          const Spacer(),
          // The trapezoid at the bottom with its screw holes.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: w * 0.025,
                  height: w * 0.025,
                  decoration: const BoxDecoration(
                    color: Color(0xFF111114),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFEDEDED));
    final hub = Paint()..color = const Color(0xFF26262B);
    canvas.drawCircle(c, r * 0.45, hub);
    for (var i = 0; i < 6; i++) {
      final a = i * pi / 3;
      canvas.drawCircle(
        c + Offset(cos(a), sin(a)) * r * 0.32,
        r * 0.09,
        Paint()..color = const Color(0xFFEDEDED),
      );
    }
  }

  @override
  bool shouldRepaint(_ReelPainter old) => false;
}
