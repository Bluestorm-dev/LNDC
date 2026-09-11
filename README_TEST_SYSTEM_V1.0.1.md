# Tests V1.0.1 — Le Nid des Champions

## Runner statique

Depuis la racine du dépôt :

```bash
node tests/run-all-v1.0.1.mjs
```

Le runner utilise `fileURLToPath(import.meta.url)` : il fonctionne aussi sous Windows lorsque le chemin contient des espaces ou des accents.

Le build livré obtient **35 PASS · 0 FAIL**. Il vérifie notamment le câblage V1.0.1, le LIVE C1, les stats buteurs/cartons, la conservation des métadonnées club, les carrousels Team, le flash LIVE, le classement, le modal joueur, les rivalités, l'auto-journée Pronostics, le SQL et la syntaxe de tous les fichiers JavaScript.

## Road-check manuel

Ouvrir `tests/test-center-v1.0.1.html` depuis l'Admin ou directement dans le navigateur et valider les scénarios réels LIVE/mobile.
