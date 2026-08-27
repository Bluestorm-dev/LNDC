# Le Nid des Champions — système de tests V0.9.8

La V0.9.8 étend le filet de régression au bloc **PDF & fin de saison**.
Le grand road-check manuel de toute l'application reste prévu pour la **V0.9.9**.

## Runner local

```bat
node tests\run-all-v0.9.8.mjs
```

Objectif : **0 FAIL**.

## Contrôle GitHub Pages

```bat
node tests\run-all-v0.9.8.mjs --url=https://bluestorm-dev.github.io/LNDC/
```

Le contrôle distant vérifie notamment VERSION, config.js, Service Worker, intégration V0.9.8,
les deux pages imprimables et le Centre de tests publié.

## Centre de tests web

`tests/test-center-v0.9.8.html`

Il contient **1660 contrôles manuels cumulés** de V0.1.x à V0.9.8, dont **170 contrôles spécifiques V0.9.8**.
Il est accessible directement depuis **Admin > Laboratoire > Centres de tests**.

Les tests automatiques du Centre contrôlent notamment :
- configuration/version ;
- fichiers frontend déployés ;
- diagnostic Supabase V0.9.8 ;
- tables Livre d'or / archives ;
- état de clôture ;
- régressions des versions précédentes.

## Documents

- `docs/TEST_CHECKLIST_V0.9.8.md` : 170 contrôles V0.9.8 ;
- `docs/TEST_MATRIX_V0.9.8.md` : 1660 contrôles cumulés ;
- `tests/test-report-v0.9.8.json` : rapport produit par le runner.

## Règle V0.9.8

Les tests automatiques ne doivent jamais archiver une saison, publier un mot dans le Livre d'or,
modifier un résultat ou créer des données métier. Les opérations destructives restent des tests manuels guidés.
