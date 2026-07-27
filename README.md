# Le Nid des Champions — V0.6.6

## Drapeaux identiques sur tous les appareils

V0.6.6 reprend V0.6.5 et remplace les emojis de pays par des drapeaux SVG servis par FlagCDN. Les codes de pays restent déterminés localement par le Nid ; seul le visuel du drapeau est chargé depuis le CDN. Un fallback texte est prévu si le CDN est indisponible. Angleterre, Écosse, Pays de Galles et Irlande du Nord utilisent leurs drapeaux propres. Aucun SQL n'est nécessaire.

---

## Correctif Web Push immédiat & Test Cron

V0.6.5 reprend V0.6.4 et ajoute la déconnexion dans Profil.

V0.6.4 part de V0.6.3 et fiabilise toute la chaîne Web Push :

- un compte joueur peut enregistrer son propre appareil même si le même navigateur avait auparavant été utilisé par un autre compte ;
- la RLS reste stricte : le transfert d'un endpoint existant n'est accepté que si les clés cryptographiques de l'abonnement correspondent ;
- toute notification créée avec `push_requested=true` et sans heure programmée déclenche désormais immédiatement `push-dispatch` via `pg_net` ;
- le Cron ne sert plus à attendre les actions humaines : il traite uniquement les événements programmés et joue le rôle de filet de secours ;
- le Cron passe à une vérification **chaque minute** ;
- le Super Admin dispose d'un **Test Cron** à heure réglable ;
- le test Push immédiat envoie exactement le titre et le texte présents dans les champs ;
- les messages Hibou / système / Team / rivalité / réaction utilisent le même mécanisme immédiat central ;
- les clés VAPID existantes ne doivent pas être régénérées.

Mise à jour : exécuter `sql/HOTFIX_V0.6.4_EXISTING_DB.sql`, redéployer `push-dispatch`, puis déployer le front V0.6.4.

---

# Historique fonctionnel — V0.6.0

## Hibou, rivalités & notifications

La V0.6.0 fait entrer le Nid dans sa phase **communication** : le joueur dispose d’un centre de notifications interne, de Web Push multi-appareils, d’un rival principal avec un duel par journée UEFA et d’un véritable canal privé avec le Hibou masqué.

### Notifications

- cloche avec compteur non lu et filtres `Toutes / Matchs / Rival / Team / Hibou / Système` ;
- lu/non lu, suppression et « tout marquer comme lu » ;
- liens profonds vers pronostics, Team, rival ou conversation ;
- préférences par catégorie ;
- rappels 24 h / 3 h / 1 h / 30 min, avec **3 h + 30 min activés par défaut** ;
- quiet hours **23 h → 8 h** configurables selon le fuseau de l’appareil ;
- notifications regroupées pour éviter le spam ;
- Web Push via l’Edge Function `push-dispatch` et VAPID ;
- plusieurs appareils par joueur, désactivation et nettoyage des abonnements invalides.

### Rivalités

- un rival principal parmi tous les joueurs actifs, même dans sa propre Team ;
- aucune acceptation du rival ; il est immédiatement prévenu ;
- un changement maximum par journée UEFA et verrouillage au premier coup d’envoi ;
- un duel par journée, égalité = nul ;
- rivalité mutuelle détectée ;
- historique conservé lors des changements de rival ;
- fiche complète : bilan, points, plus grosse victoire/défaite, série, trajectoire et anciens rivaux ;
- aperçu rapide depuis le classement ;
- provocations du Hibou réglables : Sage, Piquant, Sans pitié ou Automatique.

### Hibou & tickets

- messages du Hibou globaux, ciblés Team ou ciblés joueur ;
- Super Admin : envoi central ou depuis le profil rapide d’un joueur ;
- tickets privés `Bug / Suggestion / Question / Modification / Autre` ;
- vraie conversation joueur ↔ Hibou ;
- 3 captures maximum, PNG/JPG/WebP, 5 Mo chacune ;
- diagnostic technique automatique pour un ticket Bug ;
- seul le Super Admin accède aux tickets ;
- priorité décidée par le Super Admin ;
- le joueur peut marquer son ticket comme résolu.

### Administration Push

- journal de livraisons avec destinataire, appareil, statut et erreur ;
- **Test Push Super Admin** vers soi-même ou un joueur précis ;
- test rapide et test personnalisé ;
- pas de bouton de test global dans cette version ;
- messages système critiques séparés des messages ordinaires du Hibou.

