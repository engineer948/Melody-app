// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Artwork {

 String get itemId; String? get tag; String? get blurHash;
/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtworkCopyWith<Artwork> get copyWith => _$ArtworkCopyWithImpl<Artwork>(this as Artwork, _$identity);

  /// Serializes this Artwork to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Artwork;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Artwork&&(identical(other.itemId, _this.itemId) || other.itemId == _this.itemId)&&(identical(other.tag, _this.tag) || other.tag == _this.tag)&&(identical(other.blurHash, _this.blurHash) || other.blurHash == _this.blurHash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Artwork;
  return Object.hash(runtimeType,_this.itemId,_this.tag,_this.blurHash);
}

@override
String toString() {
  final _this = this as Artwork;
  return 'Artwork(itemId: ${_this.itemId}, tag: ${_this.tag}, blurHash: ${_this.blurHash})';
}


}

/// @nodoc
abstract mixin class $ArtworkCopyWith<$Res>  {
  factory $ArtworkCopyWith(Artwork value, $Res Function(Artwork) _then) = _$ArtworkCopyWithImpl;
@useResult
$Res call({
 String itemId, String? tag, String? blurHash
});




}
/// @nodoc
class _$ArtworkCopyWithImpl<$Res>
    implements $ArtworkCopyWith<$Res> {
  _$ArtworkCopyWithImpl(this._self, this._then);

  final Artwork _self;
  final $Res Function(Artwork) _then;

/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? tag = freezed,Object? blurHash = freezed,}) {
  return _then(Artwork(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String?,blurHash: freezed == blurHash ? _self.blurHash : blurHash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Artwork].
extension ArtworkPatterns on Artwork {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Artwork value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Artwork() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Artwork value)  $default,){
final _that = this;
switch (_that) {
case _Artwork():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Artwork value)?  $default,){
final _that = this;
switch (_that) {
case _Artwork() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String? tag,  String? blurHash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Artwork() when $default != null:
return $default(_that.itemId,_that.tag,_that.blurHash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String? tag,  String? blurHash)  $default,) {final _that = this;
switch (_that) {
case _Artwork():
return $default(_that.itemId,_that.tag,_that.blurHash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String? tag,  String? blurHash)?  $default,) {final _that = this;
switch (_that) {
case _Artwork() when $default != null:
return $default(_that.itemId,_that.tag,_that.blurHash);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Artwork implements Artwork {
  const _Artwork({required this.itemId, this.tag, this.blurHash});
  factory _Artwork.fromJson(Map<String, dynamic> json) => _$ArtworkFromJson(json);

@override final  String itemId;
@override final  String? tag;
@override final  String? blurHash;

/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtworkCopyWith<_Artwork> get copyWith => __$ArtworkCopyWithImpl<_Artwork>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtworkToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Artwork&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.blurHash, blurHash) || other.blurHash == blurHash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,itemId,tag,blurHash);
}

@override
String toString() {
    return 'Artwork(itemId: $itemId, tag: $tag, blurHash: $blurHash)';
}


}

/// @nodoc
abstract mixin class _$ArtworkCopyWith<$Res> implements $ArtworkCopyWith<$Res> {
  factory _$ArtworkCopyWith(_Artwork value, $Res Function(_Artwork) _then) = __$ArtworkCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String? tag, String? blurHash
});




}
/// @nodoc
class __$ArtworkCopyWithImpl<$Res>
    implements _$ArtworkCopyWith<$Res> {
  __$ArtworkCopyWithImpl(this._self, this._then);

  final _Artwork _self;
  final $Res Function(_Artwork) _then;

/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? tag = freezed,Object? blurHash = freezed,}) {
  return _then(_Artwork(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String?,blurHash: freezed == blurHash ? _self.blurHash : blurHash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$NamedRef {

 String get id; String get name;
/// Create a copy of NamedRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NamedRefCopyWith<NamedRef> get copyWith => _$NamedRefCopyWithImpl<NamedRef>(this as NamedRef, _$identity);

  /// Serializes this NamedRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NamedRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NamedRef&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NamedRef;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as NamedRef;
  return 'NamedRef(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $NamedRefCopyWith<$Res>  {
  factory $NamedRefCopyWith(NamedRef value, $Res Function(NamedRef) _then) = _$NamedRefCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$NamedRefCopyWithImpl<$Res>
    implements $NamedRefCopyWith<$Res> {
  _$NamedRefCopyWithImpl(this._self, this._then);

  final NamedRef _self;
  final $Res Function(NamedRef) _then;

/// Create a copy of NamedRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(NamedRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NamedRef].
extension NamedRefPatterns on NamedRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NamedRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NamedRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NamedRef value)  $default,){
final _that = this;
switch (_that) {
case _NamedRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NamedRef value)?  $default,){
final _that = this;
switch (_that) {
case _NamedRef() when $default != null:
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
case _NamedRef() when $default != null:
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
case _NamedRef():
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
case _NamedRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NamedRef implements NamedRef {
  const _NamedRef({required this.id, required this.name});
  factory _NamedRef.fromJson(Map<String, dynamic> json) => _$NamedRefFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of NamedRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NamedRefCopyWith<_NamedRef> get copyWith => __$NamedRefCopyWithImpl<_NamedRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NamedRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NamedRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'NamedRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$NamedRefCopyWith<$Res> implements $NamedRefCopyWith<$Res> {
  factory _$NamedRefCopyWith(_NamedRef value, $Res Function(_NamedRef) _then) = __$NamedRefCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$NamedRefCopyWithImpl<$Res>
    implements _$NamedRefCopyWith<$Res> {
  __$NamedRefCopyWithImpl(this._self, this._then);

  final _NamedRef _self;
  final $Res Function(_NamedRef) _then;

/// Create a copy of NamedRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_NamedRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Track {

 String get id; String get title; List<NamedRef> get artists; String? get albumId; String? get albumTitle; String? get albumArtist; Duration? get duration; int? get trackNumber; int? get discNumber; int? get year; Artwork? get artwork; String? get container; bool get isFavorite; int get playCount; List<String> get genres;/// ReplayGain-style track gain in dB, when the source knows it.
 double? get trackGainDb;/// Gain of the whole album in dB, when known.
 double? get albumGainDb;/// Id of this entry inside a playlist (needed to remove or move it).
 String? get playlistItemId;
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackCopyWith<Track> get copyWith => _$TrackCopyWithImpl<Track>(this as Track, _$identity);

  /// Serializes this Track to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Track;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Track&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.artists, _this.artists)&&(identical(other.albumId, _this.albumId) || other.albumId == _this.albumId)&&(identical(other.albumTitle, _this.albumTitle) || other.albumTitle == _this.albumTitle)&&(identical(other.albumArtist, _this.albumArtist) || other.albumArtist == _this.albumArtist)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.trackNumber, _this.trackNumber) || other.trackNumber == _this.trackNumber)&&(identical(other.discNumber, _this.discNumber) || other.discNumber == _this.discNumber)&&(identical(other.year, _this.year) || other.year == _this.year)&&(identical(other.artwork, _this.artwork) || other.artwork == _this.artwork)&&(identical(other.container, _this.container) || other.container == _this.container)&&(identical(other.isFavorite, _this.isFavorite) || other.isFavorite == _this.isFavorite)&&(identical(other.playCount, _this.playCount) || other.playCount == _this.playCount)&&const DeepCollectionEquality().equals(other.genres, _this.genres)&&(identical(other.trackGainDb, _this.trackGainDb) || other.trackGainDb == _this.trackGainDb)&&(identical(other.albumGainDb, _this.albumGainDb) || other.albumGainDb == _this.albumGainDb)&&(identical(other.playlistItemId, _this.playlistItemId) || other.playlistItemId == _this.playlistItemId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Track;
  return Object.hash(runtimeType,_this.id,_this.title,const DeepCollectionEquality().hash(_this.artists),_this.albumId,_this.albumTitle,_this.albumArtist,_this.duration,_this.trackNumber,_this.discNumber,_this.year,_this.artwork,_this.container,_this.isFavorite,_this.playCount,const DeepCollectionEquality().hash(_this.genres),_this.trackGainDb,_this.albumGainDb,_this.playlistItemId);
}

@override
String toString() {
  final _this = this as Track;
  return 'Track(id: ${_this.id}, title: ${_this.title}, artists: ${_this.artists}, albumId: ${_this.albumId}, albumTitle: ${_this.albumTitle}, albumArtist: ${_this.albumArtist}, duration: ${_this.duration}, trackNumber: ${_this.trackNumber}, discNumber: ${_this.discNumber}, year: ${_this.year}, artwork: ${_this.artwork}, container: ${_this.container}, isFavorite: ${_this.isFavorite}, playCount: ${_this.playCount}, genres: ${_this.genres}, trackGainDb: ${_this.trackGainDb}, albumGainDb: ${_this.albumGainDb}, playlistItemId: ${_this.playlistItemId})';
}


}

/// @nodoc
abstract mixin class $TrackCopyWith<$Res>  {
  factory $TrackCopyWith(Track value, $Res Function(Track) _then) = _$TrackCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<NamedRef> artists, String? albumId, String? albumTitle, String? albumArtist, Duration? duration, int? trackNumber, int? discNumber, int? year, Artwork? artwork, String? container, bool isFavorite, int playCount, List<String> genres, double? trackGainDb, double? albumGainDb, String? playlistItemId
});


$ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class _$TrackCopyWithImpl<$Res>
    implements $TrackCopyWith<$Res> {
  _$TrackCopyWithImpl(this._self, this._then);

  final Track _self;
  final $Res Function(Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? artists = null,Object? albumId = freezed,Object? albumTitle = freezed,Object? albumArtist = freezed,Object? duration = freezed,Object? trackNumber = freezed,Object? discNumber = freezed,Object? year = freezed,Object? artwork = freezed,Object? container = freezed,Object? isFavorite = null,Object? playCount = null,Object? genres = null,Object? trackGainDb = freezed,Object? albumGainDb = freezed,Object? playlistItemId = freezed,}) {
  return _then(Track(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<NamedRef>,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,albumTitle: freezed == albumTitle ? _self.albumTitle : albumTitle // ignore: cast_nullable_to_non_nullable
as String?,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,discNumber: freezed == discNumber ? _self.discNumber : discNumber // ignore: cast_nullable_to_non_nullable
as int?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,container: freezed == container ? _self.container : container // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,trackGainDb: freezed == trackGainDb ? _self.trackGainDb : trackGainDb // ignore: cast_nullable_to_non_nullable
as double?,albumGainDb: freezed == albumGainDb ? _self.albumGainDb : albumGainDb // ignore: cast_nullable_to_non_nullable
as double?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// Adds pattern-matching-related methods to [Track].
extension TrackPatterns on Track {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Track value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Track value)  $default,){
final _that = this;
switch (_that) {
case _Track():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Track value)?  $default,){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<NamedRef> artists,  String? albumId,  String? albumTitle,  String? albumArtist,  Duration? duration,  int? trackNumber,  int? discNumber,  int? year,  Artwork? artwork,  String? container,  bool isFavorite,  int playCount,  List<String> genres,  double? trackGainDb,  double? albumGainDb,  String? playlistItemId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.id,_that.title,_that.artists,_that.albumId,_that.albumTitle,_that.albumArtist,_that.duration,_that.trackNumber,_that.discNumber,_that.year,_that.artwork,_that.container,_that.isFavorite,_that.playCount,_that.genres,_that.trackGainDb,_that.albumGainDb,_that.playlistItemId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<NamedRef> artists,  String? albumId,  String? albumTitle,  String? albumArtist,  Duration? duration,  int? trackNumber,  int? discNumber,  int? year,  Artwork? artwork,  String? container,  bool isFavorite,  int playCount,  List<String> genres,  double? trackGainDb,  double? albumGainDb,  String? playlistItemId)  $default,) {final _that = this;
switch (_that) {
case _Track():
return $default(_that.id,_that.title,_that.artists,_that.albumId,_that.albumTitle,_that.albumArtist,_that.duration,_that.trackNumber,_that.discNumber,_that.year,_that.artwork,_that.container,_that.isFavorite,_that.playCount,_that.genres,_that.trackGainDb,_that.albumGainDb,_that.playlistItemId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<NamedRef> artists,  String? albumId,  String? albumTitle,  String? albumArtist,  Duration? duration,  int? trackNumber,  int? discNumber,  int? year,  Artwork? artwork,  String? container,  bool isFavorite,  int playCount,  List<String> genres,  double? trackGainDb,  double? albumGainDb,  String? playlistItemId)?  $default,) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.id,_that.title,_that.artists,_that.albumId,_that.albumTitle,_that.albumArtist,_that.duration,_that.trackNumber,_that.discNumber,_that.year,_that.artwork,_that.container,_that.isFavorite,_that.playCount,_that.genres,_that.trackGainDb,_that.albumGainDb,_that.playlistItemId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Track extends Track {
  const _Track({required this.id, required this.title,  List<NamedRef> artists = const <NamedRef>[], this.albumId, this.albumTitle, this.albumArtist, this.duration, this.trackNumber, this.discNumber, this.year, this.artwork, this.container, this.isFavorite = false, this.playCount = 0,  List<String> genres = const <String>[], this.trackGainDb, this.albumGainDb, this.playlistItemId}): _artists = artists,_genres = genres,super._();
  factory _Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

@override final  String id;
@override final  String title;
 final  List<NamedRef> _artists;
@override@JsonKey() List<NamedRef> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

@override final  String? albumId;
@override final  String? albumTitle;
@override final  String? albumArtist;
@override final  Duration? duration;
@override final  int? trackNumber;
@override final  int? discNumber;
@override final  int? year;
@override final  Artwork? artwork;
@override final  String? container;
@override@JsonKey() final  bool isFavorite;
@override@JsonKey() final  int playCount;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

/// ReplayGain-style track gain in dB, when the source knows it.
@override final  double? trackGainDb;
/// Gain of the whole album in dB, when known.
@override final  double? albumGainDb;
/// Id of this entry inside a playlist (needed to remove or move it).
@override final  String? playlistItemId;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackCopyWith<_Track> get copyWith => __$TrackCopyWithImpl<_Track>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Track&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.artists, _artists)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.albumTitle, albumTitle) || other.albumTitle == albumTitle)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.trackNumber, trackNumber) || other.trackNumber == trackNumber)&&(identical(other.discNumber, discNumber) || other.discNumber == discNumber)&&(identical(other.year, year) || other.year == year)&&(identical(other.artwork, artwork) || other.artwork == artwork)&&(identical(other.container, container) || other.container == container)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&const DeepCollectionEquality().equals(other.genres, _genres)&&(identical(other.trackGainDb, trackGainDb) || other.trackGainDb == trackGainDb)&&(identical(other.albumGainDb, albumGainDb) || other.albumGainDb == albumGainDb)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_artists),albumId,albumTitle,albumArtist,duration,trackNumber,discNumber,year,artwork,container,isFavorite,playCount,const DeepCollectionEquality().hash(_genres),trackGainDb,albumGainDb,playlistItemId);
}

