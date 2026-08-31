LE NID DES CHAMPIONS — PATCH V0.9.11 R7 -> V0.9.12
=======================================================

Périmètre :
- refonte UX/UI desktop ;
- deux carrousels Accueil ;
- Pronostics 2 colonnes + fiches clubs ;
- Classement du Nid ;
- Centre C1 réorganisé ;
- Profil compact accessible via avatar ;
- cockpit Admin cotes / scores / états / paramètres ;
- badges de classement bloqués jusqu'au premier résultat officiel ;
- mobile volontairement conservé pour la passe suivante.

Installation :
1. Sauvegarder Supabase et le dossier LNDC.
2. Extraire le patch à la racine en remplaçant les fichiers.
3. Exécuter dans Supabase SQL Editor :
   sql/HOTFIX_V0.9.12_EXISTING_DB.sql
4. Aucun redéploiement d'Edge Function n'est requis pour cette release.
5. Lancer :
   node tests\run-all-v0.9.12.mjs
6. Déployer GitHub Pages.
7. Puis :
   node tests\run-all-v0.9.12.mjs --url=https://bluestorm-dev.github.io/LNDC/
8. Ctrl+F5 / relancer la PWA.

Voir INSTALLATION_V0.9.12.txt.
