# Système de tests V0.9.9

La V0.9.9 combine trois niveaux :

1. `node tests/run-all-v0.9.9.mjs` : contrôle statique local et, avec `--url=`, contrôle du déploiement GitHub Pages.
2. `tests/test-center-v0.9.9.html` : diagnostics Supabase et matrice cumulative de **1 880 contrôles** de V0.1.x à V0.9.9.
3. `tests/road-check-v0.9.9.html` : **24 missions guidées** pour la répétition humaine finale avant V1.0.0.

## Bac à sable pré-saison

Admin > Laboratoire > Répétition générale V1 crée uniquement des données `preseason_*`. Les vrais `profiles`, `matches`, `predictions` et `teams` ne sont pas alimentés par ce générateur.

Le test de charge est plafonné à 100 000 lignes. Le nettoyage exige le mot `NETTOYER`.

## Critère GO

- 0 FAIL local ;
- 0 FAIL distant ;
- diagnostic SQL V0.9.9 sans FAIL ;
- road-check parcouru ;
- aucun KO critique non traité ;
- données TEST nettoyées avant V1.0.0.
