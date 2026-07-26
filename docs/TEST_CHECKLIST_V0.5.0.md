# Checklist V0.5.0 — Teams

## Release / migration
- [ ] `VERSION` = `0.5.0`.
- [ ] cache Service Worker = `nid-champions-v0.5.0`.
- [ ] `011_patch_v0.5.0_teams.sql` s'exécute sans erreur sur une base V0.4.2.
- [ ] `000_INSTALL_FRESH_V0.5.0.sql` fonctionne sur une base vierge.
- [ ] bucket `team-logos` présent.
- [ ] RPC `get_team_leaderboard_v050` visible par PostgREST.

## Hibou masqué / assets
- [ ] `assets/branding/owl/owl-masked-main.png` existe.
- [ ] fond réellement transparent.
- [ ] aucun logo sur le front.
- [ ] médaillon sans coupe.
- [ ] aucun ballon sous les pattes.
- [ ] asset référencé dans `docs/ASSETS_MANIFEST.md`.

## Création de Team
- [ ] joueur sans Team peut créer une Team.
- [ ] nom obligatoire entre 3 et 30 caractères.
- [ ] nom unique dans la saison.
- [ ] slogan facultatif, 80 caractères maximum.
- [ ] description facultative, 160 caractères maximum.
- [ ] équipe fétiche facultative.
- [ ] équipe fétiche peut être un club hors Ligue des champions.
- [ ] créateur devient l'unique capitaine.
- [ ] impossible de créer une deuxième Team avec un membership actif.

## Identité visuelle
- [ ] 12 formes proposées : cercle, médaillon, carré arrondi, carré prestige, losange, hexagone, écusson classique, écusson pointu, bouclier moderne, bannière, royal, prestige.
- [ ] cadres Bois / Bronze / Argent / Or / Or royal / Acier / Cuir / Obsidienne / Néon / Champions / Royal / Nuit européenne.
- [ ] couleur principale modifiable.
- [ ] couleur secondaire modifiable.
- [ ] fonds uni / vertical / horizontal / diagonal / radial / halo.
- [ ] aperçu Team mis à jour en direct.
- [ ] aperçu avatar mis à jour en direct.
- [ ] aperçu classement mis à jour en direct.
- [ ] avatar personnel reste lisible au premier plan.
- [ ] changement d'apparence se propage sans modifier chaque profil.

## Logos Team
- [ ] choix d'un logo de la bibliothèque.
- [ ] upload PNG/JPEG/WebP/SVG accepté sous 3 Mo.
- [ ] upload > 3 Mo refusé.
- [ ] logo uploadé s'affiche après sauvegarde.
- [ ] réouverture de l'éditeur conserve un logo uploadé tant qu'un autre logo n'est pas choisi.
- [ ] passage upload -> logo bibliothèque fonctionne.

## Team publique
- [ ] Team visible dans l'annuaire.
- [ ] bouton Rejoindre disponible.
- [ ] adhésion immédiate.
- [ ] nouveau membre visible sans refresh grâce au Realtime.

## Team privée
- [ ] Team visible comme privée dans l'annuaire.
- [ ] demande d'adhésion possible.
- [ ] demande visible par le capitaine.
- [ ] capitaine peut accepter.
- [ ] capitaine peut refuser.
- [ ] joueur accepté rejoint la Team.
- [ ] capitaine peut générer/régénérer un code.
- [ ] code valide permet l'entrée directe.
- [ ] ancien code révoqué n'est plus utilisable.

## Une seule Team
- [ ] un joueur membre ne peut rejoindre une autre Team publique.
- [ ] un joueur membre ne peut rejoindre par code une autre Team.
- [ ] un joueur membre ne peut créer une nouvelle Team.
- [ ] après un départ valide, il peut rejoindre/créer une autre Team.

## Capitaine
- [ ] un seul capitaine par Team.
- [ ] capitaine identifié par 👑.
- [ ] capitaine peut modifier l'identité.
- [ ] capitaine peut exclure un membre.
- [ ] capitaine ne peut pas s'exclure lui-même.
- [ ] capitaine ne peut pas quitter tant qu'il n'a pas transféré son rôle.
- [ ] transfert vers un membre actif fonctionne.
- [ ] ancien capitaine devient membre normal.
- [ ] nouveau capitaine reçoit immédiatement les outils de gestion.

## Dissolution / historique
- [ ] dissolution demande confirmation.
- [ ] Team passe à `dissolved` et n'est pas supprimée.
- [ ] memberships actifs sont fermés.
- [ ] historique reste consultable.
- [ ] création historisée.
- [ ] arrivée historisée.
- [ ] départ historisé.
- [ ] exclusion historisée.
- [ ] transfert de capitaine historisé.
- [ ] changement d'identité historisé.
- [ ] changement public/privé historisé.
- [ ] dissolution historisée.

## Classements Teams
- [ ] classement Moyenne générale visible.
- [ ] classement Top 3 visible.
- [ ] classement Journée UEFA visible.
- [ ] Team de 1 membre classée correctement.
- [ ] Team de 2 membres classée correctement en Top 3.
- [ ] Team de 3+ membres utilise les 3 meilleurs pour Top 3.
- [ ] Journée TEST n°0 n'alimente pas le général.
- [ ] bonus qualifiés/champions intégrés au général Team.
- [ ] changement de Team ne transfère jamais les anciens points.
- [ ] points d'un match attribués au membership actif au coup d'envoi.

## Habillage des joueurs
- [ ] classement individuel : avatar entouré du skin Team.
- [ ] profil : Team et rôle visibles.
- [ ] pronostics des autres après verrouillage : skin Team visible.
- [ ] membres Team : skin commun visible.
- [ ] joueur sans Team : style neutre du Nid.
- [ ] changement couleurs/cadre Team actualise tous les membres.

## Profil / annuaire
- [ ] Profil affiche Ma Team.
- [ ] joueur sans Team peut aller vers Teams depuis Profil.
- [ ] équipe fétiche Team distincte du club de cœur personnel.
- [ ] recherche annuaire par nom fonctionne.
- [ ] filtre public/privé fonctionne.

## Administration
- [ ] Admin voit les Teams actives et dissoutes.
- [ ] recherche Admin par Team/capitaine fonctionne.
- [ ] Admin peut consulter détails, membres et historique.
- [ ] opérations sensibles restent côté RPC/RLS.

## Realtime
- [ ] création/mise à jour Team visible sans refresh.
- [ ] membership visible sans refresh.
- [ ] demande d'adhésion visible sans refresh.
- [ ] événement Team visible sans refresh.
- [ ] classement Team se rafraîchit après évolution des pronostics/scores.

## Mobile / UX
- [ ] sidebar desktop contient Teams.
- [ ] barre basse mobile contient Teams.
- [ ] navigation mobile ne déborde pas de façon inutilisable.
- [ ] avatars Team restent lisibles à 40–48 px.
- [ ] éditeur Team utilisable au tactile.
- [ ] listes membres/historique restent lisibles à 360 px.

## Non-régression V0.4.x
- [ ] pronostics clavier A1 -> B1 -> A2 fonctionne.
- [ ] pronostics clavier B1 -> A1 -> A2 fonctionne.
- [ ] boutons +/- ne déplacent pas le focus.
- [ ] barème 0/3/5/7 inchangé.
- [ ] cotes 1N2 inchangées.
- [ ] pays des clubs toujours visibles et AS Monaco = France.
- [ ] Champion 1 / Champion 2 toujours dans Profil.
- [ ] phases finales, cumul, prolongation, TAB et qualifiés toujours accessibles.
- [ ] classement LIVE individuel toujours fonctionnel.
