import 'package:flutter/material.dart';

/// Big bold title above a block of content (shelves, grids, results).
///
/// Settings use the smaller `SectionHeader` instead.
class ShelfHeader extends StatelessWidget {
  /// Creates a header showing [title].
  const ShelfHeader(this.title, {super.key});

  /// Text of the header.
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
