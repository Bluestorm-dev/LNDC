# Checklist de validation — V0.3.1

## Version / cache

- [ ] `VERSION` contient `0.3.1`.
- [ ] `config.js` contient `APP_VERSION: "0.3.1"`.
- [ ] `sw.js` utilise `nid-champions-v0.3.1`.
- [ ] `sql/006_patch_v0.3.1_logos_navigation.sql` s'exécute sans erreur.

## Football-Data / logos

- [ ] `Clubs + logos` retourne 36 clubs.
- [ ] `Clubs + logos` retourne 36 logos.
- [ ] `Calendrier CL` n'affiche plus `0 clubs · 0 logos`.
- [ ] Après calendrier déjà importé, le résumé affiche 36 clubs · 36 logos · 8 journées · 144 matchs.
- [ ] Les cartes Admin des 36 clubs ont toutes un blason.
- [ ] La Journée TEST affiche les bons blasons pour PSG, Bayern, Real Madrid, Arsenal, Inter, Barcelone, Liverpool et Dortmund.
- [ ] Les clubs de la Journée TEST sont les mêmes enregistrements Football-Data que ceux de la liste Admin.
- [ ] Aucun ancien doublon actif `Paris SG`, `Bayern Munich`, `Inter Milan`, `FC Barcelone` ou `Dortmund` ne subsiste après réparation.
- [ ] Les 144 matchs officiels restent inchangés.
- [ ] Les pronostics existants restent présents.

## Saisie pronostic clavier

Sur au moins trois matchs consécutifs non verrouillés :

- [ ] cliquer sur score A du match 1 ;
- [ ] taper `2` : A vaut 2 et le focus passe sur B du match 1 ;
- [ ] taper `1` : B vaut 1 et le focus passe sur A du match 2 ;
- [ ] taper `0` : le focus passe sur B du match 2 ;
- [ ] taper `3` : le focus passe sur A du match 3 ;
- [ ] l'autosave enregistre bien 2-1 puis 0-3 ;
- [ ] l'indicateur `✓ Enregistré` apparaît ;
- [ ] à la fin du dernier match, la saisie revient sur A du même match au lieu de sortir de la page.

## Boutons + / -

- [ ] cliquer dans A puis `+` : la valeur augmente sans changement de focus ;
- [ ] cliquer plusieurs fois sur `+` pour atteindre 10 ou 11 ;
- [ ] `−` ne descend jamais sous 0 ;
- [ ] utiliser `+ / −` sur B ne passe pas automatiquement au match suivant.

## Mobile

- [ ] le clavier numérique mobile suit A → B → match suivant ;
- [ ] le prochain match est amené dans la zone visible sans saut brutal ;
- [ ] aucune carte n'est masquée par le clavier après le changement de match.

## GO V0.3.1

- [ ] bons logos dans la Journée TEST ;
- [ ] compteurs Football-Data cohérents ;
- [ ] A → B → match suivant opérationnel ;
- [ ] + / − sans déplacement de focus ;
- [ ] aucune régression Classements & Live V0.3.0.