@override
String toString() {
    return 'Track(id: $id, title: $title, artists: $artists, albumId: $albumId, albumTitle: $albumTitle, albumArtist: $albumArtist, duration: $duration, trackNumber: $trackNumber, discNumber: $discNumber, year: $year, artwork: $artwork, container: $container, isFavorite: $isFavorite, playCount: $playCount, genres: $genres, trackGainDb: $trackGainDb, albumGainDb: $albumGainDb, playlistItemId: $playlistItemId)';
}


}

/// @nodoc
abstract mixin class _$TrackCopyWith<$Res> implements $TrackCopyWith<$Res> {
  factory _$TrackCopyWith(_Track value, $Res Function(_Track) _then) = __$TrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<NamedRef> artists, String? albumId, String? albumTitle, String? albumArtist, Duration? duration, int? trackNumber, int? discNumber, int? year, Artwork? artwork, String? container, bool isFavorite, int playCount, List<String> genres, double? trackGainDb, double? albumGainDb, String? playlistItemId
});


@override $ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class __$TrackCopyWithImpl<$Res>
    implements _$TrackCopyWith<$Res> {
  __$TrackCopyWithImpl(this._self, this._then);

  final _Track _self;
  final $Res Function(_Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? artists = null,Object? albumId = freezed,Object? albumTitle = freezed,Object? albumArtist = freezed,Object? duration = freezed,Object? trackNumber = freezed,Object? discNumber = freezed,Object? year = freezed,Object? artwork = freezed,Object? container = freezed,Object? isFavorite = null,Object? playCount = null,Object? genres = null,Object? trackGainDb = freezed,Object? albumGainDb = freezed,Object? playlistItemId = freezed,}) {
  return _then(_Track(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artists: null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<NamedRef>,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,albumTitle: freezed == albumTitle ? _self.albumTitle : albumTitle // ignore: cast_nullable_to_non_nullable
as String?,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,discNumber: freezed == discNumber ? _self.discNumber : discNumber // ignore: cast_nullable_to_non_nullable
as int?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,container: freezed == container ? _self.container : container // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,trackGainDb: freezed == trackGainDb ? _self.trackGainDb : trackGainDb // ignore: cast_nullable_to_non_nullable
as double?,albumGainDb: freezed == albumGainDb ? _self.albumGainDb : albumGainDb // ignore: cast_nullable_to_non_nullable
as double?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// @nodoc
mixin _$Album {

 String get id; String get title; List<NamedRef> get artists; String? get artistName; int? get year; int? get trackCount; Duration? get duration; Artwork? get artwork; DateTime? get dateAdded; List<String> get genres; bool get isFavorite;/// Album gain in dB, when the source knows it.
 double? get gainDb;
/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumCopyWith<Album> get copyWith => _$AlbumCopyWithImpl<Album>(this as Album, _$identity);

  /// Serializes this Album to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Album;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Album&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.artists, _this.artists)&&(identical(other.artistName, _this.artistName) || other.artistName == _this.artistName)&&(identical(other.year, _this.year) || other.year == _this.year)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.artwork, _this.artwork) || other.artwork == _this.artwork)&&(identical(other.dateAdded, _this.dateAdded) || other.dateAdded == _this.dateAdded)&&const DeepCollectionEquality().equals(other.genres, _this.genres)&&(identical(other.isFavorite, _this.isFavorite) || other.isFavorite == _this.isFavorite)&&(identical(other.gainDb, _this.gainDb) || other.gainDb == _this.gainDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Album;
  return Object.hash(runtimeType,_this.id,_this.title,const DeepCollectionEquality().hash(_this.artists),_this.artistName,_this.year,_this.trackCount,_this.duration,_this.artwork,_this.dateAdded,const DeepCollectionEquality().hash(_this.genres),_this.isFavorite,_this.gainDb);
}

@override
String toString() {
  final _this = this as Album;
  return 'Album(id: ${_this.id}, title: ${_this.title}, artists: ${_this.artists}, artistName: ${_this.artistName}, year: ${_this.year}, trackCount: ${_this.trackCount}, duration: ${_this.duration}, artwork: ${_this.artwork}, dateAdded: ${_this.dateAdded}, genres: ${_this.genres}, isFavorite: ${_this.isFavorite}, gainDb: ${_this.gainDb})';
}


}

/// @nodoc
abstract mixin class $AlbumCopyWith<$Res>  {
  factory $AlbumCopyWith(Album value, $Res Function(Album) _then) = _$AlbumCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<NamedRef> artists, String? artistName, int? year, int? trackCount, Duration? duration, Artwork? artwork, DateTime? dateAdded, List<String> genres, bool isFavorite, double? gainDb
});


$ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class _$AlbumCopyWithImpl<$Res>
    implements $AlbumCopyWith<$Res> {
  _$AlbumCopyWithImpl(this._self, this._then);

  final Album _self;
  final $Res Function(Album) _then;

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? artists = null,Object? artistName = freezed,Object? year = freezed,Object? trackCount = freezed,Object? duration = freezed,Object? artwork = freezed,Object? dateAdded = freezed,Object? genres = null,Object? isFavorite = null,Object? gainDb = freezed,}) {
  return _then(Album(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<NamedRef>,artistName: freezed == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,trackCount: freezed == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,dateAdded: freezed == dateAdded ? _self.dateAdded : dateAdded // ignore: cast_nullable_to_non_nullable
as DateTime?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,gainDb: freezed == gainDb ? _self.gainDb : gainDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// Adds pattern-matching-related methods to [Album].
extension AlbumPatterns on Album {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Album value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Album() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Album value)  $default,){
final _that = this;
switch (_that) {
case _Album():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Album value)?  $default,){
final _that = this;
switch (_that) {
case _Album() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<NamedRef> artists,  String? artistName,  int? year,  int? trackCount,  Duration? duration,  Artwork? artwork,  DateTime? dateAdded,  List<String> genres,  bool isFavorite,  double? gainDb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Album() when $default != null:
return $default(_that.id,_that.title,_that.artists,_that.artistName,_that.year,_that.trackCount,_that.duration,_that.artwork,_that.dateAdded,_that.genres,_that.isFavorite,_that.gainDb);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<NamedRef> artists,  String? artistName,  int? year,  int? trackCount,  Duration? duration,  Artwork? artwork,  DateTime? dateAdded,  List<String> genres,  bool isFavorite,  double? gainDb)  $default,) {final _that = this;
switch (_that) {
case _Album():
return $default(_that.id,_that.title,_that.artists,_that.artistName,_that.year,_that.trackCount,_that.duration,_that.artwork,_that.dateAdded,_that.genres,_that.isFavorite,_that.gainDb);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<NamedRef> artists,  String? artistName,  int? year,  int? trackCount,  Duration? duration,  Artwork? artwork,  DateTime? dateAdded,  List<String> genres,  bool isFavorite,  double? gainDb)?  $default,) {final _that = this;
switch (_that) {
case _Album() when $default != null:
return $default(_that.id,_that.title,_that.artists,_that.artistName,_that.year,_that.trackCount,_that.duration,_that.artwork,_that.dateAdded,_that.genres,_that.isFavorite,_that.gainDb);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Album extends Album {
  const _Album({required this.id, required this.title,  List<NamedRef> artists = const <NamedRef>[], this.artistName, this.year, this.trackCount, this.duration, this.artwork, this.dateAdded,  List<String> genres = const <String>[], this.isFavorite = false, this.gainDb}): _artists = artists,_genres = genres,super._();
  factory _Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);

@override final  String id;
@override final  String title;
 final  List<NamedRef> _artists;
@override@JsonKey() List<NamedRef> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

@override final  String? artistName;
@override final  int? year;
@override final  int? trackCount;
@override final  Duration? duration;
@override final  Artwork? artwork;
@override final  DateTime? dateAdded;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override@JsonKey() final  bool isFavorite;
/// Album gain in dB, when the source knows it.
@override final  double? gainDb;

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumCopyWith<_Album> get copyWith => __$AlbumCopyWithImpl<_Album>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlbumToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Album&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.artists, _artists)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.year, year) || other.year == year)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.artwork, artwork) || other.artwork == artwork)&&(identical(other.dateAdded, dateAdded) || other.dateAdded == dateAdded)&&const DeepCollectionEquality().equals(other.genres, _genres)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.gainDb, gainDb) || other.gainDb == gainDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_artists),artistName,year,trackCount,duration,artwork,dateAdded,const DeepCollectionEquality().hash(_genres),isFavorite,gainDb);
}

