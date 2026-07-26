# Checklist V0.4.2 — Pays des clubs

## Release
- [ ] `VERSION` = `0.4.2`
- [ ] `config.js` / `config.example.js` = `0.4.2`
- [ ] cache service worker = `nid-champions-v0.4.2`
- [ ] aucune migration SQL supplémentaire sur une base déjà en V0.4.1

## Affichage pays
- [ ] chaque carte de match affiche le pays sous le nom du club
- [ ] le prochain match de l’accueil affiche le pays des deux clubs
- [ ] les confrontations de phase finale affichent le pays
- [ ] le Champion choisi affiche son pays dans Profil
- [ ] les listes de choix Champion indiquent le pays
- [ ] la bibliothèque Admin affiche un pays cohérent
- [ ] le Club de cœur propose le pays cohérent dans l’autocomplétion

## Monaco
- [ ] AS Monaco affiche **France 🇫🇷** dans les pronostics
- [ ] AS Monaco affiche **France 🇫🇷** sur l’accueil
- [ ] AS Monaco affiche **France 🇫🇷** dans les phases finales
- [ ] AS Monaco affiche **France** dans les sélecteurs/bibliothèques
- [ ] aucune donnée du club n’est dupliquée pour obtenir cette correction

## Non-régression
- [ ] navigation sidebar V0.4.1 intacte
- [ ] choix Champion 1/2 dans Profil intact
- [ ] saisie A1 → B1 → A2 et B1 → A1 → A2 intacte
- [ ] boutons +/- ne changent pas le focus
- [ ] cotes 1N2 intactes
- [ ] classements LIVE intacts
- [ ] phases finales, cumul, prolongation, TAB et qualifié intacts
