LE NID DES CHAMPIONS — HOTFIX V1.0.2f
======================================

PROBLÈME CORRIGÉ
----------------
Après V1.0.2e, les doublons avaient disparu mais TOUS les noms/blasons de clubs
avaient disparu dans les classements Buteurs & Cartons.

Cause exacte : core.js déclare `const state = {...}`. Ce binding global est
accessible sous le nom `state`, mais PAS sous `window.state`.
Le résolveur V1.0.2e utilisait `window.state`, voyait donc toujours une liste de
clubs vide et, comme release101 lui donnait priorité, même les club_id valides
n'étaient plus affichés.

V1.0.2f :
- restaure le club à partir du vrai `state` / clubById ;
- conserve le dédoublonnage V1.0.2d ;
- recoupe buteurs et cartons ;
- garde un mapping de secours J1 uniquement si le club_id ne se résout pas ;
- passe le cache PWA et la version en 1.0.2f.

IMPORTANT
---------
AUCUN SQL à exécuter pour ce correctif.
Ne relance pas les scripts de nettoyage J1 / 1.0.2d / 1.0.2e.
Le problème constaté ici est un bug JavaScript d'affichage.

INSTALLATION
------------
1. Décompresser le ZIP à la racine du dépôt LNDC.
2. Lancer :
   node tools\apply-v1.0.2f.mjs
3. Tester :
   node tests\test-v1.0.2f.mjs
4. Déployer :
   git add .
   git commit -m "Hotfix v1.0.2f - restauration clubs joueurs C1"
   git push origin main
5. Fermer complètement la PWA / l'onglet, puis rouvrir.

RÉSULTAT ATTENDU
----------------
- Ferran Torres : club et blason visibles.
- Serhou Guirassy : club et blason visibles.
- Ermedin Demirović, Haaland, Raphinha, Olise, etc. : clubs visibles.
- aucune réapparition des doublons.
