# Système de tests — V0.9.10

La V0.9.10 ajoute 40 contrôles manuels aux 1880 contrôles cumulés V0.9.9, soit **1920 contrôles**.

Le runner `tests/run-all-v0.9.10.mjs` vérifie notamment : cohérence de version, conservation des 100 succès, calendrier UEFA 144/8×18/36×8, verrouillage manuel, synchronisation Football-Data partielle sans suppression, sélection Champion 1 avant le calendrier API, reset pré-production et absence des labels de versions dans les écrans publics.

Après migration SQL, le Centre web `tests/test-center-v0.9.10.html` appelle également `admin_diagnostics_v0910()` et conserve les diagnostics historiques comme tests de régression.

Commandes :

```bat
node tests\run-all-v0.9.10.mjs
node tests\run-all-v0.9.10.mjs --url=https://bluestorm-dev.github.io/LNDC/
```

Critère de sortie : **0 FAIL** avant reprise du Grand road-check.
