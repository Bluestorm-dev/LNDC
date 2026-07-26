# Checklist de validation — V0.3.0

## 1. Release / fichiers

- [ ] `VERSION` contient `0.3.0`.
- [ ] `config.js` contient `APP_VERSION: "0.3.0"`.
- [ ] `sw.js` utilise le cache `nid-champions-v0.3.0`.
- [ ] `README.md`, `CHANGELOG.md` et `INSTALLATION_V0.3.0.txt` sont présents.
- [ ] `sql/005_patch_v0.3.0_classements_live.sql` s'exécute sans erreur.
- [ ] `sql/000_INSTALL_FRESH_V0.3.0.sql` permet une installation neuve.
- [ ] L'Edge Function `sync-football-data` est redéployée.

## 2. Correctifs V0.2.2 — Football-Data

- [ ] Depuis l'Admin, lancer **Clubs + logos**.
- [ ] La réponse indique source `2025/26`.
- [ ] Exactement **36 clubs** sont synchronisés.
- [ ] Les **36 logos** sont visibles dans l'aperçu Admin.
- [ ] Aucun ancien club Football-Data hors périmètre ne reste actif.
- [ ] Lancer **Calendrier CL**.
- [ ] Exactement **144 matchs** sont importés.
- [ ] Exactement **8 journées** existent.
- [ ] Chaque journée contient exactement **18 matchs**.
- [ ] Les dates sont transposées dans la saison **2026/27**.
- [ ] Les anciens matchs parasites de l'import à 188 sont supprimés.
- [ ] Aucun score historique 2025/26 n'apparaît.
- [ ] Les matchs historiques `FINISHED` côté API sont `scheduled` dans le Nid de test.
- [ ] Un résultat déjà terminé manuellement dans le Nid n'est pas écrasé lors d'une resynchronisation.
- [ ] Une réponse API avec un volume différent de 36 clubs ou 144 matchs est refusée avec un message explicite.

## 3. Pronostics — clavier / autosave

- [ ] Connexion avec un Player actif.
- [ ] Un chiffre tapé dans A remplace le score A et place le focus sur B.
- [ ] Un chiffre tapé dans B remplace le score B et replace le focus sur A.
- [ ] La séquence `1`, `2`, `3`, `0` permet de saisir rapidement plusieurs matchs sans clics inutiles.
- [ ] Le bouton `+` passe 9 → 10 → 11.
- [ ] Le bouton `−` revient 11 → 10 → 9.
- [ ] Cliquer `+ / −` ne déplace pas le focus du champ actuellement actif.
- [ ] Le score reste borné entre 0 et 99.
- [ ] L'autosave affiche `✓ Enregistré`.
- [ ] Recharger la page conserve le prono.
- [ ] Connexion Admin : l'Admin peut pronostiquer.
- [ ] Connexion Super Admin : le Super Admin peut pronostiquer.
- [ ] Au coup d'envoi, les champs sont verrouillés.

## 4. Préparation du scénario LIVE

- [ ] Créer/identifier Joueur A.
- [ ] Créer/identifier Joueur B.
- [ ] Joueur A et Joueur B saisissent des pronostics différents sur la même soirée.
- [ ] Ouvrir simultanément une session Admin et au moins une session joueur.
- [ ] Vérifier que le badge backend indique `Supabase · LIVE` après abonnement Realtime.

## 5. Passage LIVE

- [ ] Admin saisit `1–0` sur Match 1.
- [ ] Admin clique **Passer LIVE**.
- [ ] Le match affiche `LIVE · 1–0` sans refresh chez les joueurs.
- [ ] Le bandeau rouge LIVE apparaît.
- [ ] Le badge **CLASSEMENT LIVE** apparaît.
- [ ] Les points provisoires sont recalculés.
- [ ] Les points officiels stockés du match non terminé ne sont pas modifiés.
- [ ] Une variation `▲`, `▼` ou `—` apparaît dans le classement général.
- [ ] La ligne de l'utilisateur connecté reste sticky pendant le scroll.
- [ ] Les écarts dessus/dessous sont cohérents.

## 6. Modification d'un score LIVE

- [ ] Admin remplace le score par `1–1`.
- [ ] Admin clique **Actualiser LIVE**.
- [ ] Le score joueur passe à `1–1` sans rechargement manuel.
- [ ] Le classement provisoire est recalculé immédiatement.
- [ ] Les rangs changent si le nouveau score le justifie.
- [ ] Les variations suivent le nouveau rang.
- [ ] Aucun badge/exploit définitif n'est validé sur le seul score provisoire.

## 7. Plusieurs matchs LIVE

- [ ] Passer au moins deux matchs LIVE simultanément.
- [ ] Le bandeau LIVE liste les deux rencontres.
- [ ] Le classement général cumule les deux scores provisoires.
- [ ] Le classement **Soirée** ne compte que la date concernée.
- [ ] Le classement **Journée** ne compte que la journée sélectionnée.

## 8. Départages / rang unique

