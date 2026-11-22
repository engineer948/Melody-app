import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/share/mixtape.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/collection_actions.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/player/track_actions.dart';
import 'package:melody/features/share/letter_extras.dart';
import 'package:melody/features/share/share_screen.dart';
import 'package:melody/features/tailnet/qr_code.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _log = AppLogger('mixtape');

Future<T?> _push<T>(BuildContext context, Widget screen) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<T>(fullscreenDialog: true, builder: (_) => screen));

/// Opens the editor of a mixtape with [tracks]; [passing] is a received
/// letter being passed on with one more song.
Future<void> showMixtapeComposer(
  BuildContext context,
  List<Track> tracks, {
  Mixtape? passing,
}) => _push<void>(
  context,
  MixtapeComposer(
    tracks: tracks.take(Mixtape.maxSongs).toList(),
    passing: passing,
  ),
);

/// Opens the screen where a received mixtape code is pasted or read.
Future<void> showOpenMixtape(BuildContext context) =>
    _push<void>(context, const OpenMixtapeScreen());

/// Writes a title, a note and a colour for a few songs and shares them as
/// a cassette picture plus a code.
class MixtapeComposer extends ConsumerStatefulWidget {
  /// Creates the editor.
  const MixtapeComposer({required this.tracks, this.passing, super.key});

  /// Songs of the mixtape.
  final List<Track> tracks;

  /// The received letter passed on, when relaying.
  final Mixtape? passing;

  @override
  ConsumerState<MixtapeComposer> createState() => _MixtapeComposerState();
}

class _MixtapeComposerState extends ConsumerState<MixtapeComposer> {
  final GlobalKey _cardKey = GlobalKey();
  late final _title = TextEditingController(text: widget.passing?.title);
  late final _note = TextEditingController(text: widget.passing?.note);
  late int _color = widget.passing?.color ?? Mixtape.defaultColor;
  bool _busy = false;
  DateTime? _openOn;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Mixtape _mixtape(BuildContext context) => Mixtape(
    title: _title.text.trim().isEmpty
        ? context.l10n.mixtapeDefaultTitle
        : _title.text,
    note: _note.text,
    from: ref.read(sessionControllerProvider).active?.userName ?? '',
    color: _color,
    songs: [for (final t in widget.tracks) MixtapeSong.of(t)],
    openOn: _openOn,
    hops: [
      ...?widget.passing?.hops,
      if (widget.passing?.from case final from? when from.isNotEmpty) from,
    ],
  );

