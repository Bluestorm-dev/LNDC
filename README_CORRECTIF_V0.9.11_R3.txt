LE NID DES CHAMPIONS — V0.9.11 R3
=====================================

PROBLÈME
HTTP 546 sur sync-betclic-odds.

Supabase 546 = WORKER_RESOURCE_LIMIT :
la Function est déployée, mais elle est stoppée car elle consomme trop de
CPU, mémoire ou temps d'exécution.

CAUSE
Le R2 pouvait cumuler dans une seule exécution :
- décodage de 400 matchs du flux football général ;
- recherches Champions League ;
- recherches par clubs ;
- récupération et décodage de nombreux marchés 1N2.

CORRECTION R3
- "Tester Betclic" conserve le flux général (il fonctionnait déjà).
- "Synchroniser Betclic" NE lit plus les 400 matchs.
- Recherche directe :
    Ligue des Champions
    Champions League
- Fallback de seulement 2 recherches par club maximum.
- 4 recherches ciblées maximum par exécution.
- 6 marchés détaillés maximum par exécution.
- Si davantage de matchs sont appariés, l'Admin demande simplement de
  recliquer pour traiter le lot suivant.
- Les matchs sans cotes Betclic existantes sont prioritaires.
- Taille brute d'une réponse gRPC plafonnée à ~220 Ko.
- Message HTTP 546 explicite dans l'Admin.
- Les cotes manuelles restent protégées.

INSTALLATION
Remplacer :
- supabase/functions/sync-betclic-odds/index.ts
- js/release0911.js
- tests/run-all-v0.9.11.mjs

Puis :
  supabase functions deploy sync-betclic-odds

AUCUN SQL.
AUCUN NOUVEAU SECRET.
La version reste V0.9.11.
