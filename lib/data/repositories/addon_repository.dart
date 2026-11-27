import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/storage/app_database.dart';
import 'package:muvio/core/utils/url_validator.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/seed_catalog.dart';
import 'package:muvio/data/providers/stremio_addon_client.dart';

/// Manages installed Stremio addons, real network manifest installation,
/// persistence in Drift SQLite, and migration away from legacy/broken addons.
class AddonRepository {
  AddonRepository({
    required AppDatabase db,
    required MediaProvider client,
  })  : _db = db,
        _client = client;

  final AppDatabase _db;
  final MediaProvider _client;

  static const String _migrationKey = 'real_addons_v3_migrated';
  static const String _nuvioDirectMigrationKey = 'nuvio_direct_v5_migrated';
  static const String _removedDefaultsKey = 'removed_default_addon_ids';

  /// Obsolete fake or unconfigured 403 directory entries to purge automatically.
  static const Set<String> _legacyOrBrokenAddonIds = {
    'org.muvio.realdebrid',
    'org.muvio.trakt',
    'org.muvio.yts',
    'org.mediafusion.elfhosted',
    'plugin.nuvio.plexbridge',
    'plugin.nuvio.jellyfin',
    'comet.elfhosted.com',
    'stremio.addons.mediafusion|elfhosted',
    'com.linvo.stremiochannels',
  };

