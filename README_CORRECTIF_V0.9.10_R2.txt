LE NID DES CHAMPIONS — CORRECTIF V0.9.10 R2
=================================================

Ce correctif traite deux erreurs de la première livraison V0.9.10.

1. AFFICHAGE
Des mentions V0.9.9 étaient encore codées en dur dans index.html.
Elles donnaient l'impression que l'application n'était pas passée en 0.9.10.
Les numéros de version inutiles sont retirés des surfaces joueur et les
informations techniques Admin sont remises en cohérence.

2. DIAGNOSTIC HISTORIQUE V0.9.9
admin_diagnostics_v099 vérifie logiquement app_version=0.9.9.
Sur un backend correctement migré en 0.9.10, cette ligne doit être considérée
comme une compatibilité historique et non comme un échec de la release courante.
Le Centre V0.9.10 gère désormais correctement ce cas.

FICHIERS
- index.html
- tests/test-center-v0.9.10.html
- tests/run-all-v0.9.10.mjs

AUCUN SQL À REJOUER.
AUCUNE EDGE FUNCTION À REDÉPLOYER.
AUCUNE MODIFICATION DE config.js.

Après copie :
node tests\run-all-v0.9.10.mjs

Puis après déploiement :
node tests\run-all-v0.9.10.mjs --url=https://bluestorm-dev.github.io/LNDC/
