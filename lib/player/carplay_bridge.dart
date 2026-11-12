import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/player/media_browser.dart';

/// Answers the CarPlay scene (iOS) with the same tree Android Auto shows.
abstract final class CarPlayBridge {
  static const _channel = MethodChannel('melody/carplay');

  /// Starts answering; iOS only.
  static void start(ProviderContainer container) {
    if (!Platform.isIOS) return;
    final browser = MediaBrowser(container);
    _channel.setMethodCallHandler((call) => handle(browser, call));
  }

  /// Handles one call; separate for tests.
  static Future<Object?> handle(MediaBrowser browser, MethodCall call) async {
    switch (call.method) {
      case 'children':
        final items = await browser.children(call.arguments as String);
        return [
          for (final item in items)
            {
              'id': item.id,
              'title': item.title,
              'subtitle': item.artist,
              'playable': item.playable ?? true,
            },
        ];
      case 'play':
        await browser.play(call.arguments as String);
        return null;
      default:
        throw MissingPluginException(call.method);
    }
  }
}
