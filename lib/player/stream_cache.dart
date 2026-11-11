import 'dart:io';

import 'package:melody/core/logging/app_logger.dart';
import 'package:path_provider/path_provider.dart';

const _log = AppLogger('stream-cache');

/// Disk cache of played tracks, trimmed to a size limit (oldest use first).
class StreamCache {
  /// Creates a cache in [directory], or in the app cache folder.
  StreamCache([Future<Directory> Function()? directory])
    : _directory = directory ?? _defaultDirectory;

  final Future<Directory> Function() _directory;
  Directory? _resolved;

  static Future<Directory> _defaultDirectory() async =>
      Directory('${(await getApplicationCacheDirectory()).path}/audio');

  /// The folder holding cached tracks; created on first use.
  Future<Directory?> directory() async {
    try {
      final dir = _resolved ??= await _directory();
      if (!dir.existsSync()) await dir.create(recursive: true);
      return dir;
    } on Object catch (error) {
      _log.error('Cache folder unavailable', error);
      return null;
    }
  }

  /// File for [key]; marks it as recently used.
  Future<File?> fileFor(String key) async {
    final dir = await directory();
    if (dir == null) return null;
    final safe = key.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');
    final file = File('${dir.path}/$safe');
    if (file.existsSync()) {
      try {
        file.setLastModifiedSync(DateTime.now());
      } on Object {
        // Read-only file systems: the order just becomes less exact.
      }
    }
    return file;
  }

  Future<List<File>> _files() async {
    final dir = await directory();
    if (dir == null) return const [];
    return dir.listSync().whereType<File>().toList();
  }

  /// Bytes used.
  Future<int> size() async {
    var total = 0;
    for (final f in await _files()) {
      total += f.lengthSync();
    }
    return total;
  }

  /// Deletes the least recently used files until at most [maxBytes] remain.
  ///
  /// Files touched in the last minute are kept: they may be playing.
  Future<void> trim(int maxBytes) async {
    final files = await _files();
    final entries = [for (final f in files) (file: f, stat: f.statSync())]
      ..sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    var total = entries.fold(0, (sum, e) => sum + e.stat.size);
    final recent = DateTime.now().subtract(const Duration(minutes: 1));
    for (final e in entries) {
      if (total <= maxBytes) break;
      if (e.stat.modified.isAfter(recent)) continue;
      try {
        e.file.deleteSync();
        total -= e.stat.size;
      } on Object catch (error) {
        _log.error('Could not delete cached file', error);
      }
    }
  }

  /// Deletes everything.
  Future<void> clear() => trim(-1);
}
