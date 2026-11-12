import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/features/share/share_subject.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _log = AppLogger('share');

/// Opens the share screen for [subject] above everything else.
Future<void> showShareScreen(BuildContext context, ShareSubject subject) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ShareScreen(subject: subject),
      ),
    );

/// Background of the story card.
enum ShareBackground {
  /// Blurred, darkened copy of the cover.
  blur,

  /// Gradient in the cover's colours.
  color,

  /// Plain near-black.
  dark,
}

/// Logical size of the card; the exported image is [exportWidth] wide.
const shareCardSize = Size(270, 480);

/// Width in pixels of the exported image (9:16, Instagram story size).
const exportWidth = 1080.0;

/// Preview of a 9:16 story image for [subject], with a background picker
/// and buttons to share it as an image (Instagram / Facebook stories,
/// WhatsApp status, …) or as plain text.
class ShareScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ShareScreen({required this.subject, super.key});

  /// What is shared.
  final ShareSubject subject;

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final GlobalKey _cardKey = GlobalKey();
  ImageProvider? _image;
  ColorScheme? _palette;
  ShareBackground _background = ShareBackground.blur;
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _image = _resolveImage();
    unawaited(_load());
  }

  /// The downloaded cover when there is one, otherwise the server's.
  ImageProvider? _resolveImage() {
    final artwork = widget.subject.artwork;
    if (artwork == null) return null;
    final file = ref
        .read(downloadControllerProvider.notifier)
        .coverFile(artwork.itemId);
    if (file != null) return FileImage(file);
    final source = ref.read(activeSourceProvider);
    final uri = source?.artworkUri(artwork, size: exportWidth.toInt());
    if (uri == null) return null;
    return CachedNetworkImageProvider(
      uri.toString(),
      headers: source?.requestHeaders,
    );
  }

  /// Loads the cover (so the exported image never shows a placeholder)
  /// and takes the gradient colours from it.
  Future<void> _load() async {
    final image = _image;
    if (image != null) {
      try {
        _palette = await ColorScheme.fromImageProvider(
          provider: image,
          brightness: Brightness.dark,
        ).timeout(const Duration(seconds: 15));
      } on Object catch (e) {
        _log.info('Cover could not be loaded: $e');
        _image = null;
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<File> _renderPng() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: exportWidth / shareCardSize.width,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory('${(await getTemporaryDirectory()).path}/share');
    // Only the latest image is kept.
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/melody-$stamp.png');
    await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    return file;
  }

  Rect? _origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _share(BuildContext button, {required bool asImage}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final origin = _origin(button);
    setState(() => _busy = true);
    try {
      final ShareParams params;
      if (asImage) {
        final file = await _renderPng();
        params = ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: origin,
        );
      } else {
        params = ShareParams(
          text: l10n.shareMessage(widget.subject.line, AppConfig.appName),
          sharePositionOrigin: origin,
        );
      }
      await SharePlus.instance.share(params);
    } on Object catch (e) {
      _log.error('Share failed', e);
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.share),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: shareCardSize.aspectRatio,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(blurRadius: 24, color: Color(0x40000000)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FittedBox(
                          child: RepaintBoundary(
                            key: _cardKey,
                            child: SizedBox.fromSize(
                              size: shareCardSize,
                              child: _ready
                                  ? ShareCard(
                                      subject: widget.subject,
                                      image: _image,
                                      palette: _palette,
                                      background: _background,
                                    )
                                  : const ColoredBox(
                                      color: Color(0xFF121212),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SegmentedButton<ShareBackground>(
              segments: [
                ButtonSegment(
                  value: ShareBackground.blur,
                  label: Text(l10n.shareStyleBlur),
                ),
                ButtonSegment(
                  value: ShareBackground.color,
                  label: Text(l10n.shareStyleColor),
                ),
                ButtonSegment(
                  value: ShareBackground.dark,
                  label: Text(l10n.shareStyleDark),
                ),
              ],
              selected: {_background},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _background = s.first),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (button) => OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _share(button, asImage: false),
                        icon: const Icon(Icons.notes_rounded),
                        label: Text(l10n.shareAsText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (button) => FilledButton.icon(
                        onPressed: !_ready || _busy
                            ? null
                            : () => _share(button, asImage: true),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(l10n.shareToStory),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Text(
                l10n.shareHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 9:16 story image itself, laid out at [shareCardSize].
class ShareCard extends StatelessWidget {
  /// Creates the card.
  const ShareCard({
    required this.subject,
    required this.background,
    this.image,
    this.palette,
    super.key,
  });

  /// What is shown.
  final ShareSubject subject;

  /// Loaded cover, or `null` for a placeholder.
  final ImageProvider? image;

  /// Colours taken from the cover.
  final ColorScheme? palette;

  /// Background style.
  final ShareBackground background;

  static const _dark = Color(0xFF121212);

  String _kindLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (subject.kind) {
      ShareKind.track => l10n.shareKindTrack,
      ShareKind.album => l10n.shareKindAlbum,
      ShareKind.artist => l10n.shareKindArtist,
      ShareKind.playlist => l10n.shareKindPlaylist,
    };
  }

  Widget _background() {
    final image = this.image;
    final accent = palette?.primaryContainer ?? const Color(0xFF3A2F5B);
    return switch (background) {
      ShareBackground.blur when image != null => Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Transform.scale(
              scale: 1.5,
              child: Image(image: image, fit: BoxFit.cover),
            ),
          ),
          const ColoredBox(color: Color(0x80000000)),
        ],
      ),
      ShareBackground.dark => const ColoredBox(color: _dark),
      _ => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent, Color.lerp(accent, Colors.black, 0.75)!],
          ),
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    const coverSize = 180.0;
    final placeholder = ColoredBox(
      color: const Color(0xFF2A2A2A),
      child: Icon(
        subject.circular ? Icons.person_rounded : Icons.music_note_rounded,
        size: 72,
        color: Colors.white54,
      ),
    );
    final cover = SizedBox.square(
      dimension: coverSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: subject.circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: subject.circular ? null : BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              blurRadius: 24,
              offset: Offset(0, 8),
              color: Color(0x66000000),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            subject.circular ? coverSize : 10,
          ),
          child: image == null
              ? placeholder
              : Image(
                  image: image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
    // Fixed sizes: the card is always laid out at shareCardSize, whatever
    // the device's text scale, so the exported image looks the same.
    return MediaQuery.withNoTextScaling(
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _background(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 56),
              child: Column(
                children: [
                  const Spacer(),
                  cover,
                  const SizedBox(height: 24),
                  Text(
                    _kindLabel(context).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subject.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subject.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subject.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 6),
                      Text(
                        AppConfig.appName,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
