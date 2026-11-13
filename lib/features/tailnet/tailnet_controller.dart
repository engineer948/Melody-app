import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/data/tailnet/invite_code.dart';
import 'package:melody/data/tailnet/tailnet_bridge.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/player/streaming_settings.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tailnet_controller.g.dart';

const _log = AppLogger('tailnet');

/// Secrets of the built-in Tailscale node, kept in the Android Keystore
/// backed secure storage (never in plain preferences, never backed up).
@immutable
class TailnetSecrets {
  /// Creates the secrets.
  const TailnetSecrets({required this.proxySecret, required this.stateKey});

  /// Random path prefix of the loopback proxy; other apps on the phone
  /// cannot use the proxy without it.
  final String proxySecret;

  /// AES-256 key (hex) of the node's encrypted state file.
  final String stateKey;
}

/// Where [TailnetSecrets] are stored.
abstract interface class TailnetSecretStore {
  /// The saved secrets, if any.
  Future<TailnetSecrets?> read();

  /// Saves [secrets].
  Future<void> write(TailnetSecrets secrets);

  /// Forgets the secrets.
  Future<void> delete();
}

/// [TailnetSecretStore] in the platform keystore.
class SecureTailnetSecretStore implements TailnetSecretStore {
  /// Creates the store.
  const SecureTailnetSecretStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  static const _secretKey = 'tailnet.proxySecret';
  static const _stateKey = 'tailnet.stateKey';

  @override
  Future<TailnetSecrets?> read() async {
    final secret = await _storage.read(key: _secretKey);
    final state = await _storage.read(key: _stateKey);
    if (secret == null || state == null) return null;
    return TailnetSecrets(proxySecret: secret, stateKey: state);
  }

  @override
  Future<void> write(TailnetSecrets secrets) async {
    await _storage.write(key: _secretKey, value: secrets.proxySecret);
    await _storage.write(key: _stateKey, value: secrets.stateKey);
  }

  @override
  Future<void> delete() async {
    await _storage.delete(key: _secretKey);
    await _storage.delete(key: _stateKey);
  }
}

/// [TailnetSecretStore] in memory; for tests.
class MemoryTailnetSecretStore implements TailnetSecretStore {
  /// Creates the store.
  MemoryTailnetSecretStore([this.secrets]);

  /// Current content.
  TailnetSecrets? secrets;

  @override
  Future<TailnetSecrets?> read() async => secrets;

  @override
  Future<void> write(TailnetSecrets secrets) async => this.secrets = secrets;

  @override
  Future<void> delete() async => secrets = null;
}

/// What is known about the node before the first frame.
@immutable
class TailnetBootstrap {
  /// Creates the bootstrap data.
  const TailnetBootstrap({this.available = false, this.secrets});

  /// Loads it from the platform.
  static Future<TailnetBootstrap> load(
    TailnetBridge bridge,
    TailnetSecretStore store,
  ) async {
    try {
      final available = await bridge.available();
      return TailnetBootstrap(
        available: available,
        secrets: available ? await store.read() : null,
      );
    } on Object catch (error, stack) {
      _log.error('Could not read the Tailscale settings', error, stack);
      return const TailnetBootstrap();
    }
  }

  /// Whether this build has the Tailscale node.
  final bool available;

  /// Saved secrets.
  final TailnetSecrets? secrets;
}

/// Read before the first frame; overridden in `main`.
@Riverpod(keepAlive: true)
TailnetBootstrap tailnetBootstrap(Ref ref) => const TailnetBootstrap();

/// The platform side of the node.
@Riverpod(keepAlive: true)
TailnetBridge tailnetBridge(Ref ref) => const ChannelTailnetBridge();

/// Whether the music server answers through the proxy at `local`
/// (`<local>/System/Info/Public`, no sign-in needed); overridden in tests.
@Riverpod(keepAlive: true)
Future<bool> Function(Uri local) tailnetProbe(Ref ref) => (local) async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client
        .getUrl(local.replace(path: '${local.path}/System/Info/Public'))
        .timeout(const Duration(seconds: 8));
    final response = await request.close().timeout(const Duration(seconds: 8));
    await response.drain<void>();
    return response.statusCode < 500;
  } on Object {
    return false;
  } finally {
    client.close(force: true);
  }
};

/// Where the node's secrets are kept.
@Riverpod(keepAlive: true)
TailnetSecretStore tailnetSecretStore(Ref ref) =>
    const SecureTailnetSecretStore();

/// Maps the music server's tailnet address to the loopback proxy and back.
@immutable
class TailnetRouter {
  /// Creates a router; without [target] and [local] it changes nothing.
  const TailnetRouter({this.target, this.local});

