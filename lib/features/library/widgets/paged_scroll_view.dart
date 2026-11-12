import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/features/library/paged_state.dart';
import 'package:melody/l10n/l10n.dart';

/// Large-title page for a [PagedState]: loading, error, empty and content.
class PagedScrollView<T> extends StatelessWidget {
  /// Creates the page.
  const PagedScrollView({
    required this.title,
    required this.state,
    required this.sliverBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    this.actions = const [],
    this.emptyIcon = Icons.library_music_outlined,
    this.headers = const [],
    this.colors,
    super.key,
  });

  /// Colours washed behind the top of the page; see [LargeTitlePage].
  final List<Color>? colors;

  /// Page title.
  final String title;

  /// What to show.
  final PagedState<T> state;

  /// Builds the sliver holding the items.
  final Widget Function(List<T> items) sliverBuilder;

  /// Reloads from the start.
  final VoidCallback onRefresh;

  /// Requests the next page.
  final VoidCallback onLoadMore;

  /// App bar actions.
  final List<Widget> actions;

  /// Icon of the empty state.
  final IconData emptyIcon;

  /// Slivers placed above the items.
  final List<Widget> headers;

  @override
  Widget build(BuildContext context) => LargeTitlePage(
    title: title,
    colors: colors,
    actions: actions,
    onRefresh: () async => onRefresh(),
    onNearEnd: onLoadMore,
    slivers: [
      ...headers,
      ...pagedSlivers(
        context,
        state: state,
        onRetry: onRefresh,
        emptyIcon: emptyIcon,
        sliverBuilder: sliverBuilder,
      ),
    ],
  );
}

/// Slivers showing a [PagedState]; usable inside any scroll view.
List<Widget> pagedSlivers<T>(
  BuildContext context, {
  required PagedState<T> state,
  required VoidCallback onRetry,
  required Widget Function(List<T> items) sliverBuilder,
  IconData emptyIcon = Icons.library_music_outlined,
}) {
  final failure = state.failure;
  if (state.items.isEmpty) {
    final Widget body;
    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (failure != null) {
      body = FailureView(failure: failure, onRetry: onRetry);
    } else {
      body = EmptyState(icon: emptyIcon, title: context.l10n.emptyList);
    }
    return [SliverFillRemaining(hasScrollBody: false, child: body)];
  }
  return [
    if (failure != null && state.fromCache)
      const SliverToBoxAdapter(child: OfflineBanner()),
    sliverBuilder(state.items),
    if (state.isLoadingMore)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
  ];
}

/// Slivers for a provider that loads a whole value at once.
List<Widget> loadedSlivers<T>({
  required AsyncValue<T> value,
  required VoidCallback onRetry,
  required List<Widget> Function(T data) builder,
}) {
  final data = value.value;
  if (data != null) return builder(data);
  final error = value.error;
  return [
    SliverFillRemaining(
      hasScrollBody: false,
      child: error != null
          ? FailureView(failure: asFailure(error), onRetry: onRetry)
          : const Center(child: CircularProgressIndicator()),
    ),
  ];
}
