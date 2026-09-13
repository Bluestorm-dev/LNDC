Le Nid des Champions — correctif nettoyage V1.0.2g R2

Ce correctif ne modifie ni Supabase, ni le drapeau du Shakhtar, ni la version.
Il supprime seulement les 7 éléments que le test V1.0.2g signale encore présents.

Installation :
1. Copier le contenu de ce ZIP à la racine du dépôt LNDC.
2. Ouvrir CMD dans cette racine.
3. Lancer : node tools\cleanup-v1.0.2g-r2.mjs
4. Relancer : node tests\test-v1.0.2g-cleanup.mjs
5. Si 13 PASS / 0 FAIL : git add -A

Important : le script utilise volontairement le dossier courant (process.cwd()),
pour éviter qu'une détection automatique ne nettoie un autre dossier LNDC.
