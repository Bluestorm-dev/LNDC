LE NID DES CHAMPIONS — CORRECTIF V0.9.10 R4
=================================================

BUG CORRIGÉ
Les nouveaux éditeurs V0.9.10 utilisaient root.remove().
Or root correspond à #modalRoot lui-même. Après une fermeture ou un passage
Journée -> Match, #modalRoot disparaissait du DOM et toute nouvelle fenêtre
plantait avec :

Cannot set properties of null (setting 'innerHTML')
at modal (core.js...)

CORRECTIONS
- Tous les root.remove() de preprod0910.js sont remplacés par root.innerHTML="".
- modal() dans core.js est désormais auto-réparant : si #modalRoot manque,
  il le recrée dans document.body.
- Le bouton Journée -> Modifier un match fonctionne sans détruire la racine.
- Modification d'un club, d'un match et saisie manuelle des cotes restent utilisables
  successivement sans recharger la page.
- Deux tests anti-régression ont été ajoutés au runner.

INSTALLATION
Remplacer :
- js/core.js
- js/preprod0910.js
- tests/run-all-v0.9.10.mjs

AUCUN SQL.
AUCUNE EDGE FUNCTION.
AUCUNE MODIFICATION DE config.js.

Après copie :
node tests\run-all-v0.9.10.mjs