@override
String toString() {
    return 'Album(id: $id, title: $title, artists: $artists, artistName: $artistName, year: $year, trackCount: $trackCount, duration: $duration, artwork: $artwork, dateAdded: $dateAdded, genres: $genres, isFavorite: $isFavorite, gainDb: $gainDb)';
}


}

/// @nodoc
abstract mixin class _$AlbumCopyWith<$Res> implements $AlbumCopyWith<$Res> {
  factory _$AlbumCopyWith(_Album value, $Res Function(_Album) _then) = __$AlbumCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<NamedRef> artists, String? artistName, int? year, int? trackCount, Duration? duration, Artwork? artwork, DateTime? dateAdded, List<String> genres, bool isFavorite, double? gainDb
});


@override $ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class __$AlbumCopyWithImpl<$Res>
    implements _$AlbumCopyWith<$Res> {
  __$AlbumCopyWithImpl(this._self, this._then);

  final _Album _self;
  final $Res Function(_Album) _then;

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? artists = null,Object? artistName = freezed,Object? year = freezed,Object? trackCount = freezed,Object? duration = freezed,Object? artwork = freezed,Object? dateAdded = freezed,Object? genres = null,Object? isFavorite = null,Object? gainDb = freezed,}) {
  return _then(_Album(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artists: null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<NamedRef>,artistName: freezed == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,trackCount: freezed == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,dateAdded: freezed == dateAdded ? _self.dateAdded : dateAdded // ignore: cast_nullable_to_non_nullable
as DateTime?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,gainDb: freezed == gainDb ? _self.gainDb : gainDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// @nodoc
mixin _$Artist {

 String get id; String get name; Artwork? get artwork; String? get overview; bool get isFavorite;
/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistCopyWith<Artist> get copyWith => _$ArtistCopyWithImpl<Artist>(this as Artist, _$identity);

  /// Serializes this Artist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Artist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Artist&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.artwork, _this.artwork) || other.artwork == _this.artwork)&&(identical(other.overview, _this.overview) || other.overview == _this.overview)&&(identical(other.isFavorite, _this.isFavorite) || other.isFavorite == _this.isFavorite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Artist;
  return Object.hash(runtimeType,_this.id,_this.name,_this.artwork,_this.overview,_this.isFavorite);
}

@override
String toString() {
  final _this = this as Artist;
  return 'Artist(id: ${_this.id}, name: ${_this.name}, artwork: ${_this.artwork}, overview: ${_this.overview}, isFavorite: ${_this.isFavorite})';
}


}

/// @nodoc
abstract mixin class $ArtistCopyWith<$Res>  {
  factory $ArtistCopyWith(Artist value, $Res Function(Artist) _then) = _$ArtistCopyWithImpl;
@useResult
$Res call({
 String id, String name, Artwork? artwork, String? overview, bool isFavorite
});


$ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class _$ArtistCopyWithImpl<$Res>
    implements $ArtistCopyWith<$Res> {
  _$ArtistCopyWithImpl(this._self, this._then);

  final Artist _self;
  final $Res Function(Artist) _then;

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? artwork = freezed,Object? overview = freezed,Object? isFavorite = null,}) {
  return _then(Artist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// Adds pattern-matching-related methods to [Artist].
extension ArtistPatterns on Artist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Artist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Artist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Artist value)  $default,){
final _that = this;
switch (_that) {
case _Artist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Artist value)?  $default,){
final _that = this;
switch (_that) {
case _Artist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Artwork? artwork,  String? overview,  bool isFavorite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Artist() when $default != null:
return $default(_that.id,_that.name,_that.artwork,_that.overview,_that.isFavorite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Artwork? artwork,  String? overview,  bool isFavorite)  $default,) {final _that = this;
switch (_that) {
case _Artist():
return $default(_that.id,_that.name,_that.artwork,_that.overview,_that.isFavorite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Artwork? artwork,  String? overview,  bool isFavorite)?  $default,) {final _that = this;
switch (_that) {
case _Artist() when $default != null:
return $default(_that.id,_that.name,_that.artwork,_that.overview,_that.isFavorite);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Artist implements Artist {
  const _Artist({required this.id, required this.name, this.artwork, this.overview, this.isFavorite = false});
  factory _Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);

@override final  String id;
@override final  String name;
@override final  Artwork? artwork;
@override final  String? overview;
@override@JsonKey() final  bool isFavorite;

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistCopyWith<_Artist> get copyWith => __$ArtistCopyWithImpl<_Artist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Artist&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.artwork, artwork) || other.artwork == artwork)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,artwork,overview,isFavorite);
}

@override
String toString() {
    return 'Artist(id: $id, name: $name, artwork: $artwork, overview: $overview, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$ArtistCopyWith<$Res> implements $ArtistCopyWith<$Res> {
  factory _$ArtistCopyWith(_Artist value, $Res Function(_Artist) _then) = __$ArtistCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Artwork? artwork, String? overview, bool isFavorite
});


@override $ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class __$ArtistCopyWithImpl<$Res>
    implements _$ArtistCopyWith<$Res> {
  __$ArtistCopyWithImpl(this._self, this._then);

  final _Artist _self;
  final $Res Function(_Artist) _then;

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? artwork = freezed,Object? overview = freezed,Object? isFavorite = null,}) {
  return _then(_Artist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// @nodoc
mixin _$ArtistDetail {

 Artist get artist; List<Album> get albums; List<Track> get topTracks;
/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistDetailCopyWith<ArtistDetail> get copyWith => _$ArtistDetailCopyWithImpl<ArtistDetail>(this as ArtistDetail, _$identity);

  /// Serializes this ArtistDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ArtistDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistDetail&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&const DeepCollectionEquality().equals(other.albums, _this.albums)&&const DeepCollectionEquality().equals(other.topTracks, _this.topTracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ArtistDetail;
  return Object.hash(runtimeType,_this.artist,const DeepCollectionEquality().hash(_this.albums),const DeepCollectionEquality().hash(_this.topTracks));
}

@override
String toString() {
  final _this = this as ArtistDetail;
  return 'ArtistDetail(artist: ${_this.artist}, albums: ${_this.albums}, topTracks: ${_this.topTracks})';
}


}

/// @nodoc
abstract mixin class $ArtistDetailCopyWith<$Res>  {
  factory $ArtistDetailCopyWith(ArtistDetail value, $Res Function(ArtistDetail) _then) = _$ArtistDetailCopyWithImpl;
@useResult
$Res call({
 Artist artist, List<Album> albums, List<Track> topTracks
});


$ArtistCopyWith<$Res> get artist;

}
/// @nodoc
class _$ArtistDetailCopyWithImpl<$Res>
    implements $ArtistDetailCopyWith<$Res> {
  _$ArtistDetailCopyWithImpl(this._self, this._then);

  final ArtistDetail _self;
  final $Res Function(ArtistDetail) _then;

/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artist = null,Object? albums = null,Object? topTracks = null,}) {
  return _then(ArtistDetail(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as Artist,albums: null == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,topTracks: null == topTracks ? _self.topTracks : topTracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}
/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistCopyWith<$Res> get artist {
  
  return $ArtistCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArtistDetail].
extension ArtistDetailPatterns on ArtistDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistDetail value)  $default,){
final _that = this;
switch (_that) {
case _ArtistDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Artist artist,  List<Album> albums,  List<Track> topTracks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistDetail() when $default != null:
return $default(_that.artist,_that.albums,_that.topTracks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Artist artist,  List<Album> albums,  List<Track> topTracks)  $default,) {final _that = this;
switch (_that) {
case _ArtistDetail():
return $default(_that.artist,_that.albums,_that.topTracks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Artist artist,  List<Album> albums,  List<Track> topTracks)?  $default,) {final _that = this;
switch (_that) {
case _ArtistDetail() when $default != null:
return $default(_that.artist,_that.albums,_that.topTracks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistDetail implements ArtistDetail {
  const _ArtistDetail({required this.artist,  List<Album> albums = const <Album>[],  List<Track> topTracks = const <Track>[]}): _albums = albums,_topTracks = topTracks;
  factory _ArtistDetail.fromJson(Map<String, dynamic> json) => _$ArtistDetailFromJson(json);

@override final  Artist artist;
 final  List<Album> _albums;
@override@JsonKey() List<Album> get albums {
  if (_albums is EqualUnmodifiableListView) return _albums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albums);
}

 final  List<Track> _topTracks;
@override@JsonKey() List<Track> get topTracks {
  if (_topTracks is EqualUnmodifiableListView) return _topTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topTracks);
}


/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistDetailCopyWith<_ArtistDetail> get copyWith => __$ArtistDetailCopyWithImpl<_ArtistDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistDetail&&(identical(other.artist, artist) || other.artist == artist)&&const DeepCollectionEquality().equals(other.albums, _albums)&&const DeepCollectionEquality().equals(other.topTracks, _topTracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,artist,const DeepCollectionEquality().hash(_albums),const DeepCollectionEquality().hash(_topTracks));
}

@override
String toString() {
    return 'ArtistDetail(artist: $artist, albums: $albums, topTracks: $topTracks)';
}


}

/// @nodoc
abstract mixin class _$ArtistDetailCopyWith<$Res> implements $ArtistDetailCopyWith<$Res> {
  factory _$ArtistDetailCopyWith(_ArtistDetail value, $Res Function(_ArtistDetail) _then) = __$ArtistDetailCopyWithImpl;
@override @useResult
$Res call({
 Artist artist, List<Album> albums, List<Track> topTracks
});


@override $ArtistCopyWith<$Res> get artist;

}
/// @nodoc
class __$ArtistDetailCopyWithImpl<$Res>
    implements _$ArtistDetailCopyWith<$Res> {
  __$ArtistDetailCopyWithImpl(this._self, this._then);

  final _ArtistDetail _self;
  final $Res Function(_ArtistDetail) _then;

/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artist = null,Object? albums = null,Object? topTracks = null,}) {
  return _then(_ArtistDetail(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as Artist,albums: null == albums ? _self._albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,topTracks: null == topTracks ? _self._topTracks : topTracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}

/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistCopyWith<$Res> get artist {
  
  return $ArtistCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}


/// @nodoc
mixin _$AlbumDetail {

 Album get album; List<Track> get tracks;
/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumDetailCopyWith<AlbumDetail> get copyWith => _$AlbumDetailCopyWithImpl<AlbumDetail>(this as AlbumDetail, _$identity);

  /// Serializes this AlbumDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AlbumDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumDetail&&(identical(other.album, _this.album) || other.album == _this.album)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AlbumDetail;
  return Object.hash(runtimeType,_this.album,const DeepCollectionEquality().hash(_this.tracks));
}

@override
String toString() {
  final _this = this as AlbumDetail;
  return 'AlbumDetail(album: ${_this.album}, tracks: ${_this.tracks})';
}


}

/// @nodoc
abstract mixin class $AlbumDetailCopyWith<$Res>  {
  factory $AlbumDetailCopyWith(AlbumDetail value, $Res Function(AlbumDetail) _then) = _$AlbumDetailCopyWithImpl;
@useResult
$Res call({
 Album album, List<Track> tracks
});


$AlbumCopyWith<$Res> get album;

}
/// @nodoc
class _$AlbumDetailCopyWithImpl<$Res>
    implements $AlbumDetailCopyWith<$Res> {
  _$AlbumDetailCopyWithImpl(this._self, this._then);

  final AlbumDetail _self;
  final $Res Function(AlbumDetail) _then;

/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = null,Object? tracks = null,}) {
  return _then(AlbumDetail(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as Album,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}
/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlbumCopyWith<$Res> get album {
  
  return $AlbumCopyWith<$Res>(_self.album, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}


/// Adds pattern-matching-related methods to [AlbumDetail].
extension AlbumDetailPatterns on AlbumDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlbumDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlbumDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlbumDetail value)  $default,){
final _that = this;
switch (_that) {
case _AlbumDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlbumDetail value)?  $default,){
final _that = this;
switch (_that) {
case _AlbumDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Album album,  List<Track> tracks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlbumDetail() when $default != null:
return $default(_that.album,_that.tracks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Album album,  List<Track> tracks)  $default,) {final _that = this;
switch (_that) {
case _AlbumDetail():
return $default(_that.album,_that.tracks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Album album,  List<Track> tracks)?  $default,) {final _that = this;
switch (_that) {
case _AlbumDetail() when $default != null:
return $default(_that.album,_that.tracks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AlbumDetail implements AlbumDetail {
  const _AlbumDetail({required this.album,  List<Track> tracks = const <Track>[]}): _tracks = tracks;
  factory _AlbumDetail.fromJson(Map<String, dynamic> json) => _$AlbumDetailFromJson(json);

@override final  Album album;
 final  List<Track> _tracks;
@override@JsonKey() List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}


/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumDetailCopyWith<_AlbumDetail> get copyWith => __$AlbumDetailCopyWithImpl<_AlbumDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlbumDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlbumDetail&&(identical(other.album, album) || other.album == album)&&const DeepCollectionEquality().equals(other.tracks, _tracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,album,const DeepCollectionEquality().hash(_tracks));
}

@override
String toString() {
    return 'AlbumDetail(album: $album, tracks: $tracks)';
}


}

/// @nodoc
abstract mixin class _$AlbumDetailCopyWith<$Res> implements $AlbumDetailCopyWith<$Res> {
  factory _$AlbumDetailCopyWith(_AlbumDetail value, $Res Function(_AlbumDetail) _then) = __$AlbumDetailCopyWithImpl;
@override @useResult
$Res call({
 Album album, List<Track> tracks
});


@override $AlbumCopyWith<$Res> get album;

}
/// @nodoc
class __$AlbumDetailCopyWithImpl<$Res>
    implements _$AlbumDetailCopyWith<$Res> {
  __$AlbumDetailCopyWithImpl(this._self, this._then);

  final _AlbumDetail _self;
  final $Res Function(_AlbumDetail) _then;

/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? album = null,Object? tracks = null,}) {
  return _then(_AlbumDetail(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as Album,tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}

/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlbumCopyWith<$Res> get album {
  
  return $AlbumCopyWith<$Res>(_self.album, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}


/// @nodoc
mixin _$Playlist {

 String get id; String get name; int? get trackCount; Duration? get duration; Artwork? get artwork;
/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistCopyWith<Playlist> get copyWith => _$PlaylistCopyWithImpl<Playlist>(this as Playlist, _$identity);

  /// Serializes this Playlist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Playlist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Playlist&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.artwork, _this.artwork) || other.artwork == _this.artwork));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Playlist;
  return Object.hash(runtimeType,_this.id,_this.name,_this.trackCount,_this.duration,_this.artwork);
}

@override
String toString() {
  final _this = this as Playlist;
  return 'Playlist(id: ${_this.id}, name: ${_this.name}, trackCount: ${_this.trackCount}, duration: ${_this.duration}, artwork: ${_this.artwork})';
}


}

/// @nodoc
abstract mixin class $PlaylistCopyWith<$Res>  {
  factory $PlaylistCopyWith(Playlist value, $Res Function(Playlist) _then) = _$PlaylistCopyWithImpl;
@useResult
$Res call({
 String id, String name, int? trackCount, Duration? duration, Artwork? artwork
});


$ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class _$PlaylistCopyWithImpl<$Res>
    implements $PlaylistCopyWith<$Res> {
  _$PlaylistCopyWithImpl(this._self, this._then);

  final Playlist _self;
  final $Res Function(Playlist) _then;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? trackCount = freezed,Object? duration = freezed,Object? artwork = freezed,}) {
  return _then(Playlist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: freezed == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,
  ));
}
/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// Adds pattern-matching-related methods to [Playlist].
extension PlaylistPatterns on Playlist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Playlist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Playlist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Playlist value)  $default,){
final _that = this;
switch (_that) {
case _Playlist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Playlist value)?  $default,){
final _that = this;
switch (_that) {
case _Playlist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int? trackCount,  Duration? duration,  Artwork? artwork)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Playlist() when $default != null:
return $default(_that.id,_that.name,_that.trackCount,_that.duration,_that.artwork);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int? trackCount,  Duration? duration,  Artwork? artwork)  $default,) {final _that = this;
switch (_that) {
case _Playlist():
return $default(_that.id,_that.name,_that.trackCount,_that.duration,_that.artwork);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int? trackCount,  Duration? duration,  Artwork? artwork)?  $default,) {final _that = this;
switch (_that) {
case _Playlist() when $default != null:
return $default(_that.id,_that.name,_that.trackCount,_that.duration,_that.artwork);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Playlist implements Playlist {
  const _Playlist({required this.id, required this.name, this.trackCount, this.duration, this.artwork});
  factory _Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);

@override final  String id;
@override final  String name;
@override final  int? trackCount;
@override final  Duration? duration;
@override final  Artwork? artwork;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistCopyWith<_Playlist> get copyWith => __$PlaylistCopyWithImpl<_Playlist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Playlist&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.artwork, artwork) || other.artwork == artwork));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,trackCount,duration,artwork);
}

