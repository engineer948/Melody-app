import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/data/repositories/source_factory.dart';
import 'package:melody/features/auth/source_picker.dart';
import 'package:melody/l10n/l10n.dart';

/// Debug builds only: checks any source, also the hidden ones, against an
/// address without signing in.
class DebugSourcesScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const DebugSourcesScreen({super.key});

  @override
  ConsumerState<DebugSourcesScreen> createState() => _State();
}

class _State extends ConsumerState<DebugSourcesScreen> {
  final _address = TextEditingController();
  SourceType _type = SourceType.subsonic;
  String _log = '';
  bool _busy = false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _probe() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final connector = createServerConnector(
      _type,
      ref.read(clientIdentityProvider),
    );
    final result = await connector.probe(_address.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _log = switch (result) {
        Ok(:final value) =>
          '✓ ${value.name}\n${value.baseUrl}\n${value.version ?? ''}',
        Err(:final failure) => '✗ ${failureMessage(l10n, failure)}',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.debugSourcesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ENABLED_SOURCES: '
            '${FeatureFlags.enabledSources.map((s) => s.name).join(', ')}',
          ),
          const SizedBox(height: 16),
          SourcePicker(
            sources: SourceType.values.toSet(),
            selected: _type,
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _address,
            decoration: InputDecoration(
              labelText: l10n.connectAddressLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _probe,
            child: Text(l10n.debugSourcesProbe),
          ),
          const SizedBox(height: 16),
          SelectableText(_log),
        ],
      ),
    );
  }
}