Créer des données permettant de vérifier successivement :

- [ ] priorité aux points ;
- [ ] à points égaux, priorité aux scores exacts ;
- [ ] puis à la meilleure moyenne ;
- [ ] puis aux bons écarts ;
- [ ] puis au nombre de pronostics joués ;
- [ ] aucun numéro de rang n'est partagé ;
- [ ] ordre déterministe final par pseudo si tous les critères précédents sont identiques.

## 9. Vues de classement

- [ ] **Général** affiche points, exacts, précision, moyenne, écarts et joués.
- [ ] **Journée** se recalcule lors du changement de journée.
- [ ] **Soirée** se limite à la date de référence.
- [ ] **Précision** trie d'abord sur le pourcentage de bons résultats.
- [ ] **Exacts** trie d'abord sur le nombre de scores exacts.
- [ ] Podium 1/2/3 visuellement distinct.
- [ ] Tableau utilisable sur mobile avec scroll horizontal.

## 10. Révélation des pronostics

- [ ] Avant verrouillage, aucun bouton de révélation n'est proposé.
- [ ] Avant verrouillage, l'appel RPC direct à `get_match_predictions_v030` est refusé.
- [ ] Après verrouillage, **Voir les pronos du Nid** apparaît.
- [ ] Le modal montre les joueurs ayant pronostiqué.
- [ ] Le prono du joueur connecté est marqué `★`.
- [ ] En LIVE, les points courants correspondent au score courant.
- [ ] Après fin de match, les points affichés correspondent aux points officiels.

## 11. Statistiques collectives

- [ ] Aucun prono non verrouillé ne fuit dans les statistiques.
- [ ] La répartition `1 / N / 2` totalise environ 100 %.
- [ ] Les cinq scores les plus joués sont cohérents.
- [ ] Le compteur d'exacts évolue avec les scores LIVE/final.
- [ ] La Fiabilité du Nid correspond au taux de bons résultats sur les pronostics confrontés à un score.
- [ ] Les stats se mettent à jour après modification du score Admin.
- [ ] Les stats Journée/Soirée suivent le scope sélectionné.

## 12. Fin de match / barème officiel

- [ ] Admin clique **Terminer**.
- [ ] Le statut devient `Terminé` en Realtime.
- [ ] Faux résultat = **0 pt**.
- [ ] Bon vainqueur / bon nul = **3 pts**.
- [ ] Bon résultat + bon écart = **5 pts**.
- [ ] Score exact = **7 pts**.
- [ ] Les points officiels sont persistés par le mécanisme serveur existant.
- [ ] Exacts, précision et moyenne sont mis à jour.
- [ ] Historique personnel affiche le résultat et les points.
- [ ] Le classement provisoire rejoint le classement officiel pour ce match.

## 13. Reports / annulations / réouverture

- [ ] Reporter un match conserve les pronostics.
- [ ] Une nouvelle date future rend le prono à nouveau modifiable selon les règles existantes.
- [ ] Annuler neutralise le match.
- [ ] Réouvrir remet le statut à `scheduled` et efface le score LIVE/final du match.
- [ ] Le classement se recalcule après réouverture.

## 14. Realtime / multi-session

- [ ] Match LIVE visible sans refresh sur une deuxième session.
- [ ] Changement 1–0 → 1–1 visible sans refresh.
- [ ] Fin de match visible sans refresh.
- [ ] Une sauvegarde de prono personnel ne provoque pas de perte de focus sur la carte en cours.
- [ ] Les politiques RLS empêchent de lire les pronostics adverses avant verrouillage.
- [ ] Aucun événement d'une autre saison ne modifie l'écran de la saison active.

## 15. UI/UX premium

- [ ] Fond bleu nuit / violet, halos et touches or visibles.
- [ ] Contrastes lisibles sur desktop.
- [ ] Contrastes lisibles sur mobile.
- [ ] Bandeau LIVE ne masque pas la navigation.
- [ ] Pas de débordement horizontal global hors tableau de classement volontaire.
- [ ] Cartes matchs et logos restent lisibles en mobile.
- [ ] Les 36 logos de l'Admin peuvent être parcourus sans casser la page.
- [ ] Animations de LIVE non bloquantes.

## 16. PWA / régression

- [ ] Installation PWA possible.
- [ ] Cache `nid-champions-v0.3.0` créé.
- [ ] Ancien cache V0.2.0 supprimé à l'activation.
- [ ] Navigation Accueil / Pronostics / Classement / Saison / Profil / Admin fonctionne.
- [ ] Inscription pending → validation Super Admin fonctionne toujours.
- [ ] Connexion par pseudo fonctionne toujours.
- [ ] Profil modifiable.
- [ ] Mode démo démarre sans Supabase configuré.

## Critère GO V0.3.0

- [ ] Tous les tests critiques Football-Data, saisie, LIVE, classement, RLS et barème sont validés.
- [ ] Une soirée complète peut être vécue en direct sans rechargement manuel.
- [ ] La release peut être taguée `v0.3.0`.