@override
String toString() {
    return 'Playlist(id: $id, name: $name, trackCount: $trackCount, duration: $duration, artwork: $artwork)';
}


}

/// @nodoc
abstract mixin class _$PlaylistCopyWith<$Res> implements $PlaylistCopyWith<$Res> {
  factory _$PlaylistCopyWith(_Playlist value, $Res Function(_Playlist) _then) = __$PlaylistCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int? trackCount, Duration? duration, Artwork? artwork
});


@override $ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class __$PlaylistCopyWithImpl<$Res>
    implements _$PlaylistCopyWith<$Res> {
  __$PlaylistCopyWithImpl(this._self, this._then);

  final _Playlist _self;
  final $Res Function(_Playlist) _then;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? trackCount = freezed,Object? duration = freezed,Object? artwork = freezed,}) {
  return _then(_Playlist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: freezed == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,
  ));
}

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// @nodoc
mixin _$Genre {

 String get id; String get name; Artwork? get artwork;
/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenreCopyWith<Genre> get copyWith => _$GenreCopyWithImpl<Genre>(this as Genre, _$identity);

  /// Serializes this Genre to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Genre;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Genre&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.artwork, _this.artwork) || other.artwork == _this.artwork));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Genre;
  return Object.hash(runtimeType,_this.id,_this.name,_this.artwork);
}

