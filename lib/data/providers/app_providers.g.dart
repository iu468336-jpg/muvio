// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// See also [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
String _$stremioClientHash() => r'23a316a09742fe2e0cce9534c3fc86be26cad586';

/// See also [stremioClient].
@ProviderFor(stremioClient)
final stremioClientProvider = Provider<MediaProvider>.internal(
  stremioClient,
  name: r'stremioClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stremioClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StremioClientRef = ProviderRef<MediaProvider>;
String _$torrentEngineBridgeHash() =>
    r'1caed905582efe7f68493afba8ddf24b8952091f';

/// See also [torrentEngineBridge].
@ProviderFor(torrentEngineBridge)
final torrentEngineBridgeProvider = Provider<TorrentEngineBridge>.internal(
  torrentEngineBridge,
  name: r'torrentEngineBridgeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$torrentEngineBridgeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TorrentEngineBridgeRef = ProviderRef<TorrentEngineBridge>;
String _$addonRepositoryHash() => r'ee0d757addf2ca865b4410d6d9bbcf504b7c141b';

/// See also [addonRepository].
@ProviderFor(addonRepository)
final addonRepositoryProvider = Provider<AddonRepository>.internal(
  addonRepository,
  name: r'addonRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$addonRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AddonRepositoryRef = ProviderRef<AddonRepository>;
String _$catalogRepositoryHash() => r'30f2c1f9e740ef79d17002cd900e83b7ce6d52bb';

/// See also [catalogRepository].
@ProviderFor(catalogRepository)
final catalogRepositoryProvider = Provider<CatalogRepository>.internal(
  catalogRepository,
  name: r'catalogRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$catalogRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CatalogRepositoryRef = ProviderRef<CatalogRepository>;
String _$libraryRepositoryHash() => r'dc1b2685eb6380fdb375fe85759f1e1fd6fe831a';

/// See also [libraryRepository].
@ProviderFor(libraryRepository)
final libraryRepositoryProvider = Provider<LibraryRepository>.internal(
  libraryRepository,
  name: r'libraryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$libraryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LibraryRepositoryRef = ProviderRef<LibraryRepository>;
String _$settingsRepositoryHash() =>
    r'3438db64b0bb6a4eaff60fcdb439987e740734c8';

/// See also [settingsRepository].
@ProviderFor(settingsRepository)
final settingsRepositoryProvider = Provider<SettingsRepository>.internal(
  settingsRepository,
  name: r'settingsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsRepositoryRef = ProviderRef<SettingsRepository>;
String _$homeCatalogHash() => r'f38aee5ab809e07996309fa15543de241397c380';

/// See also [homeCatalog].
@ProviderFor(homeCatalog)
final homeCatalogProvider = AutoDisposeFutureProvider<List<MediaItem>>.internal(
  homeCatalog,
  name: r'homeCatalogProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$homeCatalogHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeCatalogRef = AutoDisposeFutureProviderRef<List<MediaItem>>;
String _$appSettingsControllerHash() =>
    r'7f81d136028989c203542d58d8c586fcbc15a4df';

/// See also [AppSettingsController].
@ProviderFor(AppSettingsController)
final appSettingsControllerProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>.internal(
  AppSettingsController.new,
  name: r'appSettingsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appSettingsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppSettingsController = AsyncNotifier<AppSettings>;
String _$addonsControllerHash() => r'07687e53f8ab2045fa30c88402a6096e7474aa86';

/// See also [AddonsController].
@ProviderFor(AddonsController)
final addonsControllerProvider =
    AsyncNotifierProvider<AddonsController, List<InstalledAddon>>.internal(
  AddonsController.new,
  name: r'addonsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$addonsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AddonsController = AsyncNotifier<List<InstalledAddon>>;
String _$watchlistControllerHash() =>
    r'90f51d8fbace9eb708e5674afe81590e6871bdf8';

/// See also [WatchlistController].
@ProviderFor(WatchlistController)
final watchlistControllerProvider =
    AsyncNotifierProvider<WatchlistController, List<MediaItem>>.internal(
  WatchlistController.new,
  name: r'watchlistControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchlistControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WatchlistController = AsyncNotifier<List<MediaItem>>;
String _$watchHistoryControllerHash() =>
    r'57b2c5cc1be49fe5293fc8353b41baef43788ee0';

/// See also [WatchHistoryController].
@ProviderFor(WatchHistoryController)
final watchHistoryControllerProvider = AsyncNotifierProvider<
    WatchHistoryController, List<WatchProgressItem>>.internal(
  WatchHistoryController.new,
  name: r'watchHistoryControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchHistoryControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WatchHistoryController = AsyncNotifier<List<WatchProgressItem>>;
String _$downloadsControllerHash() =>
    r'c11be9c235800789aa3100737f4d7dd1058bac11';

/// See also [DownloadsController].
@ProviderFor(DownloadsController)
final downloadsControllerProvider =
    AsyncNotifierProvider<DownloadsController, List<DownloadTaskItem>>.internal(
  DownloadsController.new,
  name: r'downloadsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$downloadsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DownloadsController = AsyncNotifier<List<DownloadTaskItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
