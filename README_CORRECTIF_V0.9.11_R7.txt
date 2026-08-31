LE NID DES CHAMPIONS — V0.9.11 R7
=====================================

DIAGNOSTIC R6
Sur le lot de 4 fixtures C1 :
- Club Brugge - Aston Villa : OK
- Real Madrid - Inter : OK
- Stuttgart - Viking : OK
- Barcelona - Feyenoord : échec uniquement sur Barcelona / Barcelone

Les autres résultats affichés (Liga, Bundesliga, catégories, etc.) sont du bruit
normal de SearchService et ne représentent pas des matchs C1 ratés.

CORRECTIONS
- Alias Barcelona / Barcelone / FC Barcelona.
- Diagnostic reformulé :
  X / 4 fixtures C1 reconnues
  + résultats Betclic hors fixture ignorés.
- Matching strict du détail, lots de 4, curseur et protection anti-546 conservés.
- Cotes manuelles toujours prioritaires.

INSTALLATION
Remplacer :
- supabase/functions/sync-betclic-odds/index.ts
- js/release0911.js
- tests/run-all-v0.9.11.mjs

Puis :
  supabase functions deploy sync-betclic-odds

AUCUN SQL.
AUCUN NOUVEAU SECRET.
Version inchangée : V0.9.11.
