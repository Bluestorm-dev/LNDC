# Système de tests — V0.9.12

La matrice cumulative contient **1 980 contrôles manuels**. La V0.9.12 ajoute 40 contrôles ciblés sur la refonte desktop et le cockpit d’exploitation des matchs.

## Local

```bat
node tests\run-all-v0.9.12.mjs
```

Objectif : **0 FAIL**.

## Déploiement

```bat
node tests\run-all-v0.9.12.mjs --url=https://bluestorm-dev.github.io/LNDC/
```

## Centre web

`tests/test-center-v0.9.12.html`

Connecte-toi au Nid avec le compte Super Admin dans le même navigateur avant de lancer les diagnostics SQL. Les tests automatiques ne modifient pas les matchs.
