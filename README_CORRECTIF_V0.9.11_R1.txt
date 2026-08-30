LE NID DES CHAMPIONS — V0.9.11 R1
=====================================

CAUSE DU 0 APPARIÉ
La V0.9.11 initiale lisait les 10 premières pages du flux football Betclic :
10 × 40 = 400 matchs. Ce flux contient surtout les rencontres les plus proches.
Une rencontre C1 plus lointaine peut donc ne jamais entrer dans ces 400 résultats.

CORRECTION
- Le flux général reste utilisé en premier.
- Si des matchs C1 restent non rapprochés :
  1) recherche « Ligue des Champions »
  2) recherche « Champions League »
  3) recherche ciblée par club pour les prochains matchs non appariés
- Maximum 20 requêtes de recherche par synchronisation.
- Tolérance horaire de rapprochement portée à 36 h.
- Les cotes manuelles restent prioritaires et ne sont jamais écrasées.
- Le retour Admin indique :
  * plage de dates du flux
  * nombre de recherches ciblées
  * résultats de recherche
  * rapprochements obtenus par la recherche

INSTALLATION
Remplacer :
- supabase/functions/sync-betclic-odds/index.ts
- js/release0911.js
- tests/run-all-v0.9.11.mjs

Puis redéployer :
  supabase functions deploy sync-betclic-odds

AUCUN SQL.
AUCUN NOUVEAU SECRET.
La version reste V0.9.11.
