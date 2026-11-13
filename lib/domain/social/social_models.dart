import 'dart:convert';

import 'package:meta/meta.dart';

/// What a sender can share with one other user on the same server.
///
/// Nothing reaches the recipient's screen before they agree, and each
/// feature can be turned off on its own.
enum SocialFeature {
  /// Songs sent with an optional note.
  dedications,

  /// A playlist both can add songs to.
  sharedPlaylist,

  /// A personal greeting and accent color on the home screen.
  welcome,

  /// Listening to the same song at the same time.
  listenTogether,
}

/// The longest note that can travel with a song.
const maxNoteLength = 140;

/// The longest greeting.
const maxWelcomeLength = 60;

/// How many songs the inbox keeps (oldest are dropped).
const maxDedications = 30;

String _clip(Object? text, int max) {
  if (text is! String) return '';
  final trimmed = text.trim();
  return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

/// A song sent to the recipient.
@immutable
class Dedication {
  /// Creates a dedication.
  const Dedication({
    required this.id,
    required this.trackId,
    required this.title,
    required this.artist,
    required this.at,
    this.albumId,
    this.note = '',
  });

  /// Reads one entry; `null` when it is broken.
  static Dedication? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final trackId = json['trackId'];
    final at = _date(json['at']);
    if (id is! String || trackId is! String || at == null) return null;
    return Dedication(
      id: id,
      trackId: trackId,
      title: _clip(json['title'], 200),
      artist: _clip(json['artist'], 200),
      albumId: json['albumId'] is String ? json['albumId'] as String : null,
      note: _clip(json['note'], maxNoteLength),
      at: at,
    );
  }

  /// Unique id (to mark it seen or liked).
  final String id;

  /// The song.
  final String trackId;

  /// Song title when it was sent.
  final String title;

  /// Artist line when it was sent.
  final String artist;

  /// Album, for the cover.
  final String? albumId;

  /// Optional note from the sender.
  final String note;

  /// When it was sent.
  final DateTime at;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'trackId': trackId,
    'title': title,
    'artist': artist,
    'albumId': ?albumId,
    if (note.isNotEmpty) 'note': note,
    'at': at.toUtc().toIso8601String(),
  };
}

/// Greeting and color the sender chose for the recipient's home screen.
@immutable
class Welcome {
  /// Creates a greeting.
  const Welcome({required this.text, required this.at, this.color});

  /// Reads it; `null` when empty or broken.
  static Welcome? fromJson(Object? json) {
    if (json is! Map) return null;
    final text = _clip(json['text'], maxWelcomeLength);
    final color = json['color'];
    final at = _date(json['at']) ?? DateTime.utc(2000);
    if (text.isEmpty && color is! int) return null;
    return Welcome(
      text: text,
      color: color is int ? 0xFF000000 | (color & 0xFFFFFF) : null,
      at: at,
    );
  }

  /// Shown instead of "Good morning"; may be empty (color only).
  final String text;

  /// Opaque ARGB accent color, or `null` to keep the recipient's own.
  final int? color;

  /// When it was last changed.
  final DateTime at;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'text': text,
    'color': ?color,
    'at': at.toUtc().toIso8601String(),
  };
}

/// The playlist shared with the recipient.
@immutable
class SharedPlaylistRef {
  /// Creates the reference.
  const SharedPlaylistRef({required this.id, required this.name});

  /// Reads it; `null` when broken.
  static SharedPlaylistRef? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (id is! String) return null;
    return SharedPlaylistRef(id: id, name: _clip(json['name'], 100));
  }

  /// Playlist id.
  final String id;

  /// Playlist name.
  final String name;

  /// JSON form.
  Map<String, Object?> toJson() => {'id': id, 'name': name};
}

/// What the sender wrote for the recipient. It lives in the recipient's
/// own server settings, written by the sender (a server administrator).
@immutable
class SocialInbox {
  /// Creates an inbox.
  const SocialInbox({
    required this.fromId,
    required this.fromName,
    required this.requestedAt,
    this.dedications = const [],
    this.welcome,
    this.playlist,
    this.listenGroupId,
  });

