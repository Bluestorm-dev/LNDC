LE NID DES CHAMPIONS — PATCH V0.8.1 → V0.9.0
================================================

1. Faire une sauvegarde du dossier V0.8.1 et de Supabase.
2. Extraire TOUT le contenu de cette archive à la racine de l'application V0.8.1.
3. Depuis cette racine, lancer :
      node tools\apply-v0.9.0.mjs
4. Dans Supabase > SQL Editor, exécuter :
      sql/HOTFIX_V0.9.0_EXISTING_DB.sql
5. Lancer :
      node tests\run-all-v0.9.0.mjs
6. Déployer le frontend puis Ctrl+F5 / fermer-réouvrir la PWA.

NOUVEAUTÉ PALMARÈS
------------------
Admin > Joueurs > Palmarès & distinctions permanentes permet de désigner manuellement
le « Vainqueur du Nid des Pronos — Coupe du monde 2026 ».
Un seul vainqueur actif peut exister. Le titre est permanent entre les saisons et peut être retiré.

Le patch conserve config.js et ne remplace que APP_VERSION via le patcher.
