import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/share/hidden_letter.dart';
import 'package:melody/domain/share/mixtape.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'letter_extras.g.dart';

// ---------------------------------------------------------------- photo

/// Longest side of a photo that carries a letter.
const hiddenPhotoMaxSide = 1600;

/// [photo] (any image file) as a PNG with [code] hidden in its pixels, or
/// `null` when it is not an image.
Future<Uint8List?> hideLetterInPhoto(Uint8List photo, String code) async {
  final ui.Image image;
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(photo);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final longest = max(descriptor.width, descriptor.height);
    final scale = longest > hiddenPhotoMaxSide
        ? hiddenPhotoMaxSide / longest
        : 1.0;
    final codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round(),
      targetHeight: (descriptor.height * scale).round(),
    );
    image = (await codec.getNextFrame()).image;
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  } on Object {
    return null;
  }
  final width = image.width;
  final height = image.height;
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();
  if (data == null) return null;
  final rgba = data.buffer.asUint8List();
  if (!HiddenLetter.hide(rgba, code)) return null;
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    width,
    height,
    ui.PixelFormat.rgba8888,
    done.complete,
  );
  final out = await done.future;
  final png = await out.toByteData(format: ui.ImageByteFormat.png);
  out.dispose();
  return png?.buffer.asUint8List();
}

/// The letter hidden in a photo by [hideLetterInPhoto], or `null`.
Future<String?> revealLetterInPhoto(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    image.dispose();
    if (data == null) return null;
    return HiddenLetter.reveal(data.buffer.asUint8List());
  } on Object {
    return null;
  }
}

// ---------------------------------------------------------------- inbox

/// A letter kept on the phone.
@immutable
class InboxLetter {
  /// Creates an entry.
  const InboxLetter({
    required this.code,
    required this.received,
    this.opened = false,
    this.own = false,
  });

  /// Restores an entry saved with [toJson].
  factory InboxLetter.fromJson(Map<String, dynamic> json) => InboxLetter(
    code: json['code'] as String,
    received: DateTime.parse(json['received'] as String),
    opened: json['opened'] as bool? ?? false,
    own: json['own'] as bool? ?? false,
  );

  /// The letter's code.
  final String code;

  /// When it arrived.
  final DateTime received;

  /// Whether it was unsealed.
  final bool opened;

  /// Whether the user made it for themselves (a time capsule).
  final bool own;

  /// The letter, or `null` when the code is broken.
  Mixtape? get mixtape {
    try {
      return Mixtape.decode(code);
    } on FormatException {
      return null;
    }
  }

  /// JSON for storage.
  Map<String, dynamic> toJson() => {
    'code': code,
    'received': received.toIso8601String(),
    'opened': opened,
    'own': own,
  };
}

/// Preference: the letters kept on the phone.
const inboxKey = 'letters.inbox';

/// Letters received or kept, newest first.
@Riverpod(keepAlive: true)
class LetterInbox extends _$LetterInbox {
  @override
  List<InboxLetter> build() {
    final raw = ref.watch(preferencesProvider).getString(inboxKey);
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List<dynamic>)
          InboxLetter.fromJson(e as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> _save(List<InboxLetter> letters) async {
    state = letters;
    await ref
        .read(preferencesProvider)
        .setString(inboxKey, jsonEncode([for (final l in letters) l.toJson()]));
  }

  /// Keeps [code] (once); [own] marks the user's own time capsule.
  Future<void> keep(String code, {bool own = false}) async {
    if (state.any((l) => l.code == code)) return;
    await _save([
      InboxLetter(code: code, received: DateTime.now(), own: own),
      ...state,
    ]);
  }

  /// Marks [code] as unsealed.
  Future<void> opened(String code) => _save([
    for (final l in state)
      if (l.code == code)
        InboxLetter(
          code: l.code,
          received: l.received,
          opened: true,
          own: l.own,
        )
      else
        l,
  ]);

  /// Forgets [code].
  Future<void> remove(String code) => _save([
    for (final l in state)
      if (l.code != code) l,
  ]);
}

/// Kept letters whose day has come and that were not opened yet.
@riverpod
List<InboxLetter> dueLetters(Ref ref) {
  final now = DateTime.now();
  return [
    for (final l in ref.watch(letterInboxProvider))
      if (!l.opened &&
          (l.mixtape?.openOn != null) &&
          !(l.mixtape?.sealedAt(now) ?? true))
        l,
  ];
}

// ---------------------------------------------------------------- NFC

/// Result of writing a tag.
enum NfcWrite {
  /// Written.
  written,

  /// The letter does not fit on the tag.
  tooBig,

  /// The tag cannot be written.
  readOnly,

  /// Something else went wrong.
  failed,

  /// Cancelled before a tag was found.
  cancelled,
}

/// The phone's NFC: writing a letter to a sticker and hearing about
/// stickers touched while the app runs. Replaced by a fake in tests.
abstract interface class NfcBridge {
  /// `null` when the phone has no NFC, else whether it is turned on.
  Future<bool?> state();