  Future<void> _pickOpenDay() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _openOn ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 30),
      helpText: context.l10n.capsuleOpenOn,
    );
    if (day != null) setState(() => _openOn = day);
  }

  Future<void> _keepForMe() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref
        .read(letterInboxProvider.notifier)
        .keep(_mixtape(context).encode(), own: true);
    messenger.showSnackBar(SnackBar(content: Text(l10n.capsuleKept)));
    navigator.pop();
  }

  Future<void> _hideInPhoto(BuildContext button) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final box = button.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final code = _mixtape(context).encode();
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'images', mimeTypes: ['image/*']),
      ],
    );
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final png = await hideLetterInPhoto(await file.readAsBytes(), code);
      if (png == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.hiddenFailed)));
        return;
      }
      final dir = Directory('${(await getTemporaryDirectory()).path}/hidden');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      final out = File('${dir.path}/photo.png');
      await out.writeAsBytes(png, flush: true);
      messenger.showSnackBar(SnackBar(content: Text(l10n.hiddenHint)));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(out.path, mimeType: 'image/png')],
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (e) {
      _log.error('Hiding a letter failed', e);
      messenger.showSnackBar(SnackBar(content: Text(l10n.hiddenFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(BuildContext button) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final box = button.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final mixtape = _mixtape(context);
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: exportWidth / shareCardSize.width,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final dir = Directory('${(await getTemporaryDirectory()).path}/mixtape');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      final file = File('${dir.path}/melody-mixtape.png');
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text:
              '${l10n.mixtapeShareText(mixtape.title, AppConfig.appName)}'
              '\n\n${mixtape.encode()}',
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (e) {
      _log.error('Mixtape share failed', e);
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mixtape = _mixtape(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mixtapeMake)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            SizedBox(
              height: 340,
              child: Center(
                child: AspectRatio(
                  aspectRatio: shareCardSize.aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FittedBox(
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: SizedBox.fromSize(
                          size: shareCardSize,
                          child: MixtapeCard(mixtape: mixtape),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              maxLength: Mixtape.maxTitle,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.mixtapeTitle,
                hintText: l10n.mixtapeDefaultTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLength: Mixtape.maxNote,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.mixtapeNote,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                for (final c in Mixtape.colors)
                  Semantics(
                    button: true,
                    selected: c == _color,
                    child: GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 3,
                            color: c == _color
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Builder(
              builder: (button) => FilledButton.icon(
                onPressed: _busy ? null : () => unawaited(_share(button)),
                icon: const Icon(Icons.send_rounded),
                label: Text(l10n.mixtapeSend),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.hourglass_bottom_rounded),
              title: Text(l10n.capsuleOpenOn),
              subtitle: Text(
                _openOn == null
                    ? l10n.capsuleAnyTime
                    : DateFormat.yMMMMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(_openOn!),
              ),
              trailing: _openOn == null
                  ? null
                  : IconButton(
                      tooltip: l10n.capsuleClear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _openOn = null),
                    ),
              onTap: () => unawaited(_pickOpenDay()),
            ),
            if (_openOn != null)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => unawaited(_keepForMe()),
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(l10n.capsuleKeep),
              ),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Builder(
                  builder: (button) => TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => unawaited(_hideInPhoto(button)),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(l10n.hiddenMake),
                  ),
                ),
                if (Platform.isAndroid)
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => unawaited(
                            writeLetterToSticker(
                              context,
                              ref,
                              _mixtape(context).encode(),
                            ),
                          ),
                    icon: const Icon(Icons.nfc_rounded),
                    label: Text(l10n.nfcMake),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.mixtapeHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

/// The 9:16 picture of a mixtape: cassette, note, song list and a QR code
/// with the mixtape, laid out at [shareCardSize].
class MixtapeCard extends StatelessWidget {
  /// Creates the card.
  const MixtapeCard({required this.mixtape, super.key});

  /// What is shown.
  final Mixtape mixtape;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = Color(mixtape.color);
    const shown = 7;
    final songs = mixtape.songs;
    return MediaQuery.withNoTextScaling(
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(color, Colors.black, 0.45)!,
                const Color(0xFF0E0E10),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
            child: Column(
              children: [
                Text(
                  l10n.mixtapeKind.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 14),
                Cassette(
                  title: mixtape.title,
                  from: mixtape.from,
                  color: color,
                ),
                if (mixtape.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    '“${mixtape.note.trim()}”',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, s) in songs.take(shown).indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Text(
                            '${i + 1}. ${s.title}'
                            '${s.artist.isEmpty ? '' : ' — ${s.artist}'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      if (songs.length > shown)
                        Text(
                          l10n.mixtapeMore(songs.length - shown),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.mixtapeHowToOpen(AppConfig.appName),
                        style: const TextStyle(
                          fontSize: 9,
                          height: 1.3,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: QrCodeView(data: mixtape.encode(), size: 84),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paste a code, or read the QR code of a received mixtape picture.
class OpenMixtapeScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const OpenMixtapeScreen({super.key});

  @override
  ConsumerState<OpenMixtapeScreen> createState() => _OpenMixtapeScreenState();
}

class _OpenMixtapeScreenState extends ConsumerState<OpenMixtapeScreen> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _open(String text) {
    try {
      final mixtape = Mixtape.decode(text);
      setState(() => _error = null);
      // Every letter opened is kept, so it can be found again.
      unawaited(ref.read(letterInboxProvider.notifier).keep(mixtape.encode()));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MixtapeScreen(mixtape: mixtape),
        ),
      );
    } on FormatException {
      setState(() => _error = context.l10n.mixtapeInvalid);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    _code.text = text;
    if (mounted) _open(text);
  }

  Future<void> _fromPicture() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'images', mimeTypes: ['image/*']),
      ],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    // A QR code on a cassette picture, or a letter hidden in a photo.
    final text = await decodeQrImage(bytes) ?? await revealLetterInPhoto(bytes);
    if (!mounted) return;
    if (text == null) {
      setState(() => _error = context.l10n.mixtapeNoQr);
      return;
    }
    _open(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mixtapeOpen)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.mixtapeOpenBody),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.mixtapeCode,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: _open,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _open(_code.text),
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(l10n.mixtapeOpenButton),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => unawaited(_paste()),
            icon: const Icon(Icons.content_paste_rounded),
            label: Text(l10n.mixtapePaste),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => unawaited(_fromPicture()),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(l10n.mixtapeFromPicture),
          ),
          const _Inbox(),
        ],
      ),
    );
  }
}

/// Opens the letter in [link] (from an NFC sticker) on top of everything
/// and keeps it in the inbox.
Future<void> openLetterLink(
  WidgetRef ref,
  NavigatorState? navigator,
  String link,
) async {
  final code = letterCodeOf(link);
  if (code == null || navigator == null) return;
  final mixtape = Mixtape.decode(code);
  await ref.read(letterInboxProvider.notifier).keep(mixtape.encode());
  await navigator.push(
    MaterialPageRoute<void>(builder: (_) => MixtapeScreen(mixtape: mixtape)),
  );
}

/// "A letter can be opened today" at the top of Home, for time capsules
/// whose day has come.
class DueLetterBanner extends ConsumerWidget {
  /// Creates the banner.
  const DueLetterBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(dueLettersProvider);
    final mixtape = due.firstOrNull?.mixtape;
    if (mixtape == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: Color(mixtape.color).withValues(alpha: 0.25),
      child: ListTile(
        leading: const Icon(Icons.mark_email_unread_rounded),
        title: Text(l10n.capsuleDue),
        subtitle: Text(
          due.first.own || mixtape.from.isEmpty
              ? mixtape.title
              : '${mixtape.title} · ${mixtape.from}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            unawaited(_push<void>(context, MixtapeScreen(mixtape: mixtape))),
      ),
    );
  }
}

/// Letters kept on the phone, newest first.
class _Inbox extends ConsumerWidget {
  const _Inbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final letters = ref.watch(letterInboxProvider);
    if (letters.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(l10n.inboxTitle, style: theme.textTheme.titleMedium),
        for (final letter in letters)
          if (letter.mixtape case final mixtape?)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(mixtape.color),
                child: Icon(
                  mixtape.sealedAt(now)
                      ? Icons.lock_clock_rounded
                      : letter.opened
                      ? Icons.drafts_outlined
                      : Icons.mail_rounded,
                  color: Colors.white,
                ),
              ),
              title: Text(mixtape.title, maxLines: 1),
              subtitle: Text(
                [
                  if (letter.own)
                    l10n.capsuleMine
                  else if (mixtape.from.isNotEmpty)
                    mixtape.from,
                  if (mixtape.sealedAt(now))
                    l10n.capsuleSealed(
                      DateFormat.yMMMd(locale).format(mixtape.openOn!),
                    )
                  else
                    DateFormat.yMMMd(locale).format(letter.received),
                ].join(' · '),
                maxLines: 1,
              ),
              trailing: IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => unawaited(
                  ref.read(letterInboxProvider.notifier).remove(letter.code),
                ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MixtapeScreen(mixtape: mixtape),
                ),
              ),
            ),
      ],
    );
  }
}

