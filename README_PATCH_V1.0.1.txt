PATCH V1.0.0 -> V1.0.1
========================
- LIVE C1 instantané côté interface
- carrousels aux couleurs de la Team
- Nid en mouvement enrichi (records, zéros, casseroles, génie)
- ruban LIVE défilant
- classement avec delta LIVE rouge + correctif bas de page
- modal joueur explicite
- rivalités recalculées automatiquement
- Pronostics : prochaine journée automatique
- fiche club enrichie
- classement buteurs et cartons C1

SQL obligatoire AVANT le nouveau front : sql/HOTFIX_V1.0.1_EXISTING_DB.sql
Edge Function à redéployer : sync-football-data
Puis lancer une synchronisation Centre C1.
