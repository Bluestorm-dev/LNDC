# Checklist de validation — V0.3.3

## 1. Release

- [ ] `VERSION` contient `0.3.3`.
- [ ] `config.js` contient `APP_VERSION: "0.3.3"`.
- [ ] `sw.js` utilise `nid-champions-v0.3.3`.
- [ ] `008_patch_v0.3.3_navigation_catalogue_clubs.sql` s'exécute sans erreur.
- [ ] `club_catalog_memberships` existe et est lisible par un utilisateur authentifié.
- [ ] `sync-football-data` V0.3.3 est redéployée après le SQL.

## 2. Navigation clavier — départ A

Sur trois matchs non verrouillés, sans utiliser les boutons +/- :

- [ ] cliquer dans A1 ;
- [ ] taper `1` → focus automatique sur B1 ;
- [ ] taper `0` → focus automatique sur A2 ;
- [ ] taper `2` → focus automatique sur B2 ;
- [ ] taper `1` → focus automatique sur A3 ;
- [ ] les valeurs sont autosauvegardées.

Résultat attendu : `A1 → B1 → A2 → B2 → A3…`.

## 3. Navigation clavier — départ B

Sur un autre match non verrouillé :

- [ ] cliquer dans B1 ;
- [ ] taper `0` → focus automatique sur A1 ;
- [ ] taper `1` → focus automatique sur A2 ;
- [ ] taper `2` → focus automatique sur B2 ;
- [ ] taper `0` → focus automatique sur A3.

Résultat attendu : `B1 → A1 → A2 → B2 → A3…`.

## 4. Boutons + / −

- [ ] cliquer dans A d'un match ;
- [ ] utiliser `+` plusieurs fois jusqu'à 10 ou 11 ;
- [ ] le focus ne saute pas sur B ;
- [ ] utiliser `−` ;
- [ ] le focus reste inchangé ;
- [ ] la valeur est sauvegardée.

## 5. Champions League inchangée

- [ ] `Clubs C1 + logos` fonctionne ;
- [ ] résumé C1 = 36 clubs ;
- [ ] résumé C1 = 36 logos exploitables ;
- [ ] `Calendrier CL` = 144 matchs ;
- [ ] 8 journées × 18 matchs ;
- [ ] aucun résultat historique importé ;
- [ ] les matchs TEST utilisent toujours les bons logos.

## 6. Bibliothèque Top 5

Cliquer **Bibliothèque Top 5 + logos**.

- [ ] l'action termine sans erreur 403/404/429 ;
- [ ] le retour Admin donne un total de clubs uniques et de logos ;
- [ ] le filtre `Ligue 1` affiche des clubs ;
- [ ] le filtre `Premier League` affiche des clubs ;
- [ ] le filtre `Liga` affiche des clubs ;
- [ ] le filtre `Serie A` affiche des clubs ;
- [ ] le filtre `Bundesliga` affiche des clubs ;
- [ ] `Tous les clubs` regroupe la bibliothèque ;
- [ ] les logos visibles correspondent aux clubs ;
- [ ] un club présent en C1 + championnat national n'apparaît qu'une fois dans `clubs`.

## 7. Club de cœur

- [ ] ouvrir Mon profil ;
- [ ] saisir quelques lettres d'un club Top 5 ;
- [ ] l'autocomplétion propose le club ;
- [ ] choisir le club puis enregistrer ;
- [ ] le nom canonique est sauvegardé ;
- [ ] le blason du club apparaît dans le badge Club de cœur ;
- [ ] un nom libre hors bibliothèque reste accepté.

## 8. Non-régression V0.3.2

- [ ] cotes 1/N/2 visibles quand le triplet existe ;
- [ ] bouton Admin `Cotes 1N2` fonctionne ;
- [ ] Classements Général/Journée/Soirée/Précision/Exacts fonctionnent ;
- [ ] scores LIVE Admin recalculent le classement ;
- [ ] Realtime fonctionne sans refresh ;
- [ ] points 0/3/5/7 inchangés.

## 9. GO V0.3.3

- [ ] aucun 404 RPC ;
- [ ] aucune erreur JavaScript bloquante ;
- [ ] aucune erreur Supabase sur `club_catalog_memberships` ;
- [ ] navigation A/B conforme dans les deux sens ;
- [ ] catalogue Top 5 exploitable pour le Club de cœur ;
- [ ] ZIP final testé après extraction.
