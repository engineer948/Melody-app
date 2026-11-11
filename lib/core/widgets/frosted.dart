import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/theme_controller.dart';

/// Translucent "frosted glass" surface that blurs what scrolls behind it.
///
/// The opacity follows the user's bar opacity setting.
class Frosted extends ConsumerWidget {
  /// Creates a frosted surface around [child].
  const Frosted({required this.child, this.borderRadius, super.key});

  /// Content drawn on the glass.
  final Widget child;

  /// Optional rounding, e.g. for the floating mini player.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opacity = ref.watch(
      themeControllerProvider.select((s) => s.barOpacity),
    );
    final color = Theme.of(context).colorScheme.surfaceContainer;
    final glass = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: ColoredBox(
        color: color.withValues(alpha: opacity),
        child: child,
      ),
    );
    return borderRadius == null
        ? ClipRect(child: glass)
        : ClipRRect(borderRadius: borderRadius!, child: glass);
  }
}
