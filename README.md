# Le Nid des Champions — V0.9.10

## Nouveautés V0.9.9 — Pré-saison & répétition générale

- **Bac à sable pré-saison isolé** : faux joueurs, Teams, matchs, pronostics, LIVE, scores, champion, badges, notifications et finale sans toucher aux données officielles ;
- **scénarios dimensionnables** depuis le Super Admin (48 joueurs / 24 matchs / 8 Teams par défaut) ;
- **test de charge isolé** jusqu’à 100 000 lignes ;
- **parcours guidé de répétition générale** avec journal des événements et nettoyage protégé par `NETTOYER` ;
- **onboarding/tutoriel joueur en 10 étapes**, reportable et rejouable depuis le Profil ;
- **banque de textes Hibou V0.9.9** pour les moments de pré-saison ;
- **Grand road-check V1** en 24 missions humaines, avec OK / KO / N/A / TODO, notes et export JSON ;
- **Centre de tests V0.9.9** : 1 880 contrôles cumulés V0.1.x → V0.9.9 ;
- conservation des PDF/fin de saison V0.9.8, du cockpit Admin V0.9.5, du multi-saisons V0.9.0 et du correctif Football-Data V0.8.1.

Les données de répétition générale vivent exclusivement dans les tables `preseason_*_v099`. Le nettoyage d’un scénario ne supprime jamais les profils, matchs ou pronostics officiels.

Voir `INSTALLATION_V0.9.9.txt`, `README_TEST_SYSTEM_V0.9.9.md` et `tests/road-check-v0.9.9.html`.

---

# Le Nid des Champions — V0.9.8

## Nouveautés V0.9.8 — PDF & fin de saison

- Collector de saison A4 imprimable / enregistrable en PDF ;
- carnet personnel A4 ;
- diplôme A4 paysage et export de tous les diplômes pour le Super Admin ;
- Livre d’or de fin de saison avec modération ;
- export global JSON ;
- snapshot final versionné + empreinte ;
- archivage définitif sécurisé par confirmation `ARCHIVER` ;
- exclusion des matchs/données TEST des statistiques finales ;
- Centre de tests V0.9.8 accessible depuis l’Admin ;
- 1660 contrôles cumulés V0.1.x → V0.9.8.

La V0.9.8 conserve le cockpit Admin V0.9.5, le multi-saisons/carrière V0.9.0 et le correctif Football-Data V0.8.1.

Voir `INSTALLATION_V0.9.8.txt` et `README_TEST_SYSTEM_V0.9.8.md`.

---

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

- R2 Admin : accès direct depuis Laboratoire aux centres de tests V0.8.1, V0.9.0 et V0.9.5 ; recherche Admin enrichie.


## V0.9.11

- Cotes 1N2 Betclic expérimentales via une Edge Function séparée.
- Ouverture progressive des fonctions par le Super Admin.
- Nettoyage global de la communication de test.
- Correctifs cumulés reset / fusion clubs / modales.
