import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Muvio';

  @override
  String get appTagline => 'Unlimited streaming, open to everyone.';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navAddons => 'Addons';

  @override
  String get navLibrary => 'Library';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeOriginalBadge => 'A MUVIO ORIGINAL FILM';

  @override
  String get watchNow => 'Watch';

  @override
  String get myList => 'My List';

  @override
  String get inMyList => 'In My List';

  @override
  String get continueWatching => 'Continue Watching';

  @override
  String get trending => 'Trending';

  @override
  String get newReleases => 'New Releases';

  @override
  String get seeAll => 'See all';

  @override
  String remainingTime(String time) {
    return '$time left';
  }

  @override
  String get addonsTitle => 'Addons';

  @override
  String get stremioAddonsTab => 'Stremio Addons';

  @override
  String get nuvioPluginsTab => 'Nuvio Plugins';

  @override
  String get addAddonByUrlTitle => 'Add addon via URL';

  @override
  String get addAddonByUrlSubtitle =>
      'Enter a Stremio addon URL to install it.';

  @override
  String get addAddonHint => 'https://example.com/manifest.json';

  @override
  String get addButton => 'Add';

  @override
  String get installedBadge => 'Installed';

  @override
  String get installButton => 'Install';

  @override
  String get offlineBadge => 'Offline';

  @override
  String get addonDeleted => 'Addon removed';

  @override
  String get addonInstalledSuccess => 'Addon installed successfully';

  @override
  String get manifestPreviewTitle => 'Manifest Preview';

  @override
  String get confirmInstall => 'Confirm Install';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get searchHint => 'Search movies, series, addons...';

  @override
  String get genreAll => 'All';

  @override
  String get genreAction => 'Action';

  @override
  String get genreDrama => 'Drama';

  @override
  String get genreSciFi => 'Sci-Fi';

  @override
  String get genreAnimation => 'Animation';

  @override
  String get genreComedy => 'Comedy';

  @override
  String get top10Today => 'Top 10 Today';

  @override
  String get noResultsTitle => 'No results found';

  @override
  String get noResultsSubtitle => 'Try another keyword or install more addons.';

  @override
  String get moviesGroup => 'Movies';

  @override
  String get seriesGroup => 'Series';

  @override
  String get channelsGroup => 'Channels';

  @override
  String get libraryTitle => 'My Library';

  @override
  String get openSourceSubtitle => 'open source';

  @override
  String get downloadsTab => 'Downloads';

  @override
  String get historyTab => 'History';

  @override
  String get pauseAll => 'Pause all';

  @override
  String get resumeAll => 'Resume all';

  @override
  String storageUsed(String used, String total) {
    return '$used GB used of $total GB';
  }

  @override
  String get emptyListTitle => 'Your list is empty';

  @override
  String get emptyListSubtitle =>
      'Add movies and shows to your list to find them here.';

  @override
  String get emptyHistoryTitle => 'No playback history';

  @override
  String get emptyHistorySubtitle =>
      'Items you watch will appear here with instant resume.';

  @override
  String get profileUser => 'Muvio User';

  @override
  String get openSourceBadge => 'Open Source';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPlaybackQuality => 'Playback & Quality';

  @override
  String get settingsSubtitlesLanguages => 'Subtitles & Languages';

  @override
  String settingsInstalledAddons(int count) {
    return 'Installed Addons ($count)';
  }

  @override
  String get manageAction => 'Manage';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsUpdates => 'Updates';

  @override
  String get settingsAbout => 'About Muvio';

  @override
  String get openSourceCardTitle => 'Muvio is open source';

  @override
  String get openSourceCardBody =>
      'Muvio is built by the community. Contribute, report issues, or suggest improvements on GitHub.';

  @override
  String get viewOnGithub => 'View on GitHub';

  @override
  String get versionFooter => 'v1.0.4 · Open Source';

  @override
  String get selectSourceTitle => 'Select Source';

  @override
  String get selectSourceSubtitle =>
      'Choose a stream from your installed add-ons.';

  @override
  String sourcesCount(int count) {
    return 'Sources · $count addons';
  }

  @override
  String get legalDisclaimer =>
      'Muvio is an open-source media player and aggregator. The app does not host, store, or distribute copyrighted content. It only plays streams provided by third-party addons voluntarily installed by the user.';

  @override
  String get castSection => 'Cast';

  @override
  String get availableStreams => 'Available Sources';

  @override
  String get downloadAction => 'Download';

  @override
  String get episodesSection => 'Episodes';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get cacheCleared => 'Cache cleared successfully';

  @override
  String get privacyNotice =>
      'Zero telemetry, zero trackers, zero ads. Your data stays strictly on your device.';

  @override
  String get upToDate => 'You are running the latest version (v1.0.4).';
}
