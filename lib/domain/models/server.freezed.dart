// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServerInfo {

 Uri get baseUrl; String get name; String? get id; String? get version; SourceType get type;
/// Create a copy of ServerInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerInfoCopyWith<ServerInfo> get copyWith => _$ServerInfoCopyWithImpl<ServerInfo>(this as ServerInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ServerInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerInfo&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.type, _this.type) || other.type == _this.type));
}


@override
int get hashCode {
  final _this = this as ServerInfo;
  return Object.hash(runtimeType,_this.baseUrl,_this.name,_this.id,_this.version,_this.type);
}

@override
String toString() {
  final _this = this as ServerInfo;
  return 'ServerInfo(baseUrl: ${_this.baseUrl}, name: ${_this.name}, id: ${_this.id}, version: ${_this.version}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $ServerInfoCopyWith<$Res>  {
  factory $ServerInfoCopyWith(ServerInfo value, $Res Function(ServerInfo) _then) = _$ServerInfoCopyWithImpl;
@useResult
$Res call({
 Uri baseUrl, String name, String? id, String? version, SourceType type
});




}
/// @nodoc
class _$ServerInfoCopyWithImpl<$Res>
    implements $ServerInfoCopyWith<$Res> {
  _$ServerInfoCopyWithImpl(this._self, this._then);

  final ServerInfo _self;
  final $Res Function(ServerInfo) _then;

/// Create a copy of ServerInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseUrl = null,Object? name = null,Object? id = freezed,Object? version = freezed,Object? type = null,}) {
  return _then(ServerInfo(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as Uri,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerInfo].
extension ServerInfoPatterns on ServerInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerInfo value)  $default,){
final _that = this;
switch (_that) {
case _ServerInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ServerInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Uri baseUrl,  String name,  String? id,  String? version,  SourceType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerInfo() when $default != null:
return $default(_that.baseUrl,_that.name,_that.id,_that.version,_that.type);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Uri baseUrl,  String name,  String? id,  String? version,  SourceType type)  $default,) {final _that = this;
switch (_that) {
case _ServerInfo():
return $default(_that.baseUrl,_that.name,_that.id,_that.version,_that.type);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Uri baseUrl,  String name,  String? id,  String? version,  SourceType type)?  $default,) {final _that = this;
switch (_that) {
case _ServerInfo() when $default != null:
return $default(_that.baseUrl,_that.name,_that.id,_that.version,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _ServerInfo extends ServerInfo {
  const _ServerInfo({required this.baseUrl, required this.name, this.id, this.version, this.type = SourceType.jellyfin}): super._();
  

@override final  Uri baseUrl;
@override final  String name;
@override final  String? id;
@override final  String? version;
@override@JsonKey() final  SourceType type;

/// Create a copy of ServerInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerInfoCopyWith<_ServerInfo> get copyWith => __$ServerInfoCopyWithImpl<_ServerInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerInfo&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode {
    return Object.hash(runtimeType,baseUrl,name,id,version,type);
}

@override
String toString() {
    return 'ServerInfo(baseUrl: $baseUrl, name: $name, id: $id, version: $version, type: $type)';
}


}

/// @nodoc
abstract mixin class _$ServerInfoCopyWith<$Res> implements $ServerInfoCopyWith<$Res> {
  factory _$ServerInfoCopyWith(_ServerInfo value, $Res Function(_ServerInfo) _then) = __$ServerInfoCopyWithImpl;
@override @useResult
$Res call({
 Uri baseUrl, String name, String? id, String? version, SourceType type
});




}
/// @nodoc
class __$ServerInfoCopyWithImpl<$Res>
    implements _$ServerInfoCopyWith<$Res> {
  __$ServerInfoCopyWithImpl(this._self, this._then);

  final _ServerInfo _self;
  final $Res Function(_ServerInfo) _then;

/// Create a copy of ServerInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseUrl = null,Object? name = null,Object? id = freezed,Object? version = freezed,Object? type = null,}) {
  return _then(_ServerInfo(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as Uri,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,
  ));
}


}

/// @nodoc
mixin _$PublicUser {

 String get id; String get name; Uri? get avatar; bool get hasPassword;
/// Create a copy of PublicUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicUserCopyWith<PublicUser> get copyWith => _$PublicUserCopyWithImpl<PublicUser>(this as PublicUser, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PublicUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicUser&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.avatar, _this.avatar) || other.avatar == _this.avatar)&&(identical(other.hasPassword, _this.hasPassword) || other.hasPassword == _this.hasPassword));
}


@override
int get hashCode {
  final _this = this as PublicUser;
  return Object.hash(runtimeType,_this.id,_this.name,_this.avatar,_this.hasPassword);
}

@override
String toString() {
  final _this = this as PublicUser;
  return 'PublicUser(id: ${_this.id}, name: ${_this.name}, avatar: ${_this.avatar}, hasPassword: ${_this.hasPassword})';
}


}

