import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_analyzer.g.dart';

/// Voice band levels of the start of a song (see `vocalStart`).
typedef VoiceBandLevels = ({List<double> mid, List<double> side, Duration hop});

/// Decodes the start of a song and measures its voice band; replaced by
/// a fake in tests.
abstract interface class VoiceAnalyzer {
  /// Whether this device can decode audio for it.
  bool get supported;

  /// The levels of the first [seconds] of [mp3]; `null` when it fails.
  Future<VoiceBandLevels?> bands(Uint8List mp3, {int seconds});
}

/// [VoiceAnalyzer] over the `melody/voice` channel (Android).
class ChannelVoiceAnalyzer implements VoiceAnalyzer {
  /// Creates the analyzer.
  const ChannelVoiceAnalyzer();

  static const _channel = MethodChannel('melody/voice');

  @override
  bool get supported => !kIsWeb && Platform.isAndroid;

  @override
  Future<VoiceBandLevels?> bands(Uint8List mp3, {int seconds = 60}) async {
    if (!supported) return null;
    final dir = await Directory.systemTemp.createTemp('melody_voice');
    try {
      final file = File('${dir.path}/start.mp3');
      await file.writeAsBytes(mp3, flush: true);
      final result = await _channel.invokeMapMethod<String, Object?>('bands', {
        'path': file.path,
        'seconds': seconds,
      });
      if (result == null) return null;
      List<double> list(Object? v) => switch (v) {
        final Float64List l => l,
        final List<Object?> l => [for (final x in l) (x! as num).toDouble()],
        _ => const [],
      };
      return (
        mid: list(result['mid']),
        side: list(result['side']),
        hop: Duration(milliseconds: (result['hopMs'] as int?) ?? 20),
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } finally {
      await dir.delete(recursive: true);
    }
  }
}

/// The voice analyzer in use.
@Riverpod(keepAlive: true)
VoiceAnalyzer voiceAnalyzer(Ref ref) => const ChannelVoiceAnalyzer();
