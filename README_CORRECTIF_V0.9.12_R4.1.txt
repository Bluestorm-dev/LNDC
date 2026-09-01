LE NID DES CHAMPIONS — V0.9.12 R4.1
=======================================

CAUSE CORRIGÉE
Le R4 contenait des séquences littérales \n dans :
- js/release0912.js
- css/release0912.css

Cela provoquait :
- Uncaught SyntaxError: Invalid or unexpected token
- non-exécution du JS V0.9.12
- règles CSS mobiles R4 invalides
- cartes de matchs pouvant apparaître grises.

CORRECTIONS
- vrais retours à la ligne dans le JS et le CSS R4 ;
- validation node --check ;
- garde-fou bleu sombre sur les cartes du carrousel de matchs ;
- garde-fou bleu sombre sur les cartes Pronostics mobiles.

INSTALLATION
À appliquer PAR-DESSUS la V0.9.12 R4.
Remplacer les trois fichiers du patch.

Aucun SQL.
Aucune Edge Function.
