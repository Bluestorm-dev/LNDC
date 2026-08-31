LE NID DES CHAMPIONS — V0.9.12 R1
=====================================

CORRECTION DES CARROUSELS ACCUEIL

Le carrousel V0.9.12 initial était un rail horizontal avec flèches.
Ce n'est pas le comportement souhaité.

NOUVEAU COMPORTEMENT
- Une seule carte visible à la fois.
- Changement automatique toutes les 5 secondes.
- Aucun bouton précédent / suivant.
- Aucun scroll horizontal.
- Transition courte en fondu.
- Même comportement pour :
  * Prochains rendez-vous
  * Casseroles, badges & records
- Le clic sur la carte d'un match continue d'ouvrir directement ce match
  dans Pronostics.
- Si un carrousel ne contient qu'une seule carte, aucun timer inutile.

INSTALLATION
Remplacer :
- index.html
- css/release0912.css
- js/release0912.js
- tests/run-all-v0.9.12.mjs

AUCUN SQL.
AUCUNE EDGE FUNCTION.
Version inchangée : V0.9.12.
