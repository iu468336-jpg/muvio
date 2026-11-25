# Changelog

Toutes les modifications notables de **Muvio** sont documentées dans ce fichier.

## [1.0.0] - 2026-11-25

### Ajouté
- **Écran 1 — Accueil** : Bannière Hero 16:9 (« ÉCLIPSE »), Continuer à regarder avec reprise à la seconde exacte, Tendances, Nouveautés, Pull-to-refresh et shimmer léger.
- **Écran 2 — Addons & Plugins** : Support complet du protocole officiel Stremio (`manifest.json`, `catalog`, `meta`, `stream`, `subtitles`) et des plugins Nuvio (`MediaProvider`), validation stricte HTTPS/anti-SSRF, circuit breaker automatique (3 échecs) et aperçu avant installation.
- **Écrans 3 & 7 — Lecteur Vidéo Portrait & Paysage 16:9** : Intégration `media_kit` (`libmpv`) avec décodage matériel, moteur torrent progressif `libtorrent4j` + serveur HTTP local `NanoHTTPD`, gestes tactiles (double-tap ±10s, luminosité, volume, zoom pincement), Picture-in-Picture (PiP Android 8+), vitesse `0.5x–2x` et changement de source à chaud.
- **Écran 4 — Recherche & Découverte** : Recherche multi-addons parallèle (`Future.wait`) avec debounce 350 ms, Top 10 avec grands chiffres rouges outline, filtres de genres et déduplication par `meta.id`.
- **Écran 5 — Bibliothèque & Téléchargements** : Ma liste, Téléchargements (file d'attente parallélisme 2, pause/reprise, anneau de progression), Historique de lecture et jauge de stockage.
- **Écran 6 — Profil & Paramètres** : Stockage chiffré Android Keystore (`flutter_secure_storage`) pour Trakt / Real-Debrid, thème sombre / AMOLED, internationalisation FR/EN, police Inter embarquée hors-ligne, zéro tracker et zéro télémétrie.
