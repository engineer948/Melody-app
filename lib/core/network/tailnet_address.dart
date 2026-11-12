/// Addresses that are only reachable inside a Tailscale network.
abstract final class TailnetAddress {
  /// Whether [host] is a Tailscale IP (100.64.0.0/10, fd7a:115c:a1e0::/48)
  /// or a MagicDNS name (`*.ts.net`).
  ///
  /// Traffic to these hosts travels inside WireGuard, so plain HTTP to them
  /// is still encrypted.
  static bool isTailnetHost(String host) {
    final h = host.toLowerCase();
    if (h.endsWith('.ts.net') && h.length > '.ts.net'.length) return true;
    final v4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$')
        .firstMatch(h);
    if (v4 != null) {
      final octets = [for (var i = 1; i <= 4; i++) int.parse(v4.group(i)!)];
      if (octets.any((o) => o > 255)) return false;
      return octets[0] == 100 && octets[1] >= 64 && octets[1] <= 127;
    }
    final v6 = h.replaceAll('[', '').replaceAll(']', '');
    return v6.startsWith('fd7a:115c:a1e0:');
  }
}
