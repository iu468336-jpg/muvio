# Design System — Muvio

Ce document définit les tokens visuels stricts utilisés dans **Muvio**, alignés au pixel sur les 7 maquettes officielles.

## 1. Palette de Couleurs (`AppColors`)

| Token | Hex | Rôle |
| --- | --- | --- |
| `AppColors.red` | `#E50914` | Rouge signature Muvio (actions primaires, onglets actifs, progression) |
| `AppColors.redDeep` | `#B0060F` | États pressés, dégradés profonds |
| `AppColors.redGlow` | `#FF2A33` | Accents lumineux, badges LIVE |
| `AppColors.bg` | `#0A0A0A` | Arrière-plan principal |
| `AppColors.surface` | `#121212` | Cartes d'addons, panneaux de sources, listes groupées |
| `AppColors.surface2` | `#161616` | Surfaces élevées, barres de recherche, chips |
| `AppColors.line` | `#242424` | Bordures subtiles de `1px` |
| `AppColors.text` | `#F5F5F5` | Texte principal à contraste élevé (WCAG AA+) |
| `AppColors.textMuted` | `#9A9A9A` | Métadonnées secondaires, durées, sous-titres |
| `AppColors.success` | `#34C759` | Badge « Installé », coche de téléchargement terminé |

## 2. Typographie (`Inter` embarquée)

- **Display** : `32 sp`, `FontWeight.w900` — Titres majeurs (« Addons », « Ma bibliothèque »)
- **H1** : `24 sp`, `FontWeight.w800` — En-têtes de sections majeures
- **H2** : `18 sp`, `FontWeight.w700` — Titres de cartes et films
- **Body** : `14 sp`, `FontWeight.w400` / `w600` — Synopsis et libellés
- **Caption** : `12 sp`, `FontWeight.w500` — Durées, tailles en Go, compteurs
- **Micro** : `11 sp`, `FontWeight.w700`, `letterSpacing: +1.4` — Badges « UN FILM ORIGINAL MUVIO », notes

## 3. Formes, Rayons & Espacements (`AppSpacing`)

- **Cartes** : rayon `20 px` + bordure `1 px` `#242424`
- **Posters (ratio 2:3)** : rayon `12 px`
- **Boutons Pill & Chips** : rayon `999 px`
- **Marges horizontales d'écran** : `20 px`
- **Espacement entre sections** : `28 px`
- **Cibles tactiles minimales** : `44 × 44 dp` + `Semantics` pour l'accessibilité

## 4. Navigation Basse Unifiée (5 onglets)

Hauteur `64 px` + `SafeArea`, arrière-plan `#0A0A0A` translucide avec `BackdropFilter` (`blur 16`) :
1. **Accueil** (`LucideIcons.home`)
2. **Recherche** (`LucideIcons.search`)
3. **Addons** (`LucideIcons.puzzle`)
4. **Bibliothèque** (`LucideIcons.library`)
5. **Profil** (`LucideIcons.user`)
