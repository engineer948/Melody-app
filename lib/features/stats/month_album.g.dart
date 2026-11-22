// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_album.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The album of the month starting at [month] (its first day).

@ProviderFor(monthAlbum)
final monthAlbumProvider = MonthAlbumFamily._();

/// The album of the month starting at [month] (its first day).

final class MonthAlbumProvider
    extends
        $FunctionalProvider<
          AsyncValue<MonthAlbum?>,
          MonthAlbum?,
          FutureOr<MonthAlbum?>
        >
    with $FutureModifier<MonthAlbum?>, $FutureProvider<MonthAlbum?> {
  /// The album of the month starting at [month] (its first day).
  MonthAlbumProvider._({
    required MonthAlbumFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'monthAlbumProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthAlbumHash();

  @override
  String toString() {
    return r'monthAlbumProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MonthAlbum?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MonthAlbum?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return monthAlbum(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthAlbumProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthAlbumHash() => r'0040883fd50134868728ed160f983c52d3e77efb';

/// The album of the month starting at [month] (its first day).

final class MonthAlbumFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MonthAlbum?>, DateTime> {
  MonthAlbumFamily._()
    : super(
        retry: null,
        name: r'monthAlbumProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The album of the month starting at [month] (its first day).

  MonthAlbumProvider call(DateTime month) =>
      MonthAlbumProvider._(argument: month, from: this);

  @override
  String toString() => r'monthAlbumProvider';
}
