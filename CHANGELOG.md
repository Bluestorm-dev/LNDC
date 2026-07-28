# CHANGELOG

## V0.7.0 — Musée, Gamification & LIVE robuste

- nouveau Musée : Badges, Records, Casseroles et Génie ;
- catalogue initial de 100 badges, moteur extensible sans limite codée à 100 ;
- création/duplication/import JSON/archivage des badges réservés au Super Admin ;
- raretés, secrets personnels, première découverte mondiale, progression et recalcul rétroactif contrôlé ;
- Casseroles 2.0 avec gravités configurables, séries de zéros, catastrophe unique et champion éliminé tôt ;
- Coups de Génie selon rareté des pronostics, exact rare et cote lorsqu’elle est fiable ;
- records personnels + Records du Nid avec historique, égalisation et ancien détenteur prévenu ;
- laboratoire Gamification TEST séparé et classement LIVE TEST ;
- correctif LIVE joueur : Realtime renforcé et resynchronisation de secours sans F5 ;
- centre de notifications enrichi avec Badges / Records / Gamification ;
- moteur narratif du Hibou et banque initiale d’environ 40 variantes par famille de sujet ;
- nouvelles animations de déblocage graduées selon la rareté ;
- blasons Team : suppression du marqueur parasite bas-droite et réduction supplémentaire de l’avatar ;
- nouveaux scripts `019_patch_v0.7.0_gamification.sql` et `020_seed_v0.7.0_narrative_texts.sql` ;
- redéploiement de `push-dispatch` requis après installation SQL ; aucune régénération VAPID.

## V0.6.5 — Déconnexion mobile

- ajout d'une zone **Compte** dans Profil ;
- bouton **Se déconnecter** disponible sur mobile et desktop ;
- le bouton desktop du header reste présent ;
- aucun changement SQL / Supabase ;
- cache PWA `nid-champions-v0.6.5`.

## V0.6.4 — Web Push immédiat & Test Cron

- correction de l'activation Push sur un compte non Super Admin quand le navigateur possède déjà un endpoint enregistré sous un autre compte ;
- ajout de `register_my_push_subscription_v064`, qui ne réattribue un endpoint que si ses clés `p256dh/auth` correspondent ;
- RLS `push_subscriptions` découpée en politiques explicites SELECT / INSERT / UPDATE / DELETE ;
- déclencheur PostgreSQL central `dispatch_immediate_push_v064` : tout Push non programmé appelle immédiatement `push-dispatch` via `pg_net` ;
- action Edge `dispatch-one` protégée par `PUSH_CRON_SECRET` ;
- envois immédiats manuels qui ne dépendent plus du passage du Cron ;
- Test Push personnalisé corrigé : le titre et le corps saisis sont ceux réellement envoyés ;
- Test Cron Super Admin avec heure réglable et message dédié ;
- Cron ramené de 15 minutes à **1 minute** pour les rappels et tests programmés ;
- Test Cron autorisé à traverser les quiet hours afin de valider réellement le réveil ;
- nouveau patch `017_patch_v0.6.4_push_immediate_cron_rls.sql`, HOTFIX et fresh install V0.6.4 ;
- cache PWA `nid-champions-v0.6.4`.

## V0.6.3 — Correctif identité visuelle

- avatar public unifié dans sidebar, accueil, profil, classement, Teams, Live, rivalités et pronostics révélés ;
- PNG d'avatar affichés sur fond transparent avec `object-fit: contain` ;
- cadre/blason Team plus visible autour du joueur et mini-marque Team renforcée ;
- proportions harmonisées sur les tailles XS/SM/MD/LG ;
- bandeau Team désormais fortement teinté par les couleurs de la Team et beaucoup moins par le bleu global du Nid ;
- motifs de Team conservés en ambiance, avec voile de lisibilité plus léger ;
- annuaire et classement Teams teintés selon l'identité de chaque Team ;
- cache PWA et manifeste passés en V0.6.3 ;
- aucune migration SQL supplémentaire.

