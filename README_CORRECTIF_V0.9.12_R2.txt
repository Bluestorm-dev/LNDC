LE NID DES CHAMPIONS — V0.9.12 R2
=====================================

- Accueil en tableau de bord compact.
- Hibou remonté sous les KPI.
- Deux carrousels automatiques côte à côte sur desktop, une carte toutes les 5 s.
- Prochains matchs avec logos, drapeaux, stade, pays et état du prono.
- Gros doublon « Prochain rendez-vous » supprimé.
- Noms de clubs courts dans Pronostics.
- Mobile remanié : accueil, carrousels, profil, C1 et barre de navigation.
- Onglet Admin direct sur mobile pour les comptes Admin / Super Admin.
- Menu Plus mobile : Soirées, Teams, Musée, Profil.
- Une fonction ouverte n'affiche plus la pastille OUVERT ; VERROUILLÉ reste visible.
- Nouvelle demande d'inscription : notification interne + Web Push au Super Admin, avec lien direct Admin > Joueurs.

INSTALLATION
1. Appliquer ce patch par-dessus V0.9.12 R1.
2. Supabase SQL Editor : exécuter sql/HOTFIX_V0.9.12_EXISTING_DB.sql.
3. Aucune Edge Function à redéployer.
4. node tests\run-all-v0.9.12.mjs
   Attendu : 311 PASS · 0 WARN · 0 FAIL.
5. Push GitHub Pages puis Ctrl+F5 / relancer la PWA.
