import 'dart:async';

import 'package:melody/data/dlna/dlna_client.dart';
import 'package:melody/data/dlna/dlna_models.dart';
import 'package:melody/data/dlna/ssdp.dart';
import 'package:melody/player/player_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'output_controller.g.dart';

/// Talks to DLNA renderers; replaced in tests.
@Riverpod(keepAlive: true)
DlnaClient dlnaClient(Ref ref) => DlnaClient();

/// Renderers found on the local network; grows while the search runs.
@riverpod
Stream<List<DlnaRenderer>> dlnaRenderers(Ref ref) async* {
  final client = ref.watch(dlnaClientProvider);
  var found = <DlnaRenderer>[];
  yield found;
  await for (final location in discoverRenderers()) {
    try {
      final renderer = await client.describe(location);
      if (renderer != null && !found.contains(renderer)) {
        found = [...found, renderer];
        yield found;
      }
    } on Object {
      // Not a usable renderer.
    }
  }
}

/// Where audio is played: `null` for this device, otherwise a DLNA
/// renderer.
@Riverpod(keepAlive: true)
class OutputController extends _$OutputController {
  @override
  DlnaRenderer? build() => null;

  /// Sets the output without touching playback; see [switchOutput].
  // A method reads better than a setter next to `switchOutput`.
  // ignore: use_setters_to_change_properties
  void set(DlnaRenderer? renderer) => state = renderer;
}

/// Moves playback to [renderer] (or back to this device with `null`),
/// keeping the queue and the position.
Future<void> switchOutput(
  ProviderContainer container,
  DlnaRenderer? renderer,
) async {
  if (renderer == container.read(outputControllerProvider)) return;
  final wasPlaying = container.read(playerControllerProvider).playing;
  await container.read(playerControllerProvider.notifier).saveQueue();
  // The engine is rebuilt for the new output and the player restores the
  // saved queue on it.
  container.read(outputControllerProvider.notifier).set(renderer);
  await Future<void>.delayed(Duration.zero);
  if (wasPlaying) {
    await container.read(playerControllerProvider.notifier).play();
  }
}