  /// The server inside the tailnet, e.g. `http://100.101.102.103:8096`.
  final Uri? target;

  /// The proxy, `http://127.0.0.1:<port>/<secret>`.
  final Uri? local;

  static bool _under(Uri url, Uri base) =>
      url.scheme == base.scheme &&
      url.host.toLowerCase() == base.host.toLowerCase() &&
      url.port == base.port &&
      (url.path == base.path ||
          base.path.isEmpty ||
          url.path.startsWith(
            base.path.endsWith('/') ? base.path : '${base.path}/',
          ));

  static Uri _rebase(Uri url, Uri from, Uri to) {
    final rest = url.path.substring(min(from.path.length, url.path.length));
    return url.replace(
      scheme: to.scheme,
      host: to.host,
      port: to.port,
      path: '${to.path}$rest',
    );
  }

  /// Whether [url] points at the tailnet server.
  bool handles(Uri url) => target != null && _under(url, target!);

  /// [url] with the tailnet server replaced by the proxy.
  Uri route(Uri url) {
    final t = target;
    final l = local;
    if (t == null || l == null || !_under(url, t)) return url;
    return _rebase(url, t, l);
  }

  /// [url] with the proxy replaced by the tailnet server.
  Uri unroute(Uri url) {
    final t = target;
    final l = local;
    if (t == null || l == null || !_under(url, l)) return url;
    return _rebase(url, l, t);
  }
}

/// State of the built-in Tailscale connection.
@immutable
class TailnetState {
  /// Creates the state.
  const TailnetState({
    this.available = false,
    this.target,
    this.name,
    this.port,
    this.secret,
    this.report = const TailnetReport(TailnetStatus.stopped),
    this.crashed = false,
    this.crashReport,
  });

  /// Whether the previous start ended with the app being killed; the node
  /// is then not started again until the user asks ([TailnetController.retry]).
  final bool crashed;

  /// What is known about that crash, to copy and send to the developer.
  final String? crashReport;

  /// Whether this build has the Tailscale node.
  final bool available;

  /// Music server joined through an invite; `null` when not set up.
  final Uri? target;

  /// Label from the invite.
  final String? name;

  /// Loopback port of the proxy.
  final int? port;

  /// Proxy path secret.
  final String? secret;

  /// Last status report.
  final TailnetReport report;

  /// Whether an invite was used on this device.
  bool get configured => target != null;

  /// Base URL of the proxy.
  Uri? get local => port == null || secret == null
      ? null
      : Uri(scheme: 'http', host: '127.0.0.1', port: port, path: '/$secret');

  /// Copy with some fields replaced.
  TailnetState copyWith({
    int? port,
    TailnetReport? report,
    bool? crashed,
    String? crashReport,
  }) => TailnetState(
    available: available,
    target: target,
    name: name,
    port: port ?? this.port,
    secret: secret,
    report: report ?? this.report,
    crashed: crashed ?? this.crashed,
    crashReport: crashReport ?? this.crashReport,
  );
}

/// Joins, runs and leaves the tailnet of an invite.
@Riverpod(keepAlive: true)
class TailnetController extends _$TailnetController {
  /// Preference keys (none of them secret).
  static const targetKey = 'tailnet.target';

  /// Label of the invite.
  static const nameKey = 'tailnet.name';

  /// Node name in the tailnet.
  static const hostnameKey = 'tailnet.hostname';

  /// Last proxy port.
  static const portKey = 'tailnet.port';

  /// Set while the node starts; still set on the next launch means the app
  /// was killed during the start (crash-loop guard).
  static const startingKey = 'tailnet.starting';

  /// How long the app must survive a start before it counts as good.
  static Duration crashWindow = const Duration(seconds: 20);

  /// How long [join] waits for the first answer.
  @visibleForTesting
  static Duration joinTimeout = const Duration(seconds: 45);

  /// How often the state is checked while connecting / connected
  /// (shortened in tests).
  static Duration fastPoll = const Duration(seconds: 1);

  /// See [fastPoll].
  @visibleForTesting
  static Duration slowPoll = const Duration(seconds: 15);

  Timer? _poll;
  Timer? _survived;
  bool _joining = false;
  DateTime? _lastHeal;

  /// Shortest time between two automatic reconnects.
  static Duration healEvery = const Duration(minutes: 1);
  TailnetSecrets? _secrets;
  Future<void>? _starting;
  final _random = Random.secure();

  TailnetBridge get _bridge => ref.read(tailnetBridgeProvider);

