# Road check manuel — Le Nid des Champions V0.9.0

Cette checklist complète la matrice historique V0.1 → V0.8.1. Elle sert à valider manuellement **Saison, carrière & mémoire** puis à refaire les régressions essentielles avant mise en production.

**Règle :** réaliser les tests destructifs (création d’une saison, changement de statut, clôture, etc.) sur une sauvegarde ou une saison de TEST avant de toucher à la saison réelle.

Nombre de contrôles V0.9.0 : **141**.

## Installation / migration

- [ ] **T1186** — Le dossier livré annonce VERSION = 0.9.0.
- [ ] **T1187** — config.js annonce APP_VERSION = 0.9.0.
- [ ] **T1188** — Le Service Worker utilise un cache nid-champions-v0.9.0.
- [ ] **T1189** — index.html charge css/career.css et js/career.js.
- [ ] **T1190** — HOTFIX_V0.9.0_EXISTING_DB.sql s'exécute sans erreur sur une base V0.8.1.
- [ ] **T1191** — Le HOTFIX conserve les données V0.8.1 existantes (joueurs, pronostics, Teams, badges, notifications, Centre C1).
- [ ] **T1192** — La table player_rank_history est créée.
- [ ] **T1193** — Les tables player_distinctions, polls, poll_options, poll_votes et season_memory_events sont créées.
- [ ] **T1194** — Les RPC V0.9.0 sont présents après migration.
- [ ] **T1195** — admin_run_diagnostics_v090 retourne zéro FAIL structurel avec un compte Super Admin.

## Multi-saisons

- [ ] **T1196** — Admin > Application affiche le panneau de gestion multi-saisons.
- [ ] **T1197** — Le Super Admin peut créer une nouvelle saison en préparation.
- [ ] **T1198** — Le slug proposé automatiquement est propre et modifiable.
- [ ] **T1199** — Deux saisons ne peuvent pas partager le même slug.
- [ ] **T1200** — La création peut copier le barème et les phases depuis la saison courante.
- [ ] **T1201** — Sans copie, les phases LEAGUE, barrages, huitièmes, quarts, demies et finale sont créées.
- [ ] **T1202** — Une nouvelle saison ne devient pas active automatiquement.
- [ ] **T1203** — Le Super Admin peut activer une saison.
- [ ] **T1204** — L'activation désactive automatiquement l'ancienne saison active.
- [ ] **T1205** — Une saison activée prend le statut En cours.
- [ ] **T1206** — Le Super Admin peut passer une saison en Préparation, En cours, Terminée ou Archivée.
- [ ] **T1207** — Une saison terminée/archivée n'est plus marquée active.
- [ ] **T1208** — Au démarrage de l'application, la saison active est prioritaire.
- [ ] **T1209** — Le sélecteur Saison affiche toutes les saisons avec leur statut.
- [ ] **T1210** — Changer de saison recharge matchs, pronostics, phases, Teams, classement, champions et mémoire de la bonne saison.
- [ ] **T1211** — Les données d'une saison ne se mélangent jamais à celles d'une autre saison.

## Profil saison

- [ ] **T1212** — L'onglet Saison > Ma saison affiche le rang actuel.
- [ ] **T1213** — Le meilleur rang de la saison est affiché.
- [ ] **T1214** — Le pire rang est calculé dans l'historique.
- [ ] **T1215** — La plus grosse remontée est calculée.
- [ ] **T1216** — La plus grosse chute est calculée.
- [ ] **T1217** — Les jours passés en tête évoluent avec l'historique de rang.
- [ ] **T1218** — Les jours en tête d'une saison terminée restent figés et ne continuent pas jusqu'à aujourd'hui.
- [ ] **T1219** — Les points de saison correspondent au classement officiel.
- [ ] **T1220** — La moyenne de points par match est correcte.
- [ ] **T1221** — Le pourcentage de précision est correct.
- [ ] **T1222** — Le nombre de scores exacts est correct.
- [ ] **T1223** — Le nombre de qualifiés correctement pronostiqués est correct.
- [ ] **T1224** — Le nombre d'oublis correspond aux matchs officiels terminés sans pronostic.
- [ ] **T1225** — Les Casseroles et leurs points sont comptés.
- [ ] **T1226** — Les coups de Génie et leurs points sont comptés.
- [ ] **T1227** — Les réussites et points Hibou solitaire sont comptés sans modifier le classement officiel.
- [ ] **T1228** — Les badges et records sont comptés.
- [ ] **T1229** — La forme récente affiche les cinq derniers verdicts.
- [ ] **T1230** — La courbe de rang se construit après plusieurs snapshots.
- [ ] **T1231** — Les distinctions permanentes apparaissent sur le profil de saison.

## Carrière

