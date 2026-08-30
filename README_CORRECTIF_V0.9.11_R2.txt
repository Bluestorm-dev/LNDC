LE NID DES CHAMPIONS — V0.9.11 R2
=====================================

CAUSE CONFIRMÉE
Le retour :
  0 résultat via 0 recherche ciblée
signifie que la Function avait 0 match local candidat.
Elle n'essayait donc même pas SearchService Betclic.

CORRECTIONS
- La synchronisation Betclic Admin porte maintenant sur toute la saison C1,
  pas uniquement sur la journée actuellement sélectionnée.
- Les anciennes lignes is_test=NULL sont considérées comme des matchs réels.
- Si une journée demandée est vide, fallback automatique sur toute la saison.
- Recherche « Ligue des Champions » et « Champions League » exécutée même
  si le filtre local retourne 0 candidat : vrai diagnostic fournisseur.
- Diagnostic détaillé :
  * matchs locaux de la saison
  * matchs éligibles
  * candidats automatiques
  * cotes manuelles protégées
  * recherches Betclic et résultats
- Les cotes manuelles restent prioritaires.

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
