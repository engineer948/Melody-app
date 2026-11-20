import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/domain/share/story_lyrics.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/features/share/audio_clip.dart';
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

class _ShareScreenState extends ConsumerState<ShareScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _discKey = GlobalKey();
  final GlobalKey _discSlotKey = GlobalKey();

  /// One turn of a record at 33⅓ rpm.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  /// Whether the cover is a spinning record (sound clips only).
  bool _spin = false;

  /// Hides the record while the rest of the card is rendered.
  bool _hideDisc = false;
  ImageProvider? _image;
  ColorScheme? _palette;
  ShareBackground _background = ShareBackground.blur;
  bool _ready = false;
  bool _busy = false;

  /// Whether a piece of the song is shared instead of the image.
  bool _sound = false;

  /// Lyrics shown on the card (sound clips only).
  LyricFrame? _cardLyrics;

  @override
  void initState() {
    super.initState();
    _image = _resolveImage();
    unawaited(_load());
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  void _setSpin(bool spin) {
    setState(() => _spin = spin);
    if (spin) {
      _turn.repeat();
    } else {
      _turn
        ..stop()
        ..value = 0;
    }
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

  /// Renders the card to a PNG in the temporary folder [folder]; the
  /// folder is emptied first unless [keep] is set.
  Future<File> _renderPng({
    String folder = 'share',
    bool keep = false,
    GlobalKey? key,
  }) async {
    final boundary =
        (key ?? _cardKey).currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: exportWidth / shareCardSize.width,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory('${(await getTemporaryDirectory()).path}/$folder');
    if (!keep && dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final file = File('${dir.path}/melody-$stamp.png');
    await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    return file;
  }

  /// Renders the card once for each lyrics state, for a story video. With
  /// [spin], the record is left out of those pictures and rendered on its
  /// own, with where it sits on the card, so the video can turn it.
  Future<StoryPictures> _renderPictures(
    List<LyricFrame> frames, {
    required bool spin,
  }) async {
    final shown = _cardLyrics;
    final pictures = <(File, Duration)>[];
    File? disc;
    Rect? discRect;
    if (spin) {
      _turn
        ..stop()
        ..value = 0;
    }
    try {
      setState(() => _hideDisc = spin);
      for (final (i, frame) in frames.indexed) {
        setState(
          () => _cardLyrics = frame.line == null && frame.next == null
              ? null
              : frame,
        );
        await WidgetsBinding.instance.endOfFrame;
        final file = await _renderPng(folder: 'story', keep: i > 0);
        pictures.add((file, frame.at));
      }
      if (spin) {
        setState(() => _hideDisc = false);
        await WidgetsBinding.instance.endOfFrame;
        disc = await _renderPng(folder: 'story', keep: true, key: _discKey);
        final card = _cardKey.currentContext!.findRenderObject()! as RenderBox;
        final slot =
            _discSlotKey.currentContext!.findRenderObject()! as RenderBox;
        final topLeft = slot.localToGlobal(Offset.zero, ancestor: card);
        discRect = Rect.fromLTWH(
          topLeft.dx / card.size.width,
          topLeft.dy / card.size.height,
          slot.size.width / card.size.width,
          slot.size.height / card.size.height,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cardLyrics = shown;
          _hideDisc = false;
        });
        if (_spin && _sound) _turn.repeat();
      }
    }
    return (pictures: pictures, disc: disc, discRect: discRect);
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

  /// The story card at whatever size its parent gives it.
  Widget _cardPreview() {
    return Center(
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
                          lyrics: _sound ? _cardLyrics : null,
                          vinyl: _sound && _spin,
                          hideCover: _hideDisc,
                          discKey: _discKey,
                          discSlotKey: _discSlotKey,
                          turn: _turn,
                        )
                      : const ColoredBox(
                          color: Color(0xFF121212),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final track = widget.subject.track;
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
            if (track != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(l10n.shareModeImage),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.graphic_eq_rounded),
                      label: Text(l10n.shareModeSound),
                    ),
                  ],
                  selected: {_sound},
                  onSelectionChanged: (s) {
                    setState(() => _sound = s.first);
                    // A new panel starts with a still cover.
                    _setSpin(false);
                  },
                ),
              ),
            if (track != null && _sound) ...[
              // Small card: the picture of a story video.
              SizedBox(
                height: 180,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _cardPreview(),
                ),
              ),
              Expanded(
                child: AudioClipPanel(
                  track: track,
                  renderPictures: _ready ? _renderPictures : null,
                  onSpin: _setSpin,
                  onCardLyrics: (lyrics) =>
                      setState(() => _cardLyrics = lyrics),
                ),
              ),
            ] else ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: _cardPreview(),
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
                onSelectionChanged: (s) =>
                    setState(() => _background = s.first),
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
    this.lyrics,
    this.vinyl = false,
    this.hideCover = false,
    this.discKey,
    this.discSlotKey,
    this.turn,
    super.key,
  });

  /// Shows the cover as a record (it turns with [turn]).
  final bool vinyl;

  /// Keeps the record's place but does not draw it.
  final bool hideCover;

  /// Repaint boundary around the record, to render it on its own.
  final GlobalKey? discKey;

  /// The record's (unturned) place on the card.
  final GlobalKey? discSlotKey;

  /// Turns of the record, 0 to 1.
  final Animation<double>? turn;

  /// What is shown.
  final ShareSubject subject;

  /// Song lines shown under the title, if any.
  final LyricFrame? lyrics;

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
    final lyrics = this.lyrics;
    final line = lyrics?.line;
    final next = lyrics?.next;
    final hasLyrics = line != null || next != null;
    // Smaller cover to make room for the lyrics.
    final coverSize = hasLyrics ? 132.0 : 180.0;
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
                  if (vinyl)
                    SizedBox.square(
                      key: discSlotKey,
                      dimension: coverSize,
                      child: RotationTransition(
                        turns: turn ?? const AlwaysStoppedAnimation(0),
                        child: RepaintBoundary(
                          key: discKey,
                          child: Opacity(
                            opacity: hideCover ? 0 : 1,
                            child: VinylDisc(size: coverSize, image: image),
                          ),
                        ),
                      ),
                    )
                  else
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
                  if (hasLyrics) ...[
                    const SizedBox(height: 20),
                    Text(
                      line ?? '♪',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        next,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Colors.white54,
                        ),
                      ),
                    ],
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

