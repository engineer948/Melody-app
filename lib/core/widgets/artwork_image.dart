import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_controller.dart';

/// Square cover image with a placeholder for missing or loading artwork.
class ArtworkImage extends ConsumerWidget {
  /// Creates the image.
  const ArtworkImage({
    required this.artwork,
    this.size,
    this.radius = 8,
    this.icon = Icons.album_outlined,
    this.circular = false,
    super.key,
  });

  /// Cover to show; `null` shows the placeholder.
  final Artwork? artwork;

  /// Edge length in logical pixels; `null` fills the parent's width.
  final double? size;

  /// Corner radius.
  final double radius;

  /// Icon of the placeholder.
  final IconData icon;

  /// Whether to clip to a circle, used for artists.
  final bool circular;

  /// Requested image sizes; few buckets keep the cache effective.
  static int bucket(double pixels) => switch (pixels) {
    <= 160 => 160,
    <= 320 => 320,
    _ => 640,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(activeSourceProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = size ?? constraints.maxWidth;
        final pixels = bucket(extent * MediaQuery.devicePixelRatioOf(context));
        final uri = source?.artworkUri(artwork, size: pixels);
        final placeholder = _Placeholder(icon: icon, extent: extent);
        final hash = artwork?.blurHash;
        final child = uri == null
            ? placeholder
            : CachedNetworkImage(
                imageUrl: uri.toString(),
                httpHeaders: source?.requestHeaders,
                memCacheWidth: pixels,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) =>
                    hash == null ? placeholder : BlurHash(hash: hash),
                // Offline: the cover saved with a download, if there is one.
                errorWidget: (_, _, _) {
                  final id = artwork?.itemId;
                  final file = id == null
                      ? null
                      : ref
                            .read(downloadControllerProvider.notifier)
                            .coverFile(id);
                  return file == null
                      ? placeholder
                      : Image.file(
                          file,
                          fit: BoxFit.cover,
                          cacheWidth: pixels,
                          errorBuilder: (_, _, _) => placeholder,
                        );
                },
              );
        return SizedBox.square(
          dimension: extent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(circular ? extent : radius),
            child: child,
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.extent});

  final IconData icon;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          icon,
          size: extent.isFinite ? extent * 0.45 : 48,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
