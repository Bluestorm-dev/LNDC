LE NID DES CHAMPIONS — CORRECTIF V0.9.10 R5
=================================================

CORRECTIONS
- Reset avant ouverture : plus de DELETE sans WHERE.
- Fusion de doublons de clubs depuis l'Admin.
- AEK Athens / AEK Athènes reconnu comme le même club que PAE AEK.
- L'identifiant Football-Data du doublon est transféré à la fiche conservée.
- Matchs, Centre C1, standings, phases finales, Champions et favori Team sont repointés.
- Correctif R4 des modales inclus.

CAS AEK
Ouvre la fiche AEK Athens / AEK Athènes que tu veux conserver.
Dans « Doublon de club », choisis PAE AEK puis « Fusionner le doublon ».
AEK Athens/Athènes restera le nom visible, mais la fiche sera reliée à Football-Data.

INSTALLATION
1. Copier le correctif en conservant l'arborescence.
2. Supabase SQL Editor :
   sql/HOTFIX_V0.9.10_R5_RESET_CLUB_MERGE.sql
3. Redéployer :
   supabase functions deploy sync-football-data
4. Déployer le frontend et faire Ctrl+F5.

Aucun nouveau secret. Aucun changement config.js.