  @override
  TailnetState build() {
    ref.onDispose(() {
      _poll?.cancel();
      _survived?.cancel();
    });
    final boot = ref.watch(tailnetBootstrapProvider);
    // Wi-Fi <-> mobile data: check the connection once the new network
    // has settled.
    ref.listen(onMobileDataProvider, (before, after) {
      final was = before?.value;
      if (was == null || was == after.value) return;
      Future<void>.delayed(
        const Duration(seconds: 3),
        () => ref.mounted ? ensureConnected() : null,
      ).ignore();
    });
    final prefs = ref.watch(preferencesProvider);
    final target = Uri.tryParse(prefs.getString(targetKey) ?? '');
    final secrets = boot.secrets;
    final configured =
        boot.available && target != null && target.hasScheme && secrets != null;
    _secrets = secrets;
    final crashed = configured && (prefs.getBool(startingKey) ?? false);
    final state = TailnetState(
      available: boot.available,
      target: configured ? target : null,
      name: configured ? prefs.getString(nameKey) : null,
      port: configured ? prefs.getInt(portKey) : null,
      secret: secrets?.proxySecret,
      crashed: crashed,
      report: crashed
          ? const TailnetReport(TailnetStatus.error, error: 'crashed')
          : const TailnetReport(TailnetStatus.stopped),
    );
    if (crashed) {
      // The last start killed the app: do not try again by ourselves.
      unawaited(Future.microtask(_loadCrashReport));
    } else if (configured) {
      // After the first frame: the node reconnects in the background.
      unawaited(Future.microtask(() => _ensureStarted(secrets)));
    }
    return state;
  }

