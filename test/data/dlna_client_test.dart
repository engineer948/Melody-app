import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/dlna/dlna_client.dart';
import 'package:melody/data/dlna/dlna_models.dart';
import 'package:melody/data/dlna/ssdp.dart';

const _description = '''
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
    <friendlyName>Salon &amp; TV</friendlyName>
    <UDN>uuid:1234</UDN>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
        <controlURL>/rc/control</controlURL>
      </service>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:2</serviceType>
        <controlURL>avt/control</controlURL>
      </service>
    </serviceList>
  </device>
</root>''';

/// Answers SOAP calls with canned XML and records them.
class _SoapAdapter implements HttpClientAdapter {
  final calls = <(String action, String body)>[];
  final answers = <String, String>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final action = '${options.headers['SOAPACTION']}'.split('#').last;
    final name = action.replaceAll('"', '');
    calls.add((name, '${options.data}'));
    return ResponseBody.fromString(
      '<s:Envelope><s:Body>${answers[name] ?? ''}</s:Body></s:Envelope>',
      200,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final location = Uri.parse('http://192.168.1.20:49152/desc/device.xml');

  test('reads name, id and control addresses from a description', () {
    final r = DlnaClient.parseDescription(_description, location)!;
    expect(r.name, 'Salon & TV');
    expect(r.id, 'uuid:1234');
    expect('${r.avTransportUrl}', 'http://192.168.1.20:49152/desc/avt/control');
    expect('${r.renderingControlUrl}', 'http://192.168.1.20:49152/rc/control');
  });

  test('devices without AVTransport and broken XML are not renderers', () {
    expect(
      DlnaClient.parseDescription(
        '<root><device><friendlyName>NAS</friendlyName></device></root>',
        location,
      ),
      isNull,
    );
    expect(DlnaClient.parseDescription('not xml <', location), isNull);
  });

  test('SSDP answers yield the LOCATION header', () {
    expect(
      parseSsdpLocation(
        'HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\n'
        'Location: http://192.168.1.20:49152/desc.xml\r\nST: x\r\n\r\n',
      ),
      Uri.parse('http://192.168.1.20:49152/desc.xml'),
    );
    expect(parseSsdpLocation('HTTP/1.1 200 OK\r\nST: x\r\n\r\n'), isNull);
  });

  test('times are formatted and parsed as H:MM:SS', () {
    expect(
      DlnaClient.formatTime(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(
      DlnaClient.parseTime('0:03:25.500'),
      const Duration(minutes: 3, seconds: 25, milliseconds: 500),
    );
    expect(DlnaClient.parseTime('NOT_IMPLEMENTED'), isNull);
    expect(DlnaClient.parseTime(null), isNull);
  });

  test('envelopes escape their arguments', () {
    final xml = DlnaClient.envelope('urn:x', 'Play', {'A': 'a&b<c>'});
    expect(xml, contains('<u:Play xmlns:u="urn:x"><A>a&amp;b&lt;c&gt;</A>'));
  });

  group('actions', () {
    late _SoapAdapter adapter;
    late DlnaClient client;
    final renderer = DlnaRenderer(
      id: 'r1',
      name: 'TV',
      avTransportUrl: Uri.parse('http://tv/avt'),
      renderingControlUrl: Uri.parse('http://tv/rc'),
    );

    setUp(() {
      adapter = _SoapAdapter();
      client = DlnaClient(Dio()..httpClientAdapter = adapter);
    });

    test('setUri sends the address with DIDL metadata', () async {
      await client.setUri(
        renderer,
        Uri.parse('http://server/audio/1?api_key=k&x=1'),
        const DlnaMetadata(title: 'Firuze', artist: 'Sezen & Co'),
      );
      final (action, body) = adapter.calls.single;
      expect(action, 'SetAVTransportURI');
      expect(body, contains('<InstanceID>0</InstanceID>'));
      expect(
        body,
        contains('<CurrentURI>http://server/audio/1?api_key=k&amp;x=1'),
      );
      // The metadata is XML inside XML, so it is escaped twice.
      expect(body, contains('&lt;dc:title&gt;Firuze&lt;/dc:title&gt;'));
      expect(body, contains('Sezen &amp;amp; Co'));
    });

    test('reads position, state and volume', () async {
      adapter.answers['GetPositionInfo'] =
          '<u:GetPositionInfoResponse><TrackDuration>0:03:05</TrackDuration>'
          '<RelTime>0:01:00</RelTime></u:GetPositionInfoResponse>';
      adapter.answers['GetTransportInfo'] =
          '<CurrentTransportState>PAUSED_PLAYBACK</CurrentTransportState>';
      adapter.answers['GetVolume'] = '<CurrentVolume>37</CurrentVolume>';

      final info = await client.position(renderer);
      expect(info.position, const Duration(minutes: 1));
      expect(info.duration, const Duration(minutes: 3, seconds: 5));
      expect(await client.transportState(renderer), DlnaTransportState.paused);
      expect(await client.volume(renderer), 37);
    });

    test('seek and volume send their values', () async {
      await client.seek(renderer, const Duration(seconds: 75));
      await client.setVolume(renderer, 140);
      expect(adapter.calls[0].$2, contains('<Target>0:01:15</Target>'));
      expect(
        adapter.calls[1].$2,
        contains('<DesiredVolume>100</DesiredVolume>'),
      );
      expect(utf8.encode(adapter.calls[0].$2), isNotEmpty);
    });
  });
}
