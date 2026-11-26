import 'package:muvio/core/errors/result.dart';

/// Validates addon manifest and resource URLs against SSRF, private IPs,
/// and unsafe protocols (`file://`, `javascript:`, etc.), while normalizing
/// user-entered URLs (missing scheme, `/configure`, `stremio://`, etc.).
class UrlSecurityValidator {
  const UrlSecurityValidator._();

  static Result<Uri> validateAddonUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return const Failure(ValidationFailure('URL vide.'));
    }

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('file:') ||
        lower.startsWith('javascript:') ||
        lower.startsWith('data:') ||
        lower.startsWith('vbscript:') ||
        lower.startsWith('http://')) {
      return const Failure(
        ValidationFailure('Seules les URLs HTTPS sécurisées sont autorisées.'),
      );
    }

    var normalized = trimmed;
    if (lower.startsWith('stremio://')) {
      normalized = 'https://${trimmed.substring('stremio://'.length)}';
    } else if (!normalized.contains('://')) {
      normalized = 'https://$normalized';
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

    var path = uri.path;
    if (path.endsWith('/configure/')) {
      path = path.substring(0, path.length - '/configure/'.length);
    } else if (path.endsWith('/configure')) {
      path = path.substring(0, path.length - '/configure'.length);
    }

    if (!path.endsWith('.json')) {
      final cleanPath =
          path.endsWith('/') ? '${path}manifest.json' : '$path/manifest.json';
      return Success(uri.replace(path: cleanPath));
    }

    return Success(uri.replace(path: path));
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
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    if (host == '127.0.0.1' || host == 'localhost') {
      return true;
    }
    return !_isPrivateOrLocalHost(host);
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
