import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/library/widgets/paged_scroll_view.dart';

/// Albums of one genre.
class GenreScreen extends ConsumerWidget {
  /// Creates the page of genre [id].
  const GenreScreen({required this.id, required this.name, super.key});

  /// Genre id.
  final String id;

  /// Genre name.
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = albumListProvider(AlbumQuery(genreId: id));
    return Scaffold(
      body: PagedScrollView<Album>(
        title: name,
        state: ref.watch(provider),
        onRefresh: () => ref.invalidate(provider),
        onLoadMore: () => ref.read(provider.notifier).loadMore(),
        sliverBuilder: (albums) => AlbumSliverGrid(albums: albums),
      ),
    );
  }
}