  /// Waits for a tag and writes [uri] to it.
  Future<NfcWrite> write(String uri);

  /// Stops waiting for a tag.
  Future<void> cancel();

  /// The link the app was opened with, once.
  Future<String?> initialLink();

  /// Links of tags touched while the app is open.
  Stream<String> get links;
}

/// [NfcBridge] over the `melody/nfc` channel (Android).
class ChannelNfcBridge implements NfcBridge {
  /// Creates the bridge.
  ChannelNfcBridge() {
    if (_supported) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'link' && call.arguments is String) {
          _links.add(call.arguments as String);
        }
      });
    }
  }

  static const _channel = MethodChannel('melody/nfc');
  final _links = StreamController<String>.broadcast();

  bool get _supported => !kIsWeb && Platform.isAndroid;

  Future<T?> _call<T>(String method, [Object? args]) async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool?> state() async {
    final value = await _call<String>('state');
    return switch (value) {
      'on' => true,
      'off' => false,
      _ => null,
    };
  }

  @override
  Future<NfcWrite> write(String uri) async {
    final value = await _call<String>('write', uri);
    return NfcWrite.values.asNameMap()[value] ?? NfcWrite.failed;
  }

  @override
  Future<void> cancel() => _call<void>('cancel');

  @override
  Future<String?> initialLink() => _call<String>('initialLink');

  @override
  Stream<String> get links => _links.stream;
}

/// The phone's NFC.
@Riverpod(keepAlive: true)
NfcBridge nfcBridge(Ref ref) => ChannelNfcBridge();

/// The link written to a sticker for [code].
String letterLink(String code) =>
    'melody://letter?c=${Uri.encodeQueryComponent(code)}';

/// The letter code inside [link] (or any text with a code), or `null`.
String? letterCodeOf(String link) {
  final uri = Uri.tryParse(link);
  final text = uri?.queryParameters['c'] ?? link;
  try {
    Mixtape.decode(text);
    return text;
  } on FormatException {
    return null;
  }
}

/// Asks to hold the phone to a sticker and writes [code] to it.
Future<void> writeLetterToSticker(
  BuildContext context,
  WidgetRef ref,
  String code,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final nfc = ref.read(nfcBridgeProvider);
  final state = await nfc.state();
  if (state != true) {
    messenger.showSnackBar(
      SnackBar(content: Text(state == null ? l10n.nfcMissing : l10n.nfcOff)),
    );
    return;
  }
  if (!context.mounted) return;
  final result = await showDialog<NfcWrite>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _NfcDialog(nfc: nfc, uri: letterLink(code)),
  );
  final text = switch (result) {
    NfcWrite.written => l10n.nfcWritten,
    NfcWrite.tooBig => l10n.nfcTooBig,
    NfcWrite.readOnly => l10n.nfcReadOnly,
    NfcWrite.failed => l10n.nfcFailed,
    NfcWrite.cancelled || null => null,
  };
  if (text != null) messenger.showSnackBar(SnackBar(content: Text(text)));
}

class _NfcDialog extends StatefulWidget {
  const _NfcDialog({required this.nfc, required this.uri});

  final NfcBridge nfc;
  final String uri;

  @override
  State<_NfcDialog> createState() => _NfcDialogState();
}

class _NfcDialogState extends State<_NfcDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(
      widget.nfc.write(widget.uri).then((result) {
        if (mounted) Navigator.pop(context, result);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      icon: const Icon(Icons.nfc_rounded, size: 40),
      title: Text(l10n.nfcHold),
      content: Text(l10n.nfcHoldBody),
      actions: [
        TextButton(
          onPressed: () {
            unawaited(widget.nfc.cancel());
            Navigator.pop(context, NfcWrite.cancelled);
          },
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- relay

/// Lets the user search their library and pick one song.
Future<Track?> pickSong(BuildContext context) => showModalBottomSheet<Track>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  useRootNavigator: true,
  builder: (context) => const _SongPicker(),
);

class _SongPicker extends ConsumerStatefulWidget {
  const _SongPicker();

  @override
  ConsumerState<_SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends ConsumerState<_SongPicker> {
  List<Track> _found = const [];
  Timer? _debounce;
  var _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final query = text.trim();
      _query = query;
      final source = ref.read(activeSourceProvider);
      if (source == null || query.isEmpty) {
        setState(() => _found = const []);
        return;
      }
      final result = await source.search(query);
      if (!mounted || query != _query) return;
      setState(
        () => _found = switch (result) {
          Ok(:final value) => value.tracks,
          Err() => const [],
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.relayPick,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _changed,
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final track in _found)
                    ListTile(
                      leading: ArtworkImage(
                        artwork: track.artwork,
                        size: 44,
                        radius: 6,
                        icon: Icons.music_note_outlined,
                      ),
                      title: Text(track.title, maxLines: 1),
                      subtitle: Text(track.artistLine, maxLines: 1),
                      onTap: () => Navigator.pop(context, track),
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
