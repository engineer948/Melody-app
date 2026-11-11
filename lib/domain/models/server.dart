import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:melody/core/config/feature_flags.dart';

part 'server.freezed.dart';
part 'server.g.dart';

/// Public facts about a server, available before signing in.
@freezed
abstract class ServerInfo with _$ServerInfo {
  /// Creates a [ServerInfo].
  const factory ServerInfo({
    required Uri baseUrl,
    required String name,
    String? id,
    String? version,
    @Default(SourceType.jellyfin) SourceType type,
  }) = _ServerInfo;

  const ServerInfo._();

  /// Whether traffic to the server is unencrypted.
  bool get isInsecure => baseUrl.scheme == 'http';
}

/// A user the server lists on its sign-in page.
@freezed
abstract class PublicUser with _$PublicUser {
  /// Creates a [PublicUser].
  const factory PublicUser({
    required String id,
    required String name,
    Uri? avatar,
    @Default(true) bool hasPassword,
  }) = _PublicUser;
}

/// A music collection on the server.
@freezed
abstract class MusicLibrary with _$MusicLibrary {
  /// Creates a [MusicLibrary].
  const factory MusicLibrary({required String id, required String name}) =
      _MusicLibrary;
}

/// A saved sign-in. The access token is stored separately.
@freezed
abstract class ServerAccount with _$ServerAccount {
  /// Creates a [ServerAccount].
  const factory ServerAccount({
    required String id,
    required SourceType type,
    required Uri baseUrl,
    required String serverName,
    required String userId,
    required String userName,
    String? serverId,
    String? serverVersion,
    String? libraryId,
  }) = _ServerAccount;

  /// Restores a [ServerAccount] from storage.
  factory ServerAccount.fromJson(Map<String, dynamic> json) =>
      _$ServerAccountFromJson(json);
}

/// Result of a successful sign-in.
@freezed
abstract class AuthSession with _$AuthSession {
  /// Creates an [AuthSession].
  const factory AuthSession({
    required ServerAccount account,
    required String accessToken,
  }) = _AuthSession;
}

/// A pending Quick Connect request.
@freezed
abstract class QuickConnectRequest with _$QuickConnectRequest {
  /// Creates a [QuickConnectRequest].
  const factory QuickConnectRequest({
    required String code,
    required String secret,
  }) = _QuickConnectRequest;
}
