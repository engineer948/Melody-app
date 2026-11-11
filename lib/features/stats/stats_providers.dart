import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/data/repositories/catalog_cache.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/recommendation/recommender.dart';
import 'package:melody/domain/stats/listening_stats.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/listening_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stats_providers.g.dart';

/// Time span of the statistics screen.
enum StatsPeriod {
  /// The last four weeks.
  month,

  /// The last six months.
  halfYear,

  /// The current calendar year.
  year,

  /// Everything recorded.
  all,
}

/// Formats a listening time as minutes, or hours and minutes.
String formatListened(AppLocalizations l10n, Duration time) {
  final minutes = time.inMinutes;
  return minutes < 60
      ? l10n.minutesValue(minutes)
      : l10n.hoursMinutesValue(minutes ~/ 60, minutes % 60);
}

/// Statistics of the active account for [period].
@riverpod
Future<ListeningStats> listeningStats(Ref ref, StatsPeriod period) async {
  ref.watch(historyRevisionProvider);
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  if (accountId == null) return const ListeningStats();
  final now = DateTime.now();
  final from = switch (period) {
    StatsPeriod.month => now.subtract(const Duration(days: 28)),
    StatsPeriod.halfYear => DateTime(now.year, now.month - 6, now.day),
    StatsPeriod.year => DateTime(now.year),
    StatsPeriod.all => null,
  };
  final events = await ref
      .watch(historyStoreProvider)
      .events(accountId, from: from);
  return ListeningStats.of(events, now: now);
}

/// Statistics of one calendar [year], for the year in review.
@riverpod
Future<ListeningStats> yearStats(Ref ref, int year) async {
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  if (accountId == null) return const ListeningStats();
  final events = await ref
      .watch(historyStoreProvider)
      .events(accountId, from: DateTime(year), to: DateTime(year + 1));
  return ListeningStats.of(events, now: DateTime.now(), top: 5);
}

/// Automatic lists shown on the home tab.
typedef Suggestions = ({
  List<Track> mix,
  List<Track> forgotten,
  List<Track> discover,
});

const Suggestions _noSuggestions = (mix: [], forgotten: [], discover: []);

/// Suggestions for the active account, computed on the device from the
/// listening history and the cached library. Empty while turned off or
/// before anything was played.
@riverpod
Future<Suggestions> suggestions(Ref ref) async {
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  final enabled = ref.watch(
    listeningSettingsControllerProvider.select((s) => s.suggestions),
  );
  if (accountId == null || !enabled) return _noSuggestions;
  final events = await ref.watch(historyStoreProvider).events(accountId);
  final recommender = Recommender(events, now: DateTime.now());
  if (!recommender.hasHistory) return _noSuggestions;
  final cached = await ref
      .watch(catalogCacheProvider)
      .sample(accountId, CacheKind.track, limit: 600);
  final pool = [...recommender.knownTracks, ...cached];
  return (
    mix: recommender.mix(pool),
    forgotten: recommender.forgotten(cached),
    discover: recommender.discover(cached),
  );
}
