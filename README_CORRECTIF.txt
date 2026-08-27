LE NID DES CHAMPIONS — CORRECTIF V0.9.9 R2

Objet : corrige le tutoriel V0.9.9 bloqué sur l’étape 1.
Cause : le helper q() ignorait le conteneur du tutoriel ; les boutons Suivant / Plus tard / Retour ne recevaient donc aucun listener.

Installation :
1. Copier js/preseason099.js dans js/ en remplaçant l’ancien fichier.
2. Copier tests/run-all-v0.9.9.mjs dans tests/ en remplaçant l’ancien fichier.
3. Déployer sur GitHub Pages.
4. Faire Ctrl+F5 ou fermer/réouvrir la PWA.
5. Relancer node tests\run-all-v0.9.9.mjs --url=https://bluestorm-dev.github.io/LNDC/

Aucun SQL. Aucune Edge Function.
