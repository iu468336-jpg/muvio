import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/storage/app_database.dart';
import 'package:muvio/core/utils/url_validator.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/seed_catalog.dart';
import 'package:muvio/data/providers/stremio_addon_client.dart';

/// Manages installed Stremio addons, Nuvio plugins, manifest validation,
/// persistence in Drift SQLite, and circuit-breaker health counters.
class AddonRepository {
  AddonRepository({
    required AppDatabase db,
    required MediaProvider client,
  })  : _db = db,
        _client = client;

  final AppDatabase _db;
  final MediaProvider _client;

  Future<List<InstalledAddon>> loadAddons() async {
    final rows = await _db.select(_db.addonEntries).get();
    if (rows.isEmpty) {
      final defaults = SeedCatalogData.defaultProposedAddons();
      for (final item in defaults) {
        await _saveAddon(item);
      }
      return defaults;
    }

    final result = <InstalledAddon>[];
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row.manifestJson) as Map<String, dynamic>;
        final kind =
            decoded['kind'] == 'nuvio' ? AddonKind.nuvio : AddonKind.stremio;
        final manifest = AddonManifest.fromJson(decoded, kind: kind);
        result.add(
          InstalledAddon(
            id: row.id,
            manifestUrl: row.manifestUrl,
            manifest: manifest,
            installed: row.installed,
            enabled: row.enabled,
            failureCount: row.failureCount,
            accentColorHex: row.accentColorHex,
            shortBadge: row.shortBadge,
            categoryLabel: row.categoryLabel,
          ),
        );
      } catch (_) {
        // Ignore corrupted row safely
      }
    }
    return result;
  }

  Future<Result<AddonManifest>> previewManifest(String rawUrl) {
    return _client.fetchManifest(rawUrl);
  }

  Future<Result<InstalledAddon>> installFromManifest({
    required String rawUrl,
    required AddonManifest manifest,
  }) async {
    final validated = UrlSecurityValidator.validateAddonUrl(rawUrl);
    if (validated is Failure<Uri>) {
      return Failure(validated.failure);
    }

    final cleanUrl = (validated as Success<Uri>).value.toString();
    final badge = manifest.name.length >= 3
        ? manifest.name.substring(0, 3).toUpperCase()
        : manifest.name.toUpperCase();

    final addon = InstalledAddon(
      id: manifest.id,
      manifestUrl: cleanUrl,
      manifest: manifest,
      installed: true,
      enabled: true,
      shortBadge: badge,
      categoryLabel:
          manifest.kind == AddonKind.nuvio ? 'Nuvio Plugin' : 'Films & Séries',
    );
    await _saveAddon(addon);
    return Success(addon);
  }

  Future<void> updateAddonState(InstalledAddon updated) async {
    await _saveAddon(updated);
  }

  Future<void> removeAddon(String addonId) async {
    await (_db.delete(_db.addonEntries)..where((t) => t.id.equals(addonId)))
        .go();
  }

  Future<void> recordFailure(InstalledAddon addon) async {
    final nextCount = addon.failureCount + 1;
    await _saveAddon(addon.copyWith(failureCount: nextCount));
  }

  Future<void> resetFailures(InstalledAddon addon) async {
    if (addon.failureCount == 0) return;
    await _saveAddon(addon.copyWith(failureCount: 0));
  }

  Future<void> _saveAddon(InstalledAddon addon) async {
    await _db.into(_db.addonEntries).insertOnConflictUpdate(
          AddonEntriesCompanion.insert(
            id: addon.id,
            manifestUrl: addon.manifestUrl,
            manifestJson: jsonEncode(addon.manifest.toJson()),
            installed: Value(addon.installed),
            enabled: Value(addon.enabled),
            failureCount: Value(addon.failureCount),
            accentColorHex: Value(addon.accentColorHex),
            shortBadge: Value(addon.shortBadge),
            categoryLabel: Value(addon.categoryLabel),
          ),
        );
  }
}