@override
String toString() {
  final _this = this as Genre;
  return 'Genre(id: ${_this.id}, name: ${_this.name}, artwork: ${_this.artwork})';
}


}

/// @nodoc
abstract mixin class $GenreCopyWith<$Res>  {
  factory $GenreCopyWith(Genre value, $Res Function(Genre) _then) = _$GenreCopyWithImpl;
@useResult
$Res call({
 String id, String name, Artwork? artwork
});


$ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class _$GenreCopyWithImpl<$Res>
    implements $GenreCopyWith<$Res> {
  _$GenreCopyWithImpl(this._self, this._then);

  final Genre _self;
  final $Res Function(Genre) _then;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? artwork = freezed,}) {
  return _then(Genre(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,
  ));
}
/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// Adds pattern-matching-related methods to [Genre].
extension GenrePatterns on Genre {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Genre value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Genre() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Genre value)  $default,){
final _that = this;
switch (_that) {
case _Genre():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Genre value)?  $default,){
final _that = this;
switch (_that) {
case _Genre() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Artwork? artwork)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Genre() when $default != null:
return $default(_that.id,_that.name,_that.artwork);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Artwork? artwork)  $default,) {final _that = this;
switch (_that) {
case _Genre():
return $default(_that.id,_that.name,_that.artwork);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Artwork? artwork)?  $default,) {final _that = this;
switch (_that) {
case _Genre() when $default != null:
return $default(_that.id,_that.name,_that.artwork);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Genre implements Genre {
  const _Genre({required this.id, required this.name, this.artwork});
  factory _Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);

@override final  String id;
@override final  String name;
@override final  Artwork? artwork;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenreCopyWith<_Genre> get copyWith => __$GenreCopyWithImpl<_Genre>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenreToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Genre&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.artwork, artwork) || other.artwork == artwork));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,artwork);
}