## V0.6.2 — Correctif social, Teams & avatars

- réactions rapides entre joueurs : `👏 🔥 😂 😱 🦉 🏆 💀 ❤️` ;
- envoi depuis le classement, la Team, les pronostics révélés et le profil public ;
- notification `social` dédiée et préférence « Réactions joueurs » ;
- anti-spam serveur : délai entre deux réactions et plafond horaire ;
- deep link d’une réaction vers le profil de son expéditeur ;
- grandes cartes Team : motifs fortement atténués, agrandis et recouverts d’un voile sombre ;
- aperçu Team du configurateur adouci de la même manière ;
- avatar public canonique pris depuis `profileDirectory` pour éviter les valeurs périmées des RPC de classement/live ;
- sidebar convertie au composant avatar commun ;
- bandeau sticky du classement mobile conserve maintenant le vrai avatar Team et affiche le nom de la Team ;
- cache PWA et manifest de release passés en V0.6.2.

---

## V0.6.0a — Administration UX

- refonte de l’administration en centre de contrôle modulaire ;
- navigation interne : Vue d’ensemble / Matchs & LIVE / Compétition / Joueurs / Teams / Communication / Application ;
- une seule rubrique visible à la fois, fin de la page Admin interminable ;
- navigation verticale sticky sur desktop et horizontale sur mobile ;
- tableau de bord avec compteurs et raccourcis ;
- nouvel annuaire Admin des joueurs avec recherche et profil rapide ;
- séparation des opérations quotidiennes Matchs/LIVE et des réglages de compétition ;
- regroupement Hibou / tickets / Push dans Communication ;
- espace Application prêt pour feature flags, saisons, sauvegardes et maintenance ;
- actions locales « Recharger les données » et « Nettoyer le cache PWA » ;
- aucune migration SQL : correctif front-only.

---

## V0.6.0 — Hibou, rivalités & notifications

- centre de notifications interne avec compteur, filtres, lu/non lu, suppression et deep links ;
- préférences de catégories, rappels et quiet hours ;
- opt-in Push volontaire : aucune demande navigateur au premier écran ;
- Web Push multi-appareils, VAPID et Edge Function `push-dispatch` ;
- rappels groupés de pronostics et champion ;
- résumés groupés de journée ;
- notifications de classement significatives ;
- journal de livraison Push et invalidation automatique des abonnements 404/410 ;
- Test Push Super Admin vers soi-même ou un joueur précis ;
- messages système critiques ;
- rival principal, changement une fois par journée, verrouillage au premier coup d’envoi ;
- notification du rival choisi et détection des rivalités mutuelles ;
- duels par journée UEFA avec victoire/nul/défaite ;
- notification avant duel et bilan automatique à la fin ;
- historique des anciens rivaux, courbe et statistiques ;
- tonalité Hibou Sage / Piquant / Sans pitié / Automatique ;
- messages Hibou globaux, Team et individuels ;
- tickets privés au Hibou avec conversation, priorités Super Admin et résolution joueur ;
- captures privées `support-captures`, 3 images max, 5 Mo/image ;
- contexte technique automatique pour les tickets Bug ;
- notifications Team automatiques ;
- profil rapide des joueurs depuis le classement avec action Hibou Super Admin ;
- migration `015_patch_v0.6.0_hibou_rivals_notifications.sql` ;
- installation fraîche `000_INSTALL_FRESH_V0.6.0.sql` ;
- cache PWA `nid-champions-v0.6.0`.

---

## V0.5.5a — Correctif Teams

