import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps access tokens out of plain storage.
abstract interface class TokenStore {
  /// Token of [accountId], if one is saved.
  Future<String?> read(String accountId);

  /// Saves [token] for [accountId].
  Future<void> write(String accountId, String token);

  /// Forgets the token of [accountId].
  Future<void> delete(String accountId);
}

/// [TokenStore] backed by the platform keystore / keychain.
class SecureTokenStore implements TokenStore {
  /// Creates the store.
  const SecureTokenStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static String _key(String accountId) => 'token.$accountId';

  @override
  Future<String?> read(String accountId) => _storage.read(key: _key(accountId));

  @override
  Future<void> write(String accountId, String token) =>
      _storage.write(key: _key(accountId), value: token);

  @override
  Future<void> delete(String accountId) =>
      _storage.delete(key: _key(accountId));
}

/// [TokenStore] that forgets everything on exit; for tests.
class MemoryTokenStore implements TokenStore {
  /// Creates the store, optionally pre-filled.
  MemoryTokenStore([Map<String, String>? initial]) : _tokens = {...?initial};

  final Map<String, String> _tokens;

  @override
  Future<String?> read(String accountId) async => _tokens[accountId];

  @override
  Future<void> write(String accountId, String token) async =>
      _tokens[accountId] = token;

  @override
  Future<void> delete(String accountId) async => _tokens.remove(accountId);
}
