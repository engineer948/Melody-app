import 'dart:async';
import 'dart:math';

import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_music_source.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/social/social_models.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'social_controller.g.dart';

const _log = AppLogger('social');

/// Sharing storage of the active account; `null` when the source cannot
/// share (only Jellyfin / Emby can).
@Riverpod(keepAlive: true)
SocialApi? socialApi(Ref ref) {
  final source = ref.watch(activeSourceProvider);
  return source is JellyfinMusicSource ? source.social : null;
}

/// Everything about sharing, seen from the signed-in user: what others
/// sent to them (incoming) and, for administrators, what they send to one
/// other user (outgoing).
@immutable
class SocialState {
  /// Creates the state.
  const SocialState({
    this.available = false,
    this.isAdmin = false,
    this.inbox,
    this.consent,
    this.recipient,
    this.outbox,
    this.recipientConsent,
  });

  /// Whether the active source supports sharing.
  final bool available;

  /// Whether the signed-in user administers the server.
  final bool isAdmin;

  /// What someone sent to the signed-in user.
  final SocialInbox? inbox;

  /// The signed-in user's own answer.
  final SocialConsent? consent;

  /// The person the signed-in administrator shares with.
  final SocialUser? recipient;

  /// What the administrator wrote for [recipient].
  final SocialInbox? outbox;

  /// [recipient]'s answer.
  final SocialConsent? recipientConsent;

  /// The answer that belongs to [inbox] (ignores answers to someone else).
  SocialConsent? get answer =>
      inbox != null && consent?.fromId == inbox!.fromId ? consent : null;

  /// Whether the signed-in user still has to answer a request.
  bool get mustAnswer => inbox != null && answer == null;

  /// Whether incoming [feature] may be shown.
  bool shows(SocialFeature feature) => answer?.allows(feature) ?? false;

  /// The recipient's answer to the signed-in administrator.
  SocialConsent? get outgoingAnswer =>
      outbox != null && recipientConsent?.fromId == outbox!.fromId
      ? recipientConsent
      : null;

  /// Whether the administrator may use [feature] with [recipient].
  bool canSend(SocialFeature feature) =>
      outgoingAnswer?.allows(feature) ?? false;

  /// Copy with some fields replaced.
  SocialState copyWith({
    bool? available,
    bool? isAdmin,
    SocialInbox? inbox,
    SocialConsent? consent,
    SocialUser? recipient,
    SocialInbox? outbox,
    SocialConsent? recipientConsent,
    bool clearRecipient = false,
  }) => SocialState(
    available: available ?? this.available,
    isAdmin: isAdmin ?? this.isAdmin,
    inbox: inbox ?? this.inbox,
    consent: consent ?? this.consent,
    recipient: clearRecipient ? null : recipient ?? this.recipient,
    outbox: clearRecipient ? null : outbox ?? this.outbox,
    recipientConsent: clearRecipient
        ? null
        : recipientConsent ?? this.recipientConsent,
  );
}

/// Loads and changes the sharing state; refreshes every few minutes.
@Riverpod(keepAlive: true)
class SocialController extends _$SocialController {
  /// How often the server is asked for news (zero: never; tests).
  static Duration refreshEvery = const Duration(minutes: 2);

  Timer? _timer;
  final _random = Random.secure();

  SocialApi? get _api => ref.read(socialApiProvider);

  String? get _accountId => ref.read(sessionControllerProvider).activeId;

  String get _recipientKey => 'social.recipient.$_accountId';

  @override
  SocialState build() {
    final api = ref.watch(socialApiProvider);
    ref.onDispose(() => _timer?.cancel());
    if (api == null) return const SocialState();
    final saved = ref.read(preferencesProvider).getString(_recipientKey);
    final parts = saved?.split('\n');
    final recipient = parts != null && parts.length == 2
        ? SocialUser(id: parts[0], name: parts[1])
        : null;
    unawaited(Future.microtask(refresh));
    if (refreshEvery > Duration.zero) {
      _timer = Timer.periodic(refreshEvery, (_) => unawaited(refresh()));
    }
    return SocialState(available: true, recipient: recipient);
  }

  /// Reads everything from the server again.
  Future<void> refresh() async {
    final api = _api;
    if (api == null) return;
    try {
      final admin = await api.isAdmin();
      final inbox = await api.readInbox();
      final consent = await api.readConsent();
      var next = SocialState(
        available: true,
        isAdmin: admin,
        inbox: inbox,
        consent: consent,
        recipient: state.recipient,
      );
      final recipient = state.recipient;
      if (admin && recipient != null) {
        next = next.copyWith(
          outbox: await api.readInbox(recipient.id),
          recipientConsent: await api.readConsent(recipient.id),
        );
      }
      state = next;
    } on Object catch (error, stack) {
      _log.error('Could not load sharing state', error, stack);
    }
  }

  // ---- Incoming (the recipient's side) ----

  Future<void> _saveConsent(SocialConsent consent) async {
    await _api?.writeConsent(consent);
    state = state.copyWith(consent: consent);
  }

