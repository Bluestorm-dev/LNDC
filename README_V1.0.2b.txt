LE NID DES CHAMPIONS — HOTFIX V1.0.2b

POURQUOI LA 1.0.2a N'APPARAISSAIT PAS
---------------------------------------
Le site contenait bien css/release102a.css et js/release102a.js, mais index.html ne les chargeait pas.
VERSION, config.js et le service worker étaient encore en 1.0.2.
La cause est le script tools/apply-v1.0.2a.mjs : il ciblait le dossier PARENT du dépôt (un ".." de trop).
En plus, il insérait 102a après release101, donc AVANT release102, ce qui pouvait laisser release102 reprendre la priorité.

CE HOTFIX 1.0.2b
-----------------
- charge release102a.css APRES release102.css ;
- charge release102a.js APRES release102.js et AVANT app.js ;
- appelle explicitement renderRelease102a() depuis app.js ;
- passe VERSION / APP_VERSION à 1.0.2b ;
- force un nouveau cache service worker ;
- conserve les correctifs demandés :
  * classement des joueurs puis Le pouls du Nid, sans carte sticky par-dessus ;
  * aucune couleur Team sur les matchs ;
  * couleurs Team uniquement sur les histoires du joueur appartenant à cette Team ;
  * Casseroles et Génie détaillés avec match, prono, résultat et raison.

INSTALLATION SUR TON DÉPÔT LOCAL
--------------------------------
1. Décompresse CE PATCH directement dans :
   C:\Users\yoann\Documents\Perso\8_Création\LeNiddesChampions\LNDC\LNDC
   en fusionnant/remplaçant les fichiers du patch.

2. À la racine du dépôt :
   node tools\apply-v1.0.2b.mjs

3. Dans Supabase SQL Editor, exécute tout :
   sql/HOTFIX_V1.0.2b_EXISTING_DB.sql

4. Vérifie :
   node tests\test-v1.0.2b.mjs
   Résultat attendu : 15 PASS · 0 FAIL

5. Git :
   git add .
   git commit -m "Hotfix v1.0.2b - branchement UI 1.0.2a"
   git pull --rebase origin main
   git push origin main

6. Sur téléphone / PWA : fermer complètement l'app puis la rouvrir.
   Si nécessaire, faire une actualisation forcée une fois afin de laisser le nouveau service worker prendre la main.

Le SQL est réexécutable : la fonction est CREATE OR REPLACE et app_settings utilise ON CONFLICT.
