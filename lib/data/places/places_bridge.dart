import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:melody/domain/stats/play_event.dart';

/// A photo of the phone's gallery.
typedef GalleryPhoto = ({int id, DateTime taken});

/// The phone's rough location, place names and photos for "soundtrack of
/// your life"; replaced by a fake in tests. Nothing is sent anywhere.
abstract interface class PlacesBridge {
  /// Whether this platform can do it at all.
  bool get supported;

  /// Whether rough location may be read.
  Future<bool> hasLocation();

  /// Asks for rough location; `true` when allowed.
  Future<bool> requestLocation();

  /// The latest rough location, or `null`.
  Future<({double latitude, double longitude})?> location();

  /// Name of the place at the coordinates, or `null` (no geocoder).
  Future<String?> placeName(double latitude, double longitude, String language);

  /// Whether photos may be read.
  Future<bool> hasPhotos();

  /// Asks for the photos; `true` when allowed (even partly).
  Future<bool> requestPhotos();

  /// Photos taken in [from, to), newest first.
  Future<List<GalleryPhoto>> photos(DateTime from, DateTime to, {int limit});

  /// A small JPEG of photo [id].
  Future<Uint8List?> thumbnail(int id, {int size});
}

/// [PlacesBridge] over the `melody/places` channel (Android).
class ChannelPlacesBridge implements PlacesBridge {
  /// Creates the bridge.
  const ChannelPlacesBridge();

  static const _channel = MethodChannel('melody/places');

  @override
  bool get supported => !kIsWeb && Platform.isAndroid;

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> hasLocation() async => await _call<bool>('hasLocation') ?? false;

  @override
  Future<bool> requestLocation() async =>
      await _call<bool>('requestLocation') ?? false;

  @override
  Future<({double latitude, double longitude})?> location() async {
    final map = await _call<Map<Object?, Object?>>('location');
    final lat = map?['latitude'];
    final lon = map?['longitude'];
    if (lat is! num || lon is! num) return null;
    return (latitude: lat.toDouble(), longitude: lon.toDouble());
  }

  @override
  Future<String?> placeName(
    double latitude,
    double longitude,
    String language,
  ) => _call<String>('placeName', {
    'latitude': latitude,
    'longitude': longitude,
    'language': language,
  });

  @override
  Future<bool> hasPhotos() async => await _call<bool>('hasPhotos') ?? false;

  @override
  Future<bool> requestPhotos() async =>
      await _call<bool>('requestPhotos') ?? false;

  @override
  Future<List<GalleryPhoto>> photos(
    DateTime from,
    DateTime to, {
    int limit = 12,
  }) async {
    final rows = await _call<List<Object?>>('photos', {
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
      'limit': limit,
    });
    return [
      for (final row in rows ?? const <Object?>[])
        if (row case {'id': final num id, 'taken': final num taken})
          (
            id: id.toInt(),
            taken: DateTime.fromMillisecondsSinceEpoch(taken.toInt()),
          ),
    ];
  }

  @override
  Future<Uint8List?> thumbnail(int id, {int size = 256}) =>
      _call<Uint8List>('thumbnail', {'id': id, 'size': size});
}

/// Finds where the phone is, with place names cached per ~1 km square.
class PlaceLocator {
  /// Creates a locator on [bridge].
  PlaceLocator(this.bridge);

  /// Platform side.
  final PlacesBridge bridge;

  final _names = <String, String?>{};

  /// The rough place now, or `null` (not allowed, no fix, too slow).
  Future<PlayPlace?> current(String language) async {
    if (!await bridge.hasLocation()) return null;
    final here = await bridge.location();
    if (here == null) return null;
    final rough = PlayPlace(latitude: here.latitude, longitude: here.longitude);
    final key = '${rough.latitude},${rough.longitude},$language';
    if (!_names.containsKey(key)) {
      try {
        _names[key] = await bridge
            .placeName(rough.latitude, rough.longitude, language)
            .timeout(const Duration(seconds: 5));
      } on Object {
        return rough; // Asked again next time.
      }
    }
    return PlayPlace(
      latitude: rough.latitude,
      longitude: rough.longitude,
      name: _names[key],
    );
  }
}
