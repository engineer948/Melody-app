// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Statistics of the active account for [period].

@ProviderFor(listeningStats)
final listeningStatsProvider = ListeningStatsFamily._();

/// Statistics of the active account for [period].

final class ListeningStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ListeningStats>,
          ListeningStats,
          FutureOr<ListeningStats>
        >
    with $FutureModifier<ListeningStats>, $FutureProvider<ListeningStats> {
  /// Statistics of the active account for [period].
  ListeningStatsProvider._({
    required ListeningStatsFamily super.from,
    required StatsPeriod super.argument,
  }) : super(
         retry: null,
         name: r'listeningStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listeningStatsHash();

  @override
  String toString() {
    return r'listeningStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ListeningStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ListeningStats> create(Ref ref) {
    final argument = this.argument as StatsPeriod;
    return listeningStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListeningStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listeningStatsHash() => r'466e6e8c3e0cd9915ed8a5eadda755ae58d23863';

/// Statistics of the active account for [period].

final class ListeningStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ListeningStats>, StatsPeriod> {
  ListeningStatsFamily._()
    : super(
        retry: null,
        name: r'listeningStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Statistics of the active account for [period].

  ListeningStatsProvider call(StatsPeriod period) =>
      ListeningStatsProvider._(argument: period, from: this);

  @override
  String toString() => r'listeningStatsProvider';
}

/// Statistics of one calendar [year], for the year in review.

@ProviderFor(yearStats)
final yearStatsProvider = YearStatsFamily._();

/// Statistics of one calendar [year], for the year in review.

final class YearStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ListeningStats>,
          ListeningStats,
          FutureOr<ListeningStats>
        >
    with $FutureModifier<ListeningStats>, $FutureProvider<ListeningStats> {
  /// Statistics of one calendar [year], for the year in review.
  YearStatsProvider._({
    required YearStatsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'yearStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$yearStatsHash();

  @override
  String toString() {
    return r'yearStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ListeningStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ListeningStats> create(Ref ref) {
    final argument = this.argument as int;
    return yearStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is YearStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$yearStatsHash() => r'020931be847799e6c06f428109afb4f78442220f';

/// Statistics of one calendar [year], for the year in review.

final class YearStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ListeningStats>, int> {
  YearStatsFamily._()
    : super(
        retry: null,
        name: r'yearStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Statistics of one calendar [year], for the year in review.

  YearStatsProvider call(int year) =>
      YearStatsProvider._(argument: year, from: this);

  @override
  String toString() => r'yearStatsProvider';
}

/// Suggestions for the active account, computed on the device from the
/// listening history and the cached library. Empty while turned off or
/// before anything was played.

@ProviderFor(suggestions)
final suggestionsProvider = SuggestionsProvider._();

/// Suggestions for the active account, computed on the device from the
/// listening history and the cached library. Empty while turned off or
/// before anything was played.

final class SuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Suggestions>,
          Suggestions,
          FutureOr<Suggestions>
        >
    with $FutureModifier<Suggestions>, $FutureProvider<Suggestions> {
  /// Suggestions for the active account, computed on the device from the
  /// listening history and the cached library. Empty while turned off or
  /// before anything was played.
  SuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suggestionsHash();

  @$internal
  @override
  $FutureProviderElement<Suggestions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Suggestions> create(Ref ref) {
    return suggestions(ref);
  }
}

String _$suggestionsHash() => r'571c679ad670e159536545ff5c1227a8e38d0bd7';