### Mise à jour depuis V0.5.5a

1. Sauvegarder Supabase.
2. Exécuter `sql/HOTFIX_V0.6.0_EXISTING_DB.sql` avec le rôle postgres.
3. Déployer `supabase/functions/push-dispatch`.
4. Générer/configurer les clés VAPID et `PUSH_CRON_SECRET`.
5. Planifier `push-dispatch` toutes les 15 minutes avec `sql/ENABLE_PUSH_CRON_V0.6.0_TEMPLATE.sql`.
6. Déployer le front en conservant les vraies valeurs de `config.js`.
7. Faire `Ctrl + F5` ou relancer la PWA.
8. Exécuter `node tests/release-v0.6.0.mjs` puis suivre `docs/TEST_CHECKLIST_V0.6.0.md`.

Notice complète : `installation/INSTALLATION_V0.6.0.txt`.

Pour une base neuve : `sql/000_INSTALL_FRESH_V0.6.0.sql`.

> Les secrets VAPID privés, le service role et le secret Cron ne doivent jamais être placés dans le front ou dans GitHub.

---

# Historique V0.5.x

## V0.5.5a — Correctif Teams avant V0.6.0

Petit correctif de finition basé sur V0.5.5.

### Prévisualisation Team

- les couleurs et le motif du blason sont toujours repris dans la mini-carte de prévisualisation ;
- le motif est désormais **suggéré** en arrière-plan : atténué, agrandi et recouvert d’un voile sombre ;
- le texte, le nombre de membres et le nom de Team restent lisibles même avec des bandes rouges/blanches ou des quartiers très contrastés.

### Quitter / dissoudre / reprendre

- un capitaine **seul peut maintenant quitter sa Team sans la dissoudre** ;
- la Team devient alors **vacante**, reste dans l’annuaire et peut être reprise ;
- le premier joueur qui reprend une Team vacante en devient capitaine ;
- une Team explicitement dissoute reste archivée ;
- son dernier capitaine peut la **réactiver** depuis le bloc « Anciennes Teams » ;
- une Team déjà dissoute en V0.5.5 peut donc être récupérée après installation de ce correctif.

### Modération Super Admin

- l’Admin peut toujours dissoudre une Team ;
- **seul le Super Admin** dispose de `Supprimer définitivement` ;
- la suppression physique efface la Team et les données communautaires liées par cascade ;
- l’action est inscrite dans `audit_logs` avant suppression ;
- le front tente également de supprimer le logo uploadé actuellement utilisé dans le bucket `team-logos`.

### Mise à jour depuis V0.5.5

1. Sauvegarder la base Supabase.
2. Exécuter `sql/HOTFIX_V0.5.5a_EXISTING_DB.sql` avec le rôle postgres.
3. Déployer les fichiers front V0.5.5a.
4. Conserver les vraies valeurs de `config.js`.
5. Faire `Ctrl + F5` ou fermer/réouvrir la PWA.
6. Suivre `docs/TEST_CHECKLIST_V0.5.5a.md`.

Pour une base neuve : `sql/000_INSTALL_FRESH_V0.5.5a.sql`.

---


## V0.5.5 — Finitions accueil & Teams

Cette version termine les ajustements de la branche V0.5 avant la V0.6.0.

### Nouveautés

- l’avatar/logo personnel est affiché **en grand sur l’accueil**, avec l’habillage Team s’il existe ;
- un onglet **⚙ Gestion** rend enfin visibles les actions de Team : quitter, transférer le capitanat, exclure un membre, invitations, demandes et dissolution ;
- le capitaine peut **transférer puis quitter** en une seule séquence guidée ;
- l’atelier Team propose désormais des fonds deux couleurs de type blason : moitiés, bandes et quartiers, en plus des dégradés ;
- la prévisualisation Team utilise le **vrai avatar du joueur**, et non plus une simple initiale ;
- l’épaisseur du cadre Team autour des avatars et blasons est légèrement réduite.

### Mise à jour depuis V0.5.4

1. Dans Supabase > SQL Editor, exécuter `sql/HOTFIX_V0.5.5_EXISTING_DB.sql` avec le rôle postgres.
2. Déployer tous les fichiers front V0.5.5.
3. Conserver les vraies valeurs de `config.js`.
4. Faire `Ctrl + F5` ou fermer/réouvrir la PWA.
5. Suivre `docs/TEST_CHECKLIST_V0.5.5.md`.

