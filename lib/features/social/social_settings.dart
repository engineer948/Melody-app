import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/social/social_models.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/settings/widgets/color_wheel.dart';
import 'package:melody/features/settings/widgets/section_header.dart';
import 'package:melody/features/social/listen_together.dart';
import 'package:melody/features/social/social_controller.dart';
import 'package:melody/features/social/social_home.dart';
import 'package:melody/l10n/l10n.dart';

/// Settings: what someone shares with this user (switches per feature)
/// and, for server administrators, the entry to share with someone.
class SocialSettingsSection extends ConsumerWidget {
  /// Creates the section.
  const SocialSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(socialControllerProvider);
    if (!state.available) return const SizedBox.shrink();
    final inbox = state.inbox;
    final answer = state.answer;
    final controller = ref.read(socialControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (inbox != null) ...[
          SectionHeader(l10n.socialSettingsTitle(inbox.fromName)),
          if (answer?.granted ?? false) ...[
            for (final feature in SocialFeature.values)
              SwitchListTile(
                title: Text(socialFeatureName(l10n, feature)),
                value: answer!.features.contains(feature),
                onChanged: (on) => controller.setFeature(feature, on: on),
              ),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: Text(l10n.socialRevoke),
              onTap: () => controller.answer(granted: false),
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.favorite_border_rounded),
              title: Text(l10n.socialAllowAgain),
              onTap: () async {
                final features = await chooseSocialFeatures(context);
                if (features == null) return;
                await controller.answer(granted: true, features: features);
              },
            ),
        ],
        if (state.isAdmin) ...[
          if (inbox == null) SectionHeader(l10n.socialSenderEntry),
          ListTile(
            leading: const Icon(Icons.volunteer_activism_outlined),
            title: Text(l10n.socialSenderEntry),
            subtitle: Text(l10n.socialSenderEntrySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(SocialSenderScreen.open(context)),
          ),
        ],
      ],
    );
  }
}

/// Sends [track] with a note to the chosen person (administrators).
Future<void> showDedicateSheet(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final state = ref.read(socialControllerProvider);
  final name = state.recipient?.name ?? '';
  final note = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    // Above the bottom navigation bar and the mini player.
    useRootNavigator: true,
    builder: (context) =>
        _NoteSheet(title: l10n.socialSendTo(name), track: track),
  );
  if (note == null) return;
  try {
    final sent = await ref
        .read(socialControllerProvider.notifier)
        .dedicate(track, note: note);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sent ? l10n.socialSentSnack(name) : l10n.socialNotAllowed,
        ),
      ),
    );
  } on Object {
    messenger.showSnackBar(SnackBar(content: Text(l10n.socialFailed)));
  }
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.title, required this.track});

  final String title;
  final Track track;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${widget.track.title} · ${widget.track.artistLine}'),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            autofocus: true,
            maxLength: maxNoteLength,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.socialNoteLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _note.text),
            icon: const Icon(Icons.send_rounded),
            label: Text(l10n.socialSend),
          ),
        ],
      ),
    );
  }
}

/// The administrator's screen: choose the person, ask for permission,
/// set the greeting and color, create the shared playlist, see what was
/// sent and liked.
class SocialSenderScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const SocialSenderScreen({super.key});

  /// Opens the screen.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SocialSenderScreen()));

  @override
  ConsumerState<SocialSenderScreen> createState() => _SocialSenderScreenState();
}

