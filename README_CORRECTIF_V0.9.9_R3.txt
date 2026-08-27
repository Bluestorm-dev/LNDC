LE NID DES CHAMPIONS — CORRECTIF V0.9.9 R3
================================================

OBJET
Le dépôt GitHub était bien en V0.9.9, mais le Centre de tests V0.9.9
contrôlait encore par erreur :
- VERSION = 0.9.8
- cache Service Worker = nid-champions-v0.9.8

CORRECTION
- Le Centre web attend maintenant VERSION = 0.9.9.
- Le Centre web attend maintenant nid-champions-v0.9.9.
- Le contrôle index.html vérifie aussi les assets V0.9.9.
- Le runner Node vérifie que le Centre web contrôle bien la version courante.

INSTALLATION
Copier le dossier tests/ du correctif à la racine du projet en remplaçant
les deux fichiers existants, puis commit/push GitHub Pages.

AUCUN SQL.
AUCUNE EDGE FUNCTION.
AUCUNE MODIFICATION DE CONFIG.JS.
