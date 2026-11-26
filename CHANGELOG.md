# Changelog

Toutes les modifications notables de **Muvio** sont documentées dans ce fichier.

## [1.0.1] - 2026-11-26

### Corrigé & Amélioré
- **Addons réels comme Nuvio** : Suppression intégrale des faux addons de démonstration (`Real-Debrid`, `Plex Bridge`, `Jellyfin Direct`, etc.). Pré-installation automatique des vrais addons officiels de base **Cinemeta** (`v3-cinemeta.strem.io`) et **OpenSubtitles v3** (`opensubtitles-v3.strem.io`), plus annuaire 1-clic réel (**Torrentio**, **Comet**, **MediaFusion**, **TMDB Addon**, **Anime Kitsu**, **All-in-One-Nuvio**, **Yoru's Repo**).
- **Installation d'addons réparée à 100 %** : Support des URLs sans `https://`, suppression automatique du suffixe `/configure`, User-Agent compatible Cloudflare, support natif des dépôts JSON Nuvio (`scrapers: [...]` sur GitHub Raw) et bouton **Coller** dans le champ URL.
- **Accueil & Bibliothèque propres** : Suppression de tous les films fictifs pré-remplis dans *Continuer à regarder*, *Ma liste* et *Téléchargements* ; la section *Continuer à regarder* n'apparaît désormais que lorsqu'une vidéo a réellement été visionnée (avec migration automatique nettoyant la base SQLite existante).
- **Adaptation écran mobile corrigée (anti-zoom)** : Recalibrage complet des tailles typographiques, marges, cartes, Hero banner et barre de navigation basse + bridage du `TextScaler` système Android (`0.90–1.05`) pour un rendu net, proportionné et sans débordement sur tous les téléphones (`armeabi-v7a` et `arm64-v8a`).

## [1.0.0] - 2026-11-25

### Ajouté
- Version initiale open-source de Muvio (Accueil, Recherche, Addons Stremio/Nuvio, Bibliothèque & Téléchargements, Profil, Lecteur `media_kit` + `libtorrent4j`).
