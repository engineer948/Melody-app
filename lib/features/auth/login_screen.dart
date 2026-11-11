import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/features/auth/auth_providers.dart';
import 'package:melody/features/auth/quick_connect_dialog.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/auth/widgets/public_user_list.dart';
import 'package:melody/l10n/l10n.dart';

/// Second step of signing in: credentials or Quick Connect.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates the sign-in screen of [server].
  const LoginScreen({
    required this.server,
    this.initialUserName,
    this.expired = false,
    super.key,
  });

  /// Server to sign in to.
  final ServerInfo server;

  /// User name to pre-fill.
  final String? initialUserName;

  /// Whether a saved session of this server was rejected.
  final bool expired;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final _user = TextEditingController(text: widget.initialUserName);
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _finish(AuthSession session) async {
    await ref.read(sessionControllerProvider.notifier).signedIn(session);
    if (mounted) context.go(AppRoutes.home);
  }

  Future<void> _signIn() async {
    final l10n = context.l10n;
    final username = _user.text.trim();
    if (username.isEmpty) {
      setState(() => _error = l10n.loginUsernameRequired);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(serverConnectorProvider)
        .signIn(widget.server, username: username, password: _password.text);
    _password.clear();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        await _finish(value);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure is UnauthorizedFailure
              ? l10n.loginFailed
              : failureMessage(l10n, failure);
        });
    }
  }

  Future<void> _quickConnect() async {
    final session = await showDialog<AuthSession>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuickConnectDialog(server: widget.server),
    );
    if (session != null && mounted) {
      setState(() => _busy = true);
      await _finish(session);
    }
  }

  void _pickUser(PublicUser user) {
    setState(() => _user.text = user.name);
    if (user.hasPassword) {
      _passwordFocus.requestFocus();
    } else {
      unawaited(_signIn());
    }
  }

  Future<void> _removeExpired() async {
    final session = ref.read(sessionControllerProvider);
    final id = session.activeId;
    if (id != null) {
      await ref.read(sessionControllerProvider.notifier).signOut(id);
    }
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final server = widget.server;
    final users = ref.watch(publicUsersProvider(server)).value ?? const [];
    final quickConnect =
        ref.watch(quickConnectAvailableProvider(server)).value ?? false;
    final version = server.version;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
        actions: [
          if (widget.expired)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.accountSignOut,
              onPressed: _removeExpired,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AutofillGroup(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.expired)
                    Card(
                      color: theme.colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l10n.loginSessionExpired,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      server.isInsecure
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline,
                    ),
                    title: Text(server.name),
                    subtitle: Text(
                      [
                        server.baseUrl.toString(),
                        if (version != null) l10n.loginServerVersion(version),
                      ].join('\n'),
                    ),
                    isThreeLine: version != null,
                  ),
                  if (users.isNotEmpty)
                    PublicUserList(users: users, onSelected: _pickUser),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _user,
                    enabled: !_busy,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.loginUsername,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    enabled: !_busy,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.loginPassword,
                      errorText: _error,
                      errorMaxLines: 3,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: _obscure
                            ? l10n.loginShowPassword
                            : l10n.loginHidePassword,
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    onSubmitted: (_) => _signIn(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.loginButton),
                  ),
                  if (quickConnect) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _quickConnect,
                      icon: const Icon(Icons.pin_outlined),
                      label: Text(l10n.loginQuickConnect),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
