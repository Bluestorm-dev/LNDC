# Le Nid des Champions — Checklist V0.5.5a

## Version / cache
- [ ] `VERSION` affiche `0.5.5a`.
- [ ] l’interface affiche `V0.5.5a`.
- [ ] le cache s’appelle `nid-champions-v0.5.5a`.
- [ ] `node tests/release-v0.5.5a.mjs` retourne `V0.5.5a release tests: OK`.

## Prévisualisation apparence Team
- [ ] sélectionner deux couleurs très contrastées, par exemple rouge/blanc ;
- [ ] sélectionner Bandes diagonales ;
- [ ] le fond de la mini-carte suggère bien les bandes mais ne les reproduit plus plein contraste ;
- [ ] le nom de la Team reste parfaitement lisible ;
- [ ] `12 membres` reste parfaitement lisible ;
- [ ] tester aussi Quartiers et Moitié diagonale.

## Capitaine seul : quitter sans dissoudre
- [ ] créer/rejoindre une Team dont je suis le seul membre et capitaine ;
- [ ] `Quitter la Team` est disponible ;
- [ ] après départ, la Team n’est plus ma Team ;
- [ ] elle reste visible dans l’annuaire ;
- [ ] elle est indiquée comme vacante / capitaine à reprendre ;
- [ ] `Reprendre la Team` me fait redevenir membre et capitaine.

## Team dissoute
- [ ] dissoudre explicitement une Team ;
- [ ] elle disparaît de l’annuaire actif ;
- [ ] le dernier capitaine la voit dans `Anciennes Teams` ;
- [ ] `Réactiver` restaure la Team et le capitanat ;
- [ ] tester aussi une Team qui avait déjà été dissoute sous V0.5.5.

## Capitaine avec plusieurs membres
- [ ] le capitaine ne peut toujours pas partir sans transmettre le capitanat ;
- [ ] `Transférer puis quitter` fonctionne ;
- [ ] le nouveau capitaine est correct après rechargement.

## Super Admin / modération
- [ ] un Admin simple ne voit pas `Supprimer définitivement` ;
- [ ] le Super Admin voit `Supprimer définitivement` dans Admin > Teams > Voir ;
- [ ] la confirmation demande de saisir `SUPPRIMER` ;
- [ ] annuler la saisie ne supprime rien ;
- [ ] après confirmation, la Team disparaît réellement de l’Admin et de l’annuaire ;
- [ ] ses memberships/demandes/invitations/événements ont disparu ;
- [ ] `audit_logs` contient l’action `team_hard_delete` ;
- [ ] si la Team utilisait un logo uploadé courant, vérifier sa suppression dans `team-logos`.

## Régression
- [ ] personnalisation Team V0.5.5 OK ;
- [ ] avatars joueurs OK ;
- [ ] classements Teams OK ;
- [ ] pronostics / LIVE / phases finales OK ;
- [ ] Admin Teams reste utilisable sur Team active, vacante et dissoute.