class _SocialSenderScreenState extends ConsumerState<SocialSenderScreen> {
  final _name = TextEditingController();
  final _welcome = TextEditingController();
  final _playlist = TextEditingController();
  int? _color;
  bool _loadedOutbox = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.text = ref.read(sessionControllerProvider).active?.userName ?? '';
    // Buttons depend on the texts.
    _name.addListener(() => setState(() {}));
    _playlist.addListener(() => setState(() {}));
    unawaited(ref.read(socialControllerProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _name.dispose();
    _welcome.dispose();
    _playlist.dispose();
    super.dispose();
  }

  SocialController get _controller =>
      ref.read(socialControllerProvider.notifier);

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.socialFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseRecipient() async {
    final users = await _controller.users();
    if (!mounted) return;
    final chosen = await showDialog<SocialUser>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.socialRecipient),
        children: [
          for (final user in users)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, user),
              child: Text(user.name),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    _loadedOutbox = false;
    await _run(() => _controller.chooseRecipient(chosen));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(socialControllerProvider);
    final recipient = state.recipient;
    final outbox = state.outbox;
    final answer = state.outgoingAnswer;
    final listen = ref.watch(listenTogetherProvider);
    if (outbox != null && !_loadedOutbox) {
      _loadedOutbox = true;
      _name.text = outbox.fromName;
      _welcome.text = outbox.welcome?.text ?? '';
      _color = outbox.welcome?.color;
    }
    if (_playlist.text.isEmpty) _playlist.text = l10n.socialPlaylistDefault;
    final (statusText, statusIcon) = switch ((outbox, answer)) {
      (null, _) => (l10n.socialStatusNotAsked, Icons.help_outline),
      (_, null) => (l10n.socialStatusWaiting, Icons.hourglass_top_rounded),
      (_, final a?) when a.granted => (
        '${l10n.socialStatusGranted}: '
            '${a.features.map((f) => socialFeatureName(l10n, f)).join(', ')}',
        Icons.check_circle_outline,
      ),
      _ => (l10n.socialStatusDenied, Icons.block_rounded),
    };
    Widget notAllowed(SocialFeature feature) => state.canSend(feature)
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.socialNotAllowed,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
    final canWelcome = state.canSend(SocialFeature.welcome) && !_busy;
    final canPlaylist = state.canSend(SocialFeature.sharedPlaylist) && !_busy;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialSenderEntry)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.socialRecipient),
            subtitle: Text(recipient?.name ?? '—'),
            trailing: TextButton(
              onPressed: _busy ? null : _chooseRecipient,
              child: Text(l10n.socialChoose),
            ),
          ),
          if (recipient != null) ...[
            ListTile(leading: Icon(statusIcon), title: Text(statusText)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _name,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: l10n.socialYourName,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (answer == null || outbox == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: _busy || _name.text.trim().isEmpty
                      ? null
                      : () => _run(
                          () => _controller.requestPermission(_name.text),
                        ),
                  child: Text(l10n.socialAsk),
                ),
              ),
            if (outbox != null) ...[
              SectionHeader(l10n.socialFeatureWelcome),
              notAllowed(SocialFeature.welcome),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _welcome,
                  enabled: canWelcome,
                  maxLength: maxWelcomeLength,
                  decoration: InputDecoration(
                    labelText: l10n.socialWelcomeLabel,
                    helperText: l10n.socialWelcomeHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              ListTile(
                enabled: canWelcome,
                title: Text(l10n.socialColor),
                subtitle: Text(_color == null ? l10n.socialOwnColor : ''),
                leading: CircleAvatar(
                  backgroundColor: _color == null
                      ? theme.colorScheme.surfaceContainerHighest
                      : Color(_color!),
                ),
                trailing: _color == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: l10n.socialOwnColor,
                        onPressed: canWelcome
                            ? () => setState(() => _color = null)
                            : null,
                      ),
                onTap: () async {
                  final color = await showColorWheel(
                    context,
                    _color == null ? theme.colorScheme.primary : Color(_color!),
                  );
                  if (color != null) {
                    setState(() => _color = color.toARGB32() | 0xFF000000);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.tonal(
                  onPressed: canWelcome
                      ? () => _run(
                          () => _controller.setWelcome(_welcome.text, _color),
                          done: l10n.socialSaved,
                        )
                      : null,
                  child: Text(l10n.save),
                ),
              ),
              SectionHeader(l10n.socialFeatureSharedPlaylist),
              notAllowed(SocialFeature.sharedPlaylist),
              if (outbox.playlist case final playlist?)
                ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(playlist.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => unawaited(
                    context.push(
                      AppRoutes.playlist(context, playlist.id, playlist.name),
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _playlist,
                    enabled: canPlaylist,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: l10n.socialPlaylistName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.tonal(
                    onPressed: canPlaylist && _playlist.text.trim().isNotEmpty
                        ? () => _run(
                            () => _controller.createSharedPlaylist(
                              _playlist.text,
                            ),
                          )
                        : null,
                    child: Text(l10n.socialPlaylistCreate),
                  ),
                ),
              ],
              SectionHeader(l10n.socialFeatureListen),
              notAllowed(SocialFeature.listenTogether),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.listenHint,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: listen.status == ListenStatus.off
                    ? FilledButton.tonalIcon(
                        onPressed:
                            state.canSend(SocialFeature.listenTogether) &&
                                !_busy
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = await ref
                                    .read(listenTogetherProvider.notifier)
                                    .start();
                                if (!ok) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(l10n.listenFailed)),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.headphones_rounded),
                        label: Text(l10n.listenStart),
                      )
                    : OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(listenTogetherProvider.notifier).leave(),
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(
                          '${l10n.listenLeave} · '
                          '${listen.participants.join(', ')}',
                        ),
                      ),
              ),
              SectionHeader(l10n.socialSent),
              notAllowed(SocialFeature.dedications),
              for (final d in outbox.dedications)
                ListTile(
                  title: Text(d.title),
                  subtitle: Text(d.note.isEmpty ? d.artist : d.note),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (answer?.seen.contains(d.id) ?? false)
                        Tooltip(
                          message: l10n.socialSeen,
                          child: const Icon(Icons.visibility_outlined),
                        ),
                      if (answer?.liked.contains(d.id) ?? false)
                        Tooltip(
                          message: l10n.socialLiked,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
