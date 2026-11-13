import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_music_source.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/l10n/l10n.dart';

/// The signed-in user's profile picture; `null` without one, or when the
/// source has no profile pictures.
final myAvatarProvider = FutureProvider<Uri?>((ref) async {
  final source = ref.watch(activeSourceProvider);
  if (source is! JellyfinMusicSource) return null;
  try {
    return await source.avatar();
  } on Object {
    return null;
  }
});

/// Square PNG of [bytes] (any image), cut from the middle, [size] wide.
Future<Uint8List?> squarePng(Uint8List bytes, {int size = 512}) async {
  final ui.Image image;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    image = (await codec.getNextFrame()).image;
    codec.dispose();
  } on Object {
    return null;
  }
  final side = image.width < image.height ? image.width : image.height;
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    Rect.fromLTWH(
      (image.width - side) / 2,
      (image.height - side) / 2,
      side.toDouble(),
      side.toDouble(),
    ),
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..filterQuality = FilterQuality.high,
  );
  image.dispose();
  final out = await recorder.endRecording().toImage(size, size);
  final data = await out.toByteData(format: ui.ImageByteFormat.png);
  out.dispose();
  return data?.buffer.asUint8List();
}

/// Round profile picture (or the first letter of [name]).
class ProfileAvatar extends ConsumerWidget {
  /// Creates the avatar.
  const ProfileAvatar({required this.name, this.radius = 20, super.key});

  /// User name, for the placeholder letter.
  final String name;

  /// Radius.
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = ref.watch(myAvatarProvider).value;
    final headers = ref.watch(activeSourceProvider)?.requestHeaders;
    return CircleAvatar(
      radius: radius,
      foregroundImage: uri == null
          ? null
          : CachedNetworkImageProvider(uri.toString(), headers: headers),
      child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase()),
    );
  }
}

/// Settings row to set or remove the profile picture.
class ProfilePictureTile extends ConsumerStatefulWidget {
  /// Creates the row.
  const ProfilePictureTile({required this.name, super.key});

  /// Signed-in user name.
  final String name;

  @override
  ConsumerState<ProfilePictureTile> createState() => _ProfilePictureTileState();
}

class _ProfilePictureTileState extends ConsumerState<ProfilePictureTile> {
  bool _busy = false;

  Future<void> _run(Future<void> Function(JellyfinMusicSource s) action) async {
    final source = ref.read(activeSourceProvider);
    if (source is! JellyfinMusicSource) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await action(source);
      ref.invalidate(myAvatarProvider);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.profilePhotoFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'images',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
          mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
          uniformTypeIdentifiers: ['public.image'],
        ),
      ],
    );
    if (file == null) return;
    await _run((source) async {
      final png = await squarePng(await file.readAsBytes());
      if (png == null) throw const FormatException('not an image');
      await source.setAvatar(png);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (ref.watch(activeSourceProvider) is! JellyfinMusicSource) {
      return const SizedBox.shrink();
    }
    final hasPhoto = ref.watch(myAvatarProvider).value != null;
    return ListTile(
      leading: _busy
          ? const SizedBox.square(
              dimension: 40,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : ProfileAvatar(name: widget.name),
      title: Text(l10n.profilePhoto),
      subtitle: Text(l10n.profilePhotoHint),
      enabled: !_busy,
      onTap: _pick,
      trailing: hasPhoto
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.profilePhotoRemove,
              onPressed: _busy
                  ? null
                  : () => _run((source) => source.removeAvatar()),
            )
          : null,
    );
  }
}