  Future<List<InstalledAddon>> loadAddons() async {
    await _migrateLegacyFakeDataIfNeeded();
    await _migrateNuvioDirectV5IfNeeded();

    final rows = await _db.select(_db.addonEntries).get();
    final removedIds = await _loadRemovedDefaultIds();
    final defaults = SeedCatalogData.defaultProposedAddons();

    if (rows.isEmpty) {
      final initial = <InstalledAddon>[];
      for (final item in defaults) {
        if (removedIds.contains(item.id)) continue;
        await _saveAddon(item);
        initial.add(item);
      }
      return initial;
    }

    final result = <InstalledAddon>[];
    final existingIds = <String>{};
    final existingUrls = <String>{};

    for (final row in rows) {
      if (_legacyOrBrokenAddonIds.contains(row.id) ||
          row.manifestUrl.contains('raw.githubusercontent.com/NuvioPlugin')) {
        await (_db.delete(_db.addonEntries)..where((t) => t.id.equals(row.id)))
            .go();
        continue;
      }
      try {
        final decoded = jsonDecode(row.manifestJson) as Map<String, dynamic>;
        final kind =
            decoded['kind'] == 'nuvio' ? AddonKind.nuvio : AddonKind.stremio;
        final manifest = AddonManifest.fromJson(
          decoded,
          kind: kind,
          fallbackUrl: row.manifestUrl,
        );
        existingIds.add(row.id);
        existingUrls.add(row.manifestUrl);
        result.add(
          InstalledAddon(
            id: row.id,
            manifestUrl: row.manifestUrl,
            manifest: manifest,
            installed: row.installed,
            enabled: row.enabled,
            // Clear stale circuit-breaker failures on app startup so temporary
            // network drops never permanently silence an installed addon.
            failureCount: 0,
            accentColorHex: row.accentColorHex,
            shortBadge: row.shortBadge,
            categoryLabel: row.categoryLabel,
          ),
        );
      } catch (_) {
        // Ignore corrupted row safely
      }
    }

    // Ensure verified base & directory addons are available unless user removed them.
    for (final def in defaults) {
      if (!existingIds.contains(def.id) &&
          !existingUrls.contains(def.manifestUrl) &&
          !removedIds.contains(def.id)) {
        await _saveAddon(def);
        result.add(def);
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
      categoryLabel: _inferCategoryLabel(manifest),
    );
    await _saveAddon(addon);
    return Success(addon);
  }

  /// Fetches the live `manifest.json` from the addon's real endpoint before
  /// marking a proposed addon as installed, falling back to the embedded
  /// verified manifest only if offline.
  Future<Result<InstalledAddon>> installProposedAddon(
    InstalledAddon proposed,
  ) async {
    final liveRes = await _client.fetchManifest(proposed.manifestUrl);
    final updated = switch (liveRes) {
      Success<AddonManifest>(:final value) => InstalledAddon(
          id: value.id,
          manifestUrl: proposed.manifestUrl,
          manifest: value,
          installed: true,
          enabled: true,
          accentColorHex: proposed.accentColorHex,
          shortBadge: proposed.shortBadge,
          categoryLabel: proposed.categoryLabel,
        ),
      Failure<AddonManifest>() => proposed.copyWith(
          installed: true,
          enabled: true,
          failureCount: 0,
        ),
    };

    if (updated.id != proposed.id) {
      await (_db.delete(_db.addonEntries)
            ..where((t) => t.id.equals(proposed.id)))
          .go();
    }
    await _saveAddon(updated);
    return Success(updated);
  }

  Future<void> updateAddonState(InstalledAddon updated) async {
    await _saveAddon(updated);
  }

  Future<void> removeAddon(String addonId) async {
    await (_db.delete(_db.addonEntries)..where((t) => t.id.equals(addonId)))
        .go();
    final removed = await _loadRemovedDefaultIds();
    if (removed.add(addonId)) {
      await _db.into(_db.settingEntries).insertOnConflictUpdate(
            SettingEntriesCompanion.insert(
              key: _removedDefaultsKey,
              value: jsonEncode(removed.toList()),
            ),
          );
    }
  }

  Future<void> recordFailure(InstalledAddon addon) async {
    final nextCount = addon.failureCount + 1;
    await _saveAddon(addon.copyWith(failureCount: nextCount));
  }

  Future<void> resetFailures(InstalledAddon addon) async {
    if (addon.failureCount == 0) return;
    await _saveAddon(addon.copyWith(failureCount: 0));
  }

  String _inferCategoryLabel(AddonManifest m) {
    if (m.supportsResource('stream') && m.supportsResource('catalog')) {
      return 'Catalogue & Sources Vidéo';
    }
    if (m.supportsResource('stream')) return 'Sources Vidéo';
    if (m.supportsResource('subtitles')) return 'Sous-titres';
    if (m.supportsResource('catalog')) return 'Catalogue & Métadonnées';
    return 'Films & Séries';
  }

  Future<Set<String>> _loadRemovedDefaultIds() async {
    final row = await (_db.select(_db.settingEntries)
          ..where((t) => t.key.equals(_removedDefaultsKey)))
        .getSingleOrNull();
    if (row == null) return <String>{};
    try {
      final list = jsonDecode(row.value) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _migrateLegacyFakeDataIfNeeded() async {
    final flag = await (_db.select(_db.settingEntries)
          ..where((t) => t.key.equals(_migrationKey)))
        .getSingleOrNull();
    if (flag != null) return;

    // Remove legacy fake or unconfigured 403/0-stream addons
    await (_db.delete(_db.addonEntries)
          ..where((t) => t.id.isIn(_legacyOrBrokenAddonIds.toList())))
        .go();

    // Purge any fake pre-seeded "Continuer à regarder" rows
    await (_db.delete(_db.playbackEntries)
          ..where((t) => t.lastStreamUrl.isNull()))
        .go();

    // Purge fake demo downloads
    await (_db.delete(_db.downloadEntries)
          ..where((t) => t.id.isIn(const ['dl_dune2', 'dl_jw4', 'dl_batman'])))
        .go();

    // Reset all failureCount counters so existing addons work fresh
    await _db
        .update(_db.addonEntries)
        .write(const AddonEntriesCompanion(failureCount: Value(0)));

    await _db.into(_db.settingEntries).insertOnConflictUpdate(
          SettingEntriesCompanion.insert(
            key: _migrationKey,
            value: 'true',
          ),
        );
  }

  /// Ensures users upgrading from Muvio v1.0.0–v1.0.4 automatically get
  /// Nuvio Direct HTTP scrapers + Torrentio Lite enabled out-of-the-box.
  Future<void> _migrateNuvioDirectV5IfNeeded() async {
    final flag = await (_db.select(_db.settingEntries)
          ..where((t) => t.key.equals(_nuvioDirectMigrationKey)))
        .getSingleOrNull();
    if (flag != null) return;

    final defaults = SeedCatalogData.defaultProposedAddons();
    for (final def in defaults) {
      if (def.installed && def.enabled) {
        await _saveAddon(def);
      }
    }

    await _db.into(_db.settingEntries).insertOnConflictUpdate(
          SettingEntriesCompanion.insert(
            key: _nuvioDirectMigrationKey,
            value: 'true',
          ),
        );
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
