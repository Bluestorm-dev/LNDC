# Patch V1.0.1a → V1.0.2

1. Exécuter `sql/HOTFIX_V1.0.2_EXISTING_DB.sql` dans Supabase **avant** le nouveau front.
2. Copier le contenu du patch à la racine de LNDC et écraser les fichiers.
3. Lancer `node tests\\run-all-v1.0.2.mjs`.
4. `git add . && git commit -m "Le Nid des Champions v1.0.2" && git push origin main`.
5. Fermer/réouvrir complètement la PWA.

La saisie manuelle des données C1 se trouve dans **Super Admin → Compétition → Données C1 manuelles**.
