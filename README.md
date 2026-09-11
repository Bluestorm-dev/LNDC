# Le Nid des Champions — V1.0.1

V1.0.1 est la première passe de finition après le démarrage réel de la Ligue des champions : le Centre C1 suit désormais le LIVE, les écrans mobiles sont clarifiés et les statistiques joueurs/clubs gagnent en profondeur.

## Nouveautés V1.0.1

- **Centre Ligue des champions en LIVE** : score et classement provisoire se recalculent dès qu'un match du Nid évolue, sans attendre une synchronisation manuelle.
- **Buteurs & cartons C1** : nouvel onglet alimenté par Football-Data lors de la synchronisation du Centre C1.
- **Fiches clubs enrichies** : pays, stade, adresse, année de fondation, entraîneur, couleurs, effectif, bilan C1 dans le Nid, meilleur buteur, discipline et calendrier récent/à venir.
- **Accueil / carrousels** : les cartes reprennent l'identité visuelle de la Team du joueur et changent avec une vraie transition.
- **Le Nid en mouvement** : records, séries à zéro, détail des casseroles et des coups de génie avec leurs points.
- **Ruban LIVE** : défilement continu façon flash infos ; un match est cliquable pour ouvrir les Pronos du Nid.
- **Classement** : points LIVE provisoires individuels affichés en rouge et correction du chevauchement visuel en bas du classement.
- **Fiche joueur** : la forme récente n'utilise plus des ronds incompréhensibles ; chaque résultat est libellé avec son type et ses points.
- **Rivalités** : finalisation automatique en base dès qu'une journée devient entièrement terminée, puis rafraîchissement du front.
- **Pronostics** : si la journée affichée est finie, l'ouverture de l'onglet bascule automatiquement sur la prochaine journée à jouer.
- **Tests** : nouveau road-check V1.0.1 et chemins Node compatibles Windows, y compris les dossiers contenant des accents.

## Mise à jour depuis V1.0.0

1. Exécuter `sql/HOTFIX_V1.0.1_EXISTING_DB.sql` dans Supabase **avant de publier le nouveau front**.
2. Redéployer `supabase/functions/sync-football-data`.
3. Copier le patch V1.0.1 à la racine du dépôt et publier GitHub Pages.
4. Dans le Super Admin, lancer une synchronisation **Centre C1** une fois afin de remplir effectifs, buteurs et cartons.
5. Fermer complètement la PWA puis la rouvrir.
6. Lancer `node tests/run-all-v1.0.1.mjs`.

Pour une installation neuve, utiliser `sql/000_INSTALL_FRESH_V1.0.1.sql`.

Voir `INSTALLATION_V1.0.1.txt` et `README_TEST_SYSTEM_V1.0.1.md`.

---

# Le Nid des Champions — V1.0.0

PWA de pronostics UEFA Champions League. V1.0.0 est la première version pensée pour la compétition réellement en cours : LIVE multi-matchs, classement mobile lisible, cockpit résultats, notifications stabilisées et Musée actif pendant la journée.

## Nouveautés V1.0.0

- Accueil LIVE : carrousel des matchs actuellement en direct avec ouverture des **Pronos du Nid**.
- « Le Nid en mouvement » refondu : leader, exacts, précision, casseroles, génie et records.
- Suppression de la carte d’accueil « La grande intuition ».
- Fiche d’un autre joueur : ses choix Champion deviennent visibles après leur verrouillage.
- Classement entièrement repensé pour mobile.
- Pronostics : matchs terminés automatiquement repoussés en bas.
- Super Admin / Matchs & LIVE : regroupement par journée UEFA, LIVE en tête, journées terminées en bas, sans création de nouvelle journée dans ce cockpit.
- Records du Musée mis à jour dès les premiers matchs terminés d’une journée.
- Push activable par les joueurs non-admin et reprise correcte d’un abonnement navigateur déjà existant.
- Notifications de changement de rang différées jusqu’à la fin du LIVE et dédupliquées.

## Mise à jour depuis V0.9.14b

1. Copier les fichiers du patch à la racine du dépôt.
2. Exécuter `sql/HOTFIX_V1.0.0_EXISTING_DB.sql` dans Supabase.
3. **Redéployer `supabase/functions/push-dispatch`**. C’est indispensable pour le correctif des notifications de classement pendant le LIVE.
4. Commit / push GitHub Pages.
5. Fermer complètement la PWA puis la rouvrir ; sur navigateur, faire une actualisation forcée.
6. Lancer `node tests/run-all-v1.0.0.mjs`.

Pour une installation neuve, utiliser `sql/000_INSTALL_FRESH_V1.0.0.sql`.

Voir `INSTALLATION_V1.0.0.txt` et `README_TEST_SYSTEM_V1.0.0.md`.

---

# Le Nid des Champions — V0.9.14

## Nouveautés V0.9.14 — Badges & Musée
- 100 nouvelles médailles découpées en 512x512, sans numérotation intégrée.
- Reveal animé par rareté lors de l’obtention d’un succès.
- Clic sur un succès dans le Musée : grande fiche animée + date d’obtention.
- GSAP/Anime.js utilisés quand disponibles, avec fallback natif.

Voir `INSTALLATION_V0.9.14.txt`.

## Nouveautés V0.9.13 — Mobile, onboarding & comptes

- navigation mobile rendue explicite sans hamburger : le logo affiche **MENU** ;
- Pronostics mobile réorganisés pour séparer les équipes des contrôles de score ;
- fiche équipe modernisée avec saisie directe du pronostic ;
- assistant de première connexion en 5 étapes ;
- comptes validés automatiquement à l’inscription ;
- suppression définitive de comptes réservée au Super Admin.

Voir `INSTALLATION_V0.9.13.txt`.

---

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


## V0.9.12

- Refonte UX/UI desktop.
- Deux carrousels Accueil, Pronostics en deux colonnes et fiches clubs.
- Centre C1 et Profil réorganisés.
- Cockpit Admin pour cotes, résultats et paramètres des matchs.
- Mobile préservé pour la passe suivante.