- mini-carte Team : fond de couleurs/motifs atténué et assombri pour préserver la lisibilité ;
- un capitaine seul peut quitter sa Team sans la dissoudre ;
- une Team sans membre devient **vacante** et reste visible dans l’annuaire ;
- reprise d’une Team vacante avec attribution automatique du capitanat ;
- réactivation par le dernier capitaine d’une Team dissoute/archivée ;
- récupération possible des Teams dissoutes involontairement en V0.5.5 ;
- distinction claire entre quitter, dissoudre et supprimer définitivement ;
- suppression définitive d’une Team réservée au **Super Admin** ;
- audit `team_hard_delete` conservé avant suppression physique ;
- nettoyage du logo Team courant dans Supabase Storage lorsque possible ;
- migration `014_patch_v0.5.5a_team_vacancy_moderation.sql` + HOTFIX V0.5.5a ;
- cache PWA `nid-champions-v0.5.5a`.

---

## V0.5.5 — Finitions accueil & Teams

- avatar/logo joueur affiché en grand dans le hero d’accueil ;
- nouvel onglet Team **Gestion** pour rendre accessibles les actions sensibles ;
- quitter une Team pour les membres ;
- transfert de capitanat pour le capitaine ;
- séquence guidée « transférer puis quitter » pour un capitaine ;
- exclusion de membres, invitations, demandes d’adhésion et dissolution regroupées dans Gestion ;
- nouveaux fonds deux couleurs : moitié verticale/horizontale/diagonale, bandes verticales/horizontales/diagonales et quartiers ;
- conservation des dégradés existants ;
- vrai avatar joueur dans la prévisualisation de personnalisation Team ;
- cadre Team légèrement aminci ;
- migration SQL `013_patch_v0.5.5_team_polish.sql` et HOTFIX V0.5.5 ;
- cache PWA incrémenté en `nid-champions-v0.5.5`.

---

## V0.5.4 — Réorganisation du front

- version **front-only**, sans migration Supabase ;
- déplacement du JavaScript de `assets/js/` vers `js/` ;
- découpage de l’ancien `app.js` en 12 fichiers spécialisés ;
- `js/app.js` devient uniquement l’orchestrateur final et le point de démarrage ;
- déplacement du CSS de `assets/css/` vers `css/` ;
- découpage de l’ancien `app.css` en 8 feuilles thématiques, chargées dans l’ordre de cascade historique ;
- déplacement de toutes les notices `INSTALLATION_V*.txt` dans `installation/` ;
- mise à jour de `index.html`, du cache PWA et du manifeste assets ;
- cache PWA incrémenté en `nid-champions-v0.5.4` ;
- ajout de `docs/TEST_CHECKLIST_V0.5.4.md`, `installation/INSTALLATION_V0.5.4.txt` et `tests/release-v0.5.4.mjs`.

---
## V0.5.3 — Avatars joueurs

- livraison de la bibliothèque officielle de **90 avatars PNG 512×512** ;
- ajout du catalogue `assets/avatars/avatar-catalog.json` et du manifeste global `assets/assets-manifest.json` ;
- nouveau sélecteur d’avatar dans le Profil avec aperçu en direct ;
- aperçu de l’avatar avec l’habillage visuel de la Team ;
- upload joueur PNG/JPG/WebP, 3 Mo maximum ;
- nouveau bucket Supabase privé `player-avatars` ;
- politiques Storage RLS : insertion dans le dossier du joueur, mise à jour/suppression par propriétaire ou Admin ;
- colonnes de profil `avatar_source`, `avatar_storage_path`, `avatar_moderation_status`, `avatar_rejection_reason`, `avatar_updated_at` ;
- RPC `select_player_avatar_v053` ;
- RPC `submit_player_avatar_v053` ;
- RPC Admin `admin_list_avatar_moderation_v053` et `admin_moderate_avatar_v053` ;
- modération Admin avec validation/refus et audit ;
- upload en attente non publié dans les vues collectives ;
- intégration du composant avatar dans la sidebar, le profil, les classements généraux/journée/soirée/LIVE, les Teams et les pronostics révélés ;
- compatibilité des anciennes clés `owl-gold`, `owl-blue`, `owl-violet` ;
- cache PWA incrémenté en V0.5.3 ;
- ajout du SQL HOTFIX, du fresh install, de l’installation, de la checklist et des tests release V0.5.3.

