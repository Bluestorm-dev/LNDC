LE NID DES CHAMPIONS — HOTFIX V1.0.2e
======================================

BUT
---
La V1.0.2d a supprimé correctement les doublons, mais certaines lignes de
buteurs/cartons peuvent encore pointer vers un ancien club inactif (ou vers
aucun club). Comme l'application ne charge que les clubs actifs, le blason et
le nom du club disparaissent dans le classement.

V1.0.2e corrige ce point sans recréer de doublons :
- remappage des anciens club_id inactifs vers le club actif correspondant ;
- recoupement des clubs entre ucl_player_stats et ucl_discipline_stats ;
- mapping de secours des joueurs J1 déjà importés ;
- résolveur côté interface si une ancienne référence persiste ;
- nouveau cache PWA 1.0.2e.

INSTALLATION
------------
1. Décompresser ce ZIP à la RACINE du dépôt LNDC.

2. Dans le terminal, à la racine du dépôt :
   node tools\apply-v1.0.2e.mjs

3. Dans Supabase > SQL Editor, exécuter TOUT le fichier :
   sql/HOTFIX_V1.0.2e_REPAIR_UCL_CLUBS.sql

4. A la fin du SQL, contrôler :
   buteurs_sans_club_actif = 0
   cartons_sans_club_actif = 0
   doublons_buteurs = 0
   doublons_cartons = 0

   Le second tableau liste explicitement les éventuels joueurs encore sans
   club actif. S'il est vide, la réparation est complète.

5. Tester :
   node tests\test-v1.0.2e.mjs

6. Déployer :
   git add .
   git commit -m "Hotfix v1.0.2e - clubs joueurs C1"
   git push origin main

7. Fermer complètement la PWA puis la rouvrir afin de charger le nouveau cache.

NOTE
----
Pas besoin de relancer le patch J1 ni de redéployer sync-football-data pour ce
correctif. La fonction de synchronisation V1.0.2d rattache déjà les nouvelles
données Football-Data à un club fournisseur ; V1.0.2e répare surtout les
références historiques laissées par les anciens patches manuels.
