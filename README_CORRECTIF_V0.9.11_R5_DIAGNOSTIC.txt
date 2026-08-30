LE NID DES CHAMPIONS — V0.9.11 R5 DIAGNOSTIC
================================================

OBJECTIF
Betclic fonctionne et une cote a déjà été écrite avec succès.
Il reste 27/28 résultats de recherche qui ne sont pas rapprochés.

Ce correctif NE relâche PAS la sécurité du matching.
Il affiche pourquoi chaque résultat Betclic est rejeté :

- Noms + date compatibles
- Noms OK / date différente
- Noms OK / date Betclic absente
- Noms de clubs non reconnus

Pour les cas où les noms correspondent, l'Admin affiche aussi le match local
le plus proche et l'écart en heures.

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

APRÈS DÉPLOIEMENT
Cliquer une fois sur « Synchroniser Betclic », puis ouvrir :
« Diagnostic des X résultats Betclic ».

La liste obtenue permettra de corriger précisément les alias ou le parsing,
sans associer une cote au mauvais match.
