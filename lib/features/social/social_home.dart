import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/shelf_header.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/social/social_models.dart';
import 'package:melody/features/social/listen_together.dart';
import 'package:melody/features/social/social_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// Title of a sharing feature.
String socialFeatureName(AppLocalizations l10n, SocialFeature feature) =>
    switch (feature) {
      SocialFeature.dedications => l10n.socialFeatureDedications,
      SocialFeature.sharedPlaylist => l10n.socialFeatureSharedPlaylist,
      SocialFeature.welcome => l10n.socialFeatureWelcome,
      SocialFeature.listenTogether => l10n.socialFeatureListen,
    };

/// The greeting someone set for this user, if they allowed it.
String? socialGreeting(SocialState state) {
  if (!state.shows(SocialFeature.welcome)) return null;
  final text = state.inbox?.welcome?.text ?? '';
  return text.isEmpty ? null : text;
}

/// The accent color someone set for this user, if they allowed it.
Color? socialAccent(SocialState state) {
  if (!state.shows(SocialFeature.welcome)) return null;
  final color = state.inbox?.welcome?.color;
  return color == null ? null : Color(color);
}

/// Asks which features to allow; `null` when cancelled.
Future<Set<SocialFeature>?> chooseSocialFeatures(
  BuildContext context, {
  Set<SocialFeature>? initial,
}) => showDialog<Set<SocialFeature>>(
  context: context,
  builder: (context) =>
      _FeatureDialog(initial: initial ?? SocialFeature.values.toSet()),
);

class _FeatureDialog extends StatefulWidget {
  const _FeatureDialog({required this.initial});

  final Set<SocialFeature> initial;

  @override
  State<_FeatureDialog> createState() => _FeatureDialogState();
}

class _FeatureDialogState extends State<_FeatureDialog> {
  late final Set<SocialFeature> _chosen = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.socialChooseTitle),
      contentPadding: const EdgeInsets.only(top: 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final feature in SocialFeature.values)
            CheckboxListTile(
              value: _chosen.contains(feature),
              title: Text(socialFeatureName(l10n, feature)),
              onChanged: (on) => setState(
                () => on ?? false
                    ? _chosen.add(feature)
                    : _chosen.remove(feature),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _chosen),
          child: Text(l10n.socialAllow),
        ),
      ],
    );
  }
}

/// Home screen parts: the permission request, songs sent with a note and
/// the shared playlist. Empty when there is nothing (allowed) to show.
List<Widget> socialHomeSlivers(BuildContext context, SocialState state) {
  final inbox = state.inbox;
  return [
    const SliverToBoxAdapter(child: _ListenBanner()),
    if (inbox != null) ..._incoming(context, state, inbox),
  ];
}

