# Checklist de validation — V0.3.2 — Cotes 1N2

## 1. Version / migration
- [ ] `VERSION` contient `0.3.2`.
- [ ] `config.js` contient `APP_VERSION: "0.3.2"`.
- [ ] `sw.js` utilise `nid-champions-v0.3.2`.
- [ ] `007_patch_v0.3.2_cotes_1n2.sql` s'exécute sans erreur.
- [ ] Les colonnes `odds_home`, `odds_draw`, `odds_away`, `odds_provider`, `odds_bookmaker`, `odds_source_season`, `odds_is_test_shifted`, `odds_updated_at` existent.

## 2. Football-Data
- [ ] `Clubs + logos` conserve 36 clubs et 36 logos.
- [ ] `Calendrier CL` conserve exactement 144 matchs, 8 × 18.
- [ ] Une réponse Football-Data contenant les trois cotes remplit les trois colonnes `odds_*`.
- [ ] Une réponse avec `odds=null` ne fabrique aucune valeur.
- [ ] Une synchronisation ultérieure sans cotes ne remplace pas une ancienne cote valide par `null`.
- [ ] L'action cotes ne modifie ni score, ni statut, ni date, ni équipes.
- [ ] En saison TEST, les cotes Football-Data affichent `source 2025/26`.

## 3. Source externe optionnelle
- [ ] `sync-odds` est déployée avec JWT actif.
- [ ] `ODDS_API_KEY` est enregistré uniquement dans les secrets Supabase.
- [ ] `ODDS_EXTERNAL_ENABLED: true` n’est activé dans `config.js` qu’après déploiement de `sync-odds`.
- [ ] Avec `ODDS_EXTERNAL_ENABLED: false`, aucun appel vers une Edge Function externe absente n’est tenté.
- [ ] Sans `ODDS_API_KEY`, le Nid affiche un message clair sans casser l'écran.
- [ ] Avec une clé valide, la fonction cherche uniquement la Champions League.
- [ ] Les événements sont rapprochés par équipes + horaire, pas par simple position dans une liste.
- [ ] Les appels de cotes sont groupés par lots de 10 événements maximum.
- [ ] Seul un triplet complet domicile/nul/extérieur est enregistré.
- [ ] Une rencontre non reconnue reste sans cote plutôt que de recevoir une cote d'un autre match.
- [ ] Sur la saison TEST transposée, zéro correspondance externe est accepté : ce n'est pas une erreur fonctionnelle.

## 4. Affichage joueur
- [ ] Un match avec les trois valeurs affiche une ligne `Cotes 1N2`.
- [ ] Les capsules sont libellées `1`, `N`, `2`.
- [ ] Les valeurs utilisent deux décimales en français.
- [ ] La source/bookmaker est visible.
- [ ] L'heure de dernière mise à jour est visible.
- [ ] Un match sans triplet complet n'affiche aucune capsule factice.
- [ ] Le bloc reste lisible sur mobile et ne décale pas la saisie du score.

## 5. Administration
- [ ] Le bouton `Cotes 1N2` tente Football-Data puis le complément externe configuré.
- [ ] Le statut indique combien de matchs disposent réellement de cotes.
- [ ] Les cotes sont visibles en compact dans chaque ligne de gestion Admin.
- [ ] LIVE / Terminer / Reporter / Annuler / Réouvrir fonctionnent toujours.

## 6. Realtime
- [ ] Une mise à jour des colonnes de cotes sur `matches` déclenche le rafraîchissement du client via l'abonnement Realtime déjà présent.
- [ ] Aucun rechargement manuel de la page n'est nécessaire après une mise à jour de cote réussie.

## 7. Non-régression pronostics
- [ ] Saisie clavier A → B → A du match suivant toujours fonctionnelle.
- [ ] Les boutons + / − ne déplacent pas le focus.
- [ ] Autosave toujours fonctionnel.
- [ ] Les cotes n'interviennent jamais dans le calcul 0/3/5/7.
- [ ] Classements Général / Journée / Soirée / Précision / Exacts restent fonctionnels.
- [ ] Les variations ▲/▼ et la ligne sticky restent fonctionnelles.
- [ ] Les statistiques collectives restent fonctionnelles.

## 8. GO V0.3.2
- [ ] Aucun `404` RPC V0.3.0.
- [ ] Aucun `400/500` lié aux colonnes `odds_*`.
- [ ] Les 36 bons logos sont toujours affichés sur la Journée TEST.
- [ ] Tous les points ci-dessus sont validés.
