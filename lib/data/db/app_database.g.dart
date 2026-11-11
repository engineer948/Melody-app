// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  /// Account id.
  final String id;

  /// JSON of the account.
  final String payload;

  /// Creation time, used for ordering.
  final DateTime createdAt;
  const Account({
    required this.id,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith({String? id, String? payload, DateTime? createdAt}) =>
      Account(
        id: id ?? this.id,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String payload,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedItemsTable extends CachedItems
    with TableInfo<$CachedItemsTable, CachedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    kind,
    itemId,
    name,
    payload,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, kind, itemId};
  @override
  CachedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedItem(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedItemsTable createAlias(String alias) {
    return $CachedItemsTable(attachedDatabase, alias);
  }
}

class CachedItem extends DataClass implements Insertable<CachedItem> {
  /// Owning account.
  final String accountId;

  /// Item kind, e.g. `album`.
  final String kind;

  /// Item id on the source.
  final String itemId;

  /// Lower-cased name for offline search.
  final String name;

  /// JSON of the domain model.
  final String payload;

  /// Last refresh.
  final DateTime updatedAt;
  const CachedItem({
    required this.accountId,
    required this.kind,
    required this.itemId,
    required this.name,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['kind'] = Variable<String>(kind);
    map['item_id'] = Variable<String>(itemId);
    map['name'] = Variable<String>(name);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedItemsCompanion(
      accountId: Value(accountId),
      kind: Value(kind),
      itemId: Value(itemId),
      name: Value(name),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedItem(
      accountId: serializer.fromJson<String>(json['accountId']),
      kind: serializer.fromJson<String>(json['kind']),
      itemId: serializer.fromJson<String>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'kind': serializer.toJson<String>(kind),
      'itemId': serializer.toJson<String>(itemId),
      'name': serializer.toJson<String>(name),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedItem copyWith({
    String? accountId,
    String? kind,
    String? itemId,
    String? name,
    String? payload,
    DateTime? updatedAt,
  }) => CachedItem(
    accountId: accountId ?? this.accountId,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedItem copyWithCompanion(CachedItemsCompanion data) {
    return CachedItem(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedItem(')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, kind, itemId, name, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedItem &&
          other.accountId == this.accountId &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class CachedItemsCompanion extends UpdateCompanion<CachedItem> {
  final Value<String> accountId;
  final Value<String> kind;
  final Value<String> itemId;
  final Value<String> name;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedItemsCompanion({
    this.accountId = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedItemsCompanion.insert({
    required String accountId,
    required String kind,
    required String itemId,
    required String name,
    required String payload,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       kind = Value(kind),
       itemId = Value(itemId),
       name = Value(name),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<CachedItem> custom({
    Expression<String>? accountId,
    Expression<String>? kind,
    Expression<String>? itemId,
    Expression<String>? name,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedItemsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? kind,
    Value<String>? itemId,
    Value<String>? name,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedItemsCompanion(
      accountId: accountId ?? this.accountId,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedItemsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedListsTable extends CachedLists
    with TableInfo<$CachedListsTable, CachedList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listKeyMeta = const VerificationMeta(
    'listKey',
  );
  @override
  late final GeneratedColumn<String> listKey = GeneratedColumn<String>(
    'list_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdsMeta = const VerificationMeta(
    'itemIds',
  );
  @override
  late final GeneratedColumn<String> itemIds = GeneratedColumn<String>(
    'item_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    listKey,
    itemIds,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('list_key')) {
      context.handle(
        _listKeyMeta,
        listKey.isAcceptableOrUnknown(data['list_key']!, _listKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_listKeyMeta);
    }
    if (data.containsKey('item_ids')) {
      context.handle(
        _itemIdsMeta,
        itemIds.isAcceptableOrUnknown(data['item_ids']!, _itemIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, listKey};
  @override
  CachedList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedList(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      listKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_key'],
      )!,
      itemIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_ids'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedListsTable createAlias(String alias) {
    return $CachedListsTable(attachedDatabase, alias);
  }
}

class CachedList extends DataClass implements Insertable<CachedList> {
  /// Owning account.
  final String accountId;

  /// Listing key, e.g. `albums:name::`.
  final String listKey;

  /// JSON array of item ids.
  final String itemIds;

  /// Last refresh.
  final DateTime updatedAt;
  const CachedList({
    required this.accountId,
    required this.listKey,
    required this.itemIds,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['list_key'] = Variable<String>(listKey);
    map['item_ids'] = Variable<String>(itemIds);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedListsCompanion toCompanion(bool nullToAbsent) {
    return CachedListsCompanion(
      accountId: Value(accountId),
      listKey: Value(listKey),
      itemIds: Value(itemIds),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedList(
      accountId: serializer.fromJson<String>(json['accountId']),
      listKey: serializer.fromJson<String>(json['listKey']),
      itemIds: serializer.fromJson<String>(json['itemIds']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'listKey': serializer.toJson<String>(listKey),
      'itemIds': serializer.toJson<String>(itemIds),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedList copyWith({
    String? accountId,
    String? listKey,
    String? itemIds,
    DateTime? updatedAt,
  }) => CachedList(
    accountId: accountId ?? this.accountId,
    listKey: listKey ?? this.listKey,
    itemIds: itemIds ?? this.itemIds,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedList copyWithCompanion(CachedListsCompanion data) {
    return CachedList(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      listKey: data.listKey.present ? data.listKey.value : this.listKey,
      itemIds: data.itemIds.present ? data.itemIds.value : this.itemIds,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedList(')
          ..write('accountId: $accountId, ')
          ..write('listKey: $listKey, ')
          ..write('itemIds: $itemIds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, listKey, itemIds, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedList &&
          other.accountId == this.accountId &&
          other.listKey == this.listKey &&
          other.itemIds == this.itemIds &&
          other.updatedAt == this.updatedAt);
}

class CachedListsCompanion extends UpdateCompanion<CachedList> {
  final Value<String> accountId;
  final Value<String> listKey;
  final Value<String> itemIds;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedListsCompanion({
    this.accountId = const Value.absent(),
    this.listKey = const Value.absent(),
    this.itemIds = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedListsCompanion.insert({
    required String accountId,
    required String listKey,
    required String itemIds,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       listKey = Value(listKey),
       itemIds = Value(itemIds),
       updatedAt = Value(updatedAt);
  static Insertable<CachedList> custom({
    Expression<String>? accountId,
    Expression<String>? listKey,
    Expression<String>? itemIds,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (listKey != null) 'list_key': listKey,
      if (itemIds != null) 'item_ids': itemIds,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedListsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? listKey,
    Value<String>? itemIds,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedListsCompanion(
      accountId: accountId ?? this.accountId,
      listKey: listKey ?? this.listKey,
      itemIds: itemIds ?? this.itemIds,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (listKey.present) {
      map['list_key'] = Variable<String>(listKey.value);
    }
    if (itemIds.present) {
      map['item_ids'] = Variable<String>(itemIds.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedListsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('listKey: $listKey, ')
          ..write('itemIds: $itemIds, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayHistoryTable extends PlayHistory
    with TableInfo<$PlayHistoryTable, PlayHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listenedMsMeta = const VerificationMeta(
    'listenedMs',
  );
  @override
  late final GeneratedColumn<int> listenedMs = GeneratedColumn<int>(
    'listened_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<bool> skipped = GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("skipped" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    trackId,
    payload,
    startedAt,
    listenedMs,
    durationMs,
    skipped,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('listened_ms')) {
      context.handle(
        _listenedMsMeta,
        listenedMs.isAcceptableOrUnknown(data['listened_ms']!, _listenedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_listenedMsMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    } else if (isInserting) {
      context.missing(_skippedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      listenedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}listened_ms'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}skipped'],
      )!,
    );
  }

  @override
  $PlayHistoryTable createAlias(String alias) {
    return $PlayHistoryTable(attachedDatabase, alias);
  }
}

class PlayHistoryData extends DataClass implements Insertable<PlayHistoryData> {
  /// Row id.
  final int id;

  /// Owning account.
  final String accountId;

  /// Track played.
  final String trackId;

  /// JSON of the track as it was when played.
  final String payload;

  /// When playback of the track began.
  final DateTime startedAt;

  /// Time actually listened, in milliseconds.
  final int listenedMs;

  /// Length of the track in milliseconds; 0 when unknown.
  final int durationMs;

  /// Whether the track was left early.
  final bool skipped;
  const PlayHistoryData({
    required this.id,
    required this.accountId,
    required this.trackId,
    required this.payload,
    required this.startedAt,
    required this.listenedMs,
    required this.durationMs,
    required this.skipped,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<String>(accountId);
    map['track_id'] = Variable<String>(trackId);
    map['payload'] = Variable<String>(payload);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['listened_ms'] = Variable<int>(listenedMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['skipped'] = Variable<bool>(skipped);
    return map;
  }

  PlayHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlayHistoryCompanion(
      id: Value(id),
      accountId: Value(accountId),
      trackId: Value(trackId),
      payload: Value(payload),
      startedAt: Value(startedAt),
      listenedMs: Value(listenedMs),
      durationMs: Value(durationMs),
      skipped: Value(skipped),
    );
  }

  factory PlayHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayHistoryData(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      payload: serializer.fromJson<String>(json['payload']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      listenedMs: serializer.fromJson<int>(json['listenedMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      skipped: serializer.fromJson<bool>(json['skipped']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<String>(accountId),
      'trackId': serializer.toJson<String>(trackId),
      'payload': serializer.toJson<String>(payload),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'listenedMs': serializer.toJson<int>(listenedMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'skipped': serializer.toJson<bool>(skipped),
    };
  }

  PlayHistoryData copyWith({
    int? id,
    String? accountId,
    String? trackId,
    String? payload,
    DateTime? startedAt,
    int? listenedMs,
    int? durationMs,
    bool? skipped,
  }) => PlayHistoryData(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    trackId: trackId ?? this.trackId,
    payload: payload ?? this.payload,
    startedAt: startedAt ?? this.startedAt,
    listenedMs: listenedMs ?? this.listenedMs,
    durationMs: durationMs ?? this.durationMs,
    skipped: skipped ?? this.skipped,
  );
  PlayHistoryData copyWithCompanion(PlayHistoryCompanion data) {
    return PlayHistoryData(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      payload: data.payload.present ? data.payload.value : this.payload,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      listenedMs: data.listenedMs.present
          ? data.listenedMs.value
          : this.listenedMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryData(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('trackId: $trackId, ')
          ..write('payload: $payload, ')
          ..write('startedAt: $startedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('skipped: $skipped')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    trackId,
    payload,
    startedAt,
    listenedMs,
    durationMs,
    skipped,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayHistoryData &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.trackId == this.trackId &&
          other.payload == this.payload &&
          other.startedAt == this.startedAt &&
          other.listenedMs == this.listenedMs &&
          other.durationMs == this.durationMs &&
          other.skipped == this.skipped);
}

class PlayHistoryCompanion extends UpdateCompanion<PlayHistoryData> {
  final Value<int> id;
  final Value<String> accountId;
  final Value<String> trackId;
  final Value<String> payload;
  final Value<DateTime> startedAt;
  final Value<int> listenedMs;
  final Value<int> durationMs;
  final Value<bool> skipped;
  const PlayHistoryCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.payload = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.listenedMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.skipped = const Value.absent(),
  });
  PlayHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String accountId,
    required String trackId,
    required String payload,
    required DateTime startedAt,
    required int listenedMs,
    required int durationMs,
    required bool skipped,
  }) : accountId = Value(accountId),
       trackId = Value(trackId),
       payload = Value(payload),
       startedAt = Value(startedAt),
       listenedMs = Value(listenedMs),
       durationMs = Value(durationMs),
       skipped = Value(skipped);
  static Insertable<PlayHistoryData> custom({
    Expression<int>? id,
    Expression<String>? accountId,
    Expression<String>? trackId,
    Expression<String>? payload,
    Expression<DateTime>? startedAt,
    Expression<int>? listenedMs,
    Expression<int>? durationMs,
    Expression<bool>? skipped,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (trackId != null) 'track_id': trackId,
      if (payload != null) 'payload': payload,
      if (startedAt != null) 'started_at': startedAt,
      if (listenedMs != null) 'listened_ms': listenedMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (skipped != null) 'skipped': skipped,
    });
  }

  PlayHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? accountId,
    Value<String>? trackId,
    Value<String>? payload,
    Value<DateTime>? startedAt,
    Value<int>? listenedMs,
    Value<int>? durationMs,
    Value<bool>? skipped,
  }) {
    return PlayHistoryCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      trackId: trackId ?? this.trackId,
      payload: payload ?? this.payload,
      startedAt: startedAt ?? this.startedAt,
      listenedMs: listenedMs ?? this.listenedMs,
      durationMs: durationMs ?? this.durationMs,
      skipped: skipped ?? this.skipped,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (listenedMs.present) {
      map['listened_ms'] = Variable<int>(listenedMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<bool>(skipped.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('trackId: $trackId, ')
          ..write('payload: $payload, ')
          ..write('startedAt: $startedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('skipped: $skipped')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originsMeta = const VerificationMeta(
    'origins',
  );
  @override
  late final GeneratedColumn<String> origins = GeneratedColumn<String>(
    'origins',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    trackId,
    payload,
    status,
    bytes,
    totalBytes,
    fileName,
    origins,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<Download> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('origins')) {
      context.handle(
        _originsMeta,
        origins.isAcceptableOrUnknown(data['origins']!, _originsMeta),
      );
    } else if (isInserting) {
      context.missing(_originsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, trackId};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      origins: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origins'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class Download extends DataClass implements Insertable<Download> {
  /// Owning account.
  final String accountId;

  /// Track id on the source.
  final String trackId;

  /// JSON of the track.
  final String payload;

  /// `queued`, `running`, `paused`, `done` or `failed`.
  final String status;

  /// Bytes on disk so far.
  final int bytes;

  /// Expected size; 0 when the server did not say.
  final int totalBytes;

  /// File name inside the download folder.
  final String fileName;

  /// JSON array of why it is kept: `manual`, `favorites`, `playlist:<id>`…
  final String origins;

  /// When it was requested.
  final DateTime createdAt;
  const Download({
    required this.accountId,
    required this.trackId,
    required this.payload,
    required this.status,
    required this.bytes,
    required this.totalBytes,
    required this.fileName,
    required this.origins,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['track_id'] = Variable<String>(trackId);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['bytes'] = Variable<int>(bytes);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['file_name'] = Variable<String>(fileName);
    map['origins'] = Variable<String>(origins);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      accountId: Value(accountId),
      trackId: Value(trackId),
      payload: Value(payload),
      status: Value(status),
      bytes: Value(bytes),
      totalBytes: Value(totalBytes),
      fileName: Value(fileName),
      origins: Value(origins),
      createdAt: Value(createdAt),
    );
  }

  factory Download.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      accountId: serializer.fromJson<String>(json['accountId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      bytes: serializer.fromJson<int>(json['bytes']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      fileName: serializer.fromJson<String>(json['fileName']),
      origins: serializer.fromJson<String>(json['origins']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'trackId': serializer.toJson<String>(trackId),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'bytes': serializer.toJson<int>(bytes),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'fileName': serializer.toJson<String>(fileName),
      'origins': serializer.toJson<String>(origins),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Download copyWith({
    String? accountId,
    String? trackId,
    String? payload,
    String? status,
    int? bytes,
    int? totalBytes,
    String? fileName,
    String? origins,
    DateTime? createdAt,
  }) => Download(
    accountId: accountId ?? this.accountId,
    trackId: trackId ?? this.trackId,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    bytes: bytes ?? this.bytes,
    totalBytes: totalBytes ?? this.totalBytes,
    fileName: fileName ?? this.fileName,
    origins: origins ?? this.origins,
    createdAt: createdAt ?? this.createdAt,
  );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      origins: data.origins.present ? data.origins.value : this.origins,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('accountId: $accountId, ')
          ..write('trackId: $trackId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('bytes: $bytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('fileName: $fileName, ')
          ..write('origins: $origins, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    trackId,
    payload,
    status,
    bytes,
    totalBytes,
    fileName,
    origins,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.accountId == this.accountId &&
          other.trackId == this.trackId &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.bytes == this.bytes &&
          other.totalBytes == this.totalBytes &&
          other.fileName == this.fileName &&
          other.origins == this.origins &&
          other.createdAt == this.createdAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<String> accountId;
  final Value<String> trackId;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> bytes;
  final Value<int> totalBytes;
  final Value<String> fileName;
  final Value<String> origins;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.accountId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.bytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.fileName = const Value.absent(),
    this.origins = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String accountId,
    required String trackId,
    required String payload,
    required String status,
    this.bytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    required String fileName,
    required String origins,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       trackId = Value(trackId),
       payload = Value(payload),
       status = Value(status),
       fileName = Value(fileName),
       origins = Value(origins),
       createdAt = Value(createdAt);
  static Insertable<Download> custom({
    Expression<String>? accountId,
    Expression<String>? trackId,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? bytes,
    Expression<int>? totalBytes,
    Expression<String>? fileName,
    Expression<String>? origins,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (trackId != null) 'track_id': trackId,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (bytes != null) 'bytes': bytes,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (fileName != null) 'file_name': fileName,
      if (origins != null) 'origins': origins,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? trackId,
    Value<String>? payload,
    Value<String>? status,
    Value<int>? bytes,
    Value<int>? totalBytes,
    Value<String>? fileName,
    Value<String>? origins,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      accountId: accountId ?? this.accountId,
      trackId: trackId ?? this.trackId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      bytes: bytes ?? this.bytes,
      totalBytes: totalBytes ?? this.totalBytes,
      fileName: fileName ?? this.fileName,
      origins: origins ?? this.origins,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (origins.present) {
      map['origins'] = Variable<String>(origins.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('trackId: $trackId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('bytes: $bytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('fileName: $fileName, ')
          ..write('origins: $origins, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CachedItemsTable cachedItems = $CachedItemsTable(this);
  late final $CachedListsTable cachedLists = $CachedListsTable(this);
  late final $PlayHistoryTable playHistory = $PlayHistoryTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    cachedItems,
    cachedLists,
    playHistory,
    downloads,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String payload,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                payload: payload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                payload: payload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  BaseReferences<_$AppDatabase, $AccountsTable, Account>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$CachedItemsTableCreateCompanionBuilder =
    CachedItemsCompanion Function({
      required String accountId,
      required String kind,
      required String itemId,
      required String name,
      required String payload,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedItemsTableUpdateCompanionBuilder =
    CachedItemsCompanion Function({
      Value<String> accountId,
      Value<String> kind,
      Value<String> itemId,
      Value<String> name,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedItemsTable,
          CachedItem,
          $$CachedItemsTableFilterComposer,
          $$CachedItemsTableOrderingComposer,
          $$CachedItemsTableAnnotationComposer,
          $$CachedItemsTableCreateCompanionBuilder,
          $$CachedItemsTableUpdateCompanionBuilder,
          (
            CachedItem,
            BaseReferences<_$AppDatabase, $CachedItemsTable, CachedItem>,
          ),
          CachedItem,
          PrefetchHooks Function()
        > {
  $$CachedItemsTableTableManager(_$AppDatabase db, $CachedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion(
                accountId: accountId,
                kind: kind,
                itemId: itemId,
                name: name,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String kind,
                required String itemId,
                required String name,
                required String payload,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion.insert(
                accountId: accountId,
                kind: kind,
                itemId: itemId,
                name: name,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedItemsTable, CachedItem>(table),
                  BaseReferences<_$AppDatabase, $CachedItemsTable, CachedItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedItemsTable,
      CachedItem,
      $$CachedItemsTableFilterComposer,
      $$CachedItemsTableOrderingComposer,
      $$CachedItemsTableAnnotationComposer,
      $$CachedItemsTableCreateCompanionBuilder,
      $$CachedItemsTableUpdateCompanionBuilder,
      (
        CachedItem,
        BaseReferences<_$AppDatabase, $CachedItemsTable, CachedItem>,
      ),
      CachedItem,
      PrefetchHooks Function()
    >;
typedef $$CachedListsTableCreateCompanionBuilder =
    CachedListsCompanion Function({
      required String accountId,
      required String listKey,
      required String itemIds,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedListsTableUpdateCompanionBuilder =
    CachedListsCompanion Function({
      Value<String> accountId,
      Value<String> listKey,
      Value<String> itemIds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedListsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedListsTable> {
  $$CachedListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listKey => $composableBuilder(
    column: $table.listKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemIds => $composableBuilder(
    column: $table.itemIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedListsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedListsTable> {
  $$CachedListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listKey => $composableBuilder(
    column: $table.listKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemIds => $composableBuilder(
    column: $table.itemIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedListsTable> {
  $$CachedListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get listKey =>
      $composableBuilder(column: $table.listKey, builder: (column) => column);

  GeneratedColumn<String> get itemIds =>
      $composableBuilder(column: $table.itemIds, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedListsTable,
          CachedList,
          $$CachedListsTableFilterComposer,
          $$CachedListsTableOrderingComposer,
          $$CachedListsTableAnnotationComposer,
          $$CachedListsTableCreateCompanionBuilder,
          $$CachedListsTableUpdateCompanionBuilder,
          (
            CachedList,
            BaseReferences<_$AppDatabase, $CachedListsTable, CachedList>,
          ),
          CachedList,
          PrefetchHooks Function()
        > {
  $$CachedListsTableTableManager(_$AppDatabase db, $CachedListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> listKey = const Value.absent(),
                Value<String> itemIds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedListsCompanion(
                accountId: accountId,
                listKey: listKey,
                itemIds: itemIds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String listKey,
                required String itemIds,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedListsCompanion.insert(
                accountId: accountId,
                listKey: listKey,
                itemIds: itemIds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedListsTable, CachedList>(table),
                  BaseReferences<_$AppDatabase, $CachedListsTable, CachedList>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedListsTable,
      CachedList,
      $$CachedListsTableFilterComposer,
      $$CachedListsTableOrderingComposer,
      $$CachedListsTableAnnotationComposer,
      $$CachedListsTableCreateCompanionBuilder,
      $$CachedListsTableUpdateCompanionBuilder,
      (
        CachedList,
        BaseReferences<_$AppDatabase, $CachedListsTable, CachedList>,
      ),
      CachedList,
      PrefetchHooks Function()
    >;
typedef $$PlayHistoryTableCreateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      required String accountId,
      required String trackId,
      required String payload,
      required DateTime startedAt,
      required int listenedMs,
      required int durationMs,
      required bool skipped,
    });
typedef $$PlayHistoryTableUpdateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      Value<String> accountId,
      Value<String> trackId,
      Value<String> payload,
      Value<DateTime> startedAt,
      Value<int> listenedMs,
      Value<int> durationMs,
      Value<bool> skipped,
    });

class $$PlayHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);
}

class $$PlayHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayHistoryTable,
          PlayHistoryData,
          $$PlayHistoryTableFilterComposer,
          $$PlayHistoryTableOrderingComposer,
          $$PlayHistoryTableAnnotationComposer,
          $$PlayHistoryTableCreateCompanionBuilder,
          $$PlayHistoryTableUpdateCompanionBuilder,
          (
            PlayHistoryData,
            BaseReferences<_$AppDatabase, $PlayHistoryTable, PlayHistoryData>,
          ),
          PlayHistoryData,
          PrefetchHooks Function()
        > {
  $$PlayHistoryTableTableManager(_$AppDatabase db, $PlayHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> listenedMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
              }) => PlayHistoryCompanion(
                id: id,
                accountId: accountId,
                trackId: trackId,
                payload: payload,
                startedAt: startedAt,
                listenedMs: listenedMs,
                durationMs: durationMs,
                skipped: skipped,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String accountId,
                required String trackId,
                required String payload,
                required DateTime startedAt,
                required int listenedMs,
                required int durationMs,
                required bool skipped,
              }) => PlayHistoryCompanion.insert(
                id: id,
                accountId: accountId,
                trackId: trackId,
                payload: payload,
                startedAt: startedAt,
                listenedMs: listenedMs,
                durationMs: durationMs,
                skipped: skipped,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayHistoryTable, PlayHistoryData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlayHistoryTable,
                    PlayHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayHistoryTable,
      PlayHistoryData,
      $$PlayHistoryTableFilterComposer,
      $$PlayHistoryTableOrderingComposer,
      $$PlayHistoryTableAnnotationComposer,
      $$PlayHistoryTableCreateCompanionBuilder,
      $$PlayHistoryTableUpdateCompanionBuilder,
      (
        PlayHistoryData,
        BaseReferences<_$AppDatabase, $PlayHistoryTable, PlayHistoryData>,
      ),
      PlayHistoryData,
      PrefetchHooks Function()
    >;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String accountId,
  required String trackId,
  required String payload,
  required String status,
  Value<int> bytes,
  Value<int> totalBytes,
  required String fileName,
  required String origins,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> accountId,
  Value<String> trackId,
  Value<String> payload,
  Value<String> status,
  Value<int> bytes,
  Value<int> totalBytes,
  Value<String> fileName,
  Value<String> origins,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origins => $composableBuilder(
    column: $table.origins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origins => $composableBuilder(
    column: $table.origins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get origins =>
      $composableBuilder(column: $table.origins, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTable,
          Download,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
          Download,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> origins = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                accountId: accountId,
                trackId: trackId,
                payload: payload,
                status: status,
                bytes: bytes,
                totalBytes: totalBytes,
                fileName: fileName,
                origins: origins,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String trackId,
                required String payload,
                required String status,
                Value<int> bytes = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                required String fileName,
                required String origins,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                accountId: accountId,
                trackId: trackId,
                payload: payload,
                status: status,
                bytes: bytes,
                totalBytes: totalBytes,
                fileName: fileName,
                origins: origins,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadsTable, Download>(table),
                  BaseReferences<_$AppDatabase, $DownloadsTable, Download>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTable,
      Download,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
      Download,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CachedItemsTableTableManager get cachedItems =>
      $$CachedItemsTableTableManager(_db, _db.cachedItems);
  $$CachedListsTableTableManager get cachedLists =>
      $$CachedListsTableTableManager(_db, _db.cachedLists);
  $$PlayHistoryTableTableManager get playHistory =>
      $$PlayHistoryTableTableManager(_db, _db.playHistory);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
}