- [ ] **T1232** — L'onglet Carrière affiche un classement distinct du classement de saison.
- [ ] **T1233** — Le classement carrière cumule toutes les saisons réellement jouées.
- [ ] **T1234** — Les points carrière sont la somme des points officiels de chaque saison.
- [ ] **T1235** — Le nombre de saisons jouées ignore les saisons sans match joué ni point.
- [ ] **T1236** — La moyenne carrière est calculée sur l'ensemble des pronostics joués.
- [ ] **T1237** — Les scores exacts carrière sont cumulés.
- [ ] **T1238** — Les podiums ne sont comptés que sur les saisons Terminée/Archivée.
- [ ] **T1239** — Les titres ne sont comptés que sur les saisons Terminée/Archivée.
- [ ] **T1240** — Le nombre de badges carrière est correct.
- [ ] **T1241** — Le nombre de records carrière est correct.
- [ ] **T1242** — Le profil personnel affiche rang carrière, saisons, points, moyenne, podiums et titres.
- [ ] **T1243** — Le profil personnel liste les saisons jouées et permet d'ouvrir une ancienne saison.
- [ ] **T1244** — Le profil rapide d'un autre joueur affiche ses statistiques de saison et de carrière.
- [ ] **T1245** — Les records historiques personnels conservent les meilleures valeurs entre saisons.

## Hall of Fame

- [ ] **T1246** — L'onglet Hall of Fame regroupe les résultats par saison.
- [ ] **T1247** — Le champion, vice-champion et troisième sont affichés.
- [ ] **T1248** — Le meilleur scoreur de chaque saison est affiché.
- [ ] **T1249** — Le joueur avec le plus de scores exacts est affiché.
- [ ] **T1250** — La Poêle d'Or est affichée lorsqu'il existe des Casseroles.
- [ ] **T1251** — Le Génie de la saison est affiché lorsqu'il existe des événements Génie.
- [ ] **T1252** — Le Hibou solitaire de la saison est affiché.
- [ ] **T1253** — La meilleure Team de la saison est affichée.
- [ ] **T1254** — Les records du Nid récents sont conservés dans le Hall of Fame.
- [ ] **T1255** — Une saison sans donnée n'invente aucun héros ni valeur.

## Replay de saison

- [ ] **T1256** — L'onglet Replay affiche une chronologie datée.
- [ ] **T1257** — Un changement réel de leader crée un événement Nouveau leader.
- [ ] **T1258** — Deux snapshots consécutifs avec le même leader ne créent pas de faux changement.
- [ ] **T1259** — Les records du Nid apparaissent dans le replay.
- [ ] **T1260** — Les Casseroles publiques apparaissent dans le replay.
- [ ] **T1261** — Les coups de Génie publics apparaissent dans le replay.
- [ ] **T1262** — Les badges légendaires apparaissent dans le replay.
- [ ] **T1263** — L'élimination d'un choix Champion apparaît dans le replay.
- [ ] **T1264** — La finale terminée crée un événement de clôture.
- [ ] **T1265** — Un Admin peut ajouter un événement éditorial de mémoire via le RPC prévu sans casser le replay.

## Champion en titre / distinctions

- [ ] **T1266** — Sur une nouvelle saison, le vainqueur de la saison précédente est identifié comme Champion en titre.
- [ ] **T1267** — Le Champion en titre provient uniquement d'une saison Terminée/Archivée.
- [ ] **T1268** — Admin > Joueurs permet d'attribuer une distinction permanente.
- [ ] **T1269** — La distinction Champion du Nid 2026 peut être conservée d'une saison à l'autre.
- [ ] **T1270** — Mettre à jour une distinction existante ne crée pas de doublon pour le même code et joueur.

## Sondages généraux

- [ ] **T1271** — L'onglet Saison > Sondages affiche les sondages généraux de la saison.
- [ ] **T1272** — Les votes mensuels Casserole/Génie V0.8 restent séparés des sondages généraux.
- [ ] **T1273** — Le Super Admin peut créer un sondage avec titre, question et au moins deux réponses.
- [ ] **T1274** — Le Super Admin peut définir une durée de sondage.
- [ ] **T1275** — Un joueur authentifié peut voter sur un sondage ouvert.
- [ ] **T1276** — Le joueur peut changer son vote lorsque allow_change est activé.
- [ ] **T1277** — Un sondage fermé refuse tout nouveau vote.
- [ ] **T1278** — Un choix appartenant à un autre sondage est refusé.
- [ ] **T1279** — Les résultats peuvent être masqués avant fermeture.
- [ ] **T1280** — Quand les résultats sont visibles, pourcentages et nombres de votes sont cohérents.
- [ ] **T1281** — Le Super Admin peut fermer manuellement un sondage.

## Archives / intégrité

- [ ] **T1282** — Une saison Terminée/Archivée affiche clairement « Archive en lecture seule ».
- [ ] **T1283** — Un joueur ne peut pas créer ou modifier un pronostic de match dans une archive.
- [ ] **T1284** — Le recalcul serveur des points reste possible sans modifier le score pronostiqué.
- [ ] **T1285** — Un joueur ne peut pas modifier son pronostic qualifié dans une archive.
- [ ] **T1286** — Un joueur ne peut pas modifier son choix Champion dans une archive.
- [ ] **T1287** — Consulter une archive ne crée plus de snapshot quotidien qui ferait dériver les jours en tête.
- [ ] **T1288** — Réactiver explicitement une saison archivée la repasse En cours et la rend active.