---

## V0.5.2 — Correctif visuel Teams
- formes réellement distinctes (cercle, médaillon, losange, hexagone, écussons, etc.) ;
- correction CSS qui écrasait toutes les formes et toutes les matières ;
- cadres bois/or/argent/etc. conformes à la forme choisie ;
- aperçu des cadres synchronisé avec la forme active ;
- choix 1 couleur / 2 couleurs rendu explicite avec aperçu des deux modes.


## V0.5.2 — Teams · correction UX/UI

- configurateur Team élargi en véritable atelier desktop, sans compression des options ;
- prévisualisation déplacée dans une colonne dédiée et séparée du formulaire ;
- formes et cadres affichés visuellement sous forme de grille au lieu de simples listes compactes ;
- les matières **bois / bronze / argent / or / acier / obsidienne / néon / Champions / etc. épousent maintenant exactement la forme du blason** ;
- logos de bibliothèque rendus sans fond opaque : le symbole laisse voir la ou les couleurs de la Team ;
- support explicite de **1 couleur** (fond uni) ou **2 couleurs** (dégradé) sans changement de schéma Supabase ;
- choix de dégradé vertical, horizontal, diagonal, radial ou halo ;
- cinq presets rapides : Champions bleu, Or royal, Bois forêt, Obsidienne et Néon ;
- aperçu séparé du blason, de l’avatar membre, de la ligne de classement et d’une carte Team ;
- aperçu immédiat d’un logo uploadé avant enregistrement ;
- bouton de réinitialisation du style ;
- responsive mobile revu pour conserver toutes les options sans écrasement ;
- mise à jour front-only depuis V0.5.0 : **aucun nouveau SQL requis**.

## V0.5.0 — Teams

- nouveau module **Teams** dans la sidebar et la navigation mobile ;
- une seule Team active par joueur et par saison ;
- création publique/privée, demande d’adhésion et code d’invitation ;
- capitaine unique, transfert, exclusion, départ et dissolution archivée ;
- équipe fétiche facultative issue de la bibliothèque de clubs ;
- identité visuelle Team : 12 formes, 12 cadres/matières, deux couleurs et 6 types de fond ;
- logo Team depuis la bibliothèque ou upload dans le bucket `team-logos` ;
- habillage Team autour des avatars dans classements, profils et pronostics révélés ;
- trois classements Teams : moyenne générale, Top 3 et journée UEFA ;
- attribution historique des points à la Team présente au coup d’envoi ;
- historique des mouvements et changements d’identité ;
- gestion Teams dans l’Administration ;
- Realtime Supabase sur Teams, memberships, demandes et événements ;
- ajout du **Hibou masqué officiel** transparent et mise à jour du manifest des assets ;
- nouvelle migration `011_patch_v0.5.0_teams.sql`, hotfix et installation fraîche V0.5.0 ;
- checklist de recette V0.5.0 et tests statiques de release.

## V0.4.2 — Pays des clubs

- ajout du pays d’origine sportive sous le nom des clubs dans les cartes de match ;
- affichage également sur le prochain match de l’accueil et les confrontations de phase finale ;
- pays visible dans le choix des champions et dans la bibliothèque Admin ;
- normalisation des principaux noms de pays en français avec drapeau ;
- cas particulier **AS Monaco** forcé en **France 🇫🇷**, conformément à son championnat ;
- aucun changement de schéma Supabase : mise à jour front-only depuis V0.4.1.

## V0.4.1 — Refonte UX/UI + champions dans Profil

