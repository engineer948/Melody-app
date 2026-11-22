import 'dart:math';

/// Where the singing starts in the first part of a song, from the level
/// of the voice band (250–3500 Hz) in the middle of the stereo picture
/// ([mid]) and at its sides ([side]), one value per [hop].
///
/// Singers are mixed in the middle, so the voice shows as the middle
/// getting clearly louder than before, and louder than the sides. The
/// earliest moment where that holds for [hold] after the music started is
/// taken; `null` when no such moment is found.
Duration? vocalStart(
  List<double> mid,
  List<double> side, {
  Duration hop = const Duration(milliseconds: 20),
  Duration hold = const Duration(milliseconds: 400),
}) {
  final n = min(mid.length, side.length);
  if (n < 50) return null;
  const eps = 1e-5;
  // Smooth over 0.2 s.
  const window = 10;
  List<double> smooth(List<double> v) {
    final out = List<double>.filled(n, 0);
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      sum += v[i];
      if (i >= window) sum -= v[i - window];
      out[i] = sum / min(i + 1, window);
    }
    return out;
  }

  final level = smooth([for (var i = 0; i < n; i++) log(mid[i] + eps)]);
  final centre = smooth([
    for (var i = 0; i < n; i++) log(mid[i] + eps) - log(side[i] + eps),
  ]);
  final sorted = [...level]..sort();
  final loud = sorted[(n * 0.95).floor()];
  // Below about -50 dB is silence.
  final floor = log(0.003);
  if (loud < floor + 1) return null;
  // The music starts where the voice band leaves the silence.
  var music = 0;
  while (music < n && level[music] < floor) {
    music++;
  }
  final steps = hold.inMicroseconds ~/ hop.inMicroseconds;
  // Compare with the 3 seconds before (or the start of the music).
  final back = 3000000 ~/ hop.inMicroseconds;
  for (var i = music + 15; i + steps < n; i++) {
    final from = max(music, i - back);
    final to = i - 5;
    if (to - from < 10) continue;
    var baseLevel = 0.0;
    var baseCentre = 0.0;
    for (var j = from; j < to; j++) {
      baseLevel += level[j];
      baseCentre += centre[j];
    }
    baseLevel /= to - from;
    baseCentre /= to - from;
    bool rose(int k) =>
        level[k] - baseLevel > 0.5 &&
        (level[k] - baseLevel) + (centre[k] - baseCentre) > 1.2 &&
        // Singing is among the loud parts of the song.
        level[k] > loud - 2;
    var held = true;
    for (var k = i; k < i + steps; k++) {
      if (!rose(k)) {
        held = false;
        break;
      }
    }
    if (held) return hop * i;
  }
  return null;
}

/// Lyrics within this much of the singing are left alone.
const vocalTolerance = Duration(milliseconds: 250);

/// Farther than this, the detection is more likely wrong than the lyrics.
const vocalMaxShift = Duration(seconds: 6);

/// The correction that puts the first sung line ([firstLine]) where the
/// singing starts ([singing]); `null` when it cannot be trusted.
Duration? vocalLyricsOffset(Duration? singing, Duration? firstLine) {
  if (singing == null || firstLine == null) return null;
  final offset = singing - firstLine;
  if (offset.abs() > vocalMaxShift) return null;
  if (offset.abs() < vocalTolerance) return Duration.zero;
  return offset;
}