  String _hex(int bytes) => [
    for (var i = 0; i < bytes; i++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();

  Future<void> _loadCrashReport() async {
    try {
      final report = await _bridge.lastCrash();
      if (report != null) state = state.copyWith(crashReport: report);
    } on Object catch (error, stack) {
      _log.error('Could not read the crash report', error, stack);
    }
  }

  /// Starts the node again after a crash.
  Future<void> retry() async {
    final secrets =
        _secrets ?? await ref.read(tailnetSecretStoreProvider).read();
    if (secrets == null || !state.configured) return;
    await ref.read(preferencesProvider).remove(startingKey);
    state = state.copyWith(
      crashed: false,
      report: const TailnetReport(TailnetStatus.starting),
    );
    await _ensureStarted(secrets);
  }

  Future<void> _ensureStarted(TailnetSecrets secrets) =>
      _starting ??= _start(secrets).whenComplete(() => _starting = null);

  Future<void> _start(TailnetSecrets secrets, {String authKey = ''}) async {
    final target = state.target;
    if (target == null) return;
    final prefs = ref.read(preferencesProvider);
    var hostname = prefs.getString(hostnameKey);
    if (hostname == null) {
      hostname = 'melody-${_hex(3)}';
      await prefs.setString(hostnameKey, hostname);
    }
    // Cleared once the app has survived the start for a while.
    await prefs.setBool(startingKey, true);
    _survived?.cancel();
    try {
      final port = await _bridge.start(
        hostname: hostname,
        target: target,
        secret: secrets.proxySecret,
        stateKey: secrets.stateKey,
        port: state.port ?? 0,
        authKey: authKey,
      );
      if (port != state.port) await prefs.setInt(portKey, port);
      state = state.copyWith(port: port);
      _schedulePoll(fastPoll);
      _survived = Timer(
        crashWindow,
        () => unawaited(prefs.remove(startingKey)),
      );
    } on Object catch (error, stack) {
      // An error (not a crash): nothing to guard against.
      await prefs.remove(startingKey);
      _log.error('Tailscale did not start', error, stack);
      state = state.copyWith(
        report: TailnetReport(TailnetStatus.error, error: '$error'),
      );
    }
  }

  void _schedulePoll(Duration after) {
    _poll?.cancel();
    _poll = Timer(after, () => unawaited(refresh()));
  }

  /// Reads the node's state now.
  Future<TailnetReport> refresh({bool heal = true}) async {
    if (!state.configured) return state.report;
    try {
      final report = await _bridge.status();
      state = state.copyWith(report: report);
      _schedulePoll(
        report.status == TailnetStatus.running ? slowPoll : fastPoll,
      );
      if (heal && _broken(report) && !_joining) {
        final last = _lastHeal;
        if (last == null || DateTime.now().difference(last) > healEvery) {
          unawaited(_heal());
        }
      }
      return report;
    } on Object catch (error) {
      _schedulePoll(slowPoll);
      return TailnetReport(TailnetStatus.error, error: '$error');
    }
  }

  /// Whether the node is down for a reason a reconnect can fix (not a
  /// missing key or a pending approval).
  static bool _broken(TailnetReport report) =>
      report.status == TailnetStatus.error ||
      report.status == TailnetStatus.stopped;

  Future<void> _heal() async {
    final secrets =
        _secrets ?? await ref.read(tailnetSecretStoreProvider).read();
    if (secrets == null || !state.configured || state.crashed) return;
    _lastHeal = DateTime.now();
    try {
      await _bridge.stop();
    } on Object catch (_) {}
    await _ensureStarted(secrets);
  }

  /// Checks the connection now and reconnects when it is down (pull to
  /// refresh on the home screen, coming back to the app).
  ///
  /// Tailscale may still say "running" after the phone changed networks
  /// while the connection is dead, so the music server is asked through
  /// the proxy too; no answer means a full restart (as Settings does).
  Future<void> ensureConnected() async {
    if (!state.configured || state.crashed || _joining) return;
    final report = await refresh(heal: false);
    if (_broken(report)) {
      await _heal();
      return;
    }
    final local = state.local;
    if (report.status == TailnetStatus.running && local != null) {
      final reachable = await ref.read(tailnetProbeProvider)(local);
      if (!reachable && state.configured && !_joining) await _heal();
    }
  }

  /// Joins the tailnet of [invite]. Only one tailnet can be joined at a
  /// time. The auth key is passed on once and never stored.
  ///
  /// Completes with the first meaningful state: running, waiting for
  /// approval or an error (then nothing is kept).
  Future<TailnetReport> join(TailnetInvite invite) async {
    if (!state.available) {
      return const TailnetReport(TailnetStatus.error, error: 'unavailable');
    }
    if (state.configured) await leave();
    _joining = true;
    try {
      return await _join(invite);
    } finally {
      _joining = false;
    }
  }

  Future<TailnetReport> _join(TailnetInvite invite) async {
    final secrets = TailnetSecrets(
      // 256-bit secrets.
      proxySecret: _hex(32),
      stateKey: _hex(32),
    );
    await ref.read(tailnetSecretStoreProvider).write(secrets);
    _secrets = secrets;
    final prefs = ref.read(preferencesProvider);
    await prefs.setString(targetKey, invite.server.toString());
    if (invite.name case final name?) {
      await prefs.setString(nameKey, name);
    } else {
      await prefs.remove(nameKey);
    }
    await prefs.remove(hostnameKey);
    await prefs.remove(portKey);
    state = TailnetState(
      available: true,
      target: invite.server,
      name: invite.name,
      secret: secrets.proxySecret,
      report: const TailnetReport(TailnetStatus.starting),
    );
    await _start(secrets, authKey: invite.authKey);

    final deadline = DateTime.now().add(joinTimeout);
    var report = state.report;
    while (DateTime.now().isBefore(deadline)) {
      if (state.report.status == TailnetStatus.error) {
        report = state.report;
        break;
      }
      report = await refresh();
      if (report.status
          case TailnetStatus.running ||
              TailnetStatus.needsApproval ||
              TailnetStatus.error) {
        break;
      }
      await Future<void>.delayed(fastPoll);
    }
    if (report.status != TailnetStatus.running &&
        report.status != TailnetStatus.needsApproval) {
      final failed = report.status == TailnetStatus.error
          ? report
          : const TailnetReport(TailnetStatus.error, error: 'timeout');
      await leave();
      return failed;
    }
    return report;
  }

  /// Leaves the tailnet: removes this device from it, deletes its keys and
  /// signs out of the accounts on that server.
  Future<void> leave() async {
    final target = state.target;
    _poll?.cancel();
    try {
      await _bridge.logout();
    } on Object catch (error, stack) {
      _log.error('Tailscale logout failed', error, stack);
    }
    await ref.read(tailnetSecretStoreProvider).delete();
    final prefs = ref.read(preferencesProvider);
    _survived?.cancel();
    _secrets = null;
    for (final key in [targetKey, nameKey, hostnameKey, portKey, startingKey]) {
      await prefs.remove(key);
    }
    final router = TailnetRouter(target: target, local: state.local);
    state = TailnetState(available: state.available);
    if (target == null) return;
    final session = ref.read(sessionControllerProvider.notifier);
    for (final account in [...ref.read(sessionControllerProvider).accounts]) {
      if (router.handles(account.baseUrl)) await session.signOut(account.id);
    }
  }
}

/// Routes requests for the tailnet server through the proxy.
@Riverpod(keepAlive: true)
TailnetRouter tailnetRouter(Ref ref) {
  final (target, local) = ref.watch(
    tailnetControllerProvider.select((s) => (s.target, s.local)),
  );
  return TailnetRouter(target: target, local: local);
}