- suppression du fond répétitif en petits points ;
- nouveau fond 100 % CSS : bleu nuit, halos, faisceaux et courbes européennes ;
- navigation desktop déplacée dans une **sidebar latérale** ;
- navigation mobile conservée en barre basse ;
- accueil entièrement épuré : plus aucune journée complète affichée ;
- nouveau dashboard d’accueil avec rang, points, progression, prochain match, résumé champions et Hibou ;
- suppression de la page Champions dédiée dans la navigation ;
- sélecteurs Champion n°1 (+100) et Champion n°2 (+50) déplacés dans **Profil** ;
- règle OM par défaut et confidentialité des choix clairement affichées dans Profil ;
- résumé des champions sur l’accueil avec accès direct au Profil ;
- ajout d’un cartouche joueur dans la sidebar ;
- aucun changement du schéma Supabase : V0.4.1 est compatible directement avec la base V0.4.0 ;
- cache PWA et version portés en V0.4.1.

## V0.4.0 — Champions & phases finales

- premier champion à **100 points** avec verrouillage au premier coup d'envoi ;
- **Olympique de Marseille attribué automatiquement** aux joueurs sans premier choix au verrouillage ;
- deuxième champion à **50 points**, ouvert après la phase de ligue et fermé au début des phases finales ;
- choix champions cachés avant verrouillage puis révélables ;
- élimination des champions suivie au fil du tableau ;
- phases `KNOCKOUT_PLAYOFF`, `ROUND_OF_16`, `QUARTER_FINAL`, `SEMI_FINAL`, `FINAL` ;
- moteur de confrontations avec propagation automatique des qualifiés ;
- aller-retour, cumul et finale en match unique ;
- score de retour/finale traité à **120 minutes** lorsqu'une prolongation est jouée ;
- tirs au but stockés séparément et utilisés uniquement pour déterminer le qualifié ;
- pronostic du qualifié : **+3 avant l'aller**, **+1 si réellement modifié après l'aller** ;
- multiplicateurs **x1 / x2 / x3 / x4** par phase et par match ;
- classement général V0.4 additionnant matchs + qualifiés + champions ;
- nouvelles tables `knockout_ties`, `tie_predictions`, `champion_predictions` ;
- nouvelles RPC V0.4.0 et Realtime sur les nouvelles tables ;
- générateur Admin d'un tableau TEST complet de 23 confrontations ;
- constructeur Admin des confrontations réelles, avec validation aller/retour et finale en match unique ;
- nouvelle UI Champions et Phases finales ;
- installation fraîche, hotfix, checklist et cache PWA V0.4.0.

# V0.3.4 — Correctif identité clubs Top 5

- Correction de la collision de sigle `BRE` entre **Stade Brestois 29** et **Brentford FC**.
- L’ID `football-data` devient l’identité canonique d’un club importé.
- Suppression de la déduplication globale par `tla` et `short_name`, qui ne sont pas uniques entre championnats.
- Le rattachement par nom exact n’est conservé que pour les anciennes lignes manuelles sans fournisseur.
- Une nouvelle synchronisation **Bibliothèque Top 5 + logos** répare automatiquement les appartenances : Brest revient en Ligue 1 et Brentford reste en Premier League.
- Conservation de la navigation clavier bidirectionnelle V0.3.3 et des cotes V0.3.2.


## V0.3.3 — Navigation A/B & bibliothèque clubs Top 5

- navigation clavier corrigée et symétrique : `A1 → B1 → A2 → B2…` **et** `B1 → A1 → A2 → B2…` ;
- le passage au match suivant se fait après la deuxième saisie clavier du match, quel que soit le côté commencé ;
- les boutons `+ / −` conservent le focus et n'activent jamais le saut automatique ;
- ajout d'une bibliothèque de clubs indépendante de la Champions League pour le **club de cœur** ;
- import Admin en une action de la Ligue 1 (`FL1`), Premier League (`PL`), Liga (`PD`), Serie A (`SA`) et Bundesliga (`BL1`) via Football-Data ;
- logos téléchargés dans le bucket `club-logos` avec le même mécanisme de fallback que les clubs C1 ;
- table `club_catalog_memberships` pour mémoriser l'appartenance d'un club à plusieurs compétitions sans dupliquer le club ;
- la synchronisation C1 reste strictement comptée à 36 clubs même après ajout des clubs Top 5 ;
- filtre Admin par championnat et aperçu des clubs/logos importés ;
- champ « Club de cœur » avec autocomplétion sur toute la bibliothèque et blason visible dans le profil ;
- migration `008_patch_v0.3.3_navigation_catalogue_clubs.sql`, hotfix base existante, installation fraîche V0.3.3 et checklist dédiées.

