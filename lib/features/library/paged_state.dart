import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/data/repositories/library_repository.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:meta/meta.dart';

/// Items of an endlessly scrolling list plus its loading status.
@immutable
class PagedState<T> {
  /// Creates a [PagedState].
  const PagedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.fromCache = false,
    this.failure,
  });

  /// Items loaded so far.
  final List<T> items;

  /// Whether the first page is still loading.
  final bool isLoading;

  /// Whether a further page is loading.
  final bool isLoadingMore;

  /// Whether more pages may exist.
  final bool hasMore;

  /// Whether [items] is the cached copy.
  final bool fromCache;

  /// Why the last request failed.
  final Failure? failure;

  /// Copy with some fields replaced; [failure] is always replaced.
  PagedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? fromCache,
    Failure? failure,
  }) => PagedState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    fromCache: fromCache ?? this.fromCache,
    failure: failure,
  );
}

/// Shared paging logic of the list controllers.
mixin PagedLoader<T> {
  /// Current state, provided by the notifier.
  PagedState<T> get state;
  set state(PagedState<T> value);

  /// Provider ref, provided by the notifier.
  Ref get ref;

  /// Number of items per request.
  int get pageSize;

  /// Cached then fresh first page.
  Stream<Loaded<List<T>>> firstPage(LibraryRepository repository);

  /// Page starting at [offset].
  Future<Result<List<T>>> nextPage(LibraryRepository repository, int offset);

  /// Starts loading; call from `build`.
  PagedState<T> start() {
    final repository = ref.watch(libraryRepositoryProvider);
    if (repository == null) {
      return const PagedState(failure: UnauthorizedFailure());
    }
    final subscription = firstPage(repository).listen(
      (loaded) => state = PagedState(
        items: loaded.value,
        fromCache: loaded.fromCache,
        isLoading: loaded.fromCache && loaded.refreshFailure == null,
        hasMore: !loaded.fromCache && loaded.value.length >= pageSize,
        failure: loaded.refreshFailure,
      ),
      onError: (Object error) => state = PagedState(
        failure: error is Failure ? error : UnknownFailure(cause: error),
      ),
    );
    ref.onDispose(subscription.cancel);
    return const PagedState(isLoading: true);
  }

  /// Loads the next page, if there is one and nothing else is running.
  Future<void> loadMore() async {
    final repository = ref.read(libraryRepositoryProvider);
    final current = state;
    if (repository == null ||
        !current.hasMore ||
        current.isLoading ||
        current.isLoadingMore) {
      return;
    }
    state = current.copyWith(isLoadingMore: true);
    final result = await nextPage(repository, current.items.length);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        items: [...state.items, ...value],
        isLoadingMore: false,
        hasMore: value.length >= pageSize,
      ),
      Err(:final failure) => state.copyWith(
        isLoadingMore: false,
        hasMore: false,
        failure: failure,
      ),
    };
  }
}
