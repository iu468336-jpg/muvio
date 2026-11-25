import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key-value storage wrapper for Trakt OAuth tokens & Real-Debrid API keys.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _traktTokenKey = 'muvio.trakt.access_token';
  static const _debridKey = 'muvio.realdebrid.api_key';

  Future<String?> getTraktToken() => _storage.read(key: _traktTokenKey);

  Future<void> setTraktToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _storage.delete(key: _traktTokenKey);
    } else {
      await _storage.write(key: _traktTokenKey, value: token.trim());
    }
  }

  Future<String?> getDebridApiKey() => _storage.read(key: _debridKey);

  Future<void> setDebridApiKey(String? apiKey) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      await _storage.delete(key: _debridKey);
    } else {
      await _storage.write(key: _debridKey, value: apiKey.trim());
    }
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return const SecureStorageService(storage);
});
