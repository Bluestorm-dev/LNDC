LE NID DES CHAMPIONS — V1.0.2g
Nettoyage GitHub + drapeau Ukraine pour le Shakhtar Donetsk

AVANT DE COMMENCER
------------------
Dans le dépôt LNDC :
  git status
  git branch sauvegarde-avant-nettoyage-102g

INSTALLATION
------------
1. Décompresser ce ZIP A LA RACINE du dépôt LNDC.
2. Lancer :
     node tools\apply-v1.0.2g-cleanup.mjs
3. Dans Supabase SQL Editor, exécuter :
     sql/HOTFIX_V1.0.2g_SHAKHTAR_UKRAINE.sql
4. Tester :
     node tests\test-v1.0.2g-cleanup.mjs
5. Si tout est PASS :
     git add -A
     git commit -m "V1.0.2g cleanup assets et drapeau Shakhtar"
     git push origin main

CE QUI EST SUPPRIME
-------------------
- assets/icons/app/
- assets/icons/ui/
- assets/icons/football/
- anciens alias assets/icons/icon-*.png, SAUF les 4 icônes PWA
- assets/icons/icon-catalog.json
- assets/source-sheets/
- assets/avatars/source-sheets/
- assets/badges/source-sheets/
- tous les anciens fichiers *.bak du dépôt

CE QUI EST CONSERVE
-------------------
- assets/icons/runtime/ : bibliothèque réellement utilisée par le site
- icon-192.png, icon-512.png, icon-maskable-192.png, icon-maskable-512.png
- tous les avatars découpés réellement utilisés
- les 100 badges découpés réellement utilisés
- les logos de clubs et le branding

GAIN SUR LE ZIP FOURNI
----------------------
Le dépôt extrait passe d'environ 282 Mo à environ 139 Mo.
Les fichiers retirés ne sont pas chargés par l'application.

SHAKHTAR
--------
- Ajout Ukraine -> code drapeau "ua" dans js/core.js.
- Le Shakhtar/Chakhtar est forcé sur Ukraine côté affichage même si une ancienne ligne DB a le pays vide.
- Le SQL remet aussi country='Ukraine' dans public.clubs.
