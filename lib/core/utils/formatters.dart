/// Formats [duration] as `m:ss`, or `h:mm:ss` from one hour on.
String formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
