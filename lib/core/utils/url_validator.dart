import 'package:muvio/core/errors/result.dart';

/// Validates addon manifest and resource URLs against SSRF, private IPs,
/// non-HTTPS schemes, and unsafe protocols (`file://`, `javascript:`, etc.).
class UrlSecurityValidator {
  const UrlSecurityValidator._();

  static Result<Uri> validateAddonUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return const Failure(ValidationFailure('URL vide.'));
    }

    var normalized = trimmed;
    if (normalized.startsWith('stremio://')) {
      normalized = 'https://${normalized.substring('stremio://'.length)}';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return const Failure(ValidationFailure('Format URL invalide.'));
    }

    if (uri.scheme.toLowerCase() != 'https') {
      return const Failure(
        ValidationFailure('Seules les URLs HTTPS sécurisées sont autorisées.'),
      );
    }

    final host = uri.host.toLowerCase();
    if (_isPrivateOrLocalHost(host)) {
      return const Failure(
        ValidationFailure('Les adresses locales ou privées sont interdites.'),
      );
    }

    if (!uri.path.endsWith('/manifest.json')) {
      final cleanPath = uri.path.endsWith('/')
          ? '${uri.path}manifest.json'
          : '${uri.path}/manifest.json';
      return Success(uri.replace(path: cleanPath));
    }

    return Success(uri);
  }

  static bool isSafeStreamUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('magnet:?')) {
      return true;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') return false;
    if (scheme == 'http') {
      return uri.host == '127.0.0.1' || uri.host == 'localhost';
    }
    return !_isPrivateOrLocalHost(uri.host.toLowerCase());
  }

  static bool _isPrivateOrLocalHost(String host) {
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1' ||
        host.endsWith('.local') ||
        host.endsWith('.internal')) {
      return true;
    }

    final parts = host.split('.');
    if (parts.length == 4) {
      final octets = parts.map(int.tryParse).toList();
      if (octets.every((o) => o != null && o >= 0 && o <= 255)) {
        final a = octets[0]!;
        final b = octets[1]!;
        if (a == 10 || a == 127 || a == 0) return true;
        if (a == 192 && b == 168) return true;
        if (a == 169 && b == 254) return true;
        if (a == 172 && b >= 16 && b <= 31) return true;
      }
    }
    return false;
  }
}
