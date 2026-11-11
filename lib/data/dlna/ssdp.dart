import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Searches the local network for UPnP media renderers (SSDP).
///
/// Sends an `M-SEARCH` to the SSDP multicast group and yields the device
/// description address of every answer, each one once.
Stream<Uri> discoverRenderers({
  Duration timeout = const Duration(seconds: 4),
}) async* {
  const target = 'urn:schemas-upnp-org:device:MediaRenderer:1';
  final request = [
    'M-SEARCH * HTTP/1.1',
    'HOST: 239.255.255.250:1900',
    'MAN: "ssdp:discover"',
    'MX: 2',
    'ST: $target',
    '',
    '',
  ].join('\r\n');
  final RawDatagramSocket socket;
  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  } on SocketException {
    return;
  }
  final found = StreamController<Uri>();
  final seen = <String>{};
  final subscription = socket.listen((event) {
    if (event != RawSocketEvent.read) return;
    final datagram = socket.receive();
    if (datagram == null) return;
    final location = parseSsdpLocation(
      utf8.decode(datagram.data, allowMalformed: true),
    );
    if (location != null && seen.add('$location')) found.add(location);
  });
  final group = InternetAddress('239.255.255.250');
  try {
    // UDP is lossy: ask twice.
    socket.send(utf8.encode(request), group, 1900);
    Timer(
      const Duration(milliseconds: 600),
      () => socket.send(utf8.encode(request), group, 1900),
    );
  } on SocketException {
    // No usable network; the stream just ends empty.
  }
  final timer = Timer(timeout, found.close);
  try {
    yield* found.stream;
  } finally {
    timer.cancel();
    await subscription.cancel();
    socket.close();
    if (!found.isClosed) await found.close();
  }
}

/// Extracts the `LOCATION` header of an SSDP answer.
Uri? parseSsdpLocation(String response) {
  for (final line in const LineSplitter().convert(response)) {
    final at = line.indexOf(':');
    if (at < 0) continue;
    if (line.substring(0, at).trim().toLowerCase() != 'location') continue;
    final uri = Uri.tryParse(line.substring(at + 1).trim());
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) return uri;
  }
  return null;
}
