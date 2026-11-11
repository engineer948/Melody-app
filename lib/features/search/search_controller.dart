import 'dart:async';

import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/data/repositories/library_repository.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_controller.g.dart';

/// What the search tab currently shows.
@immutable
class SearchState {
  /// Creates a [SearchState].
  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.result,
    this.failure,
  });

  /// Trimmed text being searched.
  final String query;

  /// Whether a request is pending.
  final bool isLoading;

  /// Latest results, possibly from the cache.
  final Loaded<SearchResult>? result;

  /// Why the latest request failed.
  final Failure? failure;
}

/// Runs searches as the user types, waiting for a short pause first.
@riverpod
class SearchQueryController extends _$SearchQueryController {
  /// Pause after the last keystroke before searching.
  static const debounce = Duration(milliseconds: 300);

  Timer? _timer;
  int _generation = 0;

  @override
  SearchState build() {
    ref
      ..watch(libraryRepositoryProvider)
      ..onDispose(() => _timer?.cancel());
    return const SearchState();
  }

  /// Updates the query; an empty one clears the results.
  void setQuery(String text) {
    final query = text.trim();
    if (query == state.query) return;
    _timer?.cancel();
    _generation++;
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }
    state = SearchState(query: query, isLoading: true, result: state.result);
    final generation = _generation;
    _timer = Timer(debounce, () => _run(query, generation));
  }

  /// Repeats the current search.
  void retry() {
    final query = state.query;
    if (query.isEmpty) return;
    state = SearchState(query: query, isLoading: true);
    unawaited(_run(query, ++_generation));
  }

  Future<void> _run(String query, int generation) async {
    final repository = ref.read(libraryRepositoryProvider);
    final result = repository == null
        ? const Err<Loaded<SearchResult>>(UnauthorizedFailure())
        : await repository.search(query);
    if (!ref.mounted || generation != _generation) return;
    state = switch (result) {
      Ok(:final value) => SearchState(query: query, result: value),
      Err(:final failure) => SearchState(query: query, failure: failure),
    };
  }
}

/// Queries the user submitted recently, newest first.
@riverpod
class RecentSearches extends _$RecentSearches {
  /// Preference key of the history.
  static const key = 'search.recent';

  /// Maximum number of remembered queries.
  static const maxEntries = 10;

  @override
  List<String> build() =>
      ref.watch(preferencesProvider).getStringList(key) ?? const [];

  /// Puts [query] at the top of the history.
  Future<void> add(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;
    state = [
      text,
      for (final old in state)
        if (old.toLowerCase() != text.toLowerCase()) old,
    ].take(maxEntries).toList();
    await ref.read(preferencesProvider).setStringList(key, state);
  }

  /// Forgets all queries.
  Future<void> clear() async {
    state = const [];
    await ref.read(preferencesProvider).remove(key);
  }
}
