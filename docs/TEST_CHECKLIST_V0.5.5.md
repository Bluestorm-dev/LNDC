# Le Nid des Champions — Checklist V0.5.5

## Version / cache
- [ ] `VERSION` affiche `0.5.5`.
- [ ] l'interface affiche `V0.5.5`.
- [ ] le cache s'appelle `nid-champions-v0.5.5`.
- [ ] `node tests/release-v0.5.5.mjs` retourne `V0.5.5 release tests: OK`.

## Accueil
- [ ] mon avatar/logo apparaît en grand dès l'arrivée sur Accueil.
- [ ] si je suis dans une Team, son habillage entoure bien mon avatar.
- [ ] le hero reste lisible sur desktop, tablette et mobile.

## Gestion Team — membre
- [ ] l'onglet `⚙ Gestion` est visible.
- [ ] un membre non capitaine voit `Quitter la Team`.
- [ ] une confirmation est demandée avant de quitter.
- [ ] après départ, la Team n'est plus affichée comme ma Team.

## Gestion Team — capitaine
- [ ] le capitaine voit le code d'invitation et sa régénération.
- [ ] le capitaine peut accepter/refuser les demandes.
- [ ] le capitaine peut donner le capitanat à un membre actif.
- [ ] le capitaine peut exclure un membre.
- [ ] `Transférer puis quitter` permet de choisir un nouveau capitaine puis de partir.
- [ ] si le capitaine est seul, l'interface indique qu'il doit dissoudre la Team.
- [ ] la dissolution fonctionne toujours.

## Personnalisation Team
- [ ] le mode 1 couleur reste disponible.
- [ ] le mode 2 couleurs affiche les dégradés existants.
- [ ] les motifs `Moitié verticale`, `Moitié horizontale`, `Moitié diagonale` fonctionnent.
- [ ] les bandes verticales/horizontales/diagonales fonctionnent.
- [ ] le motif `Quartiers` fonctionne.
- [ ] le motif choisi est conservé après sauvegarde et rechargement.
- [ ] la prévisualisation montre mon vrai avatar, pas mon initiale.
- [ ] le cadre autour de l'avatar est légèrement plus fin qu'en V0.5.4.

## Régression
- [ ] pronostics phase de ligue OK.
- [ ] classements OK.
- [ ] live OK.
- [ ] champions / phases finales OK.
- [ ] profil / avatars V0.5.3 OK.
- [ ] Admin Teams OK.
