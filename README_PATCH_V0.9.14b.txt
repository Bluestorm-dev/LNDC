LE NID DES CHAMPIONS — HOTFIX V0.9.14b

Objet
Ajoute une étoile dorée au-dessus de l'avatar du joueur portant la distinction permanente :
« Vainqueur du Nid des Pronos — Coupe du monde 2026 ».

Installation depuis V0.9.14
1. Sauvegarder le dépôt actuel.
2. Copier le contenu de ce dossier à la racine du dépôt et accepter l'écrasement.
3. Vérifier config.js : ce patch est construit depuis la V0.9.14 fournie et ne modifie que APP_VERSION.
4. Dans Supabase SQL Editor, exécuter : sql/HOTFIX_V0.9.14b_EXISTING_DB.sql
5. Commit + push GitHub Pages.
6. Fermer/réouvrir la PWA ou forcer l'actualisation du navigateur.

Aucun changement de schéma Supabase.
La distinction existante `nid-pronos-world-cup-2026` reste la source de vérité.

Résultat
- étoile visible au-dessus de l'avatar du vainqueur dans tous les composants basés sur avatarHTML();
- compatible avec l'habillage Team ;
- mise à jour immédiate lorsque le Super Admin désigne ou retire le vainqueur ;
- animation légère désactivée si « prefers-reduced-motion » est actif.
