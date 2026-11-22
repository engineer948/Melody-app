import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/playlists/smart_playlist.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'life_cards.g.dart';

/// Preference: the year the user was born, for "your teen years".
const birthYearKey = 'life.birthYear';

/// Ages counted as "teen years" (inclusive).
const ({int from, int to}) youthAges = (from: 13, to: 22);

/// The birth year the user gave, if any.
@riverpod
class BirthYear extends _$BirthYear {
  @override
  int? build() => ref.watch(preferencesProvider).getInt(birthYearKey);

  /// Saves [year].
  Future<void> set(int year) async {
    await ref.read(preferencesProvider).setInt(birthYearKey, year);
    state = year;
  }
}

/// "Your teen years": songs of the years the user was 13–22.
class YouthCard extends ConsumerStatefulWidget {
  /// Creates the card.
  const YouthCard({super.key});

  @override
  ConsumerState<YouthCard> createState() => _YouthCardState();
}

class _YouthCardState extends ConsumerState<YouthCard> {
  var _busy = false;

  Future<int?> _askYear() => showDialog<int>(
    context: context,
    builder: (context) => _YearDialog(initial: ref.read(birthYearProvider)),
  );

  Future<void> _tap() async {
    var year = ref.read(birthYearProvider);
    if (year == null) {
      year = await _askYear();
      if (year == null) return;
      await ref.read(birthYearProvider.notifier).set(year);
    }
    await _play(year);
  }

  Future<void> _play(int year) async {
    final source = ref.read(activeSourceProvider);
    if (source == null || _busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    final result = await SmartPlaylist(
      id: 'youth',
      name: 'youth',
      sort: SmartSort.random,
      yearFrom: year + youthAges.from,
      yearTo: year + youthAges.to,
    ).resolve(source);
    if (!mounted) return;
    setState(() => _busy = false);
    final songs = switch (result) {
      Ok(:final value) => value,
      Err() => const <Track>[],
    };
    if (songs.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.lifeYouthEmpty)));
      return;
    }
    await ref.read(playerControllerProvider.notifier).playTracks(songs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final year = ref.watch(birthYearProvider);
    return LifePictureCard(
      label: l10n.lifeYouth,
      title: year == null
          ? l10n.lifeYouthSet
          : l10n.lifeYouthYears(year + youthAges.from, year + youthAges.to),
      subtitle: year == null ? null : l10n.lifeYouthAges,
      icon: Icons.cake_outlined,
      busy: _busy,
      onTap: () => unawaited(_tap()),
      onLongPress: year == null
          ? null
          : () async {
              final changed = await _askYear();
              if (changed != null) {
                await ref.read(birthYearProvider.notifier).set(changed);
              }
            },
    );
  }
}

class _YearDialog extends StatefulWidget {
  const _YearDialog({required this.initial});

  final int? initial;

  @override
  State<_YearDialog> createState() => _YearDialogState();
}

class _YearDialogState extends State<_YearDialog> {
  late final _controller = TextEditingController(
    text: widget.initial?.toString(),
  );
  final int _now = DateTime.now().year;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse() {
    final year = int.tryParse(_controller.text.trim());
    return year != null && year >= 1900 && year <= _now - 10 ? year : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.lifeYouthAsk),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: InputDecoration(
          hintText: '${_now - 25}',
          helperText: l10n.lifeYouthPrivate,
        ),
        onSubmitted: (_) => Navigator.pop(context, _parse()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _parse()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// A big picture card of the home shelf.
class LifePictureCard extends StatelessWidget {
  /// Creates the card.
  const LifePictureCard({
    required this.label,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.artwork,
    this.onLongPress,
    this.busy = false,
    super.key,
  });

  /// Small pill at the top.
  final String label;

  /// Main line.
  final String title;

  /// Line under it.
  final String? subtitle;

  /// Shown at the bottom right.
  final IconData icon;

  /// Background picture; a colour without it.
  final Artwork? artwork;

  /// Called when tapped.
  final VoidCallback onTap;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// Shows a spinner instead of [icon].
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 250,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (artwork != null)
                  ArtworkImage(artwork: artwork, radius: 0)
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.tertiary, scheme.primary],
                      ),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0xCC000000)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: scheme.onSecondaryContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (subtitle case final subtitle?)
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (busy)
                              const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(icon, color: Colors.white),
                          ],
                        ),
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