## V0.3.2 — Cotes 1N2 pré-match

- stockage des cotes décimales **1 / N / 2** directement sur chaque match, avec fournisseur, bookmaker/libellé, saison source et date de mise à jour ;
- récupération prioritaire de `odds.homeWin`, `odds.draw` et `odds.awayWin` depuis Football-Data lorsque le compte API expose l’option Odds ;
- source complémentaire optionnelle **Odds-API.io** via la nouvelle Edge Function `sync-odds`, sans jamais exposer la clé API dans le navigateur ;
- bouton Admin `Cotes 1N2` : tente Football-Data puis complète avec la source externe configurée pour les rencontres réellement retrouvées ;
- appels externes groupés par lots de 10 événements afin de limiter la consommation de quota ;
- affichage premium sous chaque rencontre : source, heure de mise à jour et trois capsules `1`, `N`, `2` ;
- affichage compact des cotes dans la liste de saisie Admin ;
- pour la saison TEST transposée, les cotes Football-Data conservent explicitement la provenance **source 2025/26** ;
- aucune cote fictive en production et aucune valeur partielle : le bloc 1N2 n’apparaît que lorsque les trois valeurs existent ;
- les cotes restent purement informatives et n’entrent jamais dans le calcul des points 0/3/5/7 ;
- migration `007_patch_v0.3.2_cotes_1n2.sql`, hotfix base existante, installation fraîche V0.3.2 et checklist dédiées.

## V0.3.1 — Logos TEST & saisie en rafale

- les matchs de la `Journée TEST` sont automatiquement rattachés aux clubs Football-Data canoniques après synchronisation ;
- les anciens doublons historiques (`Paris SG`, `Bayern Munich`, etc.) sont désactivés après rattachement ;
- les matchs TEST utilisent donc exactement les mêmes logos que les clubs importés ;
- l'importeur essaie d'abord le blason réellement fourni par Football-Data avant l'URL générique par identifiant ;
- le statut de synchronisation Admin affiche désormais les **totaux réels** après `Clubs + logos` comme après `Calendrier CL` : clubs, logos, journées et matchs ;
- saisie pronostic accélérée : `A → B → A du match suivant` dès que les deux scores sont renseignés ;
- les boutons `+ / −` conservent leur comportement sans changement de focus ;
- migration de réparation `006_patch_v0.3.1_logos_navigation.sql` ;
- installation fraîche `000_INSTALL_FRESH_V0.3.1.sql` ;
- cache PWA, configuration et version passés en `0.3.1`.

## V0.3.0 — Classements & Live

- classement général LIVE avec points provisoires non persistés dans les points officiels ;
- départage : points → exacts → moyenne → bons écarts → pronostics joués ;
- rang unique ;
- variation ▲/▼ par rapport au classement avant la soirée ;
- ligne du joueur connecté sticky ;
- écarts avec le voisin du dessus et du dessous ;
- classements Journée et Soirée ;
- vues Précision et Scores exacts ;
- score Admin enregistré pendant le LIVE et actualisable autant de fois que nécessaire ;
- bandeau LIVE et scores courants ;
- Realtime sur `matches`, `matchdays` et `predictions` ;
- recalcul immédiat du classement après une modification Admin ;
- statistiques collectives 1/N/2, scores les plus joués, exacts et Fiabilité du Nid ;
- révélation des pronostics adverses après verrouillage uniquement ;
- UI/UX premium bleu nuit / violet / or / cyan ;
- podium premium, tableau sticky et cartes LIVE ;
- checklist V0.3.0 complète ;
- installation fraîche V0.3.0 ;
- version navigateur, base et cache PWA passés en 0.3.0.