## Régression V0.1 → V0.8.1

- [ ] **T1289** — Inscription, validation e-mail et connexion restent fonctionnelles.
- [ ] **T1290** — Les rôles player/admin/super_admin restent inchangés.
- [ ] **T1291** — Les pronostics 0/3/5/7 et l'autosauvegarde restent fonctionnels.
- [ ] **T1292** — Le verrouillage au coup d'envoi reste fonctionnel.
- [ ] **T1293** — Les classements Général/Journée/Soirée/Précision/Exacts restent fonctionnels.
- [ ] **T1294** — Le LIVE et Realtime restent fonctionnels.
- [ ] **T1295** — Les cotes 1N2 restent visibles lorsqu'elles existent.
- [ ] **T1296** — Les phases finales et pronostics qualifiés restent fonctionnels.
- [ ] **T1297** — Les deux choix Champion restent fonctionnels sur la saison active.
- [ ] **T1298** — Les Teams, rôles de capitaine et classements Team restent fonctionnels.
- [ ] **T1299** — Les avatars, notifications, Web Push, Hibou masqué, support et rivalités restent fonctionnels.
- [ ] **T1300** — Le Musée, badges, Casseroles, Génie, records et narrations restent fonctionnels.
- [ ] **T1301** — Le Centre C1 reste séparé du moteur de pronostics.
- [ ] **T1302** — Le 404 Football-Data 2026/27 reste traité comme season_not_available sans fallback 2025/26.
- [ ] **T1303** — Les Soirées européennes et Hibou de la nuit restent fonctionnels.
- [ ] **T1304** — Le Hibou solitaire reste un classement parallèle.
- [ ] **T1305** — Les votes mensuels V0.8 restent fonctionnels.
- [ ] **T1306** — Le système TEST Admin n'altère pas les données officielles.

## Mobile / PWA / robustesse

- [ ] **T1307** — Le nouvel écran Saison reste lisible sur 360–430 px.
- [ ] **T1308** — Le sélecteur de saison reste utilisable sur mobile.
- [ ] **T1309** — Le classement carrière défile horizontalement sans casser la page.
- [ ] **T1310** — Le Hall of Fame passe correctement en une colonne sur petit écran.
- [ ] **T1311** — Le Replay reste lisible sur mobile.
- [ ] **T1312** — Les sondages sont utilisables au toucher.
- [ ] **T1313** — Le panneau multi-saisons Admin reste utilisable sur tablette/mobile.
- [ ] **T1314** — Après déploiement, un Ctrl+F5 charge bien le cache V0.9.0.
- [ ] **T1315** — La PWA installée récupère V0.9.0 après fermeture/réouverture.
- [ ] **T1316** — Le chargement de la mémoire ne bloque pas l'ouverture générale de l'application en cas d'erreur V0.9.
- [ ] **T1317** — Le changement de saison ne laisse pas d'anciennes données visuelles d'une autre saison.
- [ ] **T1318** — Une saison avec beaucoup d'historique reste navigable sans ralentissement anormal.

## Validation de sortie

- [ ] **T1319** — node tests/run-all-v0.9.0.mjs termine avec 0 FAIL sur le dossier livré.
- [ ] **T1320** — Le Centre de tests V0.9.0 s'ouvre et récupère la session Supabase.
- [ ] **T1321** — Le diagnostic automatique V0.9.0 fusionne les contrôles historiques V0.1–V0.8.1 et les contrôles V0.9.
- [ ] **T1322** — Les états manuels OK/KO/N/A sont conservés localement.
- [ ] **T1323** — L'export JSON du Centre de tests contient la version 0.9.0.
- [ ] **T1324** — L'export CSV du Centre de tests contient les nouveaux tests V0.9.0.
- [ ] **T1325** — Le test distant --url vérifie VERSION, config.js, sw.js, index.html et js/career.js déployés.
- [ ] **T1326** — Une sauvegarde base + fichiers a été réalisée avant migration de production.

## Palmarès historique — Nid des Pronos / Coupe du monde 2026

- [ ] **T1327** — Super Admin > Mémoire permet de choisir manuellement le vainqueur du Nid des Pronos — Coupe du monde 2026.
- [ ] **T1328** — Attribuer le titre à un nouveau joueur désactive automatiquement l’ancien détenteur : un seul vainqueur actif existe.
- [ ] **T1329** — La distinction « Vainqueur du Nid des Pronos — Coupe du monde 2026 » apparaît sur le profil et dans la carrière du joueur, même en changeant de saison.
- [ ] **T1330** — Le Super Admin peut retirer le titre sans supprimer l’historique de la distinction.