@override
String toString() {
    return 'Genre(id: $id, name: $name, artwork: $artwork)';
}


}

/// @nodoc
abstract mixin class _$GenreCopyWith<$Res> implements $GenreCopyWith<$Res> {
  factory _$GenreCopyWith(_Genre value, $Res Function(_Genre) _then) = __$GenreCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Artwork? artwork
});


@override $ArtworkCopyWith<$Res>? get artwork;

}
/// @nodoc
class __$GenreCopyWithImpl<$Res>
    implements _$GenreCopyWith<$Res> {
  __$GenreCopyWithImpl(this._self, this._then);

  final _Genre _self;
  final $Res Function(_Genre) _then;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? artwork = freezed,}) {
  return _then(_Genre(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork?,
  ));
}

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $ArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}

/// @nodoc
mixin _$SearchResult {

 List<Artist> get artists; List<Album> get albums; List<Track> get tracks; List<Playlist> get playlists;
/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultCopyWith<SearchResult> get copyWith => _$SearchResultCopyWithImpl<SearchResult>(this as SearchResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResult&&const DeepCollectionEquality().equals(other.artists, _this.artists)&&const DeepCollectionEquality().equals(other.albums, _this.albums)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&const DeepCollectionEquality().equals(other.playlists, _this.playlists));
}


@override
int get hashCode {
  final _this = this as SearchResult;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.artists),const DeepCollectionEquality().hash(_this.albums),const DeepCollectionEquality().hash(_this.tracks),const DeepCollectionEquality().hash(_this.playlists));
}

@override
String toString() {
  final _this = this as SearchResult;
  return 'SearchResult(artists: ${_this.artists}, albums: ${_this.albums}, tracks: ${_this.tracks}, playlists: ${_this.playlists})';
}


}

