# Le Nid des Champions — Checklist V0.5.4

## Structure
- [ ] `assets/js/` n'existe plus.
- [ ] `assets/css/` n'existe plus.
- [ ] `js/` contient 12 fichiers JavaScript.
- [ ] `css/` contient 8 fichiers CSS.
- [ ] toutes les notices `INSTALLATION_V*.txt` sont dans `installation/`.
- [ ] `index.html` charge les CSS dans l'ordre prévu.
- [ ] `index.html` charge `js/app.js` en dernier.

## PWA
- [ ] le cache s'appelle `nid-champions-v0.5.4`.
- [ ] tous les nouveaux JS/CSS du front sont présents dans `CORE` dans `sw.js`.
- [ ] après Ctrl+F5, aucune requête vers `assets/js/app.js` ou `assets/css/app.css` n'apparaît.

## Non-régression
- [ ] connexion et inscription fonctionnent.
- [ ] accueil et pronostics fonctionnent.
- [ ] classement général, journée, soirée et live fonctionnent.
- [ ] Champions et phases finales fonctionnent.
- [ ] Teams et configurateur Team fonctionnent.
- [ ] profil et avatars officiels fonctionnent.
- [ ] upload/modération avatar fonctionne avec la base V0.5.3.
- [ ] administration fonctionne.
- [ ] Realtime fonctionne.
- [ ] version visible : `V0.5.4`.

## Release
- [ ] `node tests/release-v0.5.4.mjs` retourne `V0.5.4 release tests: OK`.
