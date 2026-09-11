Le Nid des Champions — HOTFIX V1.0.1a

Correction : démarrage bloqué par ReferenceError: user_id is not defined dans js/release101.js.
Cause : storyPlayerV101 recevait userId mais utilisait le raccourci objet {user_id}, variable inexistante.
Correction : {user_id:userId}.

Installation :
1. Copier le contenu du hotfix à la racine du projet V1.0.1 en écrasant les fichiers.
2. Aucun SQL Supabase requis.
3. git add .
4. git commit -m "Hotfix v1.0.1a - fix storyPlayer user_id"
5. git push origin main
6. Fermer puis rouvrir complètement la PWA.

Le cache PWA est bumpé en V1.0.1a pour forcer le chargement du JS corrigé.