Le HOTFIX **ne recrée pas les Teams** : il élargit uniquement la liste des styles de fond autorisés et met à jour la fonction de création.

Notice détaillée : `installation/INSTALLATION_V0.5.5.txt`.

---


## V0.5.4 — Réorganisation du front

La V0.5.4 ne change **aucune règle de jeu et aucun schéma Supabase**. Elle range le projet avant la suite du développement afin d’éviter de dépendre d’un unique `app.js` et d’un unique `app.css`.

### Nouvelle structure

- `js/` remplace `assets/js/` et découpe le JavaScript en 12 fichiers spécialisés ;
- `css/` remplace `assets/css/` et découpe le thème en 8 feuilles thématiques ;
- `js/app.js` reste le point d’orchestration et de démarrage, mais ne porte plus toute l’application ;
- `installation/` regroupe toutes les notices historiques `INSTALLATION_V*.txt` ;
- `assets/` est désormais réservé aux ressources statiques : avatars, icônes, branding et manifeste ;
- `sw.js`, `index.html` et le manifeste assets utilisent les nouveaux chemins ;
- le cache PWA passe à `nid-champions-v0.5.4`.

### Mise à jour depuis V0.5.3

Cette version est **front-only**.

1. Ne modifier aucune table Supabase.
2. Conserver les vraies valeurs de `config.js`.
3. Déployer la V0.5.4 complète.
4. Supprimer les anciens dossiers `assets/js/` et `assets/css/` du dépôt s’ils subsistent.
5. Faire `Ctrl + F5` ou fermer/réouvrir la PWA.
6. Suivre `docs/TEST_CHECKLIST_V0.5.4.md`.

Notice détaillée : `installation/INSTALLATION_V0.5.4.txt`.

---


## V0.5.3 — Avatars joueurs

La V0.5.3 ajoute l’identité visuelle personnelle complète des joueurs sans modifier le moteur de pronostics ni le système Teams.

### Bibliothèque officielle

- **90 avatars PNG 512×512** livrés dans `assets/avatars/nid/` ;
- catalogue machine dans `assets/avatars/avatar-catalog.json` ;
- manifeste global dans `assets/assets-manifest.json` ;
- sélection depuis le Profil ;
- aperçu immédiat avec le cadre, la forme, les couleurs et le logo de la Team du joueur ;
- compatibilité automatique avec les anciennes clés `owl-gold`, `owl-blue` et `owl-violet`.

### Upload personnel & modération

- PNG, JPG/JPEG ou WebP ;
- limite : **3 Mo** ;
- bucket Supabase Storage privé `player-avatars` ;
- écriture RLS limitée au dossier `<auth.uid()>/...` ;
- un upload passe en état `pending` et reste remplacé publiquement par l’avatar officiel tant qu’un Admin ne l’a pas validé ;
- Admin / Super Admin : validation ou refus avec motif facultatif ;
- chaque décision de modération est inscrite dans `audit_logs`.

### Intégration UI

Le même composant avatar est utilisé dans la **sidebar**, le **profil**, les **classements** (y compris le classement LIVE), les **Teams**, les listes de membres/demandes et les **pronostics révélés après verrouillage**. L’habillage Team reste autour de l’avatar et ne remplace jamais l’image personnelle.

### Mise à jour depuis V0.5.2

1. Sauvegarder la base Supabase.
2. Exécuter `sql/HOTFIX_V0.5.3_EXISTING_DB.sql` dans **Supabase > SQL Editor** avec le rôle `postgres`.
3. Déployer le front V0.5.3 en conservant les vraies valeurs de `config.js`.
4. Faire `Ctrl + F5` ou fermer/réouvrir la PWA.
5. Suivre `docs/TEST_CHECKLIST_V0.5.3.md`.

Pour une base neuve, utiliser `sql/000_INSTALL_FRESH_V0.5.3.sql`.

---

## V0.5.2 — Teams · correction UX/UI

La V0.5.2 conserve **tout le moteur Teams de la V0.5.0** et reprend entièrement son configurateur visuel.

### Atelier Team

