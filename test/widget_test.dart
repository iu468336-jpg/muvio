import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muvio/app.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/theme/app_theme.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/app_settings.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/models/seed_catalog.dart';
import 'package:muvio/data/providers/app_providers.dart';
import 'package:muvio/data/providers/stremio_addon_client.dart';
import 'package:muvio/data/repositories/addon_repository.dart';
import 'package:muvio/data/repositories/library_repository.dart';
import 'package:muvio/data/repositories/settings_repository.dart';
import 'package:muvio/features/player/player_screen.dart';
import 'package:muvio/l10n/app_localizations.dart';

class _FakeMediaProvider implements MediaProvider {
  const _FakeMediaProvider();

  @override
  Future<Result<List<MediaItem>>> fetchCatalog({
    required InstalledAddon addon,
    required String type,
    required String catalogId,
    int skip = 0,
    String? searchQuery,
  }) async =>
      const Success([]);

  @override
  Future<Result<AddonManifest>> fetchManifest(String rawManifestUrl) async =>
      const Failure(NetworkFailure('Mock offline'));

  @override
  Future<Result<MediaItem>> fetchMeta({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
  }) async =>
      const Failure(NetworkFailure('Mock offline'));

  @override
  Future<Result<List<StreamSource>>> fetchStreams({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
  }) async =>
      const Success([]);

  @override
  Future<Result<List<SubtitleTrackItem>>> fetchSubtitles({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
    String? videoHash,
    String? filename,
  }) async =>
      const Success([]);
}

class _InMemoryAddonRepo implements AddonRepository {
  final List<InstalledAddon> _items = SeedCatalogData.defaultProposedAddons();

  @override
  Future<List<InstalledAddon>> loadAddons() async => List.of(_items);

  @override
  Future<Result<AddonManifest>> previewManifest(String rawUrl) async =>
      const Failure(NetworkFailure('Mock'));

  @override
  Future<Result<InstalledAddon>> installFromManifest({
    required String rawUrl,
    required AddonManifest manifest,
  }) async {
    final added = InstalledAddon(
      id: manifest.id,
      manifestUrl: rawUrl,
      manifest: manifest,
      installed: true,
      enabled: true,
    );
    _items.insert(0, added);
    return Success(added);
  }

  @override
  Future<Result<InstalledAddon>> installProposedAddon(
    InstalledAddon proposed,
  ) async {
    final updated = proposed.copyWith(installed: true, enabled: true);
    return Success(updated);
  }

  @override
  Future<void> recordFailure(InstalledAddon addon) async {}

  @override
  Future<void> removeAddon(String addonId) async {
    _items.removeWhere((a) => a.id == addonId);
  }

  @override
  Future<void> resetFailures(InstalledAddon addon) async {}

  @override
  Future<void> updateAddonState(InstalledAddon updated) async {}
}

class _InMemoryLibraryRepo implements LibraryRepository {
  @override
  Future<void> addToWatchlist(MediaItem item) async {}

  @override
  Future<void> deleteDownload(String id) async {}

  @override
  Future<List<DownloadTaskItem>> loadDownloads() async => [
        const DownloadTaskItem(
          id: 'dl_dune2',
          mediaId: 'tt15239678',
          title: 'Dune: Part Two',
          thumbnail: '',
          quality: '1080p',
          totalBytes: 1800000000,
          downloadedBytes: 1170000000,
          status: DownloadStatus.downloading,
          streamUrl: SeedCatalogData.sampleVideoHls,
        ),
      ];

  @override
  Future<List<WatchProgressItem>> loadWatchHistory() async => [
        WatchProgressItem(
          media: SeedCatalogData.heroItems[1],
          positionSeconds: 2640,
          durationSeconds: 10000,
          episodeBadge: '2h 46m restantes',
          updatedAt: DateTime(2026),
        ),
      ];

  @override
  Future<List<MediaItem>> loadWatchlist() async =>
      SeedCatalogData.catalogItems.take(3).toList();

  @override
  Future<void> removeFromWatchlist(String mediaId) async {}

  @override
  Future<void> saveWatchProgress(WatchProgressItem progress) async {}

  @override
  Future<void> upsertDownload(DownloadTaskItem item) async {}
}

class _InMemorySettingsRepo implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  Future<AppSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}

void main() {
  setUpAll(AppTheme.configureFonts);

  List<Override> testOverrides() => [
        stremioClientProvider.overrideWithValue(const _FakeMediaProvider()),
        addonRepositoryProvider.overrideWithValue(_InMemoryAddonRepo()),
        libraryRepositoryProvider.overrideWithValue(_InMemoryLibraryRepo()),
        settingsRepositoryProvider.overrideWithValue(_InMemorySettingsRepo()),
      ];

  testWidgets(
      'Renders all 5 bottom tabs (Accueil, Recherche, Addons, Bibliothèque, Profil)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(),
        child: const MuvioApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    // Screen 1: Accueil
    expect(find.text('MUVIO'), findsWidgets);
    expect(find.text('Continuer à regarder'), findsOneWidget);

    // Screen 4: Recherche
    await tester.tap(find.text('Recherche'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text("Top 10 aujourd'hui"), findsOneWidget);

    // Screen 2: Addons
    await tester.tap(find.text('Addons'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Ajouter un addon via URL'), findsOneWidget);

    // Screen 5: Bibliothèque
    await tester.tap(find.text('Bibliothèque'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Ma bibliothèque'), findsOneWidget);

    // Screen 6: Profil
    await tester.tap(find.text('Profil'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Muvio User'), findsOneWidget);
  });

  testWidgets('Renders Portrait & Landscape Player screens without exceptions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(),
        child: MaterialApp(
          theme: AppTheme.build(),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const PlayerScreen(
            mediaType: 'movie',
            mediaId: 'tt0816692',
            enableNativePlayer: false,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Screen 3: Portrait player
    expect(find.text('Select Source'), findsOneWidget);
    expect(find.text('Interstellar'), findsOneWidget);

    // Screen 7: Landscape fullscreen 16:9 player
    await tester.binding.setSurfaceSize(const Size(1024, 576));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('INTERSTELLAR'), findsOneWidget);
  });
}
