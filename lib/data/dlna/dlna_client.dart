import 'package:dio/dio.dart';
import 'package:melody/data/dlna/dlna_models.dart';
import 'package:xml/xml.dart';

const _avTransport = 'urn:schemas-upnp-org:service:AVTransport:1';
const _renderingControl = 'urn:schemas-upnp-org:service:RenderingControl:1';

/// Talks to UPnP media renderers: reads their description and sends
/// AVTransport / RenderingControl actions (SOAP over HTTP).
class DlnaClient {
  /// Creates a client; [dio] is replaced in tests.
  DlnaClient([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  final Dio _dio;

  static String? _text(XmlElement parent, String name) {
    for (final child in parent.childElements) {
      if (child.name.local == name) return child.innerText.trim();
    }
    return null;
  }

  /// Reads the description at [location]; `null` when the device cannot
  /// play media.
  Future<DlnaRenderer?> describe(Uri location) async {
    final response = await _dio.getUri<String>(
      location,
      options: Options(responseType: ResponseType.plain),
    );
    return parseDescription(response.data ?? '', location);
  }

  /// Parses a device description document fetched from [location].
  static DlnaRenderer? parseDescription(String xml, Uri location) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException {
      return null;
    }
    final root = document.rootElement;
    final declared = _text(root, 'URLBase');
    final base = declared == null || declared.isEmpty
        ? location
        : Uri.tryParse(declared) ?? location;
    Uri? control(String type) {
      for (final service in root.descendantElements) {
        if (service.name.local != 'service') continue;
        // Any version of the service will do.
        final serviceType = _text(service, 'serviceType') ?? '';
        if (!serviceType.contains(':service:$type:')) continue;
        final url = _text(service, 'controlURL');
        if (url != null && url.isNotEmpty) return base.resolve(url);
      }
      return null;
    }

    final transport = control('AVTransport');
    if (transport == null) return null;
    XmlElement? device;
    for (final element in root.descendantElements) {
      if (element.name.local == 'device') {
        device = element;
        break;
      }
    }
    final name = device == null ? null : _text(device, 'friendlyName');
    final udn = device == null ? null : _text(device, 'UDN');
    return DlnaRenderer(
      id: udn == null || udn.isEmpty ? '$location' : udn,
      name: name == null || name.isEmpty ? location.host : name,
      avTransportUrl: transport,
      renderingControlUrl: control('RenderingControl'),
    );
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  /// Builds the SOAP envelope of [action] with [arguments] in order.
  static String envelope(
    String service,
    String action,
    Map<String, String> arguments,
  ) {
    final body = StringBuffer();
    arguments.forEach((key, value) {
      body.write('<$key>${_escape(value)}</$key>');
    });
    return (StringBuffer('<?xml version="1.0" encoding="utf-8"?>')
          ..write('<s:Envelope ')
          ..write('xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" ')
          ..write('s:encodingStyle=')
          ..write('"http://schemas.xmlsoap.org/soap/encoding/">')
          ..write('<s:Body><u:$action xmlns:u="$service">$body</u:$action>')
          ..write('</s:Body></s:Envelope>'))
        .toString();
  }

  /// DIDL-Lite description of a track, shown by the renderer.
  static String didl(Uri uri, DlnaMetadata meta) {
    final artist = meta.artist;
    final album = meta.album;
    final art = meta.artUri;
    final out = StringBuffer('<DIDL-Lite ')
      ..write('xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" ')
      ..write('xmlns:dc="http://purl.org/dc/elements/1.1/" ')
      ..write('xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">')
      ..write('<item id="0" parentID="-1" restricted="1">')
      ..write('<dc:title>${_escape(meta.title)}</dc:title>');
    if (artist != null) {
      out
        ..write('<upnp:artist>${_escape(artist)}</upnp:artist>')
        ..write('<dc:creator>${_escape(artist)}</dc:creator>');
    }
    if (album != null) out.write('<upnp:album>${_escape(album)}</upnp:album>');
    if (art != null) {
      out.write('<upnp:albumArtURI>${_escape('$art')}</upnp:albumArtURI>');
    }
    out
      ..write('<upnp:class>object.item.audioItem.musicTrack</upnp:class>')
      ..write('<res protocolInfo="http-get:*:audio/*:*">')
      ..write('${_escape('$uri')}</res></item></DIDL-Lite>');
    return out.toString();
  }

  Future<XmlDocument> _call(
    Uri control,
    String service,
    String action, [
    Map<String, String> arguments = const {},
  ]) async {
    final response = await _dio.postUri<String>(
      control,
      data: envelope(service, action, {'InstanceID': '0', ...arguments}),
      options: Options(
        responseType: ResponseType.plain,
        contentType: 'text/xml; charset="utf-8"',
        headers: {'SOAPACTION': '"$service#$action"'},
      ),
    );
    return XmlDocument.parse(response.data ?? '<empty/>');
  }

  static String? _value(XmlDocument document, String name) {
    for (final element in document.descendantElements) {
      if (element.name.local == name) return element.innerText.trim();
    }
    return null;
  }

  /// Loads [uri] on [renderer].
  Future<void> setUri(DlnaRenderer renderer, Uri uri, DlnaMetadata meta) =>
      _call(renderer.avTransportUrl, _avTransport, 'SetAVTransportURI', {
        'CurrentURI': '$uri',
        'CurrentURIMetaData': didl(uri, meta),
      });

  /// Starts or resumes playback.
  Future<void> play(DlnaRenderer renderer) =>
      _call(renderer.avTransportUrl, _avTransport, 'Play', {'Speed': '1'});

  /// Pauses playback.
  Future<void> pause(DlnaRenderer renderer) =>
      _call(renderer.avTransportUrl, _avTransport, 'Pause');

  /// Stops playback.
  Future<void> stop(DlnaRenderer renderer) =>
      _call(renderer.avTransportUrl, _avTransport, 'Stop');

  /// Seeks to [position] of the current track.
  Future<void> seek(DlnaRenderer renderer, Duration position) => _call(
    renderer.avTransportUrl,
    _avTransport,
    'Seek',
    {'Unit': 'REL_TIME', 'Target': formatTime(position)},
  );

  /// Position and length of the current track.
  Future<DlnaPosition> position(DlnaRenderer renderer) async {
    final document = await _call(
      renderer.avTransportUrl,
      _avTransport,
      'GetPositionInfo',
    );
    return (
      position: parseTime(_value(document, 'RelTime')) ?? Duration.zero,
      duration: parseTime(_value(document, 'TrackDuration')),
    );
  }

  /// What the renderer is doing.
  Future<DlnaTransportState> transportState(DlnaRenderer renderer) async {
    final document = await _call(
      renderer.avTransportUrl,
      _avTransport,
      'GetTransportInfo',
    );
    return switch (_value(document, 'CurrentTransportState')) {
      'PLAYING' => DlnaTransportState.playing,
      'PAUSED_PLAYBACK' => DlnaTransportState.paused,
      'TRANSITIONING' => DlnaTransportState.transitioning,
      _ => DlnaTransportState.stopped,
    };
  }

  /// Volume of the renderer, 0–100, or `null` when it cannot be read.
  Future<int?> volume(DlnaRenderer renderer) async {
    final control = renderer.renderingControlUrl;
    if (control == null) return null;
    final document = await _call(control, _renderingControl, 'GetVolume', {
      'Channel': 'Master',
    });
    return int.tryParse(_value(document, 'CurrentVolume') ?? '');
  }

  /// Sets the volume of the renderer, 0–100.
  Future<void> setVolume(DlnaRenderer renderer, int volume) async {
    final control = renderer.renderingControlUrl;
    if (control == null) return;
    await _call(control, _renderingControl, 'SetVolume', {
      'Channel': 'Master',
      'DesiredVolume': '${volume.clamp(0, 100)}',
    });
  }

  /// Formats [value] as `H:MM:SS`.
  static String formatTime(Duration value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final seconds = value.inSeconds;
    final minutes = seconds % 3600 ~/ 60;
    return '${seconds ~/ 3600}:${two(minutes)}:${two(seconds % 60)}';
  }

  /// Parses `H:MM:SS(.mmm)`; `null` for missing or "not implemented" values.
  static Duration? parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 3) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final s = double.tryParse(parts[2]);
    if (h == null || m == null || s == null) return null;
    return Duration(milliseconds: ((h * 3600 + m * 60 + s) * 1000).round());
  }
}
