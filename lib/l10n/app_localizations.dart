import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Muvio'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In fr, this message translates to:
  /// **'Le streaming sans limites, ouvert à tous.'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get navSearch;

  /// No description provided for @navAddons.
  ///
  /// In fr, this message translates to:
  /// **'Addons'**
  String get navAddons;

  /// No description provided for @navLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque'**
  String get navLibrary;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @homeOriginalBadge.
  ///
  /// In fr, this message translates to:
  /// **'UN FILM ORIGINAL MUVIO'**
  String get homeOriginalBadge;

  /// No description provided for @watchNow.
  ///
  /// In fr, this message translates to:
  /// **'Regarder'**
  String get watchNow;

  /// No description provided for @myList.
  ///
  /// In fr, this message translates to:
  /// **'Ma liste'**
  String get myList;

  /// No description provided for @inMyList.
  ///
  /// In fr, this message translates to:
  /// **'Dans ma liste'**
  String get inMyList;

  /// No description provided for @continueWatching.
  ///
  /// In fr, this message translates to:
  /// **'Continuer à regarder'**
  String get continueWatching;

  /// No description provided for @trending.
  ///
  /// In fr, this message translates to:
  /// **'Tendances'**
  String get trending;

  /// No description provided for @newReleases.
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés'**
  String get newReleases;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get seeAll;

  /// No description provided for @remainingTime.
  ///
  /// In fr, this message translates to:
  /// **'{time} restantes'**
  String remainingTime(String time);

  /// No description provided for @addonsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Addons'**
  String get addonsTitle;

  /// No description provided for @stremioAddonsTab.
  ///
  /// In fr, this message translates to:
  /// **'Stremio Addons'**
  String get stremioAddonsTab;

  /// No description provided for @nuvioPluginsTab.
  ///
  /// In fr, this message translates to:
  /// **'Nuvio Plugins'**
  String get nuvioPluginsTab;

  /// No description provided for @addAddonByUrlTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un addon via URL'**
  String get addAddonByUrlTitle;

  /// No description provided for @addAddonByUrlSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez l\'URL d\'un addon Stremio pour l\'installer.'**
  String get addAddonByUrlSubtitle;

  /// No description provided for @addAddonHint.
  ///
  /// In fr, this message translates to:
  /// **'https://exemple.com/manifest.json'**
  String get addAddonHint;

  /// No description provided for @addButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addButton;

  /// No description provided for @installedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Installé'**
  String get installedBadge;

  /// No description provided for @installButton.
  ///
  /// In fr, this message translates to:
  /// **'Installer'**
  String get installButton;

  /// No description provided for @offlineBadge.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offlineBadge;

  /// No description provided for @addonDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Addon supprimé'**
  String get addonDeleted;

  /// No description provided for @addonInstalledSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Addon installé avec succès'**
  String get addonInstalledSuccess;

  /// No description provided for @manifestPreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du Manifest'**
  String get manifestPreviewTitle;

  /// No description provided for @confirmInstall.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'installation'**
  String get confirmInstall;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher films, séries, addons...'**
  String get searchHint;

  /// No description provided for @genreAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get genreAll;

  /// No description provided for @genreAction.
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get genreAction;

  /// No description provided for @genreDrama.
  ///
  /// In fr, this message translates to:
  /// **'Drame'**
  String get genreDrama;

  /// No description provided for @genreSciFi.
  ///
  /// In fr, this message translates to:
  /// **'Sci-Fi'**
  String get genreSciFi;

  /// No description provided for @genreAnimation.
  ///
  /// In fr, this message translates to:
  /// **'Animation'**
  String get genreAnimation;

  /// No description provided for @genreComedy.
  ///
  /// In fr, this message translates to:
  /// **'Comédie'**
  String get genreComedy;

  /// No description provided for @top10Today.
  ///
  /// In fr, this message translates to:
  /// **'Top 10 aujourd\'hui'**
  String get top10Today;

  /// No description provided for @noResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get noResultsTitle;

  /// No description provided for @noResultsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre mot-clé ou installez davantage d\'addons.'**
  String get noResultsSubtitle;

  /// No description provided for @moviesGroup.
  ///
  /// In fr, this message translates to:
  /// **'Films'**
  String get moviesGroup;

  /// No description provided for @seriesGroup.
  ///
  /// In fr, this message translates to:
  /// **'Séries'**
  String get seriesGroup;

  /// No description provided for @channelsGroup.
  ///
  /// In fr, this message translates to:
  /// **'Chaînes'**
  String get channelsGroup;

  /// No description provided for @libraryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma bibliothèque'**
  String get libraryTitle;

  /// No description provided for @openSourceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'open source'**
  String get openSourceSubtitle;

  /// No description provided for @downloadsTab.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get downloadsTab;

  /// No description provided for @historyTab.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get historyTab;

  /// No description provided for @pauseAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout mettre en pause'**
  String get pauseAll;

  /// No description provided for @resumeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout reprendre'**
  String get resumeAll;

  /// No description provided for @storageUsed.
  ///
  /// In fr, this message translates to:
  /// **'{used} Go utilisés sur {total} Go'**
  String storageUsed(String used, String total);

  /// No description provided for @emptyListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre liste est vide'**
  String get emptyListTitle;

  /// No description provided for @emptyListSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des films et séries à votre liste pour les retrouver ici.'**
  String get emptyListSubtitle;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les contenus que vous regardez apparaîtront ici avec reprise automatique.'**
  String get emptyHistorySubtitle;

  /// No description provided for @profileUser.
  ///
  /// In fr, this message translates to:
  /// **'Muvio User'**
  String get profileUser;

  /// No description provided for @openSourceBadge.
  ///
  /// In fr, this message translates to:
  /// **'Open Source'**
  String get openSourceBadge;

  /// No description provided for @settingsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get settingsAccount;

  /// No description provided for @settingsPlaybackQuality.
  ///
  /// In fr, this message translates to:
  /// **'Lecture & Qualité'**
  String get settingsPlaybackQuality;

  /// No description provided for @settingsSubtitlesLanguages.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres & Langues'**
  String get settingsSubtitlesLanguages;

  /// No description provided for @settingsInstalledAddons.
  ///
  /// In fr, this message translates to:
  /// **'Addons installés ({count})'**
  String settingsInstalledAddons(int count);

  /// No description provided for @manageAction.
  ///
  /// In fr, this message translates to:
  /// **'Gérer'**
  String get manageAction;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @settingsUpdates.
  ///
  /// In fr, this message translates to:
  /// **'Mises à jour'**
  String get settingsUpdates;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos de Muvio'**
  String get settingsAbout;

  /// No description provided for @openSourceCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Muvio est open source'**
  String get openSourceCardTitle;

  /// No description provided for @openSourceCardBody.
  ///
  /// In fr, this message translates to:
  /// **'Muvio est développé par la communauté. Contribuez, signalez des problèmes ou proposez des améliorations sur GitHub.'**
  String get openSourceCardBody;

  /// No description provided for @viewOnGithub.
  ///
  /// In fr, this message translates to:
  /// **'Voir sur GitHub'**
  String get viewOnGithub;

  /// No description provided for @versionFooter.
  ///
  /// In fr, this message translates to:
  /// **'v1.0.0 · Open Source'**
  String get versionFooter;

  /// No description provided for @selectSourceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Select Source'**
  String get selectSourceTitle;

  /// No description provided for @selectSourceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choose a stream from your installed add-ons.'**
  String get selectSourceSubtitle;

  /// No description provided for @sourcesCount.
  ///
  /// In fr, this message translates to:
  /// **'Sources · {count} addons'**
  String sourcesCount(int count);

  /// No description provided for @legalDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Muvio est un lecteur et agrégateur multimédia open source. L\'application n\'héberge, ne stocke et ne distribue aucun contenu protégé. Elle lit uniquement les flux fournis par les addons tiers installés volontairement par l\'utilisateur.'**
  String get legalDisclaimer;

  /// No description provided for @castSection.
  ///
  /// In fr, this message translates to:
  /// **'Distribution'**
  String get castSection;

  /// No description provided for @availableStreams.
  ///
  /// In fr, this message translates to:
  /// **'Sources disponibles'**
  String get availableStreams;

  /// No description provided for @downloadAction.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get downloadAction;

  /// No description provided for @episodesSection.
  ///
  /// In fr, this message translates to:
  /// **'Épisodes'**
  String get episodesSection;

  /// No description provided for @clearCache.
  ///
  /// In fr, this message translates to:
  /// **'Vider le cache'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Cache vidé avec succès'**
  String get cacheCleared;

  /// No description provided for @privacyNotice.
  ///
  /// In fr, this message translates to:
  /// **'Aucune télémétrie, aucun tracker, aucune publicité. Vos données restent strictement sur votre appareil.'**
  String get privacyNotice;

  /// No description provided for @upToDate.
  ///
  /// In fr, this message translates to:
  /// **'Vous utilisez la dernière version (v1.0.0).'**
  String get upToDate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
