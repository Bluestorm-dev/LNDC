# Le Nid des Champions — V0.9.5

PWA de pronostics UEFA Champions League avec Teams, rivalités, gamification, Centre C1, mémoire multi-saisons et un cockpit Admin renforcé.


## Nouveautés V0.9.5 — Administration & durcissement

- **Admin plus simple à trouver** : recherche globale des options (`Ctrl+K` ou `/`), navigation regroupée et actions rapides.
- **Centre d’action** : inscriptions, avatars, tickets, Push en échec et suppressions à traiter remontent au Dashboard.
- **Système & sécurité** : Maintenance, inscriptions et Feature flags réunis au même endroit.
- **Sauvegardes serveur** : snapshots de saison, JSON, restauration protégée et journalisée.
- **Audit** : journal paginé/recherchable des opérations sensibles.
- **Aperçu joueur** : diagnostic en lecture seule, sans mot de passe et journalisé.
- **Confidentialité** : demande de suppression et traitement/anonymisation applicative.
- **Robustesse** : pagination joueurs, états réseau, mobile et accessibilité renforcés.
- **Tests** : 1490 contrôles cumulés V0.1.x → V0.9.5.

La V0.9.5 conserve le cœur V0.9.0 (multi-saisons, carrière, Hall of Fame, Replay, sondages et vainqueur Coupe du monde 2026) ainsi que le correctif Football-Data V0.8.1.

## Mise à jour depuis V0.9.0

Voir `INSTALLATION_V0.9.5.txt`.

## Tests V0.9.5

- `README_TEST_SYSTEM_V0.9.5.md`
- `docs/TEST_CHECKLIST_V0.9.5.md`
- `docs/TEST_MATRIX_V0.9.5.md`

## Nouveautés V0.9.0 — Saison, carrière & mémoire

- **Multi-saisons** : consulter une saison ancienne ou active sans mélanger les données.
- **Archives en lecture seule** : une saison terminée reste visible mais ses pronostics et Teams sont figés côté joueurs.
- **Profil saison enrichi** : rang, meilleur rang, remontées, jours en tête, forme, précision et historique de classement.
- **Carrière** : saisons jouées, statistiques cumulées et classement carrière.
- **Hall of Fame** : champions, podiums, Teams, scoreurs, exacts, Poêle d'Or, Génie, Hibou solitaire et records.
- **Replay de saison** : chronologie des événements et performances mémorables.
- **Champion en titre & distinctions** persistantes.
- **Sondages généraux** administrables.
- **Road-check V0.1.x → V0.9.0** : 1330 contrôles + diagnostic SQL + runner local.

Les fonctions V0.8.1 restent conservées, notamment la synchronisation Football-Data strictement 2026/27 sans fallback 2025/26.

## Mise à jour depuis V0.8.1

Voir `INSTALLATION_V0.9.0.txt`.

## Tests

- `README_TEST_SYSTEM_V0.9.0.md`
- `docs/TEST_CHECKLIST_V0.9.0.md`
- `docs/TEST_MATRIX_V0.9.0.md`

V0.9.0 — Palmarès historique
- Le Super Admin peut désigner ou retirer manuellement le « Vainqueur du Nid des Pronos — Coupe du monde 2026 ».
- Cette distinction est unique, persistante entre les saisons et visible dans le profil/carrière.
