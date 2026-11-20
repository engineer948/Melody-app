import 'dart:typed_data';

import 'package:melody/data/places/places_bridge.dart';

/// In-memory [PlacesBridge]: a fixed place and no photos unless given.
class FakePlacesBridge implements PlacesBridge {
  /// Whether location is allowed; [requestLocation] turns it on.
  bool locationAllowed = false;

  /// Whether [requestLocation] is accepted.
  bool acceptLocation = true;

  /// Where the phone is.
  ({double latitude, double longitude})? here = (
    latitude: 40.37767,
    longitude: 49.89201,
  );

  /// Name answered for any place.
  String? name = 'Sahil, Bakı';

  /// How many names were asked for.
  int nameLookups = 0;

  /// Whether photos are allowed.
  bool photosAllowed = false;

  /// Photos answered for any day.
  List<GalleryPhoto> gallery = const [];

  @override
  bool get supported => true;

  @override
  Future<bool> hasLocation() async => locationAllowed;

  @override
  Future<bool> requestLocation() async =>
      locationAllowed = locationAllowed || acceptLocation;

  @override
  Future<({double latitude, double longitude})?> location() async =>
      locationAllowed ? here : null;

  @override
  Future<String?> placeName(
    double latitude,
    double longitude,
    String language,
  ) async {
    nameLookups++;
    return name;
  }

  @override
  Future<bool> hasPhotos() async => photosAllowed;

  @override
  Future<bool> requestPhotos() async => photosAllowed = true;

  @override
  Future<List<GalleryPhoto>> photos(
    DateTime from,
    DateTime to, {
    int limit = 12,
  }) async => [
    for (final p in gallery)
      if (!p.taken.isBefore(from) && p.taken.isBefore(to)) p,
  ];

  @override
  Future<Uint8List?> thumbnail(int id, {int size = 256}) async => null;
}