/// @nodoc
abstract mixin class $PublicUserCopyWith<$Res>  {
  factory $PublicUserCopyWith(PublicUser value, $Res Function(PublicUser) _then) = _$PublicUserCopyWithImpl;
@useResult
$Res call({
 String id, String name, Uri? avatar, bool hasPassword
});




}
/// @nodoc
class _$PublicUserCopyWithImpl<$Res>
    implements $PublicUserCopyWith<$Res> {
  _$PublicUserCopyWithImpl(this._self, this._then);

  final PublicUser _self;
  final $Res Function(PublicUser) _then;

/// Create a copy of PublicUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatar = freezed,Object? hasPassword = null,}) {
  return _then(PublicUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Uri?,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PublicUser].
extension PublicUserPatterns on PublicUser {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicUser() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicUser value)  $default,){
final _that = this;
switch (_that) {
case _PublicUser():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicUser value)?  $default,){
final _that = this;
switch (_that) {
case _PublicUser() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Uri? avatar,  bool hasPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicUser() when $default != null:
return $default(_that.id,_that.name,_that.avatar,_that.hasPassword);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Uri? avatar,  bool hasPassword)  $default,) {final _that = this;
switch (_that) {
case _PublicUser():
return $default(_that.id,_that.name,_that.avatar,_that.hasPassword);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Uri? avatar,  bool hasPassword)?  $default,) {final _that = this;
switch (_that) {
case _PublicUser() when $default != null:
return $default(_that.id,_that.name,_that.avatar,_that.hasPassword);case _:
  return null;

}
}

}

/// @nodoc


class _PublicUser implements PublicUser {
  const _PublicUser({required this.id, required this.name, this.avatar, this.hasPassword = true});
  

@override final  String id;
@override final  String name;
@override final  Uri? avatar;
@override@JsonKey() final  bool hasPassword;

/// Create a copy of PublicUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicUserCopyWith<_PublicUser> get copyWith => __$PublicUserCopyWithImpl<_PublicUser>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.hasPassword, hasPassword) || other.hasPassword == hasPassword));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,avatar,hasPassword);
}

@override
String toString() {
    return 'PublicUser(id: $id, name: $name, avatar: $avatar, hasPassword: $hasPassword)';
}


}

