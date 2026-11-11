import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/data/dlna/dlna_models.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/output_controller.dart';

/// Button of the full player that opens the list of outputs; highlighted
/// while playing on another device.
class OutputButton extends ConsumerWidget {
  /// Creates the button.
  const OutputButton({required this.color, super.key});

  /// Icon colour while playing on this device.
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(outputControllerProvider) != null;
    return IconButton(
      color: remote ? Colors.white : color,
      tooltip: context.l10n.outputTitle,
      icon: Icon(remote ? Icons.cast_connected_rounded : Icons.cast_rounded),
      onPressed: () => showOutputSheet(context),
    );
  }
}

/// Lets the user pick where to play: this device or a DLNA renderer found
/// on the local network.
Future<void> showOutputSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => const _OutputSheet(),
    );

class _OutputSheet extends ConsumerWidget {
  const _OutputSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selected = ref.watch(outputControllerProvider);
    final search = ref.watch(dlnaRenderersProvider);
    final found = search.value ?? const <DlnaRenderer>[];
    // Keep the selected renderer listed even if this search missed it.
    final renderers = [
      if (selected != null && !found.contains(selected)) selected,
      ...found,
    ];
    final searching = search.isLoading || !search.hasValue;
    // The sheet (and its ref) is gone by the time the switch finishes.
    final container = ProviderScope.containerOf(context);
    void pick(DlnaRenderer? renderer) {
      Navigator.pop(context);
      unawaited(switchOutput(container, renderer));
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.outputTitle, style: theme.textTheme.titleLarge),
              trailing: searching
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: l10n.retry,
                      onPressed: () => ref.invalidate(dlnaRenderersProvider),
                    ),
            ),
            ListTile(
              leading: const Icon(Icons.smartphone_rounded),
              title: Text(l10n.outputThisDevice),
              trailing: selected == null ? const Icon(Icons.check) : null,
              onTap: () => pick(null),
            ),
            for (final r in renderers)
              ListTile(
                leading: const Icon(Icons.speaker_rounded),
                title: Text(
                  r.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(r.avTransportUrl.host),
                trailing: r == selected ? const Icon(Icons.check) : null,
                onTap: () => pick(r),
              ),
            if (selected != null) _VolumeTile(renderer: selected),
            if (!searching && renderers.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  l10n.outputNone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Volume of the selected renderer.
class _VolumeTile extends ConsumerStatefulWidget {
  const _VolumeTile({required this.renderer});

  final DlnaRenderer renderer;

  @override
  ConsumerState<_VolumeTile> createState() => _VolumeTileState();
}

class _VolumeTileState extends ConsumerState<_VolumeTile> {
  double? _volume;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final value = await ref.read(dlnaClientProvider).volume(widget.renderer);
      if (mounted && value != null) setState(() => _volume = value.toDouble());
    } on Object {
      // The renderer does not report its volume; the slider stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    final volume = _volume;
    if (volume == null) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.volume_up_rounded),
      title: Slider(
        value: volume.clamp(0, 100),
        max: 100,
        label: '${volume.round()}',
        semanticFormatterCallback: (v) => '${v.round()}',
        onChanged: (v) => setState(() => _volume = v),
        onChangeEnd: (v) => unawaited(
          ref
              .read(dlnaClientProvider)
              .setVolume(widget.renderer, v.round())
              .catchError((Object _) {}),
        ),
      ),
    );
  }
}
