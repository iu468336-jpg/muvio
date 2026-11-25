# Contribuer à Muvio

Merci de contribuer à **Muvio** ! Ce guide détaille le workflow GitHub Flow et nos exigences qualité.

## Prérequis

- **Flutter** `3.24+` stable (Dart `3.5+`)
- **JDK 17** (Zulu ou Temurin)
- **Android SDK** API 35 (`minSdkVersion 24`)

## Installation locale

```bash
git clone https://github.com/iu468336-jpg/muvio.git
cd muvio
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

## Règles de qualité obligatoires avant toute Pull Request

1. **Analyse statique stricte (`very_good_analysis`)** :
   ```bash
   flutter analyze
   ```
   Doit retourner **0 erreur et 0 warning**.
2. **Formatage** :
   ```bash
   dart format --set-exit-if-changed lib test
   ```
3. **Tests automatisés** :
   ```bash
   flutter test --concurrency=1
   ```
4. **Architecture & Performance** :
   - Aucun appel HTTP direct depuis un widget (passer par `Repository` + `Riverpod Provider`).
   - Utiliser `MuvioImage` (`memCacheWidth`) pour toutes les images réseau.
   - Aucune dépendance abandonnée, aucune WebView UI, aucun tracker.

## Workflow GitHub Flow

1. Créez une branche descriptive depuis `main` : `git checkout -b feat/nom-de-la-fonctionnalite`.
2. Ajoutez des tests unitaires et/ou widget couvrant vos changements.
3. Ouvrez une Pull Request vers `main`. La CI exécutera automatiquement `flutter analyze`, `flutter test` et la compilation APK.
