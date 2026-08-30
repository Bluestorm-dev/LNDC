# Système de tests — V0.9.11

La V0.9.11 conserve la matrice cumulative et l'étend à **1 940 contrôles manuels**.

Le runner Node contrôle en plus la release, le cache PWA, les 100 succès,
les correctifs V0.9.10, la Function Betclic, les feature gates, la sécurité des
DELETE, la purge de communication et les diagnostics SQL.

## Local

```bat
node tests\run-all-v0.9.11.mjs
```

Objectif : **0 FAIL**.

## Déploiement GitHub Pages

```bat
node tests\run-all-v0.9.11.mjs --url=https://bluestorm-dev.github.io/LNDC/
```

## Centre web

`tests/test-center-v0.9.11.html`

Connecte-toi d'abord au Nid avec le compte Super Admin dans le même navigateur.
Le Centre ne lance pas de synchronisation Betclic automatiquement : il vérifie
la Function, les RPC et les données de manière non destructive.