## V0.2.2 — Correctifs intégrés à V0.3.0

- saison Football-Data test forcée sur 2025/26 ;
- transposition des dates vers 2026/27 ;
- validation stricte de 36 clubs ;
- validation stricte de 144 matchs, 8 × 18 ;
- suppression des anciens matchs Football-Data parasites ;
- aucun résultat historique importé ;
- contrôle de présence d’un logo exploitable pour chacun des 36 clubs ;
- aperçu Admin de tous les clubs synchronisés ;
- saisie score clavier A ↔ B dès la frappe d’un chiffre ;
- boutons + / − sans changement de focus ;
- autosauvegarde conservée ;
- Admin et Super Admin peuvent pronostiquer comme les joueurs actifs.

## 0.1.0 — Le nouveau Nid

- nouveau projet PWA ;
- nouveau modèle Supabase multi-saisons ;
- authentification pseudo + mot de passe ;
- véritable e-mail réservé à la validation/récupération ;
- profils et rôles ;
- première journée test ;
- pronostics 0/3/5/7 ;
- sauvegarde et verrouillage ;
- saisie manuelle Admin ;
- recalcul serveur ;
- classement ;
- Realtime ;
- premier univers visuel du Nid des Champions ;
- mode démo local.

### Documentation assets
- ajout de `docs/ASSETS_MANIFEST.md` ;
- nomenclature et arborescence des PNG ;
- inventaire planifié de 90 avatars ;
- inventaire planifié de 100 badges classés par rareté ;
- trophées, clubs, icônes, teams et assets PDF recensés ;
- règle de maintenance du manifeste ajoutée au README.


## V0.1.2 — Admins joueurs eux aussi
- correction des cartes de l’accueil rendues par erreur en lecture seule ;
- Player, Admin et Super Admin actifs peuvent pronostiquer avec les mêmes contrôles ;
- politique RLS des pronostics explicitement réaffirmée pour tout membre actif ;
- cache PWA incrémenté en V0.1.2.

## V0.1.1 — Accès & inscriptions
- correction de l'Edge Function `login-by-username` pour les appels pré-authentification ;
- CORS modernisé avec les headers fournis par `supabase-js` ;
- `verify_jwt = false` uniquement pour l'endpoint de login ;
- suppression de la validation par clic sur e-mail dans le flux applicatif ;
- nouveaux comptes en statut `pending` ;
- validation/refus des inscriptions par le Super Admin ;
- panneau « Demandes d'inscription » dans l'administration ;
- statuts `pending`, `active`, `rejected`, `suspended`, `deleted` ;
- RLS renforcée : un compte non validé ne peut pas envoyer/modifier de pronostics ;
- messages d'erreur de connexion plus explicites ;
- cache PWA incrémenté en V0.1.1.

## V0.2.0 — Phase de ligue & pronostics

- gestion de plusieurs journées UEFA ;
- sélecteur de journées et progression par journée ;
- calendrier de saison ;
- cartes matchs enrichies avec logos et stade ;
- historique personnel des pronostics ;
- journal technique des modifications de pronostics ;
- gestion des reports et annulations ;
- match reporté à nouvelle date de nouveau modifiable avant coup d'envoi ;
- création manuelle de journées et matchs ;
- gestion Admin LIVE / Terminé / Reporté / Annulé / Réouvert ;
- barème serveur 0/3/5/7 conservé ;
- recalcul serveur conservé et étendu aux changements de statut ;
- clubs enrichis avec identifiants externes, TLA, stade et sources de logos ;
- bucket Supabase Storage `club-logos` ;
- Edge Function `sync-football-data` ;
- synchronisation clubs + blasons ;
- import des journées 1 à 8 de la phase de ligue ;
- résultats toujours manuels en V0.2.0 ;
- cache PWA mis à jour en 0.2.0.
