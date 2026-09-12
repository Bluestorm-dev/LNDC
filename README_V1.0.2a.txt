LE NID DES CHAMPIONS — HOTFIX V1.0.2a

Corrige les trois points UI demandés :
1. Le classement complet des joueurs est affiché avant « Le pouls du Nid ».
   La carte du joueur connecté n'est plus sticky au-dessus des autres lignes.
2. Les couleurs Team ne sont jamais appliquées aux cartes de matchs.
   Dans « Le Nid en mouvement », elles sont appliquées uniquement si LE JOUEUR de la carte appartient à une Team, avec les couleurs de SA Team.
3. Casseroles et coups de génie deviennent explicites : match, prono, résultat et raison (issue minoritaire, cote, écart d'erreur, seul à se tromper, série de zéros...).
   Le détail apparaît sur l'accueil, dans le Musée et dans la fiche joueur.

INSTALLATION
- Décompresser ce patch à la racine du dépôt LNDC en conservant les dossiers js/css/sql/tools/tests.
- Lancer : node tools\apply-v1.0.2a.mjs
- Dans Supabase SQL Editor, exécuter tout le fichier : sql/HOTFIX_V1.0.2a_EXISTING_DB.sql
- Tester : node tests\test-v1.0.2a.mjs
- Puis : git add . && git commit -m "Hotfix v1.0.2a classement et gamification" && git push origin main
- Fermer complètement la PWA et la rouvrir.

Aucune donnée C1/J1 n'est modifiée par ce hotfix.
