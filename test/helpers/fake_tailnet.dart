import 'package:melody/data/tailnet/tailnet_bridge.dart';

/// [TailnetBridge] that answers from a script instead of running Go.
class FakeTailnetBridge implements TailnetBridge {
  /// Reports returned by [status], in order; the last one repeats.
  List<TailnetReport> reports = [
    const TailnetReport(TailnetStatus.running, ip: '100.64.0.9', port: 41641),
  ];

  /// Arguments of every [start] call.
  final starts = <Map<String, Object>>[];

  /// How many times [logout] ran.
  int logouts = 0;

  /// Port [start] answers with.
  int port = 41641;

  @override
  Future<bool> available() async => true;

  @override
  Future<int> start({
    required String hostname,
    required Uri target,
    required String secret,
    required String stateKey,
    required int port,
    String authKey = '',
  }) async {
    starts.add({
      'hostname': hostname,
      'target': target.toString(),
      'secret': secret,
      'stateKey': stateKey,
      'port': port,
      'authKey': authKey,
    });
    return this.port;
  }

  @override
  Future<TailnetReport> status() async =>
      reports.length > 1 ? reports.removeAt(0) : reports.single;

  @override
  Future<void> stop() async {}

  @override
  Future<void> logout() async => logouts++;

  /// Answer of [lastCrash].
  String? crash;

  @override
  Future<String?> lastCrash() async => crash;
}
