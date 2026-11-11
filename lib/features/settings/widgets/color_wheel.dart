import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:melody/l10n/l10n.dart';

/// Formats [color] as `#RRGGBB`.
String hexOf(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Parses `#RRGGBB` or `RRGGBB`; `null` when invalid.
Color? parseHex(String text) {
  final hex = text.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex, radix: 16));
}

/// Opens the color wheel and returns the chosen color.
Future<Color?> showColorWheel(BuildContext context, Color initial) =>
    showDialog<Color>(
      context: context,
      builder: (context) => _ColorWheelDialog(initial: initial),
    );

class _ColorWheelDialog extends StatefulWidget {
  const _ColorWheelDialog({required this.initial});

  final Color initial;

  @override
  State<_ColorWheelDialog> createState() => _ColorWheelDialogState();
}

class _ColorWheelDialogState extends State<_ColorWheelDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final _hex = TextEditingController(text: hexOf(widget.initial));

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(HSVColor hsv) {
    setState(() => _hsv = hsv);
    _hex.text = hexOf(hsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = _hsv.toColor();
    return AlertDialog(
      title: Text(l10n.colorPickerTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorWheel(value: _hsv, onChanged: _set),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(l10n.brightness),
                Expanded(
                  child: Slider(
                    value: _hsv.value,
                    onChanged: (v) => _set(_hsv.withValue(v)),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _hex,
                    decoration: InputDecoration(
                      labelText: l10n.colorHex,
                      border: const OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    onChanged: (text) {
                      final parsed = parseHex(text);
                      if (parsed != null) {
                        setState(() => _hsv = HSVColor.fromColor(parsed));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _hsv.toColor()),
          child: Text(l10n.apply),
        ),
      ],
    );
  }
}

/// Round hue / saturation wheel.
class ColorWheel extends StatelessWidget {
  /// Creates the wheel.
  const ColorWheel({
    required this.value,
    required this.onChanged,
    this.size = 240,
    super.key,
  });

  /// Selected color.
  final HSVColor value;

  /// Called while the user drags.
  final ValueChanged<HSVColor> onChanged;

  /// Diameter.
  final double size;

  void _pick(Offset local) {
    final center = Offset(size / 2, size / 2);
    final delta = local - center;
    final hue = (atan2(delta.dy, delta.dx) * 180 / pi + 360) % 360;
    final saturation = (delta.distance / (size / 2)).clamp(0.0, 1.0);
    onChanged(value.withHue(hue).withSaturation(saturation));
  }

  @override
  Widget build(BuildContext context) {
    final angle = value.hue * pi / 180;
    final radius = value.saturation * size / 2;
    final marker = Offset(
      size / 2 + cos(angle) * radius,
      size / 2 + sin(angle) * radius,
    );
    return Semantics(
      label: context.l10n.colorPickerTitle,
      value: hexOf(value.toColor()),
      child: GestureDetector(
        onPanDown: (d) => _pick(d.localPosition),
        onPanUpdate: (d) => _pick(d.localPosition),
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _WheelPainter(brightness: value.value),
            child: Stack(
              children: [
                Positioned(
                  left: marker.dx - 12,
                  top: marker.dy - 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: value.toColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({required this.brightness});

  final double brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;
    final hues = [
      for (var h = 0; h <= 360; h += 30)
        HSVColor.fromAHSV(1, h % 360, 1, brightness).toColor(),
    ];
    canvas
      ..drawCircle(
        center,
        radius,
        Paint()..shader = SweepGradient(colors: hues).createShader(rect),
      )
      ..drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              HSVColor.fromAHSV(1, 0, 0, brightness).toColor(),
              HSVColor.fromAHSV(0, 0, 0, brightness).toColor(),
            ],
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.brightness != brightness;
}
