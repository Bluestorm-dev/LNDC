# Le Nid des Champions — système de tests V0.9.0

La V0.9.0 étend le contrôle de régression historique du Nid jusqu'au nouveau bloc **Saison, carrière & mémoire**.

## Trois niveaux de contrôle

1. **Runner local** — `node tests/run-all-v0.9.0.mjs`
   - contrôle des fichiers et versions ;
   - intégration du Service Worker ;
   - présence des modules V0.9.0 ;
   - structure attendue de la migration SQL ;
   - conservation du correctif Football-Data V0.8.1 ;
   - cohérence de la matrice de 1330 tests.

2. **Diagnostic Supabase** — `public.admin_run_diagnostics_v090()`
   - prolonge le diagnostic V0.8.1 ;
   - vérifie les tables, RPC et RLS V0.9.0 ;
   - contrôle notamment historique de rang, carrière, Hall of Fame, replay, sondages et multi-saisons.

3. **Centre de tests web** — `/tests/test-center-v0.9.0.html`
   - 1330 contrôles couvrant V0.1.x à V0.9.0 ;
   - statuts OK / KO / N/A / TODO ;
   - recherche et filtres ;
   - notes ;
   - export JSON / CSV.

## Test de la version publiée

```bat
node tests\run-all-v0.9.0.mjs --url=https://VOTRE-SITE
```

Ce mode vérifie que `VERSION`, `config.js`, `sw.js`, `index.html` et le module carrière servis en ligne correspondent bien à la V0.9.0.

## Road-check manuel conseillé

Suivre `docs/TEST_CHECKLIST_V0.9.0.md` puis la matrice complète `docs/TEST_MATRIX_V0.9.0.md`.

Les tests qui modifieraient de vraies données restent volontairement guidés et ne sont pas exécutés automatiquement : création de Team, vote, Push, résultats TEST, changement de saison, etc.

V0.9.0 — Palmarès historique
- Le Super Admin peut désigner ou retirer manuellement le « Vainqueur du Nid des Pronos — Coupe du monde 2026 ».
- Cette distinction est unique, persistante entre les saisons et visible dans le profil/carrière.
