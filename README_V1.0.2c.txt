LE NID DES CHAMPIONS — HOTFIX V1.0.2c
======================================

CORRECTIONS
- Supprime les doublons d'un même joueur dans les classements Buteurs et Cartons.
- Le dédoublonnage prend le MAX des statistiques, il ne les additionne pas.
- Si une ligne doublon a un club et l'autre non, le club connu est conservé.
- Sur mobile, un joueur avec 1 rouge affiche maintenant "1 🟥" au lieu du "0 🟨" principal.
- Le détail complet reste disponible sur desktop.
- La synchro Football-Data reconnaît RED / RED_CARD, YELLOW / YELLOW_CARD,
  YELLOW_RED / YELLOW_RED_CARD et SECOND_YELLOW / SECOND_YELLOW_CARD.

INSTALLATION
1. Décompresser ce ZIP A LA RACINE du dépôt LNDC.
2. Dans le terminal, à la racine :
     node tools\apply-v1.0.2c.mjs
3. Supabase > SQL Editor : exécuter :
     sql/HOTFIX_V1.0.2c_PLAYER_STATS.sql
4. Redéployer la fonction de synchronisation :
     npx supabase functions deploy sync-football-data
5. Tester :
     node tests\test-v1.0.2c.mjs
   Résultat attendu : 12 PASS · 0 FAIL
6. Commit / push :
     git add .
     git commit -m "Hotfix v1.0.2c - doublons joueurs et cartons rouges"
     git push origin main

IMPORTANT
- Le SQL ne fusionne pas deux homonymes si plusieurs clubs différents sont connus.
- Les statistiques des doublons sont fusionnées avec MAX() et non SUM().
