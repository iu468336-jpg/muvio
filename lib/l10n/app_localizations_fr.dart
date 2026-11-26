import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Muvio';

  @override
  String get appTagline => 'Le streaming sans limites, ouvert à tous.';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navAddons => 'Addons';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeOriginalBadge => 'UN FILM ORIGINAL MUVIO';

  @override
  String get watchNow => 'Regarder';

  @override
  String get myList => 'Ma liste';

  @override
  String get inMyList => 'Dans ma liste';

  @override
  String get continueWatching => 'Continuer à regarder';

  @override
  String get trending => 'Tendances';

  @override
  String get newReleases => 'Nouveautés';

  @override
  String get seeAll => 'Voir tout';

  @override
  String remainingTime(String time) {
    return '$time restantes';
  }

  @override
  String get addonsTitle => 'Addons';

  @override
  String get stremioAddonsTab => 'Sources Vidéo (Flux)';

  @override
  String get nuvioPluginsTab => 'Catalogues & Sous-titres';

  @override
  String get addAddonByUrlTitle => 'Ajouter un addon via URL';

  @override
  String get addAddonByUrlSubtitle =>
      'Entrez l\'URL d\'un addon Stremio pour l\'installer.';

  @override
  String get addAddonHint => 'https://exemple.com/manifest.json';

  @override
  String get addButton => 'Ajouter';

  @override
  String get installedBadge => 'Installé';

  @override
  String get installButton => 'Installer';

  @override
  String get offlineBadge => 'Hors ligne';

  @override
  String get addonDeleted => 'Addon supprimé';

  @override
  String get addonInstalledSuccess => 'Addon installé avec succès';

  @override
  String get manifestPreviewTitle => 'Aperçu du Manifest';

  @override
  String get confirmInstall => 'Confirmer l\'installation';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get searchHint => 'Rechercher films, séries, addons...';

  @override
  String get genreAll => 'Tout';

  @override
  String get genreAction => 'Action';

  @override
  String get genreDrama => 'Drame';

  @override
  String get genreSciFi => 'Sci-Fi';

  @override
  String get genreAnimation => 'Animation';

  @override
  String get genreComedy => 'Comédie';

  @override
  String get top10Today => 'Top 10 aujourd\'hui';

  @override
  String get noResultsTitle => 'Aucun résultat trouvé';

  @override
  String get noResultsSubtitle =>
      'Essayez un autre mot-clé ou installez davantage d\'addons.';

  @override
  String get moviesGroup => 'Films';

  @override
  String get seriesGroup => 'Séries';

  @override
  String get channelsGroup => 'Chaînes';

  @override
  String get libraryTitle => 'Ma bibliothèque';

  @override
  String get openSourceSubtitle => 'open source';

  @override
  String get downloadsTab => 'Téléchargements';

  @override
  String get historyTab => 'Historique';

  @override
  String get pauseAll => 'Tout mettre en pause';

  @override
  String get resumeAll => 'Tout reprendre';

  @override
  String storageUsed(String used, String total) {
    return '$used Go utilisés sur $total Go';
  }

  @override
  String get emptyListTitle => 'Votre liste est vide';

  @override
  String get emptyListSubtitle =>
      'Ajoutez des films et séries à votre liste pour les retrouver ici.';

  @override
  String get emptyHistoryTitle => 'Aucun historique';

  @override
  String get emptyHistorySubtitle =>
      'Les contenus que vous regardez apparaîtront ici avec reprise automatique.';

  @override
  String get profileUser => 'Muvio User';

  @override
  String get openSourceBadge => 'Open Source';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsPlaybackQuality => 'Lecture & Qualité';

  @override
  String get settingsSubtitlesLanguages => 'Sous-titres & Langues';

  @override
  String settingsInstalledAddons(int count) {
    return 'Addons installés ($count)';
  }

  @override
  String get manageAction => 'Gérer';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsUpdates => 'Mises à jour';

  @override
  String get settingsAbout => 'À propos de Muvio';

  @override
  String get openSourceCardTitle => 'Muvio est open source';

  @override
  String get openSourceCardBody =>
      'Muvio est développé par la communauté. Contribuez, signalez des problèmes ou proposez des améliorations sur GitHub.';

  @override
  String get viewOnGithub => 'Voir sur GitHub';

  @override
  String get versionFooter => 'v1.0.2 · Open Source';

  @override
  String get selectSourceTitle => 'Choisir une source';

  @override
  String get selectSourceSubtitle =>
      'Sélectionnez un flux depuis vos addons installés.';

  @override
  String sourcesCount(int count) {
    return 'Sources · $count addons';
  }

  @override
  String get legalDisclaimer =>
      'Muvio est un lecteur et agrégateur multimédia open source. L\'application n\'héberge, ne stocke et ne distribue aucun contenu protégé. Elle lit uniquement les flux fournis par les addons tiers installés volontairement par l\'utilisateur.';

  @override
  String get castSection => 'Distribution';

  @override
  String get availableStreams => 'Sources disponibles';

  @override
  String get downloadAction => 'Télécharger';

  @override
  String get episodesSection => 'Épisodes';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get cacheCleared => 'Cache vidé avec succès';

  @override
  String get privacyNotice =>
      'Aucune télémétrie, aucun tracker, aucune publicité. Vos données restent strictement sur votre appareil.';

  @override
  String get upToDate => 'Vous utilisez la dernière version (v1.0.2).';
}
