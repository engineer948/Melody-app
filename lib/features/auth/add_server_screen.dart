import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/features/auth/auth_providers.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/auth/source_picker.dart';
import 'package:melody/features/settings/widgets/section_header.dart';
import 'package:melody/features/tailnet/tailnet_controller.dart';
import 'package:melody/l10n/l10n.dart';

/// First step of signing in: find or type a server address.
class AddServerScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AddServerScreen({super.key});

  @override
  ConsumerState<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends ConsumerState<AddServerScreen> {
  final _address = TextEditingController();
  final _found = <ServerInfo>[];
  StreamSubscription<ServerInfo>? _scan;
  bool _scanning = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    unawaited(_scan?.cancel());
    _address.dispose();
    super.dispose();
  }

  /// Sources without an address (device files, radio): one tap adds them.
  static bool _isDirect(SourceType type) =>
      type == SourceType.local || type == SourceType.radio;

  void _select(SourceType type) {
    ref.read(selectedSourceTypeProvider.notifier).select(type);
    setState(() => _error = null);
    _startScan();
  }

  Future<void> _addDirect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final connector = ref.read(serverConnectorProvider);
    final probed = await connector.probe('');
    final result = switch (probed) {
      Ok(value: final server) => await connector.signIn(
        server,
        username: '',
        password: '',
      ),
      Err(:final failure) => Err<AuthSession>(failure),
    };
    if (!mounted) return;
    switch (result) {
      case Ok(value: final session):
        await ref.read(sessionControllerProvider.notifier).signedIn(session);
        if (mounted) context.go(AppRoutes.home);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failureMessage(context.l10n, failure);
        });
    }
  }

  void _startScan() {
    unawaited(_scan?.cancel());
    setState(() {
      _found.clear();
      _scanning = true;
    });
    _scan = ref
        .read(serverConnectorProvider)
        .discover()
        .listen(
          (server) => setState(() => _found.add(server)),
          onError: (Object _) => setState(() => _scanning = false),
          onDone: () => setState(() => _scanning = false),
        );
  }

  Future<bool> _confirmInsecure() async {
    final l10n = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_open_outlined),
        title: Text(l10n.insecureTitle),
        content: Text(l10n.insecureBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _connect(String address) async {
    final l10n = context.l10n;
    if (address.trim().isEmpty) {
      setState(() => _error = l10n.connectInvalidAddress);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(serverConnectorProvider).probe(address);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Err(:final failure):
        setState(
          () => _error = switch (failure) {
            NotFoundFailure() ||
            ParsingFailure() ||
            ServerFailure() => l10n.connectNotFound,
            _ => failureMessage(l10n, failure),
          },
        );
      case Ok(value: final server):
        if (server.isInsecure && !await _confirmInsecure()) return;
        if (!mounted) return;
        unawaited(context.push(AppRoutes.loginForServer(server)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final type = ref.watch(selectedSourceTypeProvider);
    final enabled = ref.watch(enabledSourcesProvider);
    final direct = _isDirect(type);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.connectTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    sourceIntro(l10n, type),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (enabled.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SourcePicker(
                      sources: enabled,
                      selected: type,
                      onChanged: _busy ? null : _select,
                    ),
                  ),
                if (direct) ...[
                  if (_error case final error?)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        error,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: _busy ? null : _addDirect,
                      child: Text(l10n.sourceAdd),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _address,
                      enabled: !_busy,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      textInputAction: TextInputAction.go,
                      decoration: InputDecoration(
                        labelText: l10n.connectAddressLabel,
                        hintText: l10n.connectAddressHint,
                        errorText: _error,
                        errorMaxLines: 3,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.dns_outlined),
                      ),
                      onSubmitted: _connect,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: _busy ? null : () => _connect(_address.text),
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.connectButton),
                    ),
                  ),
                  if (type == SourceType.jellyfin &&
                      ref.watch(
                        tailnetControllerProvider.select((s) => s.available),
                      ))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => context.push(AppRoutes.joinTailnet),
                        icon: const Icon(Icons.vpn_lock_outlined),
                        label: Text(l10n.tailnetJoin),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(child: SectionHeader(l10n.connectDiscovered)),
                      if (_scanning)
                        const Padding(
                          padding: EdgeInsets.only(top: 16, right: 24),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 12, right: 8),
                          child: IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: l10n.connectRescan,
                            onPressed: _startScan,
                          ),
                        ),
                    ],
                  ),
                  for (final server in _found)
                    ListTile(
                      leading: const Icon(Icons.router_outlined),
                      title: Text(server.name),
                      subtitle: Text(server.baseUrl.toString()),
                      enabled: !_busy,
                      onTap: () => _connect(server.baseUrl.toString()),
                    ),
                  if (_found.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        _scanning
                            ? l10n.connectSearching
                            : l10n.connectNoneFound,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