List<Widget> _incoming(
  BuildContext context,
  SocialState state,
  SocialInbox inbox,
) {
  return [
    if (state.shows(SocialFeature.listenTogether) &&
        inbox.listenGroupId != null)
      SliverToBoxAdapter(child: _ListenInvite(from: inbox.fromName)),
    if (state.mustAnswer) SliverToBoxAdapter(child: _RequestCard(inbox: inbox)),
    if (state.shows(SocialFeature.dedications) && inbox.dedications.isNotEmpty)
      SliverToBoxAdapter(child: _DedicationShelf(inbox: inbox)),
    if (state.shows(SocialFeature.sharedPlaylist))
      if (inbox.playlist case final playlist?)
        SliverToBoxAdapter(
          child: _SharedPlaylistTile(playlist: playlist, from: inbox.fromName),
        ),
  ];
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.inbox});

  final SocialInbox inbox;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.read(socialControllerProvider.notifier);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.socialRequestTitle(inbox.fromName),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.socialRequestBody),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => controller.answer(granted: false),
                  child: Text(l10n.socialDecline),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final features = await chooseSocialFeatures(context);
                    if (features == null) return;
                    await controller.answer(granted: true, features: features);
                  },
                  child: Text(l10n.socialAllow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A track to play from what was stored with a dedication.
Track dedicationTrack(Dedication d) => Track(
  id: d.trackId,
  title: d.title,
  artists: [if (d.artist.isNotEmpty) NamedRef(id: '', name: d.artist)],
  albumId: d.albumId,
  artwork: Artwork(itemId: d.albumId ?? d.trackId),
);

class _DedicationShelf extends ConsumerWidget {
  const _DedicationShelf({required this.inbox});

  final SocialInbox inbox;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final answer = ref.watch(socialControllerProvider.select((s) => s.answer));
    final tracks = [for (final d in inbox.dedications) dedicationTrack(d)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShelfHeader(l10n.socialFromShelf(inbox.fromName)),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: inbox.dedications.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _DedicationCard(
              dedication: inbox.dedications[i],
              unseen: !(answer?.seen.contains(inbox.dedications[i].id) ?? true),
              liked: answer?.liked.contains(inbox.dedications[i].id) ?? false,
              onPlay: () {
                unawaited(
                  ref
                      .read(socialControllerProvider.notifier)
                      .markSeen(inbox.dedications[i]),
                );
                unawaited(
                  ref
                      .read(playerControllerProvider.notifier)
                      .playTracks(tracks, start: i),
                );
              },
              onLike: () => ref
                  .read(socialControllerProvider.notifier)
                  .toggleLike(inbox.dedications[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _DedicationCard extends StatelessWidget {
  const _DedicationCard({
    required this.dedication,
    required this.unseen,
    required this.liked,
    required this.onPlay,
    required this.onLike,
  });

  final Dedication dedication;
  final bool unseen;
  final bool liked;
  final VoidCallback onPlay;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SizedBox(
      width: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPlay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ArtworkImage(
                  artwork: Artwork(
                    itemId: dedication.albumId ?? dedication.trackId,
                  ),
                  size: 150,
                  radius: 10,
                  icon: Icons.music_note_outlined,
                ),
                if (unseen)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CircleAvatar(
                      radius: 6,
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton(
                    tooltip: l10n.socialLike,
                    onPressed: onLike,
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? Colors.redAccent : Colors.white,
                      shadows: const [Shadow(blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dedication.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            if (dedication.note.isNotEmpty)
              Text(
                dedication.note,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Text(
                dedication.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SharedPlaylistTile extends StatelessWidget {
  const _SharedPlaylistTile({required this.playlist, required this.from});

  final SharedPlaylistRef playlist;
  final String from;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: ListTile(
      leading: const Icon(Icons.queue_music_rounded),
      title: Text(playlist.name),
      subtitle: Text(context.l10n.socialSharedWith(from)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => unawaited(
        context.push(AppRoutes.playlist(context, playlist.id, playlist.name)),
      ),
    ),
  );
}

/// "Listening together: …" with a leave button, while in a group.
class _ListenBanner extends ConsumerWidget {
  const _ListenBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listen = ref.watch(listenTogetherProvider);
    if (!listen.active) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ListTile(
        leading: Icon(Icons.headphones_rounded, color: scheme.primary),
        title: Text(l10n.listenActive(listen.participants.join(', '))),
        trailing: TextButton(
          onPressed: () => ref.read(listenTogetherProvider.notifier).leave(),
          child: Text(l10n.listenLeave),
        ),
      ),
    );
  }
}

/// The sender's invitation to listen together.
class _ListenInvite extends ConsumerWidget {
  const _ListenInvite({required this.from});

  final String from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listen = ref.watch(listenTogetherProvider);
    if (listen.status != ListenStatus.off) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ListTile(
        leading: const Icon(Icons.headphones_rounded),
        title: Text(l10n.listenInviteTitle(from)),
        subtitle: Text(l10n.listenHint),
        trailing: FilledButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final ok = await ref.read(listenTogetherProvider.notifier).join();
            if (!ok) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.listenFailed)),
              );
            }
          },
          child: Text(l10n.listenJoin),
        ),
      ),
    );
  }
}
