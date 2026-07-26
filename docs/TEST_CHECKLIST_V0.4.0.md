# Checklist de recette — V0.4.0 Champions & phases finales

## Installation
- [ ] `HOTFIX_V0.4.0_EXISTING_DB.sql` s'exécute sans erreur.
- [ ] Les phases `LEAGUE`, `KNOCKOUT_PLAYOFF`, `ROUND_OF_16`, `QUARTER_FINAL`, `SEMI_FINAL`, `FINAL` existent.
- [ ] Les RPC V0.4.0 existent et PostgREST a rechargé son schéma.
- [ ] Le front affiche `V0.4.0` et aucun 404 RPC n'apparaît dans la console.

## Champion 1 — 100 points
- [ ] Un joueur peut choisir un club C1 avant le premier coup d'envoi.
- [ ] Le choix peut être modifié tant que le premier match n'a pas commencé.
- [ ] Les autres joueurs ne voient pas ce choix avant verrouillage.
- [ ] Après verrouillage, le choix devient visible dans « Les choix du Nid ».
- [ ] Un joueur sans choix reçoit l'OM lorsque le premier match passe LIVE/Terminé.
- [ ] L'attribution automatique indique `assigned_default=true`.
- [ ] Un premier champion qui remporte la compétition rapporte exactement 100 points.
- [ ] Un premier champion éliminé rapporte 0 et affiche son élimination.

## Champion 2 — 50 points
- [ ] Le deuxième choix est fermé tant que la phase de ligue n'est pas terminée.
- [ ] Il s'ouvre quand tous les matchs non annulés de la phase de ligue sont terminés.
- [ ] Seuls les clubs présents dans le tableau final peuvent être choisis.
- [ ] Il se verrouille au premier coup d'envoi des phases finales.
- [ ] Son choix reste caché avant verrouillage.
- [ ] Un deuxième champion vainqueur rapporte 50 points.
- [ ] Le même club peut être choisi en Champion 1 et Champion 2 : total possible 150.

## Tirage réel Admin
- [ ] L’Admin peut créer une confrontation de barrage, huitième, quart ou demi avec deux dates.
- [ ] La finale impose automatiquement le mode match unique.
- [ ] Deux clubs identiques sont refusés.
- [ ] Un retour programmé avant l’aller est refusé.
- [ ] Corriger une confrontation encore programmée met à jour clubs et horaires des matchs associés.
- [ ] Les confrontations réelles n’altèrent pas les confrontations TEST d’une autre recette.

## Générateur TEST et tableau
- [ ] « Générer tableau TEST » crée 23 confrontations : 8 barrages, 8 huitièmes, 4 quarts, 2 demies, 1 finale.
- [ ] Les barrages créent immédiatement 16 matchs (8 aller + 8 retour).
- [ ] Les tours suivants restent en attente tant que leurs deux participants ne sont pas connus.
- [ ] Le vainqueur d'un barrage apparaît automatiquement dans le huitième correspondant.
- [ ] Le vainqueur d'un huitième apparaît automatiquement dans le quart correspondant.
- [ ] Le vainqueur d'un quart apparaît automatiquement en demi.
- [ ] Le vainqueur d'une demi apparaît automatiquement en finale.

## Aller-retour et cumul
- [ ] Le score aller est enregistré sans désigner le qualifié final.
- [ ] Le cumul est affiché en direct sur la confrontation.
- [ ] Après le retour, un cumul non nul désigne automatiquement le bon qualifié.
- [ ] Les buts à domicile n'ont aucun poids particulier.
- [ ] Le perdant est marqué éliminé dans ses choix champion.

## 120 minutes et tirs au but
- [ ] Sur un retour à cumul égal, l'Admin doit cocher « Prolongation ».
- [ ] Le score final saisi est compris comme le score après 120 minutes.
- [ ] Si le cumul reste égal après 120 minutes, les tirs au but sont obligatoires.
- [ ] Deux scores TAB identiques sont refusés.
- [ ] Le vainqueur des TAB devient le qualifié.
- [ ] En finale, une égalité impose également prolongation puis TAB.
- [ ] Les tirs au but ne sont jamais ajoutés au score du match ni au cumul.

## Pronostics des scores
- [ ] Les scores aller et retour utilisent le barème 0/3/5/7 existant.
- [ ] Pour un retour/finale avec prolongation, le joueur pronostique le score à 120 minutes.
- [ ] L'autosave fonctionne sur chaque match des phases finales.
- [ ] La navigation clavier A→B→A match suivant reste fonctionnelle.
- [ ] La navigation B→A→A match suivant reste fonctionnelle.
- [ ] Les boutons +/- ne déplacent pas le focus.

## Qualifié et bonus
- [ ] Un joueur peut choisir le qualifié avant l'aller.
- [ ] Un bon qualifié choisi avant l'aller vaut +3.
- [ ] Le même choix revalidé après l'aller conserve son statut initial.
- [ ] Un choix réellement modifié après l'aller et avant le retour passe au bonus réduit +1.
- [ ] Le choix est verrouillé au coup d'envoi du retour.
- [ ] En finale, le qualifié est verrouillé au coup d'envoi du match unique.
- [ ] Un mauvais qualifié rapporte 0.
- [ ] Le bonus qualifié est ajouté au classement général sans modifier les statistiques d'exacts/moyenne des scores.

## Multiplicateurs
- [ ] Chaque phase peut être réglée sur x1, x2, x3 ou x4.
- [ ] Le changement de phase s'applique aux matchs encore programmés/reportés.
- [ ] Un match peut recevoir un multiplicateur différent de sa phase.
- [ ] Le multiplicateur est visible avant verrouillage sur la carte joueur.
- [ ] Exemple : score exact à x2 = 14 points.
- [ ] Exemple : bon résultat à x3 = 9 points.
- [ ] Le bonus qualifié et les bonus champions ne sont pas multipliés.

## Classement & Realtime
- [ ] Le classement général additionne points matchs + bonus qualifiés + champions.
- [ ] Le départage reste points → exacts → moyenne → bons écarts → joués.
- [ ] Le LIVE des scores continue de recalculer les points provisoires.
- [ ] Une qualification terminée met à jour le classement sans rechargement manuel.
- [ ] `knockout_ties`, `tie_predictions` et `champion_predictions` sont dans Supabase Realtime.

## Critère de sortie V0.4.0
- [ ] Un joueur peut traverser toute la compétition dans le Nid : phase de ligue, champion initial, barrages, huitièmes, quarts, demies, finale, champion final, scores, cumul, prolongation, TAB, qualifiés, bonus et multiplicateurs.
