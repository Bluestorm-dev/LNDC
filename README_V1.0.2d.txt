LE NID DES CHAMPIONS — HOTFIX V1.0.2d
======================================

Corrige :
- doublons persistants dans le classement des buteurs ;
- doublons persistants dans le classement des cartons ;
- double affichage du même carton sur desktop ;
- dédoublonnage également au rendu, même si une source renvoie deux IDs pour le même joueur.

INSTALLATION
1. Décompresser ce ZIP à la racine du dépôt LNDC.
2. Lancer : node tools\apply-v1.0.2d.mjs
3. Supabase > SQL Editor : exécuter sql/HOTFIX_V1.0.2d_DEDUP_UCL_PLAYERS.sql
4. Redéployer la fonction : npx supabase functions deploy sync-football-data
5. Tester : node tests\test-v1.0.2d.mjs
6. git add .
   git commit -m "Hotfix v1.0.2d - dedoublonnage C1"
   git push origin main

Après déploiement, fermer complètement la PWA puis la rouvrir afin de charger le nouveau cache.