- grande modale desktop en deux zones : **réglages à gauche, aperçus à droite** ;
- les 12 formes et 12 cadres sont visibles immédiatement sous forme de grilles ;
- le cadre/matière suit réellement la géométrie choisie : cercle, hexagone, écusson, losange, royal, etc. ;
- les logos de bibliothèque n’ont plus de fond opaque et laissent voir les couleurs du blason ;
- choix explicite entre **1 couleur** et **2 couleurs** ;
- avec 1 couleur : fond uni ;
- avec 2 couleurs : vertical, horizontal, diagonal, radial ou halo ;
- presets : Champions bleu, Or royal, Bois forêt, Obsidienne et Néon ;
- aperçu distinct du blason Team, de l’avatar membre, d’une ligne de classement et d’une carte Team ;
- aperçu local immédiat des logos uploadés avant l’enregistrement ;
- bouton **Réinitialiser le style**.

### Mise à jour depuis V0.5.0

Cette version est **front-only**.

1. Conserver la base Supabase déjà migrée en V0.5.0.
2. Remplacer le front par la V0.5.2 en gardant les vraies clés de `config.js`.
3. Faire `Ctrl + F5`.
4. Tester le configurateur avec `docs/TEST_CHECKLIST_V0.5.2.md`.

> Aucun SQL et aucune Edge Function supplémentaires ne sont nécessaires.

---


## V0.5.0 — Teams

La V0.5.0 transforme les Teams en véritables identités visuelles et communautaires, tout en conservant le moteur football V0.4.2. Un joueur ne peut appartenir qu’à **une seule Team active par saison** et les points restent attribués à la Team dont il était membre au coup d’envoi du match.

### Fonctionnalités Teams

- création d’une Team publique ou privée ;
- nom unique, slogan et description courte ;
- **équipe fétiche optionnelle**, indépendante du club de cœur du joueur ;
- un seul capitaine, automatiquement le créateur ;
- transfert obligatoire du capitanat avant le départ du capitaine ;
- Team privée par demande d’adhésion **ou** code d’invitation ;
- exclusion, départ et dissolution avec historique ;
- dissolution non destructive : palmarès et historique sont conservés ;
- classement Teams par **moyenne**, **Top 3** et **journée UEFA** ;
- changements de Team non rétroactifs pour les points.

### Identité visuelle

Chaque Team choisit une signature appliquée autour des avatars de ses membres :

- 12 formes : cercle, médaillon, carré, losange, hexagone, écussons, bouclier, bannière, royal, prestige… ;
- 12 cadres/matières : bois, bronze, argent, or, or royal, acier, cuir, obsidienne, néon, Champions, royal et nuit européenne ;
- deux couleurs ;
- fond uni, dégradé vertical/horizontal/diagonal, radial ou halo ;
- logo de bibliothèque ou upload personnel ;
- aperçu en direct avant enregistrement.

L’avatar personnel reste au premier plan : l’habillage Team sert à reconnaître immédiatement les membres d’un même groupe dans les classements, profils et pronostics révélés.

### Hibou masqué officiel

Le Hibou masqué validé est livré dans `assets/branding/owl/owl-masked-main.png` et référencé dans `docs/ASSETS_MANIFEST.md`. Il possède un vrai canal alpha transparent, une cape bleu nuit/or, un masque, un front vierge, un médaillon vierge et aucun ballon.

### Mise à jour depuis V0.4.2

1. Sauvegarder la base Supabase.
2. Exécuter `sql/HOTFIX_V0.5.0_EXISTING_DB.sql` dans **Supabase > SQL Editor** avec le rôle `postgres`.
3. Remplacer les fichiers du front par ceux de la V0.5.0, en conservant les vraies clés de `config.js`.
4. Faire `Ctrl + F5` après déploiement.
5. Tester la création d’une Team, l’adhésion et les trois classements avec `docs/TEST_CHECKLIST_V0.5.0.md`.

Pour une base vierge, utiliser `sql/000_INSTALL_FRESH_V0.5.0.sql`.

> Aucun redéploiement d’Edge Function n’est nécessaire pour le module Teams. Le bucket public `team-logos` est créé par la migration.

---


## V0.4.0 — Champions & phases finales

La V0.4.0 étend le Nid à **toute la compétition** : le joueur peut désormais traverser la phase de ligue puis les barrages, huitièmes, quarts, demi-finales et finale sans changer d'outil.

### Champions

- **Champion 1 : +100 points**, choix ouvert jusqu'au premier coup d'envoi ;
- si le joueur oublie son premier choix, **Olympique de Marseille est attribué automatiquement** au passage du premier match en LIVE/Terminé ;
- **Champion 2 : +50 points**, ouvert après la phase de ligue et verrouillé au début des phases finales ;
- les deux choix restent **cachés aux autres joueurs avant leur verrouillage** ;
- le même club peut être choisi deux fois : all-in possible à **150 points** ;
- lorsqu'un club choisi est éliminé, son état est visible dans le centre Champions.

