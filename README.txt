LE NID DES CHAMPIONS — CORRECTIF V0.9.5 R3 — CENTRE DE TESTS

Corrige uniquement le Centre de tests V0.9.5 :
- titre V0.9.0 -> V0.9.5 ;
- sous-titre V0.1.x -> V0.8.1 -> V0.1.x -> V0.9.5 ;
- faux FAIL config.version : comparaison 0.9.0 -> 0.9.5 ;
- runner renforcé pour détecter ces incohérences à l'avenir.

Aucun SQL. Aucun redéploiement Edge Function.

Installation : copier le dossier tests/ à la racine de l'application en remplaçant les deux fichiers.
Puis redéployer sur GitHub Pages et faire Ctrl+F5.