/// A received mixtape: a sealed envelope first, then the cassette, the
/// note and the songs found in this library.
class MixtapeScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const MixtapeScreen({required this.mixtape, super.key});

  /// What was received.
  final Mixtape mixtape;

  @override
  ConsumerState<MixtapeScreen> createState() => _MixtapeScreenState();
}

class _MixtapeScreenState extends ConsumerState<MixtapeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _reels = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  List<Track>? _tracks;
  int _searched = 0;

  @override
  void dispose() {
    _open.dispose();
    _reels.dispose();
    super.dispose();
  }

  Future<void> _unseal() async {
    unawaited(
      ref.read(letterInboxProvider.notifier).opened(widget.mixtape.encode()),
    );
    unawaited(_find());
    await _open.forward();
    if (mounted) _reels.repeat();
  }

  Future<void> _passOn(List<Track> tracks) async {
    final song = await pickSong(context);
    if (song == null || !mounted) return;
    await showMixtapeComposer(context, [
      ...tracks,
      song,
    ], passing: widget.mixtape);
  }

  Future<void> _find() async {
    final source = ref.read(activeSourceProvider);
    if (source == null) {
      setState(() => _tracks = const []);
      return;
    }
    final found = await findMixtapeSongs(
      source,
      widget.mixtape,
      onProgress: (done) {
        if (mounted) setState(() => _searched = done);
      },
    );
    if (mounted) setState(() => _tracks = found);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mixtape = widget.mixtape;
    final color = Color(mixtape.color);
    final editable =
        ref.watch(activeSourceProvider)?.capabilities.editablePlaylists ??
        false;
    final tracks = _tracks;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mixtapeKind)),
      body: AnimatedBuilder(
        animation: _open,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_open.value);
          if (t == 0) {
            return _Envelope(
              color: color,
              from: mixtape.from,
              openOn: mixtape.sealedAt(DateTime.now()) ? mixtape.openOn : null,
              onOpen: () => unawaited(_unseal()),
            );
          }
          return Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.85 + 0.15 * t,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Center(
                    child: Cassette(
                      title: mixtape.title,
                      from: mixtape.from,
                      color: color,
                      turns: _reels,
                      width: 280,
                    ),
                  ),
                  if (mixtape.hops.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      [
                        ...mixtape.hops,
                        if (mixtape.from.isNotEmpty) mixtape.from,
                        l10n.relayYou,
                      ].join(' → '),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  if (mixtape.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      '“${mixtape.note.trim()}”',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (tracks == null) ...[
                    LinearProgressIndicator(
                      value: _searched / mixtape.songs.length,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.mixtapeFinding(_searched, mixtape.songs.length),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    if (tracks.length < mixtape.songs.length)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.mixtapeMissing(
                            mixtape.songs.length - tracks.length,
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (tracks.isNotEmpty) ...[
                      PlayShuffleButtons(tracks: tracks),
                      for (final (i, track) in tracks.indexed)
                        TrackTile(track: track, queue: tracks, index: i),
                      if (editable)
                        TextButton.icon(
                          onPressed: () => unawaited(
                            createPlaylist(context, ref, tracks: tracks),
                          ),
                          icon: const Icon(Icons.playlist_add_rounded),
                          label: Text(l10n.mixtapeSave),
                        ),
                      if (tracks.length < Mixtape.maxSongs)
                        TextButton.icon(
                          onPressed: () => unawaited(_passOn(tracks)),
                          icon: const Icon(Icons.forward_to_inbox_rounded),
                          label: Text(l10n.relayAdd),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Envelope extends StatelessWidget {
  const _Envelope({
    required this.color,
    required this.from,
    required this.onOpen,
    this.openOn,
  });

  final Color color;
  final String from;
  final VoidCallback onOpen;

  /// Set while the letter is a time capsule that cannot be opened yet.
  final DateTime? openOn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sealedUntil = openOn;
    final now = DateTime.now();
    final daysLeft = sealedUntil
        ?.difference(DateTime(now.year, now.month, now.day))
        .inDays;
    return Center(
      child: GestureDetector(
        onTap: sealedUntil == null ? onOpen : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 280,
              height: 180,
              child: CustomPaint(painter: _EnvelopePainter(color)),
            ),
            const SizedBox(height: 24),
            Text(
              from.isEmpty ? l10n.mixtapeSealed : l10n.mixtapeSealedFrom(from),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (sealedUntil != null) ...[
              const Icon(Icons.lock_clock_rounded, size: 32),
              const SizedBox(height: 8),
              Text(
                l10n.capsuleSealed(
                  DateFormat.yMMMMd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(sealedUntil),
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                l10n.capsuleDaysLeft(daysLeft ?? 0),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.drafts_rounded),
                label: Text(l10n.mixtapeOpenButton),
              ),
          ],
        ),
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas
      ..drawRRect(body, Paint()..color = Color.lerp(color, Colors.white, 0.15)!)
      ..drawPath(
        Path()
          ..moveTo(0, 12)
          ..lineTo(size.width / 2, size.height * 0.58)
          ..lineTo(size.width, 12)
          ..lineTo(size.width, 0)
          ..lineTo(0, 0)
          ..close(),
        Paint()..color = Color.lerp(color, Colors.black, 0.15)!,
      )
      // Wax seal.
      ..drawCircle(
        Offset(size.width / 2, size.height * 0.58),
        18,
        Paint()..color = Color.lerp(color, Colors.black, 0.4)!,
      );
    final heart = TextPainter(
      text: const TextSpan(
        text: '♪',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    heart.paint(
      canvas,
      Offset(size.width / 2, size.height * 0.58) -
          Offset(heart.width / 2, heart.height / 2),
    );
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => old.color != color;
}