### Phases finales

- confrontations aller-retour de Barrages à Demi-finales ;
- finale en match unique ;
- **cumul automatique** des deux manches ;
- aucune règle des buts à l'extérieur ;
- en cas d'égalité au cumul, le retour passe par la prolongation et le score saisi/pronostiqué est le **score à 120 minutes** ;
- si l'égalité subsiste, les **tirs au but** sont saisis séparément et ne sont jamais ajoutés au score/cumul ;
- le qualifié est calculé côté serveur puis automatiquement injecté dans le tour suivant.

### Pronostic du qualifié

Chaque confrontation possède un choix « Qualifié » distinct du score :

- bon qualifié choisi avant l'aller : **+3 points** ;
- le choix peut réellement être modifié après l'aller et avant le retour, mais son bonus tombe alors à **+1 point** ;
- revalider exactement le même club après l'aller ne réduit pas le bonus ;
- le choix est verrouillé au retour (ou au coup d'envoi de la finale).

### Multiplicateurs

Les scores conservent le barème **0 / 3 / 5 / 7**. L'Admin peut appliquer **x1 / x2 / x3 / x4** par phase et surcharger un match précis. Les bonus qualifié et champions ne sont pas multipliés.

### Classement

Le classement général V0.4.0 additionne :

`points des matchs + bonus qualifiés + bonus champions`

Les exacts, la précision et la moyenne restent basés sur les pronostics de scores afin de ne pas fausser les départages.

### Tableau TEST et tirage réel

Le bouton Admin **Générer tableau TEST** crée un chemin de 23 confrontations : **8 barrages → 8 huitièmes → 4 quarts → 2 demies → 1 finale**. Les matchs des tours suivants naissent automatiquement lorsque les deux qualifiés sont connus.

Pour la vraie compétition, le bloc Admin **Créer une confrontation réelle** permet de saisir chaque affiche officielle, ses dates aller/retour ou la finale en match unique. Une correction du tirage avant coup d’envoi met également à jour les matchs déjà programmés.

Voir `docs/TEST_CHECKLIST_V0.4.0.md`.

---

## Navigation A/B & bibliothèque clubs

V0.3.4 conserve tout le socle V0.3.2 (Classements & Live, logos TEST corrigés et cotes 1N2) et ajoute deux améliorations demandées pour l'usage quotidien.

### Saisie clavier

La navigation est maintenant symétrique :

- départ sur A : `A1 → B1 → A2 → B2 → A3…` ;
- départ sur B : `B1 → A1 → A2 → B2 → A3…` ;
- le passage à `A` du match suivant n'arrive qu'après la seconde saisie clavier du match ;
- `+ / −` modifie uniquement le score ciblé et ne déplace jamais le focus.

### Bibliothèque clubs Top 5

L'Admin dispose d'un bouton **Bibliothèque Top 5 + logos** qui récupère les équipes courantes et leurs blasons pour :

- Ligue 1 (`FL1`) ;
- Premier League (`PL`) ;
- Liga (`PD`) ;
- Serie A (`SA`) ;
- Bundesliga (`BL1`).

Ces clubs sont stockés dans la même table `clubs`, sans doublon lorsqu'un club est aussi en Champions League. La table `club_catalog_memberships` mémorise les championnats auxquels il appartient. Le catalogue est indépendant de la saison TEST C1 : importer le Top 5 ne modifie ni les 144 matchs, ni les journées, ni les scores, ni les cotes Champions League.

Dans **Mon profil**, le champ Club de cœur propose les clubs importés en autocomplétion. Lorsqu'un club connu est choisi, son blason est affiché dans le profil. Un nom libre reste accepté pour les clubs hors catalogue.

## Cotes 1N2 — V0.3.2

Chaque match peut désormais stocker :

- cote **1** — victoire domicile ;
- cote **N** — match nul ;
- cote **2** — victoire extérieure ;
- fournisseur technique ;
- bookmaker/libellé de source ;
- date de mise à jour ;
- saison source lorsqu’une cote historique est utilisée dans la saison TEST transposée.

Les cotes apparaissent dans une barre premium sous la carte du match :

`Cotes 1N2 · Bet365   1 1,85   N 3,60   2 4,20`

Aucune cote n’est inventée en production. Si aucune source ne renvoie les trois valeurs, la barre n’est pas affichée.

### Sources des cotes

La V0.3.2 utilise **deux niveaux de source** :

1. **Football-Data**, déjà relié au Nid. La réponse Match peut contenir un objet `odds` avec `homeWin`, `draw` et `awayWin`. Pour la saison TEST, c’est la source prioritaire : les rencontres proviennent réellement de 2025/26 avant d’être transposées d’un an dans le Nid.
2. **Odds-API.io**, complément optionnel via l’Edge Function `sync-odds`. La clé `ODDS_API_KEY` reste côté Supabase. Cette source recherche les véritables rencontres Champions League à venir, rapproche équipes + horaire, puis lit le marché Match Result / ML auprès des bookmakers configurés.

Le bouton Admin **Cotes 1N2** tente d’abord Football-Data, puis le complément externe lorsqu’il est déployé et configuré. Les appels externes de cotes sont groupés jusqu’à 10 événements par requête.

Pour la saison TEST actuelle, les rencontres 2025/26 sont transposées en 2026/27, mais une cote Football-Data reste explicitement marquée **source 2025/26**. Une API de cotes courantes peut logiquement ne trouver aucune correspondance sur ce calendrier artificiellement décalé ; dans ce cas le Nid laisse la rencontre sans cote plutôt que de faire une association douteuse.

Les scores, statuts, dates et rattachements de clubs ne sont jamais modifiés par l’action « Cotes 1N2 ».

> Important : Football-Data ne renvoie pas nécessairement les cotes avec tous les abonnements. Si aucune source ne fournit les trois valeurs, aucune cote n’est inventée et la carte du match reste inchangée.


## Correctifs V0.3.1

Cette release corrige deux défauts visibles après la première mise en situation réelle et accélère fortement la saisie des pronostics :

- **Journée TEST** : les anciens clubs créés à la main sont rattachés aux clubs Football-Data canoniques après synchronisation. Les matchs TEST affichent donc les **bons blasons importés** ;
- les anciens doublons de clubs TEST sont désactivés après rattachement ;
- l'importeur privilégie le blason réellement renvoyé par Football-Data avant son URL générique ;
- le résumé Admin ne montre plus `0 clubs · 0 logos` après `Calendrier CL` : il recompte l'état réel de la base et affiche les totaux disponibles ;
- au clavier, un chiffre dans **A** place le focus sur **B** ; quand **B** est saisi et que les deux scores sont renseignés, le focus passe directement sur **A du match suivant** ;
- les boutons `+ / −` ne déplacent toujours jamais le focus.

### Critère de sortie V0.3.0

> Une soirée de Champions League peut être vécue en direct : l’Admin met les matchs LIVE, modifie les scores, les joueurs voient les résultats et le classement provisoire évoluer sans recharger la page, puis les points officiels sont figés à la fin des matchs.

## Correctifs V0.2.2 intégrés

La V0.3.0 inclut directement les correctifs qui devaient constituer V0.2.2 :

- source football-data.org **forcée sur la saison 2025/26** pour le jeu de test ;
- dates transposées d’un an dans la saison test 2026/27 ;
- **36 clubs strictement** ;
- **144 matchs strictement** de phase de ligue, soit **8 journées × 18 matchs** ;
- refus de l’import si les volumes ne correspondent pas ;
- suppression des anciens matchs football-data parasites, notamment l’ancien import à 188 rencontres ;
- aucun résultat historique 2025/26 importé : les matchs de la saison test repartent programmés ;
- synchronisation et affichage des logos des 36 clubs dans l’Admin ;
- saisie clavier accélérée : un chiffre dans A place le focus sur B, puis B passe sur A du match suivant quand les deux scores sont renseignés ;
- boutons `+ / −` utilisables pour 10, 11, etc. **sans voler ni déplacer le focus** ;
- autosauvegarde conservée ;
- Player, Admin et Super Admin actifs peuvent tous pronostiquer.

## Classements V0.3.0

### Général

Le classement général additionne les points officiels des matchs terminés et, lorsqu’un match est LIVE, les points provisoires calculés sur son score courant.

Départage unique :

1. points ;
2. scores exacts ;
3. moyenne de points par match scoré ;
4. bons écarts ;
5. pronostics joués ;
6. pseudo pour garantir un ordre déterministe.

Le rang utilise `row_number()` : deux joueurs ne partagent jamais le même numéro de rang.

### Variations et ligne personnelle

- variation `▲ / ▼` du rang général par rapport au classement avant la soirée de référence ;
- écarts avec le joueur du dessus et du dessous ;
- ligne du joueur connecté épinglée en bas du tableau pendant le scroll ;
- podium visuel premium pour les trois premières places.

### Vues disponibles

- **Général** ;
- **Journée** : uniquement les matchs de la journée UEFA sélectionnée ;
- **Soirée** : uniquement les matchs de la date européenne de référence ;
- **Précision** : tri par taux de bons résultats ;
- **Exacts** : tri par nombre de scores exacts.

## LIVE V0.3.0

### Admin

Chaque match dispose d’une saisie de score et des actions :

- Passer LIVE ;
- Actualiser LIVE ;
- Terminer ;
- Reporter ;
- Annuler ;
- Réouvrir.

Le score LIVE est enregistré en base. Une modification du score déclenche le recalcul du classement provisoire côté serveur, sans écrire de faux points officiels dans les pronostics.

### Realtime

La migration V0.3.0 ajoute `matches` et `predictions` à la publication Supabase Realtime lorsque nécessaire. Le client écoute les changements de la saison active et rafraîchit :

- scores et statuts ;
- bandeau LIVE ;
- classement provisoire ;
- variations ;
- statistiques collectives.

Les politiques RLS existantes continuent de cacher les pronostics adverses avant le verrouillage.

## Pronostics adverses

Dès qu’un match est verrouillé, le bouton **Voir les pronos du Nid** affiche les prédictions des membres actifs et leurs points courants sur le score LIVE/final. Avant le verrouillage, la fonction serveur refuse la révélation.

## Statistiques collectives

Les statistiques n’utilisent que les pronostics de matchs déjà verrouillés :

- répartition victoire domicile / nul / victoire extérieure ;
- cinq scores les plus joués ;
- nombre de scores exacts ;
- nombre de pronostics déjà confrontés à un score ;
- **Fiabilité du Nid** : proportion de bons résultats parmi les pronostics confrontés à un score LIVE ou final.

## UI/UX V0.3.0

- bleu nuit profond, violet électrique, cyan et touches or ;
- halos de stade et fond étoilé ;
- cartes translucides ;
- bandeau `LIVE` pulsé ;
- podium premium ;
- variations de rang animées visuellement ;
- tableau de classement sticky ;
- cartes collectives dédiées ;
- matchs LIVE mis en évidence ;
- responsive desktop/mobile conservé.

## Mise à jour depuis une V0.3.2

1. Exécuter `sql/008_patch_v0.3.4_navigation_catalogue_clubs.sql` (ou `HOTFIX_V0.3.4_EXISTING_DB.sql`) dans Supabase SQL Editor.
2. Redéployer `supabase/functions/sync-football-data/index.ts`.
3. Vérifier le secret serveur `FOOTBALL_DATA_API_KEY`.
4. Déployer les fichiers web V0.3.4.
5. Recharger la PWA avec `Ctrl + F5` ; cache attendu : `nid-champions-v0.3.4`.
6. Dans Admin, relancer **Clubs C1 + logos** une fois afin d'enregistrer l'appartenance C1 canonique.
7. Lancer **Bibliothèque Top 5 + logos** pour importer les cinq championnats.
8. Vérifier le filtre de bibliothèque et le champ **Club de cœur**.
9. Exécuter `docs/TEST_CHECKLIST_V0.3.4.md`.

Les réglages Odds V0.3.2 restent inchangés : `sync-odds`, `ODDS_API_KEY` et `ODDS_EXTERNAL_ENABLED` ne sont nécessaires que si la source de cotes externe est utilisée.

## Installation depuis une V0.2.0

1. Exécuter `sql/005_patch_v0.3.0_classements_live.sql`.
2. Exécuter `sql/006_patch_v0.3.1_logos_navigation.sql`.
3. Exécuter `sql/007_patch_v0.3.2_cotes_1n2.sql`.
4. Exécuter `sql/008_patch_v0.3.4_navigation_catalogue_clubs.sql`.
5. Redéployer `supabase/functions/sync-football-data/index.ts`.
6. Vérifier `FOOTBALL_DATA_API_KEY`.
7. Optionnel : conserver/déployer `sync-odds` pour les cotes externes.
8. Déployer les fichiers web V0.3.4 et forcer le renouvellement du cache PWA.

Il n’existe pas de migration SQL V0.2.2 séparée : ses correctifs sont intégrés dans le code des releases V0.3.x.

## Installation sur un Supabase neuf

Exécuter :

`sql/000_INSTALL_FRESH_V0.3.4.sql`

Puis promouvoir le premier Super Admin avec :

`sql/BOOTSTRAP_PARKAF_SUPER_ADMIN.sql`

Déployer ensuite les Edge Functions :

- `login-by-username` avec `verify_jwt = false` ;
- `sync-football-data` avec vérification JWT active ;
- `sync-odds` avec vérification JWT active si la source externe de cotes est utilisée.

## Configuration navigateur

`config.js` :

```js
window.NIDC_CONFIG = {
  SUPABASE_URL: "https://xxxxx.supabase.co",
  SUPABASE_ANON_KEY: "xxxxx",
  APP_VERSION: "0.3.4",
  DEFAULT_SEASON_SLUG: "ucl-2026-27",
  ODDS_EXTERNAL_ENABLED: false,
  DEMO_WHEN_UNCONFIGURED: true
};
```

## Synchronisation Football-Data

Dans l’Admin :

1. **Clubs C1 + logos** : saison TEST C1 2025/26, exactement 36 clubs ;
2. **Calendrier CL** : exactement 144 matchs, soit 8 journées × 18, transposés en 2026/27 ;
3. **Bibliothèque Top 5 + logos** : équipes courantes de `FL1`, `PL`, `PD`, `SA`, `BL1`, sans modifier le calendrier C1 ;
4. **Cotes 1N2** : comportement V0.3.2 conservé.

La bibliothèque autorise plusieurs appartenances pour un même club. Un Real Madrid présent en Liga et en C1 ne devient donc pas deux clubs différents.

## Mode démonstration

Sans Supabase configuré, l’application simule localement :

- pronostics et autosauvegarde ;
- Admin/Super Admin ;
- score LIVE ;
- classements Général/Journée/Soirée/Précision/Exacts ;
- statistiques collectives ;
- cotes 1N2 de démonstration uniquement pour valider le rendu ;
- révélation des pronostics après verrouillage.

Compte Admin de démonstration :

- pseudo : `Parkaf` ;
- mot de passe : n’importe quelle valeur non vide.

## Fichiers principaux V0.5.4

- `js/app.js` — orchestration et démarrage ;
- `js/core.js` — état partagé et utilitaires ;
- `js/predictions.js` — matchs et pronostics ;
- `js/ranking.js` — classements et live ;
- `js/teams.js` — Teams ;
- `js/avatars.js` / `js/profile.js` — avatars et profil ;
- `js/admin.js` — administration ;
- `css/` — feuilles de style thématiques ;
- `installation/` — notices de déploiement ;
- `sql/005_patch_v0.3.0_classements_live.sql` — fonctions serveur V0.3.0 ;
- `sql/006_patch_v0.3.1_logos_navigation.sql` — réparation des doublons TEST ;
- `sql/007_patch_v0.3.2_cotes_1n2.sql` — colonnes de cotes et passage base en V0.3.2 ;
- `sql/008_patch_v0.3.4_navigation_catalogue_clubs.sql` — table de catalogue et passage base en V0.3.4 ;
- `sql/000_INSTALL_FRESH_V0.3.4.sql` — installation complète sur projet neuf ;
- `supabase/functions/sync-football-data/index.ts` — synchro Football-Data stricte + récupération automatique des cotes si disponibles ;
- `supabase/functions/sync-odds/index.ts` — complément optionnel Odds-API.io, rapprochement des événements et récupération du marché 1N2 ;
- `docs/TEST_CHECKLIST_V0.3.0.md` — recette fonctionnelle Classements & Live ;
- `docs/TEST_CHECKLIST_V0.3.1.md` — recette logos TEST et navigation de saisie ;
- `docs/TEST_CHECKLIST_V0.3.2.md` — recette cotes 1N2 ;
- `docs/TEST_CHECKLIST_V0.3.4.md` — recette navigation bidirectionnelle et bibliothèque Top 5 ;
- `docs/CORRECTIFS_V0.2.2.md` — détail du correctif intégré ;
- `CHANGELOG.md` — historique de version ;
- `VERSION` — version de la release.

## Roadmap

La V0.3.4 consolide la saisie et la bibliothèque de clubs autour du jalon **Classements & Live**. La prochaine étape majeure du cahier des charges reste la V0.4.0 consacrée aux champions et aux phases finales.