import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/tailnet/qr_code.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_party.g.dart';

/// A running party: where guests open the page.
@immutable
class PartyState {
  /// Creates the state.
  const PartyState({this.url, this.added = 0});

  /// Address of the page; `null` when no party is running.
  final String? url;

  /// Songs guests added.
  final int added;

  /// Whether the page is served.
  bool get running => url != null;
}

/// Seconds a guest waits between two songs.
const partyGuestPause = Duration(seconds: 3);

/// Most songs guests can add in one party.
const partyMaxSongs = 200;

/// "House party": a small web page served from this phone on the local
/// network. Guests scan a QR code, search the library in their browser and
/// add songs to the queue; no app and no internet needed. Only someone
/// with the link (it carries a random key) can use it, and it stops when
/// the party ends or the app closes.
@Riverpod(keepAlive: true)
class HouseParty extends _$HouseParty {
  HttpServer? _server;
  String _key = '';
  final _found = <String, Track>{};
  final _lastAdd = <String, DateTime>{};

  @override
  PartyState build() {
    ref.onDispose(() => unawaited(_server?.close(force: true)));
    return const PartyState();
  }

  /// The phone's address on the local network, or `null` without one.
  @visibleForTesting
  static Future<String?> localAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    String? any;
    for (final i in interfaces) {
      for (final a in i.addresses) {
        if (a.isLoopback) continue;
        final ip = a.address;
        // Prefer home networks over mobile data or VPNs.
        if (ip.startsWith('192.168.') || ip.startsWith('10.')) return ip;
        if (ip.startsWith('172.')) any ??= ip;
      }
    }
    return any;
  }

  /// Starts serving the page; `false` when there is no local network.
  Future<bool> start({String? host}) async {
    if (state.running) return true;
    final address = host ?? await localAddress();
    if (address == null) return false;
    final random = Random.secure();
    _key = List.generate(
      10,
      (_) => 'abcdefghjkmnpqrstuvwxyz23456789'[random.nextInt(31)],
    ).join();
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    server.listen((request) => unawaited(_handle(request)));
    state = PartyState(url: 'http://$address:${server.port}/?k=$_key');
    return true;
  }

  /// Ends the party.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _found.clear();
    _lastAdd.clear();
    state = const PartyState();
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      if (request.uri.queryParameters['k'] != _key) {
        response.statusCode = HttpStatus.forbidden;
        return;
      }
      switch ((request.method, request.uri.path)) {
        case ('GET', '/'):
          response.headers.contentType = ContentType.html;
          response.write(partyPage);
        case ('GET', '/search'):
          await _search(request);
        case ('POST', '/add'):
          _add(request);
        case ('GET', '/now'):
          final track = ref.read(playerControllerProvider).current;
          _json(response, {
            'title': track?.title ?? '',
            'artist': track?.artistLine ?? '',
          });
        default:
          response.statusCode = HttpStatus.notFound;
      }
    } on Object {
      response.statusCode = HttpStatus.internalServerError;
    } finally {
      await response.close();
    }
  }

  Future<void> _search(HttpRequest request) async {
    final query = (request.uri.queryParameters['q'] ?? '').trim();
    final source = ref.read(activeSourceProvider);
    if (query.isEmpty || source == null || query.length > 100) {
      _json(request.response, <Object>[]);
      return;
    }
    final result = await source.search(query, limit: 15);
    final tracks = switch (result) {
      Ok(:final value) => value.tracks,
      Err() => const <Track>[],
    };
    for (final t in tracks) {
      _found[t.id] = t;
    }
    _json(request.response, [
      for (final t in tracks)
        {'id': t.id, 'title': t.title, 'artist': t.artistLine},
    ]);
  }

  void _add(HttpRequest request) {
    final response = request.response;
    final track = _found[request.uri.queryParameters['id']];
    final guest = request.connectionInfo?.remoteAddress.address ?? '';
    final last = _lastAdd[guest];
    final now = DateTime.now();
    if (track == null) {
      response.statusCode = HttpStatus.notFound;
      return;
    }
    if (state.added >= partyMaxSongs ||
        (last != null && now.difference(last) < partyGuestPause)) {
      response.statusCode = HttpStatus.tooManyRequests;
      return;
    }
    _lastAdd[guest] = now;
    final player = ref.read(playerControllerProvider.notifier);
    if (ref.read(playerControllerProvider).hasQueue) {
      unawaited(player.addToQueue([track]));
    } else {
      unawaited(player.playTracks([track]));
    }
    state = PartyState(url: state.url, added: state.added + 1);
    _json(response, {'ok': true});
  }

  void _json(HttpResponse response, Object value) {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(value));
  }
}

