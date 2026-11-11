import 'package:flutter/material.dart';

/// Title of a group of settings.
class SectionHeader extends StatelessWidget {
  /// Creates a header showing [title].
  const SectionHeader(this.title, {super.key});

  /// Text of the header.
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