  /// Answers the request: [features] are allowed, or nothing when
  /// [granted] is false.
  Future<void> answer({
    required bool granted,
    Set<SocialFeature> features = const {},
  }) async {
    final inbox = state.inbox;
    if (inbox == null) return;
    final old = state.answer;
    await _saveConsent(
      SocialConsent(
        fromId: inbox.fromId,
        granted: granted,
        features: granted ? features : const {},
        seen: old?.seen ?? const {},
        liked: old?.liked ?? const {},
      ),
    );
  }

  /// Turns one feature on or off.
  Future<void> setFeature(SocialFeature feature, {required bool on}) async {
    final answer = state.answer;
    if (answer == null || !answer.granted) return;
    await _saveConsent(
      answer.copyWith(
        features: on
            ? {...answer.features, feature}
            : ({...answer.features}..remove(feature)),
      ),
    );
  }

  /// Marks [dedication] as seen.
  Future<void> markSeen(Dedication dedication) async {
    final answer = state.answer;
    if (answer == null || answer.seen.contains(dedication.id)) return;
    await _saveConsent(answer.copyWith(seen: {...answer.seen, dedication.id}));
  }

  /// Likes or unlikes [dedication].
  Future<void> toggleLike(Dedication dedication) async {
    final answer = state.answer;
    if (answer == null) return;
    final liked = {...answer.liked};
    if (!liked.remove(dedication.id)) liked.add(dedication.id);
    await _saveConsent(answer.copyWith(liked: liked));
  }

  // ---- Outgoing (the administrator's side) ----

  /// Users the administrator can share with.
  Future<List<SocialUser>> users() async => await _api?.users() ?? const [];

  /// Picks the person to share with.
  Future<void> chooseRecipient(SocialUser user) async {
    await ref
        .read(preferencesProvider)
        .setString(_recipientKey, '${user.id}\n${user.name}');
    state = state.copyWith(clearRecipient: true);
    state = state.copyWith(recipient: user);
    await refresh();
  }

  Future<void> _saveOutbox(SocialInbox inbox) async {
    final recipient = state.recipient;
    final api = _api;
    if (recipient == null || api == null) return;
    await api.writeInbox(recipient.id, inbox);
    state = state.copyWith(outbox: inbox);
  }

  /// Asks the recipient for permission, showing [fromName] as the sender.
  Future<void> requestPermission(String fromName) async {
    final api = _api;
    if (api == null) return;
    final existing = state.outbox;
    await _saveOutbox(
      existing?.copyWith(fromName: fromName) ??
          SocialInbox(
            fromId: api.selfId,
            fromName: fromName,
            requestedAt: DateTime.now().toUtc(),
          ),
    );
  }

  /// Sends [track] with an optional [note].
  Future<bool> dedicate(Track track, {String note = ''}) async {
    final outbox = state.outbox;
    if (outbox == null || !state.canSend(SocialFeature.dedications)) {
      return false;
    }
    final dedication = Dedication(
      id: [
        for (var i = 0; i < 8; i++)
          _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join(),
      trackId: track.id,
      title: track.title,
      artist: track.artistLine,
      albumId: track.albumId,
      note: note.trim().length > maxNoteLength
          ? note.trim().substring(0, maxNoteLength)
          : note.trim(),
      at: DateTime.now().toUtc(),
    );
    await _saveOutbox(
      outbox.copyWith(dedications: [dedication, ...outbox.dedications]),
    );
    return true;
  }

  /// Sets (or with an empty [text] and no [color], removes) the greeting.
  Future<void> setWelcome(String text, int? color) async {
    final outbox = state.outbox;
    if (outbox == null) return;
    final trimmed = text.trim();
    final clipped = trimmed.length > maxWelcomeLength
        ? trimmed.substring(0, maxWelcomeLength)
        : trimmed;
    await _saveOutbox(
      clipped.isEmpty && color == null
          ? outbox.copyWith(clearWelcome: true)
          : outbox.copyWith(
              welcome: Welcome(
                text: clipped,
                color: color,
                at: DateTime.now().toUtc(),
              ),
            ),
    );
  }

  /// Invites the recipient to listening group [groupId] (`null`: no
  /// invitation).
  Future<void> setListenInvite(String? groupId) async {
    final outbox = state.outbox;
    if (outbox == null) return;
    await _saveOutbox(
      groupId == null
          ? outbox.copyWith(clearListen: true)
          : outbox.copyWith(listenGroupId: groupId),
    );
  }

  /// Creates the shared playlist called [name].
  Future<void> createSharedPlaylist(String name) async {
    final outbox = state.outbox;
    final recipient = state.recipient;
    final api = _api;
    if (outbox == null || recipient == null || api == null) return;
    if (!state.canSend(SocialFeature.sharedPlaylist)) return;
    final playlist = await api.createSharedPlaylist(name.trim(), recipient.id);
    await _saveOutbox(outbox.copyWith(playlist: playlist));
  }
}