/// Shows the party: start it, the QR code for guests, stop it.
Future<void> showHouseParty(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  useRootNavigator: true,
  builder: (context) => const _PartySheet(),
);

class _PartySheet extends ConsumerStatefulWidget {
  const _PartySheet();

  @override
  ConsumerState<_PartySheet> createState() => _PartySheetState();
}

class _PartySheetState extends ConsumerState<_PartySheet> {
  var _busy = false;
  var _noNetwork = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    final ok = await ref.read(housePartyProvider.notifier).start();
    if (mounted) {
      setState(() {
        _busy = false;
        _noNetwork = !ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final party = ref.watch(housePartyProvider);
    final url = party.url;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.partyTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            url == null ? l10n.partyBody : l10n.partyScan,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (url != null) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: QrCodeView(data: url, size: 220),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(url, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.partyAdded(party.added)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () =>
                  unawaited(ref.read(housePartyProvider.notifier).stop()),
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.partyStop),
            ),
          ] else ...[
            if (_noNetwork)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.partyNoNetwork,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton.icon(
              onPressed: _busy ? null : () => unawaited(_start()),
              icon: const Icon(Icons.celebration_rounded),
              label: Text(l10n.partyStart),
            ),
          ],
        ],
      ),
    );
  }
}

/// The guests' page: search, add, see what plays. Plain HTML so any phone
/// browser can use it.
const partyPage = '''
<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Melody party</title>
<style>
body{font-family:system-ui,sans-serif;margin:0;background:#15131a;color:#fff}
header{padding:20px 16px 8px}h1{margin:0;font-size:22px}
#now{color:#bbb;font-size:14px;margin-top:4px;min-height:18px}
input{box-sizing:border-box;width:calc(100% - 32px);margin:8px 16px;padding:14px;
border-radius:12px;border:0;font-size:17px;background:#26242e;color:#fff}
ul{list-style:none;padding:0;margin:0 16px}
li{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid #2a2833}
li div{flex:1;min-width:0}li b,li small{display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
li small{color:#aaa}
button{border:0;border-radius:20px;padding:10px 16px;font-size:15px;background:#e8505b;color:#fff}
button:disabled{background:#3a8f5a}
#msg{position:fixed;bottom:16px;left:16px;right:16px;text-align:center;padding:12px;
border-radius:12px;background:#333;display:none}
</style></head><body>
<header><h1>🎉 Melody</h1><div id="now"></div></header>
<input id="q" type="search" placeholder="🔍" autofocus>
<ul id="list"></ul><div id="msg"></div>
<script>
const key=new URLSearchParams(location.search).get('k');
const q=document.getElementById('q'),list=document.getElementById('list'),
msg=document.getElementById('msg'),now=document.getElementById('now');
let timer;
function show(t){msg.textContent=t;msg.style.display='block';
setTimeout(()=>msg.style.display='none',2000)}
q.addEventListener('input',()=>{clearTimeout(timer);timer=setTimeout(search,300)});
async function search(){
const r=await fetch('/search?k='+key+'&q='+encodeURIComponent(q.value));
const songs=await r.json();list.innerHTML='';
for(const s of songs){const li=document.createElement('li');
const d=document.createElement('div');const b=document.createElement('b');
b.textContent=s.title;const sm=document.createElement('small');
sm.textContent=s.artist;d.append(b,sm);
const btn=document.createElement('button');btn.textContent='+';
btn.onclick=async()=>{const a=await fetch('/add?k='+key+'&id='+encodeURIComponent(s.id),{method:'POST'});
if(a.ok){btn.textContent='✓';btn.disabled=true;show('♪ '+s.title)}else{show('⏳')}};
li.append(d,btn);list.append(li)}}
async function playing(){try{const r=await fetch('/now?k='+key);const n=await r.json();
now.textContent=n.title?'▶ '+n.title+' · '+n.artist:''}catch(e){}}
playing();setInterval(playing,5000);
</script></body></html>
''';
