# Système de test V0.8.1

Ce patch ajoute un dispositif de régression couvrant **V0.1.x à V0.8.1**.

## Commandes

```bat
node tools\apply-v0.8.1.mjs
node tests\run-all-v0.8.1.mjs
```

Pour contrôler aussi les fichiers réellement déployés :

```bat
node tests\run-all-v0.8.1.mjs --url=https://VOTRE-SITE
```

## Centre de tests web

Après déploiement, ouvrir `tests/test-center-v0.8.1.html` sur le même domaine que l'application. Le navigateur réutilise la session Supabase persistée sur cet origin.

Le Centre de tests combine :
- contrôles frontend/PWA ;
- disponibilité de `sync-football-data` sans déclencher d'import ;
- diagnostic SQL Super Admin ;
- contrôles de cohérence de données en lecture seule ;
- **1185 tests manuels historiques et fonctionnels** avec filtres et rapport.

## Sécurité

Aucune clé privée n'est demandée. Le Centre de tests utilise uniquement la clé anon publique déjà présente dans `config.js` et la session du compte connecté.

## Correctif Windows

Le runner utilise `fileURLToPath(import.meta.url)` afin de résoudre correctement les chemins Windows (`C:\\...`) sans produire de chemin invalide de type `C:\\C:\\...`.