/// @nodoc
abstract mixin class $SearchResultCopyWith<$Res>  {
  factory $SearchResultCopyWith(SearchResult value, $Res Function(SearchResult) _then) = _$SearchResultCopyWithImpl;
@useResult
$Res call({
 List<Artist> artists, List<Album> albums, List<Track> tracks, List<Playlist> playlists
});




}
/// @nodoc
class _$SearchResultCopyWithImpl<$Res>
    implements $SearchResultCopyWith<$Res> {
  _$SearchResultCopyWithImpl(this._self, this._then);

  final SearchResult _self;
  final $Res Function(SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artists = null,Object? albums = null,Object? tracks = null,Object? playlists = null,}) {
  return _then(SearchResult(
artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<Artist>,albums: null == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,playlists: null == playlists ? _self.playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResult].
extension SearchResultPatterns on SearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResult value)  $default,){
final _that = this;
switch (_that) {
case _SearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Artist> artists,  List<Album> albums,  List<Track> tracks,  List<Playlist> playlists)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.artists,_that.albums,_that.tracks,_that.playlists);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Artist> artists,  List<Album> albums,  List<Track> tracks,  List<Playlist> playlists)  $default,) {final _that = this;
switch (_that) {
case _SearchResult():
return $default(_that.artists,_that.albums,_that.tracks,_that.playlists);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Artist> artists,  List<Album> albums,  List<Track> tracks,  List<Playlist> playlists)?  $default,) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.artists,_that.albums,_that.tracks,_that.playlists);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResult extends SearchResult {
  const _SearchResult({ List<Artist> artists = const <Artist>[],  List<Album> albums = const <Album>[],  List<Track> tracks = const <Track>[],  List<Playlist> playlists = const <Playlist>[]}): _artists = artists,_albums = albums,_tracks = tracks,_playlists = playlists,super._();
  

 final  List<Artist> _artists;
@override@JsonKey() List<Artist> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

 final  List<Album> _albums;
@override@JsonKey() List<Album> get albums {
  if (_albums is EqualUnmodifiableListView) return _albums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albums);
}

 final  List<Track> _tracks;
@override@JsonKey() List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}

 final  List<Playlist> _playlists;
@override@JsonKey() List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultCopyWith<_SearchResult> get copyWith => __$SearchResultCopyWithImpl<_SearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResult&&const DeepCollectionEquality().equals(other.artists, _artists)&&const DeepCollectionEquality().equals(other.albums, _albums)&&const DeepCollectionEquality().equals(other.tracks, _tracks)&&const DeepCollectionEquality().equals(other.playlists, _playlists));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_artists),const DeepCollectionEquality().hash(_albums),const DeepCollectionEquality().hash(_tracks),const DeepCollectionEquality().hash(_playlists));
}

