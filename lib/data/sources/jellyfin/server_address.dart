/// Turns what a user typed into server addresses worth trying.
abstract final class ServerAddress {
  /// Default Jellyfin HTTP port.
  static const defaultHttpPort = 8096;

  /// Default Jellyfin HTTPS port.
  static const defaultHttpsPort = 8920;

  /// Candidate base URLs for [input], most likely first.
  ///
  /// A missing scheme yields both HTTPS and HTTP variants; a missing port
  /// additionally yields the Jellyfin default port. Returns an empty list
  /// when [input] cannot be an address.
  static List<Uri> candidates(String input) {
    var text = input.trim();
    if (text.isEmpty || text.contains(RegExp(r'\s'))) return const [];
    while (text.endsWith('/')) {
      text = text.substring(0, text.length - 1);
    }
    final hasScheme = RegExp('^https?://', caseSensitive: false).hasMatch(text);
    if (!hasScheme && text.contains('://')) return const [];

    final results = <Uri>[];
    void add(String scheme, String rest) {
      final uri = Uri.tryParse('$scheme://$rest');
      if (uri == null || uri.host.isEmpty) return;
      final normalized = _normalize(uri);
      if (!results.contains(normalized)) results.add(normalized);
      final authority = rest.split('/').first;
      if (!RegExp(r':\d+$').hasMatch(authority)) {
        final port = scheme == 'https' ? defaultHttpsPort : defaultHttpPort;
        final withPort = _normalize(uri.replace(port: port));
        if (!results.contains(withPort)) results.add(withPort);
      }
    }

    if (hasScheme) {
      final index = text.indexOf('://');
      add(text.substring(0, index).toLowerCase(), text.substring(index + 3));
    } else {
      add('https', text);
      add('http', text);
    }
    return results;
  }

  static Uri _normalize(Uri uri) {
    var path = uri.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
    );
  }
}
