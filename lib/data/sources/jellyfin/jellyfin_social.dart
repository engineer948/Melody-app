import 'package:melody/data/sources/jellyfin/jellyfin_api.dart';
import 'package:melody/domain/social/social_models.dart';

/// [SocialApi] on Jellyfin.
///
/// The data lives in Jellyfin's per-user "display preferences" (custom
/// key-value settings, client `melody`):
/// - `melody-inbox` of the recipient: written only by the sender, which
///   Jellyfin allows only to server administrators;
/// - `melody-consent` of the recipient: written only by the recipient;
///   the administrator can read it.
/// One writer per record, so nothing is overwritten by the other side.
class JellyfinSocial implements SocialApi {
  /// Creates the API for the signed-in [selfId].
  JellyfinSocial(this._api, {required this.selfId});

  final JellyfinApi _api;

  @override
  final String selfId;

  static const _client = 'melody';
  static const _inboxId = 'melody-inbox';
  static const _consentId = 'melody-consent';
  static const _key = 'v1';

  Future<String?> _read(String id, String? userId) async {
    final json = await _api.getObject('DisplayPreferences/$id', {
      'userId': userId ?? selfId,
      'client': _client,
    });
    final prefs = json['CustomPrefs'];
    if (prefs is! Map) return null;
    final value = prefs[_key];
    return value is String ? value : null;
  }

  Future<void> _write(String id, String userId, String value) => _api.post(
    'DisplayPreferences/$id',
    query: {'userId': userId, 'client': _client},
    body: {
      'Id': id,
      'Client': _client,
      'SortBy': 'SortName',
      'SortOrder': 'Ascending',
      'RememberIndexing': false,
      'RememberSorting': false,
      'PrimaryImageHeight': 0,
      'PrimaryImageWidth': 0,
      'ScrollDirection': 'Horizontal',
      'ShowBackdrop': false,
      'ShowSidebar': false,
      'CustomPrefs': {_key: value},
    },
  );

  @override
  Future<bool> isAdmin() async {
    final me = await _api.getObject('Users/Me');
    final policy = me['Policy'];
    return policy is Map && policy['IsAdministrator'] == true;
  }

  @override
  Future<List<SocialUser>> users() async {
    final list = await _api.getList('Users');
    return [
      for (final u in list)
        if (u is Map &&
            u['Id'] is String &&
            u['Id'] != selfId &&
            !((u['Policy'] as Map?)?['IsDisabled'] == true))
          SocialUser(id: u['Id'] as String, name: '${u['Name'] ?? ''}'),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<SocialInbox?> readInbox([String? userId]) async =>
      SocialInbox.decode(await _read(_inboxId, userId));

  @override
  Future<void> writeInbox(String userId, SocialInbox inbox) =>
      _write(_inboxId, userId, inbox.encode());

  @override
  Future<SocialConsent?> readConsent([String? userId]) async =>
      SocialConsent.decode(await _read(_consentId, userId));

  @override
  Future<void> writeConsent(SocialConsent consent) =>
      _write(_consentId, selfId, consent.encode());

  @override
  Future<SharedPlaylistRef> createSharedPlaylist(
    String name,
    String userId,
  ) async {
    final json = await _api.post(
      'Playlists',
      body: {
        'Name': name,
        'Ids': const <String>[],
        'UserId': selfId,
        'MediaType': 'Audio',
        'Users': [
          {'UserId': userId, 'CanEdit': true},
        ],
        'IsPublic': false,
      },
    );
    final id = json['Id'];
    if (id is! String) throw const FormatException('no playlist id');
    // Older servers ignore "Users" on creation; share explicitly as well.
    await _api.post('Playlists/$id/Users/$userId', body: {'CanEdit': true});
    return SharedPlaylistRef(id: id, name: name);
  }
}
