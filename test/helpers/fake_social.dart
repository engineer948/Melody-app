import 'package:melody/domain/social/social_models.dart';

/// The server side of sharing: stored text per user, like Jellyfin's
/// per-user display preferences.
class FakeSocialServer {
  /// Inbox text per user.
  final inboxes = <String, String>{};

  /// Consent text per user.
  final consents = <String, String>{};

  /// Playlists shared: id -> recipient.
  final playlists = <String, String>{};

  /// Users on the server.
  final users = <SocialUser>[
    const SocialUser(id: 'admin', name: 'Ali'),
    const SocialUser(id: 'ayla', name: 'Ayla'),
  ];
}

/// [SocialApi] of one user on a [FakeSocialServer], with Jellyfin's rule:
/// only administrators may touch another user's records.
class FakeSocialApi implements SocialApi {
  /// Creates the API for [selfId].
  FakeSocialApi(this.server, this.selfId, {this.admin = false});

  /// Shared storage.
  final FakeSocialServer server;

  @override
  final String selfId;

  /// Whether [selfId] administers the server.
  final bool admin;

  void _check(String? userId) {
    if (userId != null && userId != selfId && !admin) {
      throw StateError('Forbidden');
    }
  }

  @override
  Future<bool> isAdmin() async => admin;

  @override
  Future<List<SocialUser>> users() async {
    _check('someone else');
    return [
      for (final u in server.users)
        if (u.id != selfId) u,
    ];
  }

  @override
  Future<SocialInbox?> readInbox([String? userId]) async {
    _check(userId);
    return SocialInbox.decode(server.inboxes[userId ?? selfId]);
  }

  @override
  Future<void> writeInbox(String userId, SocialInbox inbox) async {
    _check(userId);
    server.inboxes[userId] = inbox.encode();
  }

  @override
  Future<void> clearInbox(String userId) async {
    _check(userId);
    server.inboxes.remove(userId);
  }

  @override
  Future<SocialConsent?> readConsent([String? userId]) async {
    _check(userId);
    return SocialConsent.decode(server.consents[userId ?? selfId]);
  }

  @override
  Future<void> writeConsent(SocialConsent consent) async {
    server.consents[selfId] = consent.encode();
  }

  @override
  Future<SharedPlaylistRef> createSharedPlaylist(
    String name,
    String userId,
  ) async {
    final id = 'pl${server.playlists.length + 1}';
    server.playlists[id] = userId;
    return SharedPlaylistRef(id: id, name: name);
  }
}