/// @nodoc
abstract mixin class _$PublicUserCopyWith<$Res> implements $PublicUserCopyWith<$Res> {
  factory _$PublicUserCopyWith(_PublicUser value, $Res Function(_PublicUser) _then) = __$PublicUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Uri? avatar, bool hasPassword
});




}
/// @nodoc
class __$PublicUserCopyWithImpl<$Res>
    implements _$PublicUserCopyWith<$Res> {
  __$PublicUserCopyWithImpl(this._self, this._then);

  final _PublicUser _self;
  final $Res Function(_PublicUser) _then;

/// Create a copy of PublicUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatar = freezed,Object? hasPassword = null,}) {
  return _then(_PublicUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Uri?,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$MusicLibrary {

 String get id; String get name;
/// Create a copy of MusicLibrary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicLibraryCopyWith<MusicLibrary> get copyWith => _$MusicLibraryCopyWithImpl<MusicLibrary>(this as MusicLibrary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MusicLibrary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicLibrary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}


@override
int get hashCode {
  final _this = this as MusicLibrary;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as MusicLibrary;
  return 'MusicLibrary(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $MusicLibraryCopyWith<$Res>  {
  factory $MusicLibraryCopyWith(MusicLibrary value, $Res Function(MusicLibrary) _then) = _$MusicLibraryCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$MusicLibraryCopyWithImpl<$Res>
    implements $MusicLibraryCopyWith<$Res> {
  _$MusicLibraryCopyWithImpl(this._self, this._then);

  final MusicLibrary _self;
  final $Res Function(MusicLibrary) _then;

/// Create a copy of MusicLibrary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(MusicLibrary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicLibrary].
extension MusicLibraryPatterns on MusicLibrary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicLibrary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicLibrary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicLibrary value)  $default,){
final _that = this;
switch (_that) {
case _MusicLibrary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicLibrary value)?  $default,){
final _that = this;
switch (_that) {
case _MusicLibrary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicLibrary() when $default != null:
return $default(_that.id,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _MusicLibrary():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _MusicLibrary() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _MusicLibrary implements MusicLibrary {
  const _MusicLibrary({required this.id, required this.name});
  

@override final  String id;
@override final  String name;

/// Create a copy of MusicLibrary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicLibraryCopyWith<_MusicLibrary> get copyWith => __$MusicLibraryCopyWithImpl<_MusicLibrary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicLibrary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'MusicLibrary(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$MusicLibraryCopyWith<$Res> implements $MusicLibraryCopyWith<$Res> {
  factory _$MusicLibraryCopyWith(_MusicLibrary value, $Res Function(_MusicLibrary) _then) = __$MusicLibraryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$MusicLibraryCopyWithImpl<$Res>
    implements _$MusicLibraryCopyWith<$Res> {
  __$MusicLibraryCopyWithImpl(this._self, this._then);

  final _MusicLibrary _self;
  final $Res Function(_MusicLibrary) _then;

/// Create a copy of MusicLibrary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_MusicLibrary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ServerAccount {

 String get id; SourceType get type; Uri get baseUrl; String get serverName; String get userId; String get userName; String? get serverId; String? get serverVersion; String? get libraryId;
/// Create a copy of ServerAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerAccountCopyWith<ServerAccount> get copyWith => _$ServerAccountCopyWithImpl<ServerAccount>(this as ServerAccount, _$identity);

  /// Serializes this ServerAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ServerAccount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerAccount&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.serverName, _this.serverName) || other.serverName == _this.serverName)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.userName, _this.userName) || other.userName == _this.userName)&&(identical(other.serverId, _this.serverId) || other.serverId == _this.serverId)&&(identical(other.serverVersion, _this.serverVersion) || other.serverVersion == _this.serverVersion)&&(identical(other.libraryId, _this.libraryId) || other.libraryId == _this.libraryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ServerAccount;
  return Object.hash(runtimeType,_this.id,_this.type,_this.baseUrl,_this.serverName,_this.userId,_this.userName,_this.serverId,_this.serverVersion,_this.libraryId);
}

@override
String toString() {
  final _this = this as ServerAccount;
  return 'ServerAccount(id: ${_this.id}, type: ${_this.type}, baseUrl: ${_this.baseUrl}, serverName: ${_this.serverName}, userId: ${_this.userId}, userName: ${_this.userName}, serverId: ${_this.serverId}, serverVersion: ${_this.serverVersion}, libraryId: ${_this.libraryId})';
}


}

/// @nodoc
abstract mixin class $ServerAccountCopyWith<$Res>  {
  factory $ServerAccountCopyWith(ServerAccount value, $Res Function(ServerAccount) _then) = _$ServerAccountCopyWithImpl;
@useResult
$Res call({
 String id, SourceType type, Uri baseUrl, String serverName, String userId, String userName, String? serverId, String? serverVersion, String? libraryId
});




}
/// @nodoc
class _$ServerAccountCopyWithImpl<$Res>
    implements $ServerAccountCopyWith<$Res> {
  _$ServerAccountCopyWithImpl(this._self, this._then);

  final ServerAccount _self;
  final $Res Function(ServerAccount) _then;

/// Create a copy of ServerAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? baseUrl = null,Object? serverName = null,Object? userId = null,Object? userName = null,Object? serverId = freezed,Object? serverVersion = freezed,Object? libraryId = freezed,}) {
  return _then(ServerAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as Uri,serverName: null == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,libraryId: freezed == libraryId ? _self.libraryId : libraryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerAccount].
extension ServerAccountPatterns on ServerAccount {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerAccount() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerAccount value)  $default,){
final _that = this;
switch (_that) {
case _ServerAccount():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerAccount value)?  $default,){
final _that = this;
switch (_that) {
case _ServerAccount() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SourceType type,  Uri baseUrl,  String serverName,  String userId,  String userName,  String? serverId,  String? serverVersion,  String? libraryId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerAccount() when $default != null:
return $default(_that.id,_that.type,_that.baseUrl,_that.serverName,_that.userId,_that.userName,_that.serverId,_that.serverVersion,_that.libraryId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SourceType type,  Uri baseUrl,  String serverName,  String userId,  String userName,  String? serverId,  String? serverVersion,  String? libraryId)  $default,) {final _that = this;
switch (_that) {
case _ServerAccount():
return $default(_that.id,_that.type,_that.baseUrl,_that.serverName,_that.userId,_that.userName,_that.serverId,_that.serverVersion,_that.libraryId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SourceType type,  Uri baseUrl,  String serverName,  String userId,  String userName,  String? serverId,  String? serverVersion,  String? libraryId)?  $default,) {final _that = this;
switch (_that) {
case _ServerAccount() when $default != null:
return $default(_that.id,_that.type,_that.baseUrl,_that.serverName,_that.userId,_that.userName,_that.serverId,_that.serverVersion,_that.libraryId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerAccount implements ServerAccount {
  const _ServerAccount({required this.id, required this.type, required this.baseUrl, required this.serverName, required this.userId, required this.userName, this.serverId, this.serverVersion, this.libraryId});
  factory _ServerAccount.fromJson(Map<String, dynamic> json) => _$ServerAccountFromJson(json);

@override final  String id;
@override final  SourceType type;
@override final  Uri baseUrl;
@override final  String serverName;
@override final  String userId;
@override final  String userName;
@override final  String? serverId;
@override final  String? serverVersion;
@override final  String? libraryId;

/// Create a copy of ServerAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerAccountCopyWith<_ServerAccount> get copyWith => __$ServerAccountCopyWithImpl<_ServerAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServerAccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.libraryId, libraryId) || other.libraryId == libraryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,baseUrl,serverName,userId,userName,serverId,serverVersion,libraryId);
}

@override
String toString() {
    return 'ServerAccount(id: $id, type: $type, baseUrl: $baseUrl, serverName: $serverName, userId: $userId, userName: $userName, serverId: $serverId, serverVersion: $serverVersion, libraryId: $libraryId)';
}


}

/// @nodoc
abstract mixin class _$ServerAccountCopyWith<$Res> implements $ServerAccountCopyWith<$Res> {
  factory _$ServerAccountCopyWith(_ServerAccount value, $Res Function(_ServerAccount) _then) = __$ServerAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, SourceType type, Uri baseUrl, String serverName, String userId, String userName, String? serverId, String? serverVersion, String? libraryId
});




}
/// @nodoc
class __$ServerAccountCopyWithImpl<$Res>
    implements _$ServerAccountCopyWith<$Res> {
  __$ServerAccountCopyWithImpl(this._self, this._then);

  final _ServerAccount _self;
  final $Res Function(_ServerAccount) _then;

/// Create a copy of ServerAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? baseUrl = null,Object? serverName = null,Object? userId = null,Object? userName = null,Object? serverId = freezed,Object? serverVersion = freezed,Object? libraryId = freezed,}) {
  return _then(_ServerAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as Uri,serverName: null == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,libraryId: freezed == libraryId ? _self.libraryId : libraryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AuthSession {

 ServerAccount get account; String get accessToken;
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSessionCopyWith<AuthSession> get copyWith => _$AuthSessionCopyWithImpl<AuthSession>(this as AuthSession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSession&&(identical(other.account, _this.account) || other.account == _this.account)&&(identical(other.accessToken, _this.accessToken) || other.accessToken == _this.accessToken));
}


@override
int get hashCode {
  final _this = this as AuthSession;
  return Object.hash(runtimeType,_this.account,_this.accessToken);
}

@override
String toString() {
  final _this = this as AuthSession;
  return 'AuthSession(account: ${_this.account}, accessToken: ${_this.accessToken})';
}


}

/// @nodoc
abstract mixin class $AuthSessionCopyWith<$Res>  {
  factory $AuthSessionCopyWith(AuthSession value, $Res Function(AuthSession) _then) = _$AuthSessionCopyWithImpl;
@useResult
$Res call({
 ServerAccount account, String accessToken
});


$ServerAccountCopyWith<$Res> get account;

}
/// @nodoc
class _$AuthSessionCopyWithImpl<$Res>
    implements $AuthSessionCopyWith<$Res> {
  _$AuthSessionCopyWithImpl(this._self, this._then);

  final AuthSession _self;
  final $Res Function(AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? account = null,Object? accessToken = null,}) {
  return _then(AuthSession(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as ServerAccount,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServerAccountCopyWith<$Res> get account {
  
  return $ServerAccountCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthSession].
extension AuthSessionPatterns on AuthSession {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthSession value)  $default,){
final _that = this;
switch (_that) {
case _AuthSession():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthSession value)?  $default,){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ServerAccount account,  String accessToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.account,_that.accessToken);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ServerAccount account,  String accessToken)  $default,) {final _that = this;
switch (_that) {
case _AuthSession():
return $default(_that.account,_that.accessToken);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ServerAccount account,  String accessToken)?  $default,) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.account,_that.accessToken);case _:
  return null;

}
}

}

/// @nodoc


class _AuthSession implements AuthSession {
  const _AuthSession({required this.account, required this.accessToken});
  

@override final  ServerAccount account;
@override final  String accessToken;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthSessionCopyWith<_AuthSession> get copyWith => __$AuthSessionCopyWithImpl<_AuthSession>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthSession&&(identical(other.account, account) || other.account == account)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken));
}


@override
int get hashCode {
    return Object.hash(runtimeType,account,accessToken);
}

@override
String toString() {
    return 'AuthSession(account: $account, accessToken: $accessToken)';
}


}

/// @nodoc
abstract mixin class _$AuthSessionCopyWith<$Res> implements $AuthSessionCopyWith<$Res> {
  factory _$AuthSessionCopyWith(_AuthSession value, $Res Function(_AuthSession) _then) = __$AuthSessionCopyWithImpl;
@override @useResult
$Res call({
 ServerAccount account, String accessToken
});


@override $ServerAccountCopyWith<$Res> get account;

}
/// @nodoc
class __$AuthSessionCopyWithImpl<$Res>
    implements _$AuthSessionCopyWith<$Res> {
  __$AuthSessionCopyWithImpl(this._self, this._then);

  final _AuthSession _self;
  final $Res Function(_AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? account = null,Object? accessToken = null,}) {
  return _then(_AuthSession(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as ServerAccount,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServerAccountCopyWith<$Res> get account {
  
  return $ServerAccountCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}

/// @nodoc
mixin _$QuickConnectRequest {

 String get code; String get secret;
/// Create a copy of QuickConnectRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickConnectRequestCopyWith<QuickConnectRequest> get copyWith => _$QuickConnectRequestCopyWithImpl<QuickConnectRequest>(this as QuickConnectRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as QuickConnectRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickConnectRequest&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.secret, _this.secret) || other.secret == _this.secret));
}


@override
int get hashCode {
  final _this = this as QuickConnectRequest;
  return Object.hash(runtimeType,_this.code,_this.secret);
}

@override
String toString() {
  final _this = this as QuickConnectRequest;
  return 'QuickConnectRequest(code: ${_this.code}, secret: ${_this.secret})';
}


}

/// @nodoc
abstract mixin class $QuickConnectRequestCopyWith<$Res>  {
  factory $QuickConnectRequestCopyWith(QuickConnectRequest value, $Res Function(QuickConnectRequest) _then) = _$QuickConnectRequestCopyWithImpl;
@useResult
$Res call({
 String code, String secret
});




}
/// @nodoc
class _$QuickConnectRequestCopyWithImpl<$Res>
    implements $QuickConnectRequestCopyWith<$Res> {
  _$QuickConnectRequestCopyWithImpl(this._self, this._then);

  final QuickConnectRequest _self;
  final $Res Function(QuickConnectRequest) _then;

/// Create a copy of QuickConnectRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? secret = null,}) {
  return _then(QuickConnectRequest(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QuickConnectRequest].
extension QuickConnectRequestPatterns on QuickConnectRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickConnectRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickConnectRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickConnectRequest value)  $default,){
final _that = this;
switch (_that) {
case _QuickConnectRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickConnectRequest value)?  $default,){
final _that = this;
switch (_that) {
case _QuickConnectRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String secret)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickConnectRequest() when $default != null:
return $default(_that.code,_that.secret);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String secret)  $default,) {final _that = this;
switch (_that) {
case _QuickConnectRequest():
return $default(_that.code,_that.secret);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String secret)?  $default,) {final _that = this;
switch (_that) {
case _QuickConnectRequest() when $default != null:
return $default(_that.code,_that.secret);case _:
  return null;

}
}

}

/// @nodoc


class _QuickConnectRequest implements QuickConnectRequest {
  const _QuickConnectRequest({required this.code, required this.secret});
  

@override final  String code;
@override final  String secret;

/// Create a copy of QuickConnectRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuickConnectRequestCopyWith<_QuickConnectRequest> get copyWith => __$QuickConnectRequestCopyWithImpl<_QuickConnectRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickConnectRequest&&(identical(other.code, code) || other.code == code)&&(identical(other.secret, secret) || other.secret == secret));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,secret);
}

@override
String toString() {
    return 'QuickConnectRequest(code: $code, secret: $secret)';
}


}

/// @nodoc
abstract mixin class _$QuickConnectRequestCopyWith<$Res> implements $QuickConnectRequestCopyWith<$Res> {
  factory _$QuickConnectRequestCopyWith(_QuickConnectRequest value, $Res Function(_QuickConnectRequest) _then) = __$QuickConnectRequestCopyWithImpl;
@override @useResult
$Res call({
 String code, String secret
});




}
/// @nodoc
class __$QuickConnectRequestCopyWithImpl<$Res>
    implements _$QuickConnectRequestCopyWith<$Res> {
  __$QuickConnectRequestCopyWithImpl(this._self, this._then);

  final _QuickConnectRequest _self;
  final $Res Function(_QuickConnectRequest) _then;

/// Create a copy of QuickConnectRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? secret = null,}) {
  return _then(_QuickConnectRequest(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
