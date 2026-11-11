import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/data/repositories/token_store.dart';
import 'package:melody/domain/models/server.dart';

/// A saved account together with its token, when one is still valid.
typedef StoredAccount = ({ServerAccount account, String? token});

/// Persists accounts in the database and tokens in secure storage.
class AccountStore {
  /// Creates the store.
  AccountStore(this._db, this._tokens);

  final AppDatabase _db;
  final TokenStore _tokens;

  /// All saved accounts, oldest first.
  Future<List<StoredAccount>> loadAll() async {
    final rows = await (_db.select(
      _db.accounts,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
    final result = <StoredAccount>[];
    for (final row in rows) {
      final ServerAccount account;
      try {
        account = ServerAccount.fromJson(
          jsonDecode(row.payload) as Map<String, dynamic>,
        );
      } on Object {
        continue;
      }
      String? token;
      try {
        token = await _tokens.read(account.id);
      } on Object {
        token = null; // Keystore unavailable: ask the user to sign in again.
      }
      result.add((account: account, token: token));
    }
    return result;
  }

  /// Saves [account]; the token is replaced when [token] is given.
  Future<void> save(ServerAccount account, {String? token}) async {
    final payload = jsonEncode(account.toJson());
    final updated =
        await (_db.update(_db.accounts)..where((t) => t.id.equals(account.id)))
            .write(AccountsCompanion(payload: Value(payload)));
    if (updated == 0) {
      await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: account.id,
              payload: payload,
              createdAt: DateTime.now(),
            ),
          );
    }
    if (token != null) await _tokens.write(account.id, token);
  }

  /// Forgets the token of [accountId] but keeps the account.
  Future<void> clearToken(String accountId) => _tokens.delete(accountId);

  /// Removes [accountId] and its token.
  Future<void> remove(String accountId) async {
    await (_db.delete(_db.accounts)..where((t) => t.id.equals(accountId))).go();
    await _tokens.delete(accountId);
  }
}