  /// Reads the stored text; `null` when there is none or it is broken.
  static SocialInbox? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (json is! Map) return null;
    final fromId = json['fromId'];
    final requestedAt = _date(json['requestedAt']);
    if (fromId is! String || requestedAt == null) return null;
    final list = json['dedications'];
    return SocialInbox(
      fromId: fromId,
      fromName: _clip(json['fromName'], 40),
      requestedAt: requestedAt,
      dedications: [
        if (list is List)
          for (final entry in list) ?Dedication.fromJson(entry),
      ],
      welcome: Welcome.fromJson(json['welcome']),
      playlist: SharedPlaylistRef.fromJson(json['playlist']),
      listenGroupId: json['listenGroupId'] is String
          ? json['listenGroupId'] as String
          : null,
    );
  }

  /// Sender's user id.
  final String fromId;

  /// Name the sender chose to show.
  final String fromName;

  /// When the sender first asked for permission.
  final DateTime requestedAt;

  /// Songs sent, newest first.
  final List<Dedication> dedications;

  /// Greeting and color.
  final Welcome? welcome;

  /// Shared playlist.
  final SharedPlaylistRef? playlist;

  /// Listening group the sender invites to, if any.
  final String? listenGroupId;

  /// Stored text.
  String encode() => jsonEncode({
    'fromId': fromId,
    'fromName': fromName,
    'requestedAt': requestedAt.toUtc().toIso8601String(),
    'dedications': [for (final d in dedications) d.toJson()],
    if (welcome case final w?) 'welcome': w.toJson(),
    if (playlist case final p?) 'playlist': p.toJson(),
    'listenGroupId': ?listenGroupId,
  });

  /// Copy with some fields replaced; `clear…` removes optional parts.
  SocialInbox copyWith({
    String? fromName,
    List<Dedication>? dedications,
    Welcome? welcome,
    bool clearWelcome = false,
    SharedPlaylistRef? playlist,
    String? listenGroupId,
    bool clearListen = false,
  }) => SocialInbox(
    fromId: fromId,
    fromName: fromName ?? this.fromName,
    requestedAt: requestedAt,
    dedications: (dedications ?? this.dedications)
        .take(maxDedications)
        .toList(),
    welcome: clearWelcome ? null : welcome ?? this.welcome,
    playlist: playlist ?? this.playlist,
    listenGroupId: clearListen ? null : listenGroupId ?? this.listenGroupId,
  );
}

/// The recipient's answer. It lives in the recipient's own server
/// settings and only they write it; the sender can only read it.
@immutable
class SocialConsent {
  /// Creates an answer.
  const SocialConsent({
    required this.fromId,
    required this.granted,
    required this.features,
    this.seen = const {},
    this.liked = const {},
    this.requestedAt,
  });

  /// Reads the stored text; `null` when there is none or it is broken.
  static SocialConsent? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (json is! Map) return null;
    final fromId = json['fromId'];
    final granted = json['granted'];
    if (fromId is! String || granted is! bool) return null;
    final features = json['features'];
    Set<String> strings(Object? list) => {
      if (list is List)
        for (final s in list.take(200))
          if (s is String) s,
    };
    return SocialConsent(
      fromId: fromId,
      granted: granted,
      features: {
        for (final name in strings(features))
          ?SocialFeature.values.asNameMap()[name],
      },
      seen: strings(json['seen']),
      liked: strings(json['liked']),
      requestedAt: _date(json['requestedAt']),
    );
  }

  /// The request this answers ([SocialInbox.requestedAt]); a withdrawn and
  /// repeated request must be answered again. `null` in answers stored by
  /// older versions (they match any request from the same sender).
  final DateTime? requestedAt;

  /// Whether this is the answer to [inbox].
  bool answers(SocialInbox inbox) =>
      fromId == inbox.fromId &&
      (requestedAt == null || requestedAt == inbox.requestedAt);

  /// The sender this answer is for.
  final String fromId;

  /// Whether the recipient agreed at all.
  final bool granted;

  /// Features the recipient allows.
  final Set<SocialFeature> features;

  /// Dedications already looked at.
  final Set<String> seen;

  /// Dedications liked (❤).
  final Set<String> liked;

  /// Whether [feature] may be shown.
  bool allows(SocialFeature feature) => granted && features.contains(feature);

  /// Stored text.
  String encode() => jsonEncode({
    'fromId': fromId,
    'granted': granted,
    'features': [for (final f in features) f.name],
    'seen': seen.toList(),
    'liked': liked.toList(),
    if (requestedAt case final at?) 'requestedAt': at.toIso8601String(),
  });

  /// Copy with some fields replaced.
  SocialConsent copyWith({
    bool? granted,
    Set<SocialFeature>? features,
    Set<String>? seen,
    Set<String>? liked,
  }) => SocialConsent(
    fromId: fromId,
    granted: granted ?? this.granted,
    features: features ?? this.features,
    seen: seen ?? this.seen,
    liked: liked ?? this.liked,
    requestedAt: requestedAt,
  );
}

/// Another user on the server.
@immutable
class SocialUser {
  /// Creates a user.
  const SocialUser({required this.id, required this.name});

  /// User id.
  final String id;

  /// User name.
  final String name;
}

/// Server-side storage and actions behind the sharing features.
abstract interface class SocialApi {
  /// The signed-in user's id.
  String get selfId;

  /// Whether the signed-in user administers the server (only then can
  /// they write to another user's inbox).
  Future<bool> isAdmin();

  /// Other enabled users (administrators only).
  Future<List<SocialUser>> users();

  /// Inbox of [userId] (default: the signed-in user).
  Future<SocialInbox?> readInbox([String? userId]);

  /// Writes [userId]'s inbox (administrators only).
  Future<void> writeInbox(String userId, SocialInbox inbox);

  /// Empties [userId]'s inbox: the request is withdrawn (administrators
  /// only).
  Future<void> clearInbox(String userId);

  /// Answer stored by [userId] (default: the signed-in user).
  Future<SocialConsent?> readConsent([String? userId]);

  /// Stores the signed-in user's answer.
  Future<void> writeConsent(SocialConsent consent);

  /// Creates a playlist owned by the signed-in user that [userId] may edit.
  Future<SharedPlaylistRef> createSharedPlaylist(String name, String userId);
}