/// A record with [image] as its label.
class VinylDisc extends StatelessWidget {
  /// Creates the record.
  const VinylDisc({required this.size, this.image, super.key});

  /// Diameter.
  final double size;

  /// Cover in the middle, or `null` for a plain label.
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    final label = size * 0.42;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF101010),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  offset: Offset(0, 8),
                  color: Color(0x66000000),
                ),
              ],
            ),
            child: SizedBox.expand(),
          ),
          CustomPaint(size: Size.square(size), painter: _GroovePainter()),
          ClipOval(
            child: SizedBox.square(
              dimension: label,
              child: image == null
                  ? const ColoredBox(color: Color(0xFF8E2C2C))
                  : Image(
                      image: image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Color(0xFF8E2C2C)),
                    ),
            ),
          ),
          Container(
            width: size * 0.045,
            height: size * 0.045,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF101010),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fine grooves and a soft light reflection; the reflection turns with
/// the record, so the turning is visible even on a plain label.
class _GroovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0x14FFFFFF);
    for (var r = radius * 0.24; r < radius * 0.97; r += radius * 0.025) {
      canvas.drawCircle(center, r, groove);
    }
    final shine = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0x22FFFFFF),
          Color(0x00FFFFFF),
          Color(0x00FFFFFF),
          Color(0x22FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0, 0.08, 0.2, 0.5, 0.58, 0.7],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.97, shine);
  }

  @override
  bool shouldRepaint(_GroovePainter old) => false;
}
