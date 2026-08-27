# Le Nid des Champions — système de tests V0.9.5

La V0.9.5 prolonge le contrôle de régression jusqu'au bloc **Administration & durcissement**. Le grand road-check manuel historique reste prévu pour la V0.9.9 ; la V0.9.5 conserve néanmoins tous les tests afin de ne rien perdre d'ici là.

## Contrôle automatique local

```bat
node tests\run-all-v0.9.5.mjs
```

Le runner contrôle notamment : versions, cache PWA, branchement des modules, UX Admin, pagination, Feature flags, Maintenance, sauvegardes, audit, RLS, confidentialité, installation fraîche et conservation des fonctions V0.9.0 / Football-Data V0.8.1.

## Contrôle du site réellement déployé

```bat
node tests\run-all-v0.9.5.mjs --url=https://VOTRE-SITE
```

Il valide à distance `VERSION`, `config.js`, `sw.js`, `index.html`, `js/admin095.js` et `css/admin095.css`.

## Diagnostic Supabase

Avec un compte Admin/Super Admin :

```sql
select * from public.admin_diagnostics_v095();
```

Le Centre web exécute également le diagnostic V0.9.0 afin de vérifier que multi-saisons, carrière et mémoire restent présents.

## Centre de tests web

`tests/test-center-v0.9.5.html`

- **1490 tests** de V0.1.x à V0.9.5 ;
- filtres par version/catégorie/état ;
- notes locales ;
- OK / KO / N/A / TODO ;
- export JSON / CSV ;
- diagnostic Supabase et contrôles navigateur.

## Documents

- `docs/TEST_CHECKLIST_V0.9.5.md` : 160 tests spécifiques à la V0.9.5 ;
- `docs/TEST_MATRIX_V0.9.5.md` : matrice cumulative de 1490 contrôles.

Les scénarios destructifs (restauration, changement de saison, modification de production...) restent volontairement manuels et doivent être exécutés après sauvegarde.