@override
String toString() {
    return 'SearchResult(artists: $artists, albums: $albums, tracks: $tracks, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class _$SearchResultCopyWith<$Res> implements $SearchResultCopyWith<$Res> {
  factory _$SearchResultCopyWith(_SearchResult value, $Res Function(_SearchResult) _then) = __$SearchResultCopyWithImpl;
@override @useResult
$Res call({
 List<Artist> artists, List<Album> albums, List<Track> tracks, List<Playlist> playlists
});




}
/// @nodoc
class __$SearchResultCopyWithImpl<$Res>
    implements _$SearchResultCopyWith<$Res> {
  __$SearchResultCopyWithImpl(this._self, this._then);

  final _SearchResult _self;
  final $Res Function(_SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artists = null,Object? albums = null,Object? tracks = null,Object? playlists = null,}) {
  return _then(_SearchResult(
artists: null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<Artist>,albums: null == albums ? _self._albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}


/// @nodoc
mixin _$LyricLine {

 String get text; Duration? get start;
/// Create a copy of LyricLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricLineCopyWith<LyricLine> get copyWith => _$LyricLineCopyWithImpl<LyricLine>(this as LyricLine, _$identity);

  /// Serializes this LyricLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LyricLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricLine&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.start, _this.start) || other.start == _this.start));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LyricLine;
  return Object.hash(runtimeType,_this.text,_this.start);
}

@override
String toString() {
  final _this = this as LyricLine;
  return 'LyricLine(text: ${_this.text}, start: ${_this.start})';
}


}

/// @nodoc
abstract mixin class $LyricLineCopyWith<$Res>  {
  factory $LyricLineCopyWith(LyricLine value, $Res Function(LyricLine) _then) = _$LyricLineCopyWithImpl;
@useResult
$Res call({
 String text, Duration? start
});




}
/// @nodoc
class _$LyricLineCopyWithImpl<$Res>
    implements $LyricLineCopyWith<$Res> {
  _$LyricLineCopyWithImpl(this._self, this._then);

  final LyricLine _self;
  final $Res Function(LyricLine) _then;

/// Create a copy of LyricLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? start = freezed,}) {
  return _then(LyricLine(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [LyricLine].
extension LyricLinePatterns on LyricLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LyricLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LyricLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LyricLine value)  $default,){
final _that = this;
switch (_that) {
case _LyricLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LyricLine value)?  $default,){
final _that = this;
switch (_that) {
case _LyricLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  Duration? start)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LyricLine() when $default != null:
return $default(_that.text,_that.start);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  Duration? start)  $default,) {final _that = this;
switch (_that) {
case _LyricLine():
return $default(_that.text,_that.start);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  Duration? start)?  $default,) {final _that = this;
switch (_that) {
case _LyricLine() when $default != null:
return $default(_that.text,_that.start);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LyricLine implements LyricLine {
  const _LyricLine({required this.text, this.start});
  factory _LyricLine.fromJson(Map<String, dynamic> json) => _$LyricLineFromJson(json);

@override final  String text;
@override final  Duration? start;

/// Create a copy of LyricLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricLineCopyWith<_LyricLine> get copyWith => __$LyricLineCopyWithImpl<_LyricLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LyricLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LyricLine&&(identical(other.text, text) || other.text == text)&&(identical(other.start, start) || other.start == start));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,start);
}

@override
String toString() {
    return 'LyricLine(text: $text, start: $start)';
}


}

/// @nodoc
abstract mixin class _$LyricLineCopyWith<$Res> implements $LyricLineCopyWith<$Res> {
  factory _$LyricLineCopyWith(_LyricLine value, $Res Function(_LyricLine) _then) = __$LyricLineCopyWithImpl;
@override @useResult
$Res call({
 String text, Duration? start
});




}
/// @nodoc
class __$LyricLineCopyWithImpl<$Res>
    implements _$LyricLineCopyWith<$Res> {
  __$LyricLineCopyWithImpl(this._self, this._then);

  final _LyricLine _self;
  final $Res Function(_LyricLine) _then;

/// Create a copy of LyricLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? start = freezed,}) {
  return _then(_LyricLine(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}


/// @nodoc
mixin _$TrackLyrics {

 String get trackId; Lyrics get lyrics;
/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackLyricsCopyWith<TrackLyrics> get copyWith => _$TrackLyricsCopyWithImpl<TrackLyrics>(this as TrackLyrics, _$identity);

  /// Serializes this TrackLyrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TrackLyrics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackLyrics&&(identical(other.trackId, _this.trackId) || other.trackId == _this.trackId)&&(identical(other.lyrics, _this.lyrics) || other.lyrics == _this.lyrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TrackLyrics;
  return Object.hash(runtimeType,_this.trackId,_this.lyrics);
}

@override
String toString() {
  final _this = this as TrackLyrics;
  return 'TrackLyrics(trackId: ${_this.trackId}, lyrics: ${_this.lyrics})';
}


}

/// @nodoc
abstract mixin class $TrackLyricsCopyWith<$Res>  {
  factory $TrackLyricsCopyWith(TrackLyrics value, $Res Function(TrackLyrics) _then) = _$TrackLyricsCopyWithImpl;
@useResult
$Res call({
 String trackId, Lyrics lyrics
});


$LyricsCopyWith<$Res> get lyrics;

}
/// @nodoc
class _$TrackLyricsCopyWithImpl<$Res>
    implements $TrackLyricsCopyWith<$Res> {
  _$TrackLyricsCopyWithImpl(this._self, this._then);

  final TrackLyrics _self;
  final $Res Function(TrackLyrics) _then;

/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trackId = null,Object? lyrics = null,}) {
  return _then(TrackLyrics(
trackId: null == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String,lyrics: null == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as Lyrics,
  ));
}
/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LyricsCopyWith<$Res> get lyrics {
  
  return $LyricsCopyWith<$Res>(_self.lyrics, (value) {
    return _then(_self.copyWith(lyrics: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrackLyrics].
extension TrackLyricsPatterns on TrackLyrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackLyrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackLyrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackLyrics value)  $default,){
final _that = this;
switch (_that) {
case _TrackLyrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackLyrics value)?  $default,){
final _that = this;
switch (_that) {
case _TrackLyrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trackId,  Lyrics lyrics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackLyrics() when $default != null:
return $default(_that.trackId,_that.lyrics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trackId,  Lyrics lyrics)  $default,) {final _that = this;
switch (_that) {
case _TrackLyrics():
return $default(_that.trackId,_that.lyrics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trackId,  Lyrics lyrics)?  $default,) {final _that = this;
switch (_that) {
case _TrackLyrics() when $default != null:
return $default(_that.trackId,_that.lyrics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackLyrics implements TrackLyrics {
  const _TrackLyrics({required this.trackId, required this.lyrics});
  factory _TrackLyrics.fromJson(Map<String, dynamic> json) => _$TrackLyricsFromJson(json);

@override final  String trackId;
@override final  Lyrics lyrics;

/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackLyricsCopyWith<_TrackLyrics> get copyWith => __$TrackLyricsCopyWithImpl<_TrackLyrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackLyricsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackLyrics&&(identical(other.trackId, trackId) || other.trackId == trackId)&&(identical(other.lyrics, lyrics) || other.lyrics == lyrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,trackId,lyrics);
}

@override
String toString() {
    return 'TrackLyrics(trackId: $trackId, lyrics: $lyrics)';
}


}

/// @nodoc
abstract mixin class _$TrackLyricsCopyWith<$Res> implements $TrackLyricsCopyWith<$Res> {
  factory _$TrackLyricsCopyWith(_TrackLyrics value, $Res Function(_TrackLyrics) _then) = __$TrackLyricsCopyWithImpl;
@override @useResult
$Res call({
 String trackId, Lyrics lyrics
});


@override $LyricsCopyWith<$Res> get lyrics;

}
/// @nodoc
class __$TrackLyricsCopyWithImpl<$Res>
    implements _$TrackLyricsCopyWith<$Res> {
  __$TrackLyricsCopyWithImpl(this._self, this._then);

  final _TrackLyrics _self;
  final $Res Function(_TrackLyrics) _then;

/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trackId = null,Object? lyrics = null,}) {
  return _then(_TrackLyrics(
trackId: null == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String,lyrics: null == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as Lyrics,
  ));
}

/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LyricsCopyWith<$Res> get lyrics {
  
  return $LyricsCopyWith<$Res>(_self.lyrics, (value) {
    return _then(_self.copyWith(lyrics: value));
  });
}
}


/// @nodoc
mixin _$Lyrics {

 List<LyricLine> get lines; bool get synced; LyricsOrigin get origin;
/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricsCopyWith<Lyrics> get copyWith => _$LyricsCopyWithImpl<Lyrics>(this as Lyrics, _$identity);

  /// Serializes this Lyrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Lyrics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lyrics&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&(identical(other.synced, _this.synced) || other.synced == _this.synced)&&(identical(other.origin, _this.origin) || other.origin == _this.origin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Lyrics;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.lines),_this.synced,_this.origin);
}

@override
String toString() {
  final _this = this as Lyrics;
  return 'Lyrics(lines: ${_this.lines}, synced: ${_this.synced}, origin: ${_this.origin})';
}


}

/// @nodoc
abstract mixin class $LyricsCopyWith<$Res>  {
  factory $LyricsCopyWith(Lyrics value, $Res Function(Lyrics) _then) = _$LyricsCopyWithImpl;
@useResult
$Res call({
 List<LyricLine> lines, bool synced, LyricsOrigin origin
});




}
/// @nodoc
class _$LyricsCopyWithImpl<$Res>
    implements $LyricsCopyWith<$Res> {
  _$LyricsCopyWithImpl(this._self, this._then);

  final Lyrics _self;
  final $Res Function(Lyrics) _then;

/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lines = null,Object? synced = null,Object? origin = null,}) {
  return _then(Lyrics(
lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<LyricLine>,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LyricsOrigin,
  ));
}

}


/// Adds pattern-matching-related methods to [Lyrics].
extension LyricsPatterns on Lyrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lyrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lyrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lyrics value)  $default,){
final _that = this;
switch (_that) {
case _Lyrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lyrics value)?  $default,){
final _that = this;
switch (_that) {
case _Lyrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LyricLine> lines,  bool synced,  LyricsOrigin origin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lyrics() when $default != null:
return $default(_that.lines,_that.synced,_that.origin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LyricLine> lines,  bool synced,  LyricsOrigin origin)  $default,) {final _that = this;
switch (_that) {
case _Lyrics():
return $default(_that.lines,_that.synced,_that.origin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LyricLine> lines,  bool synced,  LyricsOrigin origin)?  $default,) {final _that = this;
switch (_that) {
case _Lyrics() when $default != null:
return $default(_that.lines,_that.synced,_that.origin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Lyrics extends Lyrics {
  const _Lyrics({ List<LyricLine> lines = const <LyricLine>[], this.synced = false, this.origin = LyricsOrigin.server}): _lines = lines,super._();
  factory _Lyrics.fromJson(Map<String, dynamic> json) => _$LyricsFromJson(json);

 final  List<LyricLine> _lines;
@override@JsonKey() List<LyricLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override@JsonKey() final  bool synced;
@override@JsonKey() final  LyricsOrigin origin;

/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricsCopyWith<_Lyrics> get copyWith => __$LyricsCopyWithImpl<_Lyrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LyricsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lyrics&&const DeepCollectionEquality().equals(other.lines, _lines)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.origin, origin) || other.origin == origin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_lines),synced,origin);
}

@override
String toString() {
    return 'Lyrics(lines: $lines, synced: $synced, origin: $origin)';
}


}

/// @nodoc
abstract mixin class _$LyricsCopyWith<$Res> implements $LyricsCopyWith<$Res> {
  factory _$LyricsCopyWith(_Lyrics value, $Res Function(_Lyrics) _then) = __$LyricsCopyWithImpl;
@override @useResult
$Res call({
 List<LyricLine> lines, bool synced, LyricsOrigin origin
});




}
/// @nodoc
class __$LyricsCopyWithImpl<$Res>
    implements _$LyricsCopyWith<$Res> {
  __$LyricsCopyWithImpl(this._self, this._then);

  final _Lyrics _self;
  final $Res Function(_Lyrics) _then;

/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lines = null,Object? synced = null,Object? origin = null,}) {
  return _then(_Lyrics(
lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<LyricLine>,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LyricsOrigin,
  ));
}


}

// dart format on
