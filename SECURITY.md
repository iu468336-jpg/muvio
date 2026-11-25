# Politique de Sécurité (Security Policy)

## Versions supportées

| Version | Supportée |
| ------- | --------- |
| 1.0.x   | ✅ Oui    |

## Mesures de sécurité intégrées dans Muvio

1. **Validation stricte des URLs d'addons** (`UrlSecurityValidator`) :
   - Protocole `https://` exigé pour tous les manifests d'addons.
   - Blocage explicite des schémas dangereux (`file://`, `javascript:`, `data:`) et des plages IP privées/locales (`127.0.0.1`, `10.0.0.0/8`, `192.168.0.0/16`, `172.16.0.0/12`, `169.254.0.0/16`) afin d'éviter toute attaque SSRF.
   - Taille maximale de réponse réseau plafonnée à **5 Mo** et timeout strict de **10 secondes**.
2. **Stockage chiffré** :
   - Les tokens Trakt et clés API Real-Debrid sont chiffrés via `EncryptedSharedPreferences` / Android Keystore (`flutter_secure_storage`).
3. **Confidentialité absolue** :
   - Aucun SDK d'analytics, aucun tracker publicitaire, aucune télémétrie.

## Signaler une vulnérabilité

Merci d'ouvrir un signalement privé via l'onglet **Security > Advisories** du dépôt GitHub plutôt qu'une issue publique. Une réponse vous sera apportée sous 48 heures.
