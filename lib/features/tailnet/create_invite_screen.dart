import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:melody/data/tailnet/invite_code.dart';
import 'package:melody/features/tailnet/qr_code.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Tag the invite keys should carry; used in the access rule.
const friendTag = 'tag:melody-friend';

/// Tailscale policy snippet that lets invited devices reach only [server].
String accessRuleFor(Uri? server) {
  final dst = server == null
      ? '100.x.y.z:8096'
      : '${server.host.contains(':') ? '[${server.host}]' : server.host}'
            ':${server.port}';
  return '''
// Melody: invited friends can only reach the music server.
"tagOwners": {
  "$friendTag": ["autogroup:admin"]
},
"acls": [
  // Your own devices: everything, as before (also exit nodes).
  {"action": "accept", "src": ["autogroup:member"], "dst": ["*:*"]},
  // Invited friends: only the music server.
  {"action": "accept", "src": ["$friendTag"], "dst": ["$dst"]}
]''';
}

/// Packs a Tailscale auth key and the server address into an invite code
/// and QR code for a friend. Nothing entered here is stored.
class CreateInviteScreen extends StatefulWidget {
  /// Creates the screen.
  const CreateInviteScreen({super.key});

  /// Opens the screen.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CreateInviteScreen()));

  @override
  State<CreateInviteScreen> createState() => _CreateInviteScreenState();
}

class _CreateInviteScreenState extends State<CreateInviteScreen> {
  final _key = TextEditingController();
  final _server = TextEditingController();
  final _name = TextEditingController();
  bool _showKey = false;
  String? _keyError;
  String? _serverError;
  String? _code;

  @override
  void initState() {
    super.initState();
    _server.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _key.dispose();
    _server.dispose();
    _name.dispose();
    super.dispose();
  }

  void _create() {
    final l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final keyOk = TailnetInvite.isAuthKey(_key.text.trim());
    final serverOk = TailnetInvite.parseServer(_server.text) != null;
    setState(() {
      _keyError = keyOk ? null : l10n.tailnetErrorNotAuthKey;
      _serverError = serverOk ? null : l10n.tailnetErrorNotTailnet;
      _code = keyOk && serverOk
          ? TailnetInvite.create(
              authKey: _key.text,
              server: _server.text,
              name: _name.text,
            ).encode()
          : null;
    });
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Rect? _origin(BuildContext button) {
    final box = button.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareText(BuildContext button, String code) => SharePlus
      .instance
      .share(ShareParams(text: code, sharePositionOrigin: _origin(button)));

  Future<void> _shareQr(BuildContext button, String code) async {
    final origin = _origin(button);
    final png = await qrPng(code);
    final dir = Directory('${(await getTemporaryDirectory()).path}/share');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final file = File('${dir.path}/melody-invite.png');
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final code = _code;
    final rule = accessRuleFor(TailnetInvite.parseServer(_server.text));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tailnetInviteCreate)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.tailnetInviteIntro, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                _Checklist(rule: rule, onCopied: _snack),
                const SizedBox(height: 16),
                TextField(
                  controller: _key,
                  obscureText: !_showKey,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (_) => setState(() => _code = null),
                  decoration: InputDecoration(
                    labelText: l10n.tailnetAuthKeyLabel,
                    hintText: 'tskey-auth-…',
                    errorText: _keyError,
                    errorMaxLines: 3,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showKey ? Icons.visibility_off : Icons.visibility,
                      ),
                      tooltip: _showKey
                          ? l10n.tailnetHideKey
                          : l10n.tailnetShowKey,
                      onPressed: () => setState(() => _showKey = !_showKey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _server,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() => _code = null),
                  decoration: InputDecoration(
                    labelText: l10n.tailnetServerLabel,
                    hintText: l10n.tailnetServerHint,
                    errorText: _serverError,
                    errorMaxLines: 3,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.dns_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() => _code = null),
                  decoration: InputDecoration(
                    labelText: l10n.tailnetNameLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _create,
                  child: Text(l10n.tailnetInviteGenerate),
                ),
                if (code != null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: QrCodeView(data: code, size: 260),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          _snack(l10n.tailnetInviteCopied);
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(l10n.tailnetInviteCopy),
                      ),
                      Builder(
                        builder: (button) => OutlinedButton.icon(
                          onPressed: () => _shareText(button, code),
                          icon: const Icon(Icons.share_outlined),
                          label: Text(l10n.tailnetInviteShareText),
                        ),
                      ),
                      Builder(
                        builder: (button) => OutlinedButton.icon(
                          onPressed: () => _shareQr(button, code),
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: Text(l10n.tailnetInviteShareQr),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      title: Text(
                        l10n.tailnetInviteSecretWarning,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
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

class _Checklist extends StatelessWidget {
  const _Checklist({required this.rule, required this.onCopied});

  final String rule;
  final void Function(String) onCopied;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final items = [
      l10n.tailnetChecklist1,
      l10n.tailnetChecklist2,
      l10n.tailnetChecklist3,
      l10n.tailnetChecklist4,
      l10n.tailnetChecklist5,
    ];
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.shield_outlined),
        title: Text(l10n.tailnetChecklistTitle),
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, item) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${i + 1}. $item'),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              rule,
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: rule));
              onCopied(l10n.tailnetAclCopied);
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(l10n.tailnetAclCopy),
          ),
        ],
      ),
    );
  }
}
