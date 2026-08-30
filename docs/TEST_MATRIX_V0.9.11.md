# Le Nid des Champions — Matrice cumulative V0.9.11

**1940 contrôles manuels** de V0.1.x à V0.9.11.

## 0.1.x

### Installation / PWA

- [ ] **T0001** — Le site démarre sans erreur JavaScript.
- [ ] **T0002** — Le Service Worker est enregistré et la PWA peut être installée.
### Authentification

- [ ] **T0003** — Un nouvel utilisateur peut s’inscrire avec pseudo, e-mail et mot de passe.
- [ ] **T0004** — La validation e-mail permet ensuite la connexion.
- [ ] **T0005** — La connexion par pseudo fonctionne via login-by-username.
- [ ] **T0006** — Un compte inactif ne peut pas utiliser les fonctions joueur.
### Profils / rôles

- [ ] **T0007** — Le profil affiche le pseudo, l’avatar et le club de cœur.
- [ ] **T0008** — Les rôles player / admin / super_admin donnent les écrans attendus.
- [ ] **T0009** — Les fonctions Super Admin ne sont pas accessibles à un joueur.
### Multi-saisons

- [ ] **T0010** — La saison active est chargée par season_id/slug et les données restent rattachées à la saison.
### Navigation

- [ ] **T0011** — La navigation principale fonctionne sur desktop.
- [ ] **T0012** — La navigation principale fonctionne sur mobile.
### Mode démo

- [ ] **T0013** — Sans configuration Supabase, le mode démo fonctionne si DEMO_WHEN_UNCONFIGURED est activé.
### V0.1.2

- [ ] **T0014** — Un joueur actif peut pronostiquer.
- [ ] **T0015** — Un Admin actif peut également pronostiquer.
- [ ] **T0016** — Un Super Admin actif peut également pronostiquer.
## 0.2.0

### Installation

- [ ] **T0017** — Patch SQL V0.2.0 exécuté sans erreur.
- [ ] **T0018** — `login-by-username` toujours fonctionnelle.
- [ ] **T0019** — `sync-football-data` déployée.
- [ ] **T0020** — `FOOTBALL_DATA_API_KEY` configurée si synchronisation automatique utilisée.
- [ ] **T0021** — Cache PWA renouvelé en V0.2.0.
### Journées

- [ ] **T0022** — Plusieurs journées apparaissent dans le sélecteur.
- [ ] **T0023** — Le changement de journée recharge les bons matchs.
- [ ] **T0024** — La progression est différente pour chaque journée.
- [ ] **T0025** — Le calendrier Saison ouvre la bonne journée.
### Pronostics

- [ ] **T0026** — Joueur peut pronostiquer.
- [ ] **T0027** — Admin peut pronostiquer.
- [ ] **T0028** — Super Admin peut pronostiquer.
- [ ] **T0029** — `+/-` fonctionne.
- [ ] **T0030** — À 5 buts domicile, le focus passe au score extérieur.
- [ ] **T0031** — Il reste possible de dépasser 5.
- [ ] **T0032** — Autosauvegarde visible.
- [ ] **T0033** — Prono bloqué au coup d'envoi.
- [ ] **T0034** — Journée complète affiche le message du Hibou.
### Résultats

- [ ] **T0035** — Admin peut passer LIVE.
- [ ] **T0036** — Admin peut terminer un match.
- [ ] **T0037** — Le résultat recalcule les points.
- [ ] **T0038** — 0 / 3 / 5 / 7 vérifié sur quatre scénarios.
- [ ] **T0039** — Annulation donne 0 impact.
- [ ] **T0040** — Report + nouvelle date conserve le prono et le rend modifiable si la nouvelle date est future.
- [ ] **T0041** — Réouverture remet les points du match à 0 jusqu'au nouveau résultat.
### Historique

- [ ] **T0042** — Match terminé apparaît dans Mon historique.
- [ ] **T0043** — Score pronostiqué correct.
- [ ] **T0044** — Résultat correct.
- [ ] **T0045** — Points corrects.
- [ ] **T0046** — Modification d'un prono crée une entrée dans `prediction_history`.
### Clubs / logos

- [ ] **T0047** — Bouton Clubs + logos fonctionne.
- [ ] **T0048** — Logos apparaissent sur les cartes.
- [ ] **T0049** — Storage `club-logos` contient les images récupérées quand possible.
- [ ] **T0050** — Fallback distant utilisé si aucun fichier local n'a pu être copié.
- [ ] **T0051** — Bouton Calendrier CL crée/import les journées 1 à 8 si l'API les expose.
### Mobile

- [ ] **T0052** — Sélecteur de journées scrollable.
- [ ] **T0053** — Cartes matchs lisibles.
- [ ] **T0054** — `+/-` utilisables sans chevauchement.
- [ ] **T0055** — Historique lisible.
- [ ] **T0056** — Barre basse toujours accessible.
## 0.3.0

### 1. Release / fichiers

- [ ] **T0057** — `VERSION` contient `0.3.0`.
- [ ] **T0058** — `config.js` contient `APP_VERSION: "0.3.0"`.
- [ ] **T0059** — `sw.js` utilise le cache `nid-champions-v0.3.0`.
- [ ] **T0060** — `README.md`, `CHANGELOG.md` et `INSTALLATION_V0.3.0.txt` sont présents.
- [ ] **T0061** — `sql/005_patch_v0.3.0_classements_live.sql` s'exécute sans erreur.
- [ ] **T0062** — `sql/000_INSTALL_FRESH_V0.3.0.sql` permet une installation neuve.
- [ ] **T0063** — L'Edge Function `sync-football-data` est redéployée.
### 2. Correctifs V0.2.2 — Football-Data

- [ ] **T0064** — Depuis l'Admin, lancer **Clubs + logos**.
- [ ] **T0065** — La réponse indique source `2025/26`.
- [ ] **T0066** — Exactement **36 clubs** sont synchronisés.
- [ ] **T0067** — Les **36 logos** sont visibles dans l'aperçu Admin.
- [ ] **T0068** — Aucun ancien club Football-Data hors périmètre ne reste actif.
- [ ] **T0069** — Lancer **Calendrier CL**.
- [ ] **T0070** — Exactement **144 matchs** sont importés.
- [ ] **T0071** — Exactement **8 journées** existent.
- [ ] **T0072** — Chaque journée contient exactement **18 matchs**.
- [ ] **T0073** — Les dates sont transposées dans la saison **2026/27**.
- [ ] **T0074** — Les anciens matchs parasites de l'import à 188 sont supprimés.
- [ ] **T0075** — Aucun score historique 2025/26 n'apparaît.
- [ ] **T0076** — Les matchs historiques `FINISHED` côté API sont `scheduled` dans le Nid de test.
- [ ] **T0077** — Un résultat déjà terminé manuellement dans le Nid n'est pas écrasé lors d'une resynchronisation.
- [ ] **T0078** — Une réponse API avec un volume différent de 36 clubs ou 144 matchs est refusée avec un message explicite.
### 3. Pronostics — clavier / autosave

- [ ] **T0079** — Connexion avec un Player actif.
- [ ] **T0080** — Un chiffre tapé dans A remplace le score A et place le focus sur B.
- [ ] **T0081** — Un chiffre tapé dans B remplace le score B et replace le focus sur A.
- [ ] **T0082** — La séquence `1`, `2`, `3`, `0` permet de saisir rapidement plusieurs matchs sans clics inutiles.
- [ ] **T0083** — Le bouton `+` passe 9 → 10 → 11.
- [ ] **T0084** — Le bouton `−` revient 11 → 10 → 9.
- [ ] **T0085** — Cliquer `+ / −` ne déplace pas le focus du champ actuellement actif.
- [ ] **T0086** — Le score reste borné entre 0 et 99.
- [ ] **T0087** — L'autosave affiche `✓ Enregistré`.
- [ ] **T0088** — Recharger la page conserve le prono.
- [ ] **T0089** — Connexion Admin : l'Admin peut pronostiquer.
- [ ] **T0090** — Connexion Super Admin : le Super Admin peut pronostiquer.
- [ ] **T0091** — Au coup d'envoi, les champs sont verrouillés.
### 4. Préparation du scénario LIVE

- [ ] **T0092** — Créer/identifier Joueur A.
- [ ] **T0093** — Créer/identifier Joueur B.
- [ ] **T0094** — Joueur A et Joueur B saisissent des pronostics différents sur la même soirée.
- [ ] **T0095** — Ouvrir simultanément une session Admin et au moins une session joueur.
- [ ] **T0096** — Vérifier que le badge backend indique `Supabase · LIVE` après abonnement Realtime.
### 5. Passage LIVE

- [ ] **T0097** — Admin saisit `1–0` sur Match 1.
- [ ] **T0098** — Admin clique **Passer LIVE**.
- [ ] **T0099** — Le match affiche `LIVE · 1–0` sans refresh chez les joueurs.
- [ ] **T0100** — Le bandeau rouge LIVE apparaît.
- [ ] **T0101** — Le badge **CLASSEMENT LIVE** apparaît.
- [ ] **T0102** — Les points provisoires sont recalculés.
- [ ] **T0103** — Les points officiels stockés du match non terminé ne sont pas modifiés.
- [ ] **T0104** — Une variation `▲`, `▼` ou `—` apparaît dans le classement général.
- [ ] **T0105** — La ligne de l'utilisateur connecté reste sticky pendant le scroll.
- [ ] **T0106** — Les écarts dessus/dessous sont cohérents.
### 6. Modification d'un score LIVE

- [ ] **T0107** — Admin remplace le score par `1–1`.
- [ ] **T0108** — Admin clique **Actualiser LIVE**.
- [ ] **T0109** — Le score joueur passe à `1–1` sans rechargement manuel.
- [ ] **T0110** — Le classement provisoire est recalculé immédiatement.
- [ ] **T0111** — Les rangs changent si le nouveau score le justifie.
- [ ] **T0112** — Les variations suivent le nouveau rang.
- [ ] **T0113** — Aucun badge/exploit définitif n'est validé sur le seul score provisoire.
### 7. Plusieurs matchs LIVE

- [ ] **T0114** — Passer au moins deux matchs LIVE simultanément.
- [ ] **T0115** — Le bandeau LIVE liste les deux rencontres.
- [ ] **T0116** — Le classement général cumule les deux scores provisoires.
- [ ] **T0117** — Le classement **Soirée** ne compte que la date concernée.
- [ ] **T0118** — Le classement **Journée** ne compte que la journée sélectionnée.
### 8. Départages / rang unique

- [ ] **T0119** — priorité aux points ;
- [ ] **T0120** — à points égaux, priorité aux scores exacts ;
- [ ] **T0121** — puis à la meilleure moyenne ;
- [ ] **T0122** — puis aux bons écarts ;
- [ ] **T0123** — puis au nombre de pronostics joués ;
- [ ] **T0124** — aucun numéro de rang n'est partagé ;
- [ ] **T0125** — ordre déterministe final par pseudo si tous les critères précédents sont identiques.
### 9. Vues de classement

- [ ] **T0126** — **Général** affiche points, exacts, précision, moyenne, écarts et joués.
- [ ] **T0127** — **Journée** se recalcule lors du changement de journée.
- [ ] **T0128** — **Soirée** se limite à la date de référence.
- [ ] **T0129** — **Précision** trie d'abord sur le pourcentage de bons résultats.
- [ ] **T0130** — **Exacts** trie d'abord sur le nombre de scores exacts.
- [ ] **T0131** — Podium 1/2/3 visuellement distinct.
- [ ] **T0132** — Tableau utilisable sur mobile avec scroll horizontal.
### 10. Révélation des pronostics

- [ ] **T0133** — Avant verrouillage, aucun bouton de révélation n'est proposé.
- [ ] **T0134** — Avant verrouillage, l'appel RPC direct à `get_match_predictions_v030` est refusé.
- [ ] **T0135** — Après verrouillage, **Voir les pronos du Nid** apparaît.
- [ ] **T0136** — Le modal montre les joueurs ayant pronostiqué.
- [ ] **T0137** — Le prono du joueur connecté est marqué `★`.
- [ ] **T0138** — En LIVE, les points courants correspondent au score courant.
- [ ] **T0139** — Après fin de match, les points affichés correspondent aux points officiels.
### 11. Statistiques collectives

- [ ] **T0140** — Aucun prono non verrouillé ne fuit dans les statistiques.
- [ ] **T0141** — La répartition `1 / N / 2` totalise environ 100 %.
- [ ] **T0142** — Les cinq scores les plus joués sont cohérents.
- [ ] **T0143** — Le compteur d'exacts évolue avec les scores LIVE/final.
- [ ] **T0144** — La Fiabilité du Nid correspond au taux de bons résultats sur les pronostics confrontés à un score.
- [ ] **T0145** — Les stats se mettent à jour après modification du score Admin.
- [ ] **T0146** — Les stats Journée/Soirée suivent le scope sélectionné.
### 12. Fin de match / barème officiel

- [ ] **T0147** — Admin clique **Terminer**.
- [ ] **T0148** — Le statut devient `Terminé` en Realtime.
- [ ] **T0149** — Faux résultat = **0 pt**.
- [ ] **T0150** — Bon vainqueur / bon nul = **3 pts**.
- [ ] **T0151** — Bon résultat + bon écart = **5 pts**.
- [ ] **T0152** — Score exact = **7 pts**.
- [ ] **T0153** — Les points officiels sont persistés par le mécanisme serveur existant.
- [ ] **T0154** — Exacts, précision et moyenne sont mis à jour.
- [ ] **T0155** — Historique personnel affiche le résultat et les points.
- [ ] **T0156** — Le classement provisoire rejoint le classement officiel pour ce match.
### 13. Reports / annulations / réouverture

- [ ] **T0157** — Reporter un match conserve les pronostics.
- [ ] **T0158** — Une nouvelle date future rend le prono à nouveau modifiable selon les règles existantes.
- [ ] **T0159** — Annuler neutralise le match.
- [ ] **T0160** — Réouvrir remet le statut à `scheduled` et efface le score LIVE/final du match.
- [ ] **T0161** — Le classement se recalcule après réouverture.
### 14. Realtime / multi-session

- [ ] **T0162** — Match LIVE visible sans refresh sur une deuxième session.
- [ ] **T0163** — Changement 1–0 → 1–1 visible sans refresh.
- [ ] **T0164** — Fin de match visible sans refresh.
- [ ] **T0165** — Une sauvegarde de prono personnel ne provoque pas de perte de focus sur la carte en cours.
- [ ] **T0166** — Les politiques RLS empêchent de lire les pronostics adverses avant verrouillage.
- [ ] **T0167** — Aucun événement d'une autre saison ne modifie l'écran de la saison active.
### 15. UI/UX premium

- [ ] **T0168** — Fond bleu nuit / violet, halos et touches or visibles.
- [ ] **T0169** — Contrastes lisibles sur desktop.
- [ ] **T0170** — Contrastes lisibles sur mobile.
- [ ] **T0171** — Bandeau LIVE ne masque pas la navigation.
- [ ] **T0172** — Pas de débordement horizontal global hors tableau de classement volontaire.
- [ ] **T0173** — Cartes matchs et logos restent lisibles en mobile.
- [ ] **T0174** — Les 36 logos de l'Admin peuvent être parcourus sans casser la page.
- [ ] **T0175** — Animations de LIVE non bloquantes.
### 16. PWA / régression

- [ ] **T0176** — Installation PWA possible.
- [ ] **T0177** — Cache `nid-champions-v0.3.0` créé.
- [ ] **T0178** — Ancien cache V0.2.0 supprimé à l'activation.
- [ ] **T0179** — Navigation Accueil / Pronostics / Classement / Saison / Profil / Admin fonctionne.
- [ ] **T0180** — Inscription pending → validation Super Admin fonctionne toujours.
- [ ] **T0181** — Connexion par pseudo fonctionne toujours.
- [ ] **T0182** — Profil modifiable.
- [ ] **T0183** — Mode démo démarre sans Supabase configuré.
### Critère GO V0.3.0

- [ ] **T0184** — Tous les tests critiques Football-Data, saisie, LIVE, classement, RLS et barème sont validés.
- [ ] **T0185** — Une soirée complète peut être vécue en direct sans rechargement manuel.
- [ ] **T0186** — La release peut être taguée `v0.3.0`.
## 0.3.1

### Version / cache

- [ ] **T0187** — `VERSION` contient `0.3.1`.
- [ ] **T0188** — `config.js` contient `APP_VERSION: "0.3.1"`.
- [ ] **T0189** — `sw.js` utilise `nid-champions-v0.3.1`.
- [ ] **T0190** — `sql/006_patch_v0.3.1_logos_navigation.sql` s'exécute sans erreur.
### Football-Data / logos

- [ ] **T0191** — `Clubs + logos` retourne 36 clubs.
- [ ] **T0192** — `Clubs + logos` retourne 36 logos.
- [ ] **T0193** — `Calendrier CL` n'affiche plus `0 clubs · 0 logos`.
- [ ] **T0194** — Après calendrier déjà importé, le résumé affiche 36 clubs · 36 logos · 8 journées · 144 matchs.
- [ ] **T0195** — Les cartes Admin des 36 clubs ont toutes un blason.
- [ ] **T0196** — La Journée TEST affiche les bons blasons pour PSG, Bayern, Real Madrid, Arsenal, Inter, Barcelone, Liverpool et Dortmund.
- [ ] **T0197** — Les clubs de la Journée TEST sont les mêmes enregistrements Football-Data que ceux de la liste Admin.
- [ ] **T0198** — Aucun ancien doublon actif `Paris SG`, `Bayern Munich`, `Inter Milan`, `FC Barcelone` ou `Dortmund` ne subsiste après réparation.
- [ ] **T0199** — Les 144 matchs officiels restent inchangés.
- [ ] **T0200** — Les pronostics existants restent présents.
### Saisie pronostic clavier

- [ ] **T0201** — cliquer sur score A du match 1 ;
- [ ] **T0202** — taper `2` : A vaut 2 et le focus passe sur B du match 1 ;
- [ ] **T0203** — taper `1` : B vaut 1 et le focus passe sur A du match 2 ;
- [ ] **T0204** — taper `0` : le focus passe sur B du match 2 ;
- [ ] **T0205** — taper `3` : le focus passe sur A du match 3 ;
- [ ] **T0206** — l'autosave enregistre bien 2-1 puis 0-3 ;
- [ ] **T0207** — l'indicateur `✓ Enregistré` apparaît ;
- [ ] **T0208** — à la fin du dernier match, la saisie revient sur A du même match au lieu de sortir de la page.
### Boutons + / -

- [ ] **T0209** — cliquer dans A puis `+` : la valeur augmente sans changement de focus ;
- [ ] **T0210** — cliquer plusieurs fois sur `+` pour atteindre 10 ou 11 ;
- [ ] **T0211** — `−` ne descend jamais sous 0 ;
- [ ] **T0212** — utiliser `+ / −` sur B ne passe pas automatiquement au match suivant.
### Mobile

- [ ] **T0213** — le clavier numérique mobile suit A → B → match suivant ;
- [ ] **T0214** — le prochain match est amené dans la zone visible sans saut brutal ;
- [ ] **T0215** — aucune carte n'est masquée par le clavier après le changement de match.
### GO V0.3.1

- [ ] **T0216** — bons logos dans la Journée TEST ;
- [ ] **T0217** — compteurs Football-Data cohérents ;
- [ ] **T0218** — A → B → match suivant opérationnel ;
- [ ] **T0219** — + / − sans déplacement de focus ;
- [ ] **T0220** — aucune régression Classements & Live V0.3.0.
## 0.3.2

### 1. Version / migration

- [ ] **T0221** — `VERSION` contient `0.3.2`.
- [ ] **T0222** — `config.js` contient `APP_VERSION: "0.3.2"`.
- [ ] **T0223** — `sw.js` utilise `nid-champions-v0.3.2`.
- [ ] **T0224** — `007_patch_v0.3.2_cotes_1n2.sql` s'exécute sans erreur.
- [ ] **T0225** — Les colonnes `odds_home`, `odds_draw`, `odds_away`, `odds_provider`, `odds_bookmaker`, `odds_source_season`, `odds_is_test_shifted`, `odds_updated_at` existent.
### 2. Football-Data

- [ ] **T0226** — `Clubs + logos` conserve 36 clubs et 36 logos.
- [ ] **T0227** — `Calendrier CL` conserve exactement 144 matchs, 8 × 18.
- [ ] **T0228** — Une réponse Football-Data contenant les trois cotes remplit les trois colonnes `odds_*`.
- [ ] **T0229** — Une réponse avec `odds=null` ne fabrique aucune valeur.
- [ ] **T0230** — Une synchronisation ultérieure sans cotes ne remplace pas une ancienne cote valide par `null`.
- [ ] **T0231** — L'action cotes ne modifie ni score, ni statut, ni date, ni équipes.
- [ ] **T0232** — En saison TEST, les cotes Football-Data affichent `source 2025/26`.
### 3. Source externe optionnelle

- [ ] **T0233** — `sync-odds` est déployée avec JWT actif.
- [ ] **T0234** — `ODDS_API_KEY` est enregistré uniquement dans les secrets Supabase.
- [ ] **T0235** — `ODDS_EXTERNAL_ENABLED: true` n’est activé dans `config.js` qu’après déploiement de `sync-odds`.
- [ ] **T0236** — Avec `ODDS_EXTERNAL_ENABLED: false`, aucun appel vers une Edge Function externe absente n’est tenté.
- [ ] **T0237** — Sans `ODDS_API_KEY`, le Nid affiche un message clair sans casser l'écran.
- [ ] **T0238** — Avec une clé valide, la fonction cherche uniquement la Champions League.
- [ ] **T0239** — Les événements sont rapprochés par équipes + horaire, pas par simple position dans une liste.
- [ ] **T0240** — Les appels de cotes sont groupés par lots de 10 événements maximum.
- [ ] **T0241** — Seul un triplet complet domicile/nul/extérieur est enregistré.
- [ ] **T0242** — Une rencontre non reconnue reste sans cote plutôt que de recevoir une cote d'un autre match.
- [ ] **T0243** — Sur la saison TEST transposée, zéro correspondance externe est accepté : ce n'est pas une erreur fonctionnelle.
### 4. Affichage joueur

- [ ] **T0244** — Un match avec les trois valeurs affiche une ligne `Cotes 1N2`.
- [ ] **T0245** — Les capsules sont libellées `1`, `N`, `2`.
- [ ] **T0246** — Les valeurs utilisent deux décimales en français.
- [ ] **T0247** — La source/bookmaker est visible.
- [ ] **T0248** — L'heure de dernière mise à jour est visible.
- [ ] **T0249** — Un match sans triplet complet n'affiche aucune capsule factice.
- [ ] **T0250** — Le bloc reste lisible sur mobile et ne décale pas la saisie du score.
### 5. Administration

- [ ] **T0251** — Le bouton `Cotes 1N2` tente Football-Data puis le complément externe configuré.
- [ ] **T0252** — Le statut indique combien de matchs disposent réellement de cotes.
- [ ] **T0253** — Les cotes sont visibles en compact dans chaque ligne de gestion Admin.
- [ ] **T0254** — LIVE / Terminer / Reporter / Annuler / Réouvrir fonctionnent toujours.
### 6. Realtime

- [ ] **T0255** — Une mise à jour des colonnes de cotes sur `matches` déclenche le rafraîchissement du client via l'abonnement Realtime déjà présent.
- [ ] **T0256** — Aucun rechargement manuel de la page n'est nécessaire après une mise à jour de cote réussie.
### 7. Non-régression pronostics

- [ ] **T0257** — Saisie clavier A → B → A du match suivant toujours fonctionnelle.
- [ ] **T0258** — Les boutons + / − ne déplacent pas le focus.
- [ ] **T0259** — Autosave toujours fonctionnel.
- [ ] **T0260** — Les cotes n'interviennent jamais dans le calcul 0/3/5/7.
- [ ] **T0261** — Classements Général / Journée / Soirée / Précision / Exacts restent fonctionnels.
- [ ] **T0262** — Les variations ▲/▼ et la ligne sticky restent fonctionnelles.
- [ ] **T0263** — Les statistiques collectives restent fonctionnelles.
### 8. GO V0.3.2

- [ ] **T0264** — Aucun `404` RPC V0.3.0.
- [ ] **T0265** — Aucun `400/500` lié aux colonnes `odds_*`.
- [ ] **T0266** — Les 36 bons logos sont toujours affichés sur la Journée TEST.
- [ ] **T0267** — Tous les points ci-dessus sont validés.
## 0.3.3

### 1. Release

- [ ] **T0268** — `VERSION` contient `0.3.3`.
- [ ] **T0269** — `config.js` contient `APP_VERSION: "0.3.3"`.
- [ ] **T0270** — `sw.js` utilise `nid-champions-v0.3.3`.
- [ ] **T0271** — `008_patch_v0.3.3_navigation_catalogue_clubs.sql` s'exécute sans erreur.
- [ ] **T0272** — `club_catalog_memberships` existe et est lisible par un utilisateur authentifié.
- [ ] **T0273** — `sync-football-data` V0.3.3 est redéployée après le SQL.
### 2. Navigation clavier — départ A

- [ ] **T0274** — cliquer dans A1 ;
- [ ] **T0275** — taper `1` → focus automatique sur B1 ;
- [ ] **T0276** — taper `0` → focus automatique sur A2 ;
- [ ] **T0277** — taper `2` → focus automatique sur B2 ;
- [ ] **T0278** — taper `1` → focus automatique sur A3 ;
- [ ] **T0279** — les valeurs sont autosauvegardées.
### 3. Navigation clavier — départ B

- [ ] **T0280** — cliquer dans B1 ;
- [ ] **T0281** — taper `0` → focus automatique sur A1 ;
- [ ] **T0282** — taper `1` → focus automatique sur A2 ;
- [ ] **T0283** — taper `2` → focus automatique sur B2 ;
- [ ] **T0284** — taper `0` → focus automatique sur A3.
### 4. Boutons + / −

- [ ] **T0285** — cliquer dans A d'un match ;
- [ ] **T0286** — utiliser `+` plusieurs fois jusqu'à 10 ou 11 ;
- [ ] **T0287** — le focus ne saute pas sur B ;
- [ ] **T0288** — utiliser `−` ;
- [ ] **T0289** — le focus reste inchangé ;
- [ ] **T0290** — la valeur est sauvegardée.
### 5. Champions League inchangée

- [ ] **T0291** — `Clubs C1 + logos` fonctionne ;
- [ ] **T0292** — résumé C1 = 36 clubs ;
- [ ] **T0293** — résumé C1 = 36 logos exploitables ;
- [ ] **T0294** — `Calendrier CL` = 144 matchs ;
- [ ] **T0295** — 8 journées × 18 matchs ;
- [ ] **T0296** — aucun résultat historique importé ;
- [ ] **T0297** — les matchs TEST utilisent toujours les bons logos.
### 6. Bibliothèque Top 5

- [ ] **T0298** — l'action termine sans erreur 403/404/429 ;
- [ ] **T0299** — le retour Admin donne un total de clubs uniques et de logos ;
- [ ] **T0300** — le filtre `Ligue 1` affiche des clubs ;
- [ ] **T0301** — le filtre `Premier League` affiche des clubs ;
- [ ] **T0302** — le filtre `Liga` affiche des clubs ;
- [ ] **T0303** — le filtre `Serie A` affiche des clubs ;
- [ ] **T0304** — le filtre `Bundesliga` affiche des clubs ;
- [ ] **T0305** — `Tous les clubs` regroupe la bibliothèque ;
- [ ] **T0306** — les logos visibles correspondent aux clubs ;
- [ ] **T0307** — un club présent en C1 + championnat national n'apparaît qu'une fois dans `clubs`.
### 7. Club de cœur

- [ ] **T0308** — ouvrir Mon profil ;
- [ ] **T0309** — saisir quelques lettres d'un club Top 5 ;
- [ ] **T0310** — l'autocomplétion propose le club ;
- [ ] **T0311** — choisir le club puis enregistrer ;
- [ ] **T0312** — le nom canonique est sauvegardé ;
- [ ] **T0313** — le blason du club apparaît dans le badge Club de cœur ;
- [ ] **T0314** — un nom libre hors bibliothèque reste accepté.
### 8. Non-régression V0.3.2

- [ ] **T0315** — cotes 1/N/2 visibles quand le triplet existe ;
- [ ] **T0316** — bouton Admin `Cotes 1N2` fonctionne ;
- [ ] **T0317** — Classements Général/Journée/Soirée/Précision/Exacts fonctionnent ;
- [ ] **T0318** — scores LIVE Admin recalculent le classement ;
- [ ] **T0319** — Realtime fonctionne sans refresh ;
- [ ] **T0320** — points 0/3/5/7 inchangés.
### 9. GO V0.3.3

- [ ] **T0321** — aucun 404 RPC ;
- [ ] **T0322** — aucune erreur JavaScript bloquante ;
- [ ] **T0323** — aucune erreur Supabase sur `club_catalog_memberships` ;
- [ ] **T0324** — navigation A/B conforme dans les deux sens ;
- [ ] **T0325** — catalogue Top 5 exploitable pour le Club de cœur ;
- [ ] **T0326** — ZIP final testé après extraction.
## 0.3.4

### Général

- [ ] **T0327** — Edge Function `sync-football-data` V0.3.4 redéployée.
- [ ] **T0328** — Lancer « Bibliothèque Top 5 + logos ».
- [ ] **T0329** — Ligue 1 contient **Stade Brestois 29** / Brest.
- [ ] **T0330** — Ligue 1 ne contient pas Brentford FC.
- [ ] **T0331** — Premier League contient Brentford FC.
- [ ] **T0332** — Les logos Brest et Brentford sont distincts.
- [ ] **T0333** — FL1 = 18, PL = 20, PD = 20, SA = 20, BL1 = 18 (selon la saison actuellement renvoyée par le fournisseur).
- [ ] **T0334** — La requête diagnostic des clubs présents dans plusieurs championnats nationaux ne retourne aucune collision artificielle.
- [ ] **T0335** — Navigation clavier A1→B1→A2 et B1→A1→A2 toujours fonctionnelle.
- [ ] **T0336** — Boutons +/- sans changement de focus.
## 0.4.0

### Installation

- [ ] **T0337** — `HOTFIX_V0.4.0_EXISTING_DB.sql` s'exécute sans erreur.
- [ ] **T0338** — Les phases `LEAGUE`, `KNOCKOUT_PLAYOFF`, `ROUND_OF_16`, `QUARTER_FINAL`, `SEMI_FINAL`, `FINAL` existent.
- [ ] **T0339** — Les RPC V0.4.0 existent et PostgREST a rechargé son schéma.
- [ ] **T0340** — Le front affiche `V0.4.0` et aucun 404 RPC n'apparaît dans la console.
### Champion 1 — 100 points

- [ ] **T0341** — Un joueur peut choisir un club C1 avant le premier coup d'envoi.
- [ ] **T0342** — Le choix peut être modifié tant que le premier match n'a pas commencé.
- [ ] **T0343** — Les autres joueurs ne voient pas ce choix avant verrouillage.
- [ ] **T0344** — Après verrouillage, le choix devient visible dans « Les choix du Nid ».
- [ ] **T0345** — Un joueur sans choix reçoit l'OM lorsque le premier match passe LIVE/Terminé.
- [ ] **T0346** — L'attribution automatique indique `assigned_default=true`.
- [ ] **T0347** — Un premier champion qui remporte la compétition rapporte exactement 100 points.
- [ ] **T0348** — Un premier champion éliminé rapporte 0 et affiche son élimination.
### Champion 2 — 50 points

- [ ] **T0349** — Le deuxième choix est fermé tant que la phase de ligue n'est pas terminée.
- [ ] **T0350** — Il s'ouvre quand tous les matchs non annulés de la phase de ligue sont terminés.
- [ ] **T0351** — Seuls les clubs présents dans le tableau final peuvent être choisis.
- [ ] **T0352** — Il se verrouille au premier coup d'envoi des phases finales.
- [ ] **T0353** — Son choix reste caché avant verrouillage.
- [ ] **T0354** — Un deuxième champion vainqueur rapporte 50 points.
- [ ] **T0355** — Le même club peut être choisi en Champion 1 et Champion 2 : total possible 150.
### Tirage réel Admin

- [ ] **T0356** — L’Admin peut créer une confrontation de barrage, huitième, quart ou demi avec deux dates.
- [ ] **T0357** — La finale impose automatiquement le mode match unique.
- [ ] **T0358** — Deux clubs identiques sont refusés.
- [ ] **T0359** — Un retour programmé avant l’aller est refusé.
- [ ] **T0360** — Corriger une confrontation encore programmée met à jour clubs et horaires des matchs associés.
- [ ] **T0361** — Les confrontations réelles n’altèrent pas les confrontations TEST d’une autre recette.
### Générateur TEST et tableau

- [ ] **T0362** — « Générer tableau TEST » crée 23 confrontations : 8 barrages, 8 huitièmes, 4 quarts, 2 demies, 1 finale.
- [ ] **T0363** — Les barrages créent immédiatement 16 matchs (8 aller + 8 retour).
- [ ] **T0364** — Les tours suivants restent en attente tant que leurs deux participants ne sont pas connus.
- [ ] **T0365** — Le vainqueur d'un barrage apparaît automatiquement dans le huitième correspondant.
- [ ] **T0366** — Le vainqueur d'un huitième apparaît automatiquement dans le quart correspondant.
- [ ] **T0367** — Le vainqueur d'un quart apparaît automatiquement en demi.
- [ ] **T0368** — Le vainqueur d'une demi apparaît automatiquement en finale.
### Aller-retour et cumul

- [ ] **T0369** — Le score aller est enregistré sans désigner le qualifié final.
- [ ] **T0370** — Le cumul est affiché en direct sur la confrontation.
- [ ] **T0371** — Après le retour, un cumul non nul désigne automatiquement le bon qualifié.
- [ ] **T0372** — Les buts à domicile n'ont aucun poids particulier.
- [ ] **T0373** — Le perdant est marqué éliminé dans ses choix champion.
### 120 minutes et tirs au but

- [ ] **T0374** — Sur un retour à cumul égal, l'Admin doit cocher « Prolongation ».
- [ ] **T0375** — Le score final saisi est compris comme le score après 120 minutes.
- [ ] **T0376** — Si le cumul reste égal après 120 minutes, les tirs au but sont obligatoires.
- [ ] **T0377** — Deux scores TAB identiques sont refusés.
- [ ] **T0378** — Le vainqueur des TAB devient le qualifié.
- [ ] **T0379** — En finale, une égalité impose également prolongation puis TAB.
- [ ] **T0380** — Les tirs au but ne sont jamais ajoutés au score du match ni au cumul.
### Pronostics des scores

- [ ] **T0381** — Les scores aller et retour utilisent le barème 0/3/5/7 existant.
- [ ] **T0382** — Pour un retour/finale avec prolongation, le joueur pronostique le score à 120 minutes.
- [ ] **T0383** — L'autosave fonctionne sur chaque match des phases finales.
- [ ] **T0384** — La navigation clavier A→B→A match suivant reste fonctionnelle.
- [ ] **T0385** — La navigation B→A→A match suivant reste fonctionnelle.
- [ ] **T0386** — Les boutons +/- ne déplacent pas le focus.
### Qualifié et bonus

- [ ] **T0387** — Un joueur peut choisir le qualifié avant l'aller.
- [ ] **T0388** — Un bon qualifié choisi avant l'aller vaut +3.
- [ ] **T0389** — Le même choix revalidé après l'aller conserve son statut initial.
- [ ] **T0390** — Un choix réellement modifié après l'aller et avant le retour passe au bonus réduit +1.
- [ ] **T0391** — Le choix est verrouillé au coup d'envoi du retour.
- [ ] **T0392** — En finale, le qualifié est verrouillé au coup d'envoi du match unique.
- [ ] **T0393** — Un mauvais qualifié rapporte 0.
- [ ] **T0394** — Le bonus qualifié est ajouté au classement général sans modifier les statistiques d'exacts/moyenne des scores.
### Multiplicateurs

- [ ] **T0395** — Chaque phase peut être réglée sur x1, x2, x3 ou x4.
- [ ] **T0396** — Le changement de phase s'applique aux matchs encore programmés/reportés.
- [ ] **T0397** — Un match peut recevoir un multiplicateur différent de sa phase.
- [ ] **T0398** — Le multiplicateur est visible avant verrouillage sur la carte joueur.
- [ ] **T0399** — Exemple : score exact à x2 = 14 points.
- [ ] **T0400** — Exemple : bon résultat à x3 = 9 points.
- [ ] **T0401** — Le bonus qualifié et les bonus champions ne sont pas multipliés.
### Classement & Realtime

- [ ] **T0402** — Le classement général additionne points matchs + bonus qualifiés + champions.
- [ ] **T0403** — Le départage reste points → exacts → moyenne → bons écarts → joués.
- [ ] **T0404** — Le LIVE des scores continue de recalculer les points provisoires.
- [ ] **T0405** — Une qualification terminée met à jour le classement sans rechargement manuel.
- [ ] **T0406** — `knockout_ties`, `tie_predictions` et `champion_predictions` sont dans Supabase Realtime.
### Critère de sortie V0.4.0

- [ ] **T0407** — Un joueur peut traverser toute la compétition dans le Nid : phase de ligue, champion initial, barrages, huitièmes, quarts, demies, finale, champion final, scores, cumul, prolongation, TAB, qualifiés, bonus et multiplicateurs.
## 0.4.1

### Migration

- [ ] **T0408** — Base déjà en V0.4.0
- [ ] **T0409** — Aucun SQL supplémentaire exécuté
- [ ] **T0410** — `VERSION` = `0.4.1`
- [ ] **T0411** — cache service worker = `nid-champions-v0.4.1`
### Navigation desktop

- [ ] **T0412** — sidebar visible
- [ ] **T0413** — Accueil ouvre Accueil
- [ ] **T0414** — Pronostics ouvre la phase de ligue
- [ ] **T0415** — Phases finales ouvre le tableau KO
- [ ] **T0416** — Classements ouvre les classements
- [ ] **T0417** — Saison ouvre la saison
- [ ] **T0418** — Profil ouvre Profil & champions
- [ ] **T0419** — Admin visible uniquement Admin/Super Admin
- [ ] **T0420** — cartouche joueur de sidebar ouvre Profil
- [ ] **T0421** — élément actif clairement visible
### Navigation mobile

- [ ] **T0422** — sidebar masquée
- [ ] **T0423** — barre basse visible
- [ ] **T0424** — 6 entrées utilisables sans scroll horizontal
- [ ] **T0425** — contenu non masqué derrière la barre basse
### Fond / identité visuelle

- [ ] **T0426** — aucun motif répétitif de petits points
- [ ] **T0427** — fond bleu nuit stable au scroll
- [ ] **T0428** — halos/courbes non gênants pour la lecture
- [ ] **T0429** — contraste suffisant des textes et boutons
- [ ] **T0430** — pas d’image de fond externe
### Accueil épuré

- [ ] **T0431** — aucune liste complète de matchs sur Accueil
- [ ] **T0432** — rang affiché
- [ ] **T0433** — points affichés
- [ ] **T0434** — progression de journée affichée
- [ ] **T0435** — prochain match affiché
- [ ] **T0436** — logos des deux clubs visibles
- [ ] **T0437** — prono personnel affiché si déjà saisi
- [ ] **T0438** — bouton vers Pronostics fonctionnel
- [ ] **T0439** — match de phase finale renvoie vers Phases finales
- [ ] **T0440** — résumé Champion 1 visible
- [ ] **T0441** — résumé Champion 2 visible
- [ ] **T0442** — message Hibou visible
### Profil

- [ ] **T0443** — pseudo modifiable
- [ ] **T0444** — club de cœur modifiable
- [ ] **T0445** — bibliothèque de clubs toujours proposée
- [ ] **T0446** — cartouche sidebar mis à jour après sauvegarde du profil
### Champion n°1

- [ ] **T0447** — bloc présent DANS Profil
- [ ] **T0448** — bonus +100 affiché
- [ ] **T0449** — liste des clubs disponible tant que le choix est ouvert
- [ ] **T0450** — enregistrement fonctionnel
- [ ] **T0451** — choix personnel visible après sauvegarde
- [ ] **T0452** — autres choix cachés avant verrouillage
- [ ] **T0453** — OM par défaut clairement expliqué
- [ ] **T0454** — état OM par défaut visible lorsqu'il est attribué
- [ ] **T0455** — état éliminé visible si le club sort
### Champion n°2

- [ ] **T0456** — bloc présent DANS Profil
- [ ] **T0457** — bonus +50 affiché
- [ ] **T0458** — fermé avant sa fenêtre d'ouverture
- [ ] **T0459** — candidats disponibles lorsque la fenêtre s'ouvre
- [ ] **T0460** — enregistrement fonctionnel
- [ ] **T0461** — même club que Champion n°1 autorisé
- [ ] **T0462** — choix caché avant verrouillage
### Non-régression V0.4.0

- [ ] **T0463** — saisie A1 → B1 → A2
- [ ] **T0464** — saisie B1 → A1 → A2
- [ ] **T0465** — +/- ne déplace pas le focus
- [ ] **T0466** — autosave fonctionne
- [ ] **T0467** — logos clubs corrects
- [ ] **T0468** — cotes 1N2 toujours affichées si disponibles
- [ ] **T0469** — classement Realtime fonctionne
- [ ] **T0470** — LIVE Admin fonctionne
- [ ] **T0471** — barrages aller/retour fonctionnent
- [ ] **T0472** — cumul fonctionne
- [ ] **T0473** — score à 120 minutes fonctionne
- [ ] **T0474** — tirs au but fonctionnent
- [ ] **T0475** — qualifié +3/+1 fonctionne
- [ ] **T0476** — multiplicateurs x1/x2/x3/x4 fonctionnent
- [ ] **T0477** — finale match unique fonctionne
## 0.4.2

### Release

- [ ] **T0478** — `VERSION` = `0.4.2`
- [ ] **T0479** — `config.js` / `config.example.js` = `0.4.2`
- [ ] **T0480** — cache service worker = `nid-champions-v0.4.2`
- [ ] **T0481** — aucune migration SQL supplémentaire sur une base déjà en V0.4.1
### Affichage pays

- [ ] **T0482** — chaque carte de match affiche le pays sous le nom du club
- [ ] **T0483** — le prochain match de l’accueil affiche le pays des deux clubs
- [ ] **T0484** — les confrontations de phase finale affichent le pays
- [ ] **T0485** — le Champion choisi affiche son pays dans Profil
- [ ] **T0486** — les listes de choix Champion indiquent le pays
- [ ] **T0487** — la bibliothèque Admin affiche un pays cohérent
- [ ] **T0488** — le Club de cœur propose le pays cohérent dans l’autocomplétion
### Monaco

- [ ] **T0489** — AS Monaco affiche **France 🇫🇷** dans les pronostics
- [ ] **T0490** — AS Monaco affiche **France 🇫🇷** sur l’accueil
- [ ] **T0491** — AS Monaco affiche **France 🇫🇷** dans les phases finales
- [ ] **T0492** — AS Monaco affiche **France** dans les sélecteurs/bibliothèques
- [ ] **T0493** — aucune donnée du club n’est dupliquée pour obtenir cette correction
### Non-régression

- [ ] **T0494** — navigation sidebar V0.4.1 intacte
- [ ] **T0495** — choix Champion 1/2 dans Profil intact
- [ ] **T0496** — saisie A1 → B1 → A2 et B1 → A1 → A2 intacte
- [ ] **T0497** — boutons +/- ne changent pas le focus
- [ ] **T0498** — cotes 1N2 intactes
- [ ] **T0499** — classements LIVE intacts
- [ ] **T0500** — phases finales, cumul, prolongation, TAB et qualifié intacts
## 0.5.0

### Release / migration

- [ ] **T0501** — `VERSION` = `0.5.0`.
- [ ] **T0502** — cache Service Worker = `nid-champions-v0.5.0`.
- [ ] **T0503** — `011_patch_v0.5.0_teams.sql` s'exécute sans erreur sur une base V0.4.2.
- [ ] **T0504** — `000_INSTALL_FRESH_V0.5.0.sql` fonctionne sur une base vierge.
- [ ] **T0505** — bucket `team-logos` présent.
- [ ] **T0506** — RPC `get_team_leaderboard_v050` visible par PostgREST.
### Hibou masqué / assets

- [ ] **T0507** — `assets/branding/owl/owl-masked-main.png` existe.
- [ ] **T0508** — fond réellement transparent.
- [ ] **T0509** — aucun logo sur le front.
- [ ] **T0510** — médaillon sans coupe.
- [ ] **T0511** — aucun ballon sous les pattes.
- [ ] **T0512** — asset référencé dans `docs/ASSETS_MANIFEST.md`.
### Création de Team

- [ ] **T0513** — joueur sans Team peut créer une Team.
- [ ] **T0514** — nom obligatoire entre 3 et 30 caractères.
- [ ] **T0515** — nom unique dans la saison.
- [ ] **T0516** — slogan facultatif, 80 caractères maximum.
- [ ] **T0517** — description facultative, 160 caractères maximum.
- [ ] **T0518** — équipe fétiche facultative.
- [ ] **T0519** — équipe fétiche peut être un club hors Ligue des champions.
- [ ] **T0520** — créateur devient l'unique capitaine.
- [ ] **T0521** — impossible de créer une deuxième Team avec un membership actif.
### Identité visuelle

- [ ] **T0522** — 12 formes proposées : cercle, médaillon, carré arrondi, carré prestige, losange, hexagone, écusson classique, écusson pointu, bouclier moderne, bannière, royal, prestige.
- [ ] **T0523** — cadres Bois / Bronze / Argent / Or / Or royal / Acier / Cuir / Obsidienne / Néon / Champions / Royal / Nuit européenne.
- [ ] **T0524** — couleur principale modifiable.
- [ ] **T0525** — couleur secondaire modifiable.
- [ ] **T0526** — fonds uni / vertical / horizontal / diagonal / radial / halo.
- [ ] **T0527** — aperçu Team mis à jour en direct.
- [ ] **T0528** — aperçu avatar mis à jour en direct.
- [ ] **T0529** — aperçu classement mis à jour en direct.
- [ ] **T0530** — avatar personnel reste lisible au premier plan.
- [ ] **T0531** — changement d'apparence se propage sans modifier chaque profil.
### Logos Team

- [ ] **T0532** — choix d'un logo de la bibliothèque.
- [ ] **T0533** — upload PNG/JPEG/WebP/SVG accepté sous 3 Mo.
- [ ] **T0534** — upload > 3 Mo refusé.
- [ ] **T0535** — logo uploadé s'affiche après sauvegarde.
- [ ] **T0536** — réouverture de l'éditeur conserve un logo uploadé tant qu'un autre logo n'est pas choisi.
- [ ] **T0537** — passage upload -> logo bibliothèque fonctionne.
### Team publique

- [ ] **T0538** — Team visible dans l'annuaire.
- [ ] **T0539** — bouton Rejoindre disponible.
- [ ] **T0540** — adhésion immédiate.
- [ ] **T0541** — nouveau membre visible sans refresh grâce au Realtime.
### Team privée

- [ ] **T0542** — Team visible comme privée dans l'annuaire.
- [ ] **T0543** — demande d'adhésion possible.
- [ ] **T0544** — demande visible par le capitaine.
- [ ] **T0545** — capitaine peut accepter.
- [ ] **T0546** — capitaine peut refuser.
- [ ] **T0547** — joueur accepté rejoint la Team.
- [ ] **T0548** — capitaine peut générer/régénérer un code.
- [ ] **T0549** — code valide permet l'entrée directe.
- [ ] **T0550** — ancien code révoqué n'est plus utilisable.
### Une seule Team

- [ ] **T0551** — un joueur membre ne peut rejoindre une autre Team publique.
- [ ] **T0552** — un joueur membre ne peut rejoindre par code une autre Team.
- [ ] **T0553** — un joueur membre ne peut créer une nouvelle Team.
- [ ] **T0554** — après un départ valide, il peut rejoindre/créer une autre Team.
### Capitaine

- [ ] **T0555** — un seul capitaine par Team.
- [ ] **T0556** — capitaine identifié par 👑.
- [ ] **T0557** — capitaine peut modifier l'identité.
- [ ] **T0558** — capitaine peut exclure un membre.
- [ ] **T0559** — capitaine ne peut pas s'exclure lui-même.
- [ ] **T0560** — capitaine ne peut pas quitter tant qu'il n'a pas transféré son rôle.
- [ ] **T0561** — transfert vers un membre actif fonctionne.
- [ ] **T0562** — ancien capitaine devient membre normal.
- [ ] **T0563** — nouveau capitaine reçoit immédiatement les outils de gestion.
### Dissolution / historique

- [ ] **T0564** — dissolution demande confirmation.
- [ ] **T0565** — Team passe à `dissolved` et n'est pas supprimée.
- [ ] **T0566** — memberships actifs sont fermés.
- [ ] **T0567** — historique reste consultable.
- [ ] **T0568** — création historisée.
- [ ] **T0569** — arrivée historisée.
- [ ] **T0570** — départ historisé.
- [ ] **T0571** — exclusion historisée.
- [ ] **T0572** — transfert de capitaine historisé.
- [ ] **T0573** — changement d'identité historisé.
- [ ] **T0574** — changement public/privé historisé.
- [ ] **T0575** — dissolution historisée.
### Classements Teams

- [ ] **T0576** — classement Moyenne générale visible.
- [ ] **T0577** — classement Top 3 visible.
- [ ] **T0578** — classement Journée UEFA visible.
- [ ] **T0579** — Team de 1 membre classée correctement.
- [ ] **T0580** — Team de 2 membres classée correctement en Top 3.
- [ ] **T0581** — Team de 3+ membres utilise les 3 meilleurs pour Top 3.
- [ ] **T0582** — Journée TEST n°0 n'alimente pas le général.
- [ ] **T0583** — bonus qualifiés/champions intégrés au général Team.
- [ ] **T0584** — changement de Team ne transfère jamais les anciens points.
- [ ] **T0585** — points d'un match attribués au membership actif au coup d'envoi.
### Habillage des joueurs

- [ ] **T0586** — classement individuel : avatar entouré du skin Team.
- [ ] **T0587** — profil : Team et rôle visibles.
- [ ] **T0588** — pronostics des autres après verrouillage : skin Team visible.
- [ ] **T0589** — membres Team : skin commun visible.
- [ ] **T0590** — joueur sans Team : style neutre du Nid.
- [ ] **T0591** — changement couleurs/cadre Team actualise tous les membres.
### Profil / annuaire

- [ ] **T0592** — Profil affiche Ma Team.
- [ ] **T0593** — joueur sans Team peut aller vers Teams depuis Profil.
- [ ] **T0594** — équipe fétiche Team distincte du club de cœur personnel.
- [ ] **T0595** — recherche annuaire par nom fonctionne.
- [ ] **T0596** — filtre public/privé fonctionne.
### Administration

- [ ] **T0597** — Admin voit les Teams actives et dissoutes.
- [ ] **T0598** — recherche Admin par Team/capitaine fonctionne.
- [ ] **T0599** — Admin peut consulter détails, membres et historique.
- [ ] **T0600** — opérations sensibles restent côté RPC/RLS.
### Realtime

- [ ] **T0601** — création/mise à jour Team visible sans refresh.
- [ ] **T0602** — membership visible sans refresh.
- [ ] **T0603** — demande d'adhésion visible sans refresh.
- [ ] **T0604** — événement Team visible sans refresh.
- [ ] **T0605** — classement Team se rafraîchit après évolution des pronostics/scores.
### Mobile / UX

- [ ] **T0606** — sidebar desktop contient Teams.
- [ ] **T0607** — barre basse mobile contient Teams.
- [ ] **T0608** — navigation mobile ne déborde pas de façon inutilisable.
- [ ] **T0609** — avatars Team restent lisibles à 40–48 px.
- [ ] **T0610** — éditeur Team utilisable au tactile.
- [ ] **T0611** — listes membres/historique restent lisibles à 360 px.
### Non-régression V0.4.x

- [ ] **T0612** — pronostics clavier A1 -> B1 -> A2 fonctionne.
- [ ] **T0613** — pronostics clavier B1 -> A1 -> A2 fonctionne.
- [ ] **T0614** — boutons +/- ne déplacent pas le focus.
- [ ] **T0615** — barème 0/3/5/7 inchangé.
- [ ] **T0616** — cotes 1N2 inchangées.
- [ ] **T0617** — pays des clubs toujours visibles et AS Monaco = France.
- [ ] **T0618** — Champion 1 / Champion 2 toujours dans Profil.
- [ ] **T0619** — phases finales, cumul, prolongation, TAB et qualifiés toujours accessibles.
- [ ] **T0620** — classement LIVE individuel toujours fonctionnel.
## 0.5.2

### Desktop

- [ ] **T0621** — Ouvrir **Teams > Modifier l'apparence**
- [ ] **T0622** — La modale occupe une largeur confortable et les champs ne sont plus compressés
- [ ] **T0623** — Les réglages sont à gauche et l'aperçu reste dans une zone dédiée à droite
- [ ] **T0624** — Les 12 formes sont visibles sans ouvrir une liste
- [ ] **T0625** — Les 12 cadres/matières sont visibles sans ouvrir une liste
- [ ] **T0626** — Les logos de bibliothèque n'ont pas de carré/fond opaque
- [ ] **T0627** — Le blason laisse clairement voir les couleurs Team derrière le logo
### Régression visuelle V0.5.2

- [ ] **T0628** — Les 12 vignettes de forme sont visuellement différentes (pas 12 carrés arrondis)
- [ ] **T0629** — Cercle est réellement circulaire
- [ ] **T0630** — Médaillon est festonné et différent du cercle
- [ ] **T0631** — Losange est réellement en losange
- [ ] **T0632** — Hexagone possède six côtés visibles
- [ ] **T0633** — Les trois écussons ont des silhouettes distinctes
- [ ] **T0634** — Les 12 matières sont visuellement différentes (bois/or/argent/etc.)
- [ ] **T0635** — Après changement de forme, toutes les vignettes de cadre reprennent cette forme
- [ ] **T0636** — Le sélecteur 1 couleur / 2 couleurs est visible sans ambiguïté
- [ ] **T0637** — En mode 2 couleurs, deux sélecteurs de couleur sont affichés simultanément
### Formes & cadres

- [ ] **T0638** — Cercle + Bois : le bois suit le cercle
- [ ] **T0639** — Hexagone + Or : l'or suit les six côtés
- [ ] **T0640** — Losange + Argent : aucun cadre rectangulaire coupé
- [ ] **T0641** — Écusson classique + Obsidienne : la bordure suit l'écusson
- [ ] **T0642** — Blason royal + Or royal : la matière suit les pointes
- [ ] **T0643** — Néon : halo propre sans débordement gênant
- [ ] **T0644** — Changer de forme ne déforme pas le logo
- [ ] **T0645** — Changer de cadre ne modifie pas la forme
### Couleurs

- [ ] **T0646** — Choisir **1 couleur**
- [ ] **T0647** — Le second sélecteur disparaît
- [ ] **T0648** — Le choix de dégradé disparaît
- [ ] **T0649** — L'aperçu devient réellement uni
- [ ] **T0650** — Enregistrer puis rouvrir : le mode 1 couleur est conservé
- [ ] **T0651** — Choisir **2 couleurs**
- [ ] **T0652** — Le second sélecteur apparaît
- [ ] **T0653** — Tester vertical
- [ ] **T0654** — Tester horizontal
- [ ] **T0655** — Tester diagonal
- [ ] **T0656** — Tester radial
- [ ] **T0657** — Tester halo
- [ ] **T0658** — Enregistrer puis rouvrir : couleurs et fond sont conservés
### Presets

- [ ] **T0659** — Champions bleu
- [ ] **T0660** — Or royal
- [ ] **T0661** — Bois forêt
- [ ] **T0662** — Obsidienne
- [ ] **T0663** — Néon
- [ ] **T0664** — Chaque preset met à jour forme, cadre et couleurs en direct
- [ ] **T0665** — **Réinitialiser le style** revient à l'écusson Champions bleu/violet par défaut
### Logos

- [ ] **T0666** — Sélectionner chacun des logos de bibliothèque
- [ ] **T0667** — Aucun logo de bibliothèque n'a de fond opaque propre
- [ ] **T0668** — Choisir une image uploadée
- [ ] **T0669** — L'aperçu local change avant l'enregistrement
- [ ] **T0670** — Enregistrer l'upload
- [ ] **T0671** — Le logo reste visible après rechargement
- [ ] **T0672** — Repasser à un logo de bibliothèque supprime visuellement l'upload
### Aperçus

- [ ] **T0673** — Aperçu **Blason Team**
- [ ] **T0674** — Aperçu **Avatar membre**
- [ ] **T0675** — Aperçu **Ligne de classement**
- [ ] **T0676** — Aperçu **Carte Team**
- [ ] **T0677** — Le pseudo ne déborde pas
- [ ] **T0678** — Les couleurs restent lisibles avec un cadre clair
- [ ] **T0679** — Les couleurs restent lisibles avec un cadre sombre
### Mobile

- [ ] **T0680** — La modale repasse en une colonne
- [ ] **T0681** — Aucune option n'est coupée horizontalement
- [ ] **T0682** — Les grilles restent utilisables au doigt
- [ ] **T0683** — Les aperçus passent sous les réglages
- [ ] **T0684** — Les boutons Enregistrer / Réinitialiser restent accessibles
- [ ] **T0685** — Aucun scroll horizontal global
### Non-régression Teams V0.5.0

- [ ] **T0686** — Création Team
- [ ] **T0687** — Modification Team
- [ ] **T0688** — Équipe fétiche
- [ ] **T0689** — Team publique
- [ ] **T0690** — Team privée
- [ ] **T0691** — Demande d'adhésion
- [ ] **T0692** — Code d'invitation
- [ ] **T0693** — Capitaine unique
- [ ] **T0694** — Transfert de capitanat
- [ ] **T0695** — Classement moyenne
- [ ] **T0696** — Classement Top 3
- [ ] **T0697** — Classement journée
- [ ] **T0698** — Historique
- [ ] **T0699** — Realtime
## 0.5.3

### 1. Migration Supabase

- [ ] **T0700** — `sql/HOTFIX_V0.5.3_EXISTING_DB.sql` s’exécute sans erreur avec le rôle `postgres`.
- [ ] **T0701** — `app_settings.app_version` vaut `0.5.3`.
- [ ] **T0702** — Le bucket `player-avatars` existe, est privé, limité à 3 Mo et aux MIME PNG/JPEG/WebP.
- [ ] **T0703** — Les colonnes avatar V0.5.3 existent dans `profiles`.
- [ ] **T0704** — Les quatre RPC `*avatar*v053` sont visibles après reload du schéma.
### 2. Bibliothèque officielle

- [ ] **T0705** — Le Profil affiche 13 catégories / 168 avatars.
- [ ] **T0706** — Chaque vignette charge un PNG sans image cassée.
- [ ] **T0707** — Cliquer un avatar change l’aperçu sans l’enregistrer immédiatement.
- [ ] **T0708** — « Utiliser l’avatar officiel sélectionné » met à jour l’avatar du joueur.
- [ ] **T0709** — Après rechargement, l’avatar sélectionné est conservé.
### 3. Habillage Team

- [ ] **T0710** — Sans Team, l’aperçu affiche uniquement l’avatar.
- [ ] **T0711** — Avec Team, le cadre/forme/couleurs/logo restent autour de l’avatar.
- [ ] **T0712** — L’image personnelle reste au premier plan et n’est pas remplacée par le logo Team.
### 4. Upload joueur

- [ ] **T0713** — PNG accepté.
- [ ] **T0714** — JPG/JPEG accepté.
- [ ] **T0715** — WebP accepté.
- [ ] **T0716** — Un autre format est refusé côté front.
- [ ] **T0717** — Un fichier > 3 Mo est refusé.
- [ ] **T0718** — Le fichier apparaît en aperçu local avant envoi.
- [ ] **T0719** — Après envoi, `profiles.avatar_moderation_status = pending`.
- [ ] **T0720** — Le joueur voit son upload en attente dans son Profil avec l’indicateur ⏳.
- [ ] **T0721** — Les autres vues publiques continuent d’afficher l’avatar officiel tant que l’upload est pending.
### 5. RLS Storage

- [ ] **T0722** — Un joueur peut uploader dans `<son_uuid>/...`.
- [ ] **T0723** — Un joueur ne peut pas uploader dans le dossier UUID d’un autre joueur.
- [ ] **T0724** — Un joueur ne peut pas modifier directement `avatar_moderation_status` via le front.
- [ ] **T0725** — Admin/Super Admin peut modérer l’avatar.
### 6. Modération Admin

- [ ] **T0726** — Administration > « Modération des avatars » liste les uploads pending.
- [ ] **T0727** — « Valider » passe l’avatar en `approved`.
- [ ] **T0728** — L’avatar approuvé apparaît ensuite dans les vues publiques.
- [ ] **T0729** — « Refuser » accepte un motif facultatif et passe en `rejected`.
- [ ] **T0730** — Après refus, l’avatar officiel est utilisé publiquement.
- [ ] **T0731** — Une ligne `audit_logs` est créée pour approve/reject.
### 7. Intégrations

- [ ] **T0732** — Sidebar : avatar correct.
- [ ] **T0733** — Profil : avatar correct.
- [ ] **T0734** — Classement général : avatar correct.
- [ ] **T0735** — Classement journée/soirée/précision/exacts : avatar correct.
- [ ] **T0736** — Classement LIVE : avatar correct pendant un match live.
- [ ] **T0737** — Teams : membres et demandes affichent les avatars.
- [ ] **T0738** — Pronos révélés : après verrouillage, la modale affiche les avatars.
- [ ] **T0739** — Aucun avatar adverse n’est révélé avant le verrouillage via la modale des pronostics.
### 8. PWA / régression

- [ ] **T0740** — Cache `nid-champions-v0.5.3`.
- [ ] **T0741** — Auth, pronostics, Champions, phases finales et Teams V0.5.2 restent fonctionnels.
- [ ] **T0742** — `node tests/release-v0.5.3.mjs` retourne `OK`.
## 0.5.4

### Structure

- [ ] **T0743** — `assets/js/` n'existe plus.
- [ ] **T0744** — `assets/css/` n'existe plus.
- [ ] **T0745** — `js/` contient 12 fichiers JavaScript.
- [ ] **T0746** — `css/` contient 8 fichiers CSS.
- [ ] **T0747** — toutes les notices `INSTALLATION_V*.txt` sont dans `installation/`.
- [ ] **T0748** — `index.html` charge les CSS dans l'ordre prévu.
- [ ] **T0749** — `index.html` charge `js/app.js` en dernier.
### PWA

- [ ] **T0750** — le cache s'appelle `nid-champions-v0.5.4`.
- [ ] **T0751** — tous les nouveaux JS/CSS du front sont présents dans `CORE` dans `sw.js`.
- [ ] **T0752** — après Ctrl+F5, aucune requête vers `assets/js/app.js` ou `assets/css/app.css` n'apparaît.
### Non-régression

- [ ] **T0753** — connexion et inscription fonctionnent.
- [ ] **T0754** — accueil et pronostics fonctionnent.
- [ ] **T0755** — classement général, journée, soirée et live fonctionnent.
- [ ] **T0756** — Champions et phases finales fonctionnent.
- [ ] **T0757** — Teams et configurateur Team fonctionnent.
- [ ] **T0758** — profil et avatars officiels fonctionnent.
- [ ] **T0759** — upload/modération avatar fonctionne avec la base V0.5.3.
- [ ] **T0760** — administration fonctionne.
- [ ] **T0761** — Realtime fonctionne.
- [ ] **T0762** — version visible : `V0.5.4`.
### Release

- [ ] **T0763** — `node tests/release-v0.5.4.mjs` retourne `V0.5.4 release tests: OK`.
## 0.5.5

### Version / cache

- [ ] **T0764** — `VERSION` affiche `0.5.5`.
- [ ] **T0765** — l'interface affiche `V0.5.5`.
- [ ] **T0766** — le cache s'appelle `nid-champions-v0.5.5`.
- [ ] **T0767** — `node tests/release-v0.5.5.mjs` retourne `V0.5.5 release tests: OK`.
### Accueil

- [ ] **T0768** — mon avatar/logo apparaît en grand dès l'arrivée sur Accueil.
- [ ] **T0769** — si je suis dans une Team, son habillage entoure bien mon avatar.
- [ ] **T0770** — le hero reste lisible sur desktop, tablette et mobile.
### Gestion Team — membre

- [ ] **T0771** — l'onglet `⚙ Gestion` est visible.
- [ ] **T0772** — un membre non capitaine voit `Quitter la Team`.
- [ ] **T0773** — une confirmation est demandée avant de quitter.
- [ ] **T0774** — après départ, la Team n'est plus affichée comme ma Team.
### Gestion Team — capitaine

- [ ] **T0775** — le capitaine voit le code d'invitation et sa régénération.
- [ ] **T0776** — le capitaine peut accepter/refuser les demandes.
- [ ] **T0777** — le capitaine peut donner le capitanat à un membre actif.
- [ ] **T0778** — le capitaine peut exclure un membre.
- [ ] **T0779** — `Transférer puis quitter` permet de choisir un nouveau capitaine puis de partir.
- [ ] **T0780** — si le capitaine est seul, l'interface indique qu'il doit dissoudre la Team.
- [ ] **T0781** — la dissolution fonctionne toujours.
### Personnalisation Team

- [ ] **T0782** — le mode 1 couleur reste disponible.
- [ ] **T0783** — le mode 2 couleurs affiche les dégradés existants.
- [ ] **T0784** — les motifs `Moitié verticale`, `Moitié horizontale`, `Moitié diagonale` fonctionnent.
- [ ] **T0785** — les bandes verticales/horizontales/diagonales fonctionnent.
- [ ] **T0786** — le motif `Quartiers` fonctionne.
- [ ] **T0787** — le motif choisi est conservé après sauvegarde et rechargement.
- [ ] **T0788** — la prévisualisation montre mon vrai avatar, pas mon initiale.
- [ ] **T0789** — le cadre autour de l'avatar est légèrement plus fin qu'en V0.5.4.
### Régression

- [ ] **T0790** — pronostics phase de ligue OK.
- [ ] **T0791** — classements OK.
- [ ] **T0792** — live OK.
- [ ] **T0793** — champions / phases finales OK.
- [ ] **T0794** — profil / avatars V0.5.3 OK.
- [ ] **T0795** — Admin Teams OK.
## 0.5.5a

### Version / cache

- [ ] **T0796** — `VERSION` affiche `0.5.5a`.
- [ ] **T0797** — l’interface affiche `V0.5.5a`.
- [ ] **T0798** — le cache s’appelle `nid-champions-v0.5.5a`.
- [ ] **T0799** — `node tests/release-v0.5.5a.mjs` retourne `V0.5.5a release tests: OK`.
### Prévisualisation apparence Team

- [ ] **T0800** — sélectionner deux couleurs très contrastées, par exemple rouge/blanc ;
- [ ] **T0801** — sélectionner Bandes diagonales ;
- [ ] **T0802** — le fond de la mini-carte suggère bien les bandes mais ne les reproduit plus plein contraste ;
- [ ] **T0803** — le nom de la Team reste parfaitement lisible ;
- [ ] **T0804** — `12 membres` reste parfaitement lisible ;
- [ ] **T0805** — tester aussi Quartiers et Moitié diagonale.
### Capitaine seul : quitter sans dissoudre

- [ ] **T0806** — créer/rejoindre une Team dont je suis le seul membre et capitaine ;
- [ ] **T0807** — `Quitter la Team` est disponible ;
- [ ] **T0808** — après départ, la Team n’est plus ma Team ;
- [ ] **T0809** — elle reste visible dans l’annuaire ;
- [ ] **T0810** — elle est indiquée comme vacante / capitaine à reprendre ;
- [ ] **T0811** — `Reprendre la Team` me fait redevenir membre et capitaine.
### Team dissoute

- [ ] **T0812** — dissoudre explicitement une Team ;
- [ ] **T0813** — elle disparaît de l’annuaire actif ;
- [ ] **T0814** — le dernier capitaine la voit dans `Anciennes Teams` ;
- [ ] **T0815** — `Réactiver` restaure la Team et le capitanat ;
- [ ] **T0816** — tester aussi une Team qui avait déjà été dissoute sous V0.5.5.
### Capitaine avec plusieurs membres

- [ ] **T0817** — le capitaine ne peut toujours pas partir sans transmettre le capitanat ;
- [ ] **T0818** — `Transférer puis quitter` fonctionne ;
- [ ] **T0819** — le nouveau capitaine est correct après rechargement.
### Super Admin / modération

- [ ] **T0820** — un Admin simple ne voit pas `Supprimer définitivement` ;
- [ ] **T0821** — le Super Admin voit `Supprimer définitivement` dans Admin > Teams > Voir ;
- [ ] **T0822** — la confirmation demande de saisir `SUPPRIMER` ;
- [ ] **T0823** — annuler la saisie ne supprime rien ;
- [ ] **T0824** — après confirmation, la Team disparaît réellement de l’Admin et de l’annuaire ;
- [ ] **T0825** — ses memberships/demandes/invitations/événements ont disparu ;
- [ ] **T0826** — `audit_logs` contient l’action `team_hard_delete` ;
- [ ] **T0827** — si la Team utilisait un logo uploadé courant, vérifier sa suppression dans `team-logos`.
### Régression

- [ ] **T0828** — personnalisation Team V0.5.5 OK ;
- [ ] **T0829** — avatars joueurs OK ;
- [ ] **T0830** — classements Teams OK ;
- [ ] **T0831** — pronostics / LIVE / phases finales OK ;
- [ ] **T0832** — Admin Teams reste utilisable sur Team active, vacante et dissoute.
## 0.6.0

### Release

- [ ] **T0833** — `VERSION` = `0.6.0`.
- [ ] **T0834** — `config.js` conserve les vraies clés publiques Supabase.
- [ ] **T0835** — cache Service Worker = `nid-champions-v0.6.0`.
- [ ] **T0836** — `node tests/release-v0.6.0.mjs` retourne `V0.6.0 release tests: OK`.
- [ ] **T0837** — aucun dossier du projet ne dépasse 100 fichiers pour l'upload GitHub par dossier.
### Migration

- [ ] **T0838** — sauvegarde Supabase réalisée.
- [ ] **T0839** — `sql/HOTFIX_V0.6.0_EXISTING_DB.sql` exécuté avec le rôle postgres.
- [ ] **T0840** — `app_settings.app_version` = `0.6.0`.
- [ ] **T0841** — bucket privé `support-captures` présent.
### Notifications internes

- [ ] **T0842** — cloche visible desktop et mobile.
- [ ] **T0843** — badge = nombre de notifications non lues autorisées par les préférences.
- [ ] **T0844** — ouvrir la cloche ne marque pas tout comme lu.
- [ ] **T0845** — filtres Toutes / Matchs / Rival / Team / Hibou / Système fonctionnels.
- [ ] **T0846** — Lu / Non lu / Supprimer fonctionnent.
- [ ] **T0847** — Tout marquer comme lu fonctionne.
- [ ] **T0848** — liens profonds ouvrent le bon écran.
### Préférences

- [ ] **T0849** — Sage / Piquant / Sans pitié / Automatique, Automatique par défaut.
- [ ] **T0850** — catégories Matchs, Champion, Résultats, Rivalités, Teams, Hibou, Réponses du Hibou, Classement.
- [ ] **T0851** — rappels par défaut : 3 h + 30 min.
- [ ] **T0852** — 24 h et 1 h désactivés par défaut.
- [ ] **T0853** — quiet hours par défaut : 23:00 -> 08:00.
- [ ] **T0854** — fuseau local de l'appareil enregistré.
- [ ] **T0855** — urgence prono peut contourner les quiet hours.
### Opt-in Push

- [ ] **T0856** — aucune permission navigateur demandée automatiquement à la connexion.
- [ ] **T0857** — carte « Ne rate plus tes pronostics » proposée sur l'accueil.
- [ ] **T0858** — la permission navigateur apparaît seulement après clic.
- [ ] **T0859** — refus du Push ne bloque jamais les notifications internes.
- [ ] **T0860** — plusieurs appareils peuvent être actifs sur le même compte.
- [ ] **T0861** — un appareil peut être désactivé individuellement.
### Rappels

- [ ] **T0862** — plusieurs pronostics manquants produisent UNE notification groupée.
- [ ] **T0863** — notification indique le nombre manquant.
- [ ] **T0864** — clic ouvre la journée concernée.
- [ ] **T0865** — aucun rappel si tout est pronostiqué.
- [ ] **T0866** — champion absent produit un rappel uniquement pendant sa fenêtre de choix.
### Rival

- [ ] **T0867** — n'importe quel joueur actif peut être choisi, y compris dans la même Team.
- [ ] **T0868** — impossible de se choisir soi-même.
- [ ] **T0869** — le rival reçoit une notification.
- [ ] **T0870** — un seul changement par journée UEFA.
- [ ] **T0871** — changement impossible après le premier coup d'envoi.
- [ ] **T0872** — rivalité mutuelle détectée.
- [ ] **T0873** — avant la journée, notification de reprise du duel.
- [ ] **T0874** — un duel est figé par journée UEFA.
- [ ] **T0875** — égalité = nul, sans départage.
- [ ] **T0876** — fin de journée -> notification victoire / nul / défaite.
- [ ] **T0877** — niveau de pique respecte le réglage du Hibou.
- [ ] **T0878** — anciens rivaux et duels restent consultables.
- [ ] **T0879** — fiche détaillée affiche bilan, marges, série et trajectoire.
- [ ] **T0880** — rival marqué dans le classement ; comparaison rapide accessible.
### Hibou

- [ ] **T0881** — message global visible.
- [ ] **T0882** — message ciblé Team visible seulement par ses membres actifs.
- [ ] **T0883** — message ciblé joueur visible seulement par le joueur.
- [ ] **T0884** — Super Admin peut envoyer un message depuis le centre Admin.
- [ ] **T0885** — Super Admin peut envoyer depuis le profil rapide d'un joueur.
- [ ] **T0886** — message critique système apparaît dans le centre interne.
### Tickets

- [ ] **T0887** — Bug / Suggestion / Question / Modification / Autre.
- [ ] **T0888** — vraie conversation joueur <-> Hibou.
- [ ] **T0889** — maximum 3 captures.
- [ ] **T0890** — PNG/JPG/WebP uniquement ; 5 Mo maximum par fichier.
- [ ] **T0891** — ticket Bug contient version, navigateur/appareil, résolution, vue, date/fuseau et erreurs JS récentes.
- [ ] **T0892** — joueur peut marquer son ticket résolu.
- [ ] **T0893** — joueur ne choisit pas la priorité.
- [ ] **T0894** — Super Admin choisit priorité et statut.
- [ ] **T0895** — Admin classique ne voit pas les tickets.
- [ ] **T0896** — réponse du Hibou produit une notification essentielle.
### Teams / classement

- [ ] **T0897** — demande d'adhésion prévient le capitaine et ouvre Gestion.
- [ ] **T0898** — acceptation/refus, nouveau membre, capitanat, exclusion, dissolution produisent les notifications prévues.
- [ ] **T0899** — changement d'apparence reste interne, sans Push.
- [ ] **T0900** — prise/perte #1 et entrée/sortie podium peuvent produire un Push.
- [ ] **T0901** — dépassement du rival peut produire un Push.
- [ ] **T0902** — petit changement de rang reste interne.
### Push réel

- [ ] **T0903** — VAPID configuré uniquement dans Supabase Secrets.
- [ ] **T0904** — `push-dispatch` déployée.
- [ ] **T0905** — Cron appelle la fonction toutes les 15 minutes.
- [ ] **T0906** — quiet hours respectées.
- [ ] **T0907** — abonnement 404/410 est désactivé.
- [ ] **T0908** — ancien abonnement désactivé peut être nettoyé après 30 jours.
- [ ] **T0909** — clic Push refocalise une PWA ouverte ou ouvre le site à la bonne destination.
### Super Admin — Test Push

- [ ] **T0910** — destinataire = Moi ou un joueur précis, jamais « tout le monde ».
- [ ] **T0911** — test rapide fonctionne.
- [ ] **T0912** — test personnalisé titre/message/destination fonctionne.
- [ ] **T0913** — journal affiche destinataire, appareil, date, statut et erreur éventuelle.
- [ ] **T0914** — message système critique demande confirmation avant envoi.
## 0.6.0a

### Navigation

- [ ] **T0915** — Admin s'ouvre sur **Vue d'ensemble** au premier accès.
- [ ] **T0916** — Les 7 rubriques sont visibles sur desktop.
- [ ] **T0917** — Une seule rubrique est affichée à la fois.
- [ ] **T0918** — La rubrique active est mémorisée après changement de page puis retour dans Admin.
- [ ] **T0919** — Sur mobile, la navigation Admin devient horizontale et reste utilisable sans chevauchement.
### Vue d'ensemble

- [ ] **T0920** — Les compteurs Matchs / Joueurs / Teams sont cohérents.
- [ ] **T0921** — Le compteur Tickets apparaît pour le Super Admin.
- [ ] **T0922** — Les cartes raccourcis ouvrent la bonne rubrique.
### Matchs & LIVE

- [ ] **T0923** — Création de journée inchangée.
- [ ] **T0924** — Création de match inchangée.
- [ ] **T0925** — Onglets de journées présents.
- [ ] **T0926** — LIVE / score / résultat final fonctionnent comme en V0.6.0.
### Compétition

- [ ] **T0927** — Synchronisation clubs C1 / Top 5 / calendrier / cotes accessible.
- [ ] **T0928** — Bibliothèque de clubs visible.
- [ ] **T0929** — Multiplicateurs et création de confrontation accessibles.
- [ ] **T0930** — Gestion des phases finales inchangée.
### Joueurs & Teams

- [ ] **T0931** — Recherche joueur fonctionnelle.
- [ ] **T0932** — « Voir le profil » ouvre le profil rapide.
- [ ] **T0933** — Demandes d'inscription visibles uniquement au Super Admin.
- [ ] **T0934** — Modération des avatars accessible.
- [ ] **T0935** — Recherche Team et fiche Team fonctionnelles.
### Communication

- [ ] **T0936** — Hibou, tickets et notifications/push sont regroupés dans la rubrique Communication.
- [ ] **T0937** — Les droits Super Admin restent inchangés.
- [ ] **T0938** — Test Push reste accessible après configuration V0.6.0.
### Application

- [ ] **T0939** — Version, saison, backend et rôle sont affichés.
- [ ] **T0940** — « Recharger les données » fonctionne.
- [ ] **T0941** — « Nettoyer le cache PWA » demande confirmation puis recharge l'application.
### Régression

- [ ] **T0942** — Aucun SQL V0.6.0a n'est nécessaire.
- [ ] **T0943** — Teams V0.5.5a toujours fonctionnelles.
- [ ] **T0944** — Notifications / rivalités / tickets V0.6.0 inchangés.
## 0.6.2

### Réactions joueurs

- [ ] **T0945** — Depuis le classement, ouvrir le sélecteur 😊 d’un autre joueur.
- [ ] **T0946** — Envoyer chacun des 8 emojis.
- [ ] **T0947** — Vérifier qu’on ne peut pas réagir à soi-même.
- [ ] **T0948** — Vérifier la notification « Réactions » chez le destinataire.
- [ ] **T0949** — Cliquer la notification et vérifier l’ouverture du profil expéditeur.
- [ ] **T0950** — Vérifier le bouton réaction dans Membres de Team.
- [ ] **T0951** — Vérifier le bouton réaction dans les pronostics révélés.
- [ ] **T0952** — Vérifier le bouton réaction dans le profil public.
- [ ] **T0953** — Vérifier l’anti-spam en envoyant deux réactions immédiatement.
### Teams

- [ ] **T0954** — Tester une Team rouge/blanc avec bandes diagonales sur mobile.
- [ ] **T0955** — Vérifier que le blason conserve le motif fort.
- [ ] **T0956** — Vérifier que la grande carte Team n’utilise plus le motif à pleine puissance.
- [ ] **T0957** — Vérifier la lisibilité du nom, slogan, capitaine, membres et visibilité.
- [ ] **T0958** — Vérifier le mini-aperçu du configurateur.
### Avatar unifié

- [ ] **T0959** — Accueil : vrai avatar + cadre Team.
- [ ] **T0960** — Sidebar desktop : même avatar + cadre Team.
- [ ] **T0961** — Classement ligne joueur : même avatar + cadre Team.
- [ ] **T0962** — Bandeau sticky mobile : avatar visible, pas seulement le motif Team.
- [ ] **T0963** — Bandeau sticky : nom de Team affiché sous le pseudo.
- [ ] **T0964** — Teams / Rival / Live / Pronos révélés : même avatar.
### Régression

- [ ] **T0965** — Pronostics inchangés.
- [ ] **T0966** — Classements inchangés.
- [ ] **T0967** — Gestion Team quitter/reprendre/dissoudre inchangée.
- [ ] **T0968** — Centre notifications V0.6.0 fonctionnel.
- [ ] **T0969** — Admin modulaire V0.6.0a fonctionnel.
## 0.6.3

### Avatar unique

- [ ] **T0970** — Accueil : avatar correct.
- [ ] **T0971** — Sidebar : exactement le même avatar.
- [ ] **T0972** — Classement : exactement le même avatar.
- [ ] **T0973** — Profil / Team / Live / pronostics révélés : même source.
- [ ] **T0974** — PNG officiel détouré, sans fond bleu ajouté.
- [ ] **T0975** — Aucun recadrage qui coupe le hibou.
### Habillage Team

- [ ] **T0976** — Cadre Team clairement visible autour du joueur.
- [ ] **T0977** — Mini-marque Team lisible sans masquer l'avatar.
- [ ] **T0978** — Proportions cohérentes sur desktop et mobile.
### Couleurs Team

- [ ] **T0979** — Bandeau principal dominé par les couleurs de la Team, pas par le bleu du Nid.
- [ ] **T0980** — Motif visible en ambiance mais texte lisible.
- [ ] **T0981** — Annuaire Teams teinté.
- [ ] **T0982** — Classement Teams teinté.
- [ ] **T0983** — Aperçu du configurateur fidèle au rendu réel.
### Régression

- [ ] **T0984** — Navigation mobile.
- [ ] **T0985** — Classements.
- [ ] **T0986** — Réactions emoji V0.6.2.
- [ ] **T0987** — Gestion Team / quitter / reprendre / dissoudre.
- [ ] **T0988** — Admin V0.6.0a.
## 0.6.4

### Général

- [ ] **T0989** — `VERSION` affiche `0.6.4`.
- [ ] **T0990** — `app_settings.app_version` vaut `0.6.4` après le HOTFIX.
- [ ] **T0991** — `push-dispatch` V0.6.4 est redéployée.
- [ ] **T0992** — Le job `nid-champions-push-v060` affiche `* * * * *`.
- [ ] **T0993** — Un compte joueur non Super Admin peut activer le Push sans erreur RLS.
- [ ] **T0994** — Le même navigateur peut être réaffecté au compte connecté sans ouvrir les droits RLS aux autres appareils.
- [ ] **T0995** — Le Test Push envoie exactement le titre personnalisé.
- [ ] **T0996** — Le Test Push envoie exactement le corps personnalisé.
- [ ] **T0997** — Un message Hibou avec Push arrive immédiatement.
- [ ] **T0998** — Un message Hibou sans Push reste uniquement dans le Nid.
- [ ] **T0999** — Un message système critique avec Push arrive immédiatement.
- [ ] **T1000** — Une réaction / notification Team / rivalité demandant un Push passe par le déclencheur immédiat.
- [ ] **T1001** — Le Test Cron peut être programmé à une heure future.
- [ ] **T1002** — Le Test Cron n'est pas envoyé immédiatement au moment de la programmation.
- [ ] **T1003** — Le Test Cron est reçu à l'heure choisie, avec une tolérance d'environ 1 minute.
- [ ] **T1004** — Le journal Push distingue `immediate`, `test`, `cron-test` et les livraisons ordinaires.
- [ ] **T1005** — Un abonnement 404/410 est toujours désactivé automatiquement.
- [ ] **T1006** — Le cache PWA est `nid-champions-v0.6.4`.
## 0.6.7

### Général

- [ ] **T1007** — L'onglet Admin > Test n'est visible qu'au Super Admin.
- [ ] **T1008** — Deux journées TEST sont affichées dans le générateur.
- [ ] **T1009** — Un match permet de choisir domicile, extérieur, stade, pays, date et heure.
- [ ] **T1010** — Le stade et le pays suivent automatiquement l'équipe domicile et restent modifiables.
- [ ] **T1011** — On peut ajouter et supprimer des matchs dans chaque journée.
- [ ] **T1012** — Les journées créées apparaissent aux joueurs avec le badge TEST.
- [ ] **T1013** — Un rappel 3 h / 30 min est généré par le Cron selon les préférences.
- [ ] **T1014** — Désactiver les matchs TEST les retire des pronostics et arrête les rappels.
- [ ] **T1015** — Réactiver les matchs TEST les remet en scheduled.
- [ ] **T1016** — Les matchs TEST ne modifient ni classement général ni classement Teams.
- [ ] **T1017** — Les matchs TEST ne ferment pas le choix Champion n°1.
- [ ] **T1018** — Supprimer les matchs TEST ne touche pas aux matchs réels.
- [ ] **T1019** — Vider tous les matchs exige le mot VIDER.
- [ ] **T1020** — Vider tous les matchs supprime aussi les anciens 4 matchs TEST initiaux.
## 0.6.8

### Général

- [ ] **T1021** — Plus aucun logo/pictogramme dans les blasons Team.
- [ ] **T1022** — Le blason Team repose uniquement sur les couleurs et motifs.
- [ ] **T1023** — L'avatar du joueur est légèrement réduit dans le blason.
- [ ] **T1024** — L'avatar d'accueil mobile est légèrement réduit.
- [ ] **T1025** — Une Team existante peut être mise à jour sans SQL supplémentaire.
## 0.7.0

### 1. Version / cache

- [ ] **T1026** — `VERSION`, `config.js`, interface et Service Worker affichent `0.7.0`.
- [ ] **T1027** — Après Ctrl+F5 / relance PWA, aucun ancien asset V0.6.x ne reste affiché.
### 2. Blasons Team / avatars

- [ ] **T1028** — Aucun logo Team ni mini-marque/pastille en bas à droite des avatars.
- [ ] **T1029** — Le blason conserve ses couleurs/motifs.
- [ ] **T1030** — Le Hibou est nettement plus petit au centre du blason.
- [ ] **T1031** — Sur accueil mobile, le Hibou laisse une marge visible autour de lui.
### 3. LIVE sans F5

- [ ] **T1032** — Deux sessions distinctes : Admin + Joueur.
- [ ] **T1033** — Passage `scheduled -> live` visible côté joueur sans rechargement.
- [ ] **T1034** — Modification `0-0 -> 1-0` visible côté joueur sans rechargement.
- [ ] **T1035** — Le ticker LIVE se met à jour.
- [ ] **T1036** — Les points provisoires se mettent à jour.
- [ ] **T1037** — Le classement LIVE officiel se met à jour pour un match officiel.
- [ ] **T1038** — Après une coupure/reprise réseau, le filet de sécurité resynchronise l'écran.
### 4. Classement TEST

- [ ] **T1039** — Un match TEST n'ajoute aucun point au classement officiel.
- [ ] **T1040** — L'onglet `🧪 TEST` apparaît lorsqu'un calendrier TEST actif existe.
- [ ] **T1041** — Le score LIVE TEST modifie le classement LIVE TEST.
- [ ] **T1042** — Les données TEST sont visuellement identifiées et séparées.
### 5. Musée

- [ ] **T1043** — Vue générale : badges, records, points Casserole, points Génie.
- [ ] **T1044** — Sous-vues Badges / Records / Casseroles / Génie fonctionnelles.
- [ ] **T1045** — Recherche et filtres Badges fonctionnent.
- [ ] **T1046** — Obtenus en premier puis progression proche du déblocage.
- [ ] **T1047** — Un secret inconnu reste `???` ou invisible selon sa configuration.
- [ ] **T1048** — Le Musée public d'un autre joueur masque les secrets que le visiteur ne connaît pas.
### 6. Badges

- [ ] **T1049** — Le catalogue contient 100 badges initiaux mais accepte des badges supplémentaires.
- [ ] **T1050** — Création Super Admin avec catégorie, rareté, scope, secret, image et conditions.
- [ ] **T1051** — Condition avancée `ET / OU` évaluable.
- [ ] **T1052** — Upload image PNG/JPG/WebP <= 5 Mo.
- [ ] **T1053** — Visuel générique si aucun visuel spécifique n'est fourni.
- [ ] **T1054** — Duplication, import/export JSON, désactivation et archivage.
- [ ] **T1055** — Attribution manuelle + révocation avec motif/audit.
- [ ] **T1056** — Recalcul en aperçu puis exécution.
- [ ] **T1057** — Plusieurs badges obtenus ensemble => une notification groupée.
- [ ] **T1058** — Animation basée sur la rareté la plus élevée du groupe.
- [ ] **T1059** — Animation Commun < Rare < Épique < Légendaire ; Secret spécifique.
### 7. Secrets

- [ ] **T1060** — La première découverte mondiale est enregistrée.
- [ ] **T1061** — Seule la première découverte mondiale peut déclencher l'annonce globale.
- [ ] **T1062** — L'annonce donne pseudo + Team éventuelle, jamais le nom/condition du secret.
- [ ] **T1063** — Le premier découvreur conserve sa mention historique.
- [ ] **T1064** — Le choix d'annoncer ou non les découvertes rétroactives est configurable.
### 8. Casseroles

- [ ] **T1065** — Calcul uniquement sur match `finished`.
- [ ] **T1066** — Seuils d'erreur par défaut : 3 / 4 / 6 / 8.
- [ ] **T1067** — Points par défaut : +1 / +3 / +5 / +10.
- [ ] **T1068** — Plusieurs labels possibles mais seule la gravité la plus forte donne les points.
- [ ] **T1069** — Joueur unique à se tromper => traitement automatique.
- [ ] **T1070** — Séries de zéros 3 / 5 / 8 par défaut.
- [ ] **T1071** — Journée complète à zéro => gravité configurable.
- [ ] **T1072** — Champion éliminé tôt => règle configurable par phase.
- [ ] **T1073** — Industrielle/Nucléaire peut être annoncée au Nid.
- [ ] **T1074** — Casserole manuelle avec texte, média, points, visibilité et Push.
### 9. Génie

- [ ] **T1075** — Aucun Génie avec moins de 5 pronostics verrouillés par défaut.
- [ ] **T1076** — Bon résultat rare sans exact peut déclencher un Génie.
- [ ] **T1077** — Barème 10-20%=1, 5-10%=3, 2-5%=5, <2%=7, unique=10.
- [ ] **T1078** — Exact rare ajoute +2 sans dépasser 10.
- [ ] **T1079** — Cote fiable peut renforcer le score, plafond 10.
- [ ] **T1080** — Exact courant n'est pas automatiquement un Génie.
- [ ] **T1081** — +7/+10 peut être annoncé au Nid.
- [ ] **T1082** — Classement Génie séparé.
### 10. Records

- [ ] **T1083** — Records personnels et Records du Nid sont distincts.
- [ ] **T1084** — Le premier détenteur conserve une égalité.
- [ ] **T1085** — Le joueur qui égale reçoit `Record égalé`.
- [ ] **T1086** — Lorsqu'un record est battu, le nouveau et l'ancien détenteur sont notifiés.
- [ ] **T1087** — Historique complet conservé ; interface = 5 derniers + Voir tout.
- [ ] **T1088** — Catégories de records modifiables par Super Admin.
### 11. Narration du Hibou

- [ ] **T1089** — Les familles principales possèdent environ 40 formulations chacune.
- [ ] **T1090** — Les phrases de 0 / 3 / 5 / 7 points changent et restent contextuelles.
- [ ] **T1091** — Résumé journée/soirée varie selon performance.
- [ ] **T1092** — Variation de classement peut être commentée.
- [ ] **T1093** — Rivalité victoire/défaite/nul varie.
- [ ] **T1094** — Badges, secrets, records, Casseroles, Génie, champions, Teams et rappels varient.
- [ ] **T1095** — Le moteur évite les formulations récemment utilisées côté joueur.
- [ ] **T1096** — Les boutons/libellés fonctionnels restent fixes.
### 12. Laboratoire Gamification

- [ ] **T1097** — Activation/désactivation TEST.
- [ ] **T1098** — Génération de faux pronostics par pourcentages.
- [ ] **T1099** — Simulation immédiate du score final.
- [ ] **T1100** — Test d'une condition de badge sur un joueur.
- [ ] **T1101** — Notification TEST ciblée Super Admin ou joueur choisi, jamais de blast global réel.
- [ ] **T1102** — Nettoyage supprime badges/événements/records TEST mais garde l'audit.
### 13. Notifications / Push

- [ ] **T1103** — Préférences Badges, Records et Gamification présentes.
- [ ] **T1104** — Deep links vers le Musée.
- [ ] **T1105** — Push immédiat fonctionne après redéploiement de `push-dispatch`.
- [ ] **T1106** — Aucun besoin de régénérer les clés VAPID.
### 14. Clôture saison

- [ ] **T1107** — Prévisualisation avant clôture.
- [ ] **T1108** — Poêle d'Or départagée : points > nucléaires > industrielles > belles ; égalité restante = co-gagnants.
- [ ] **T1109** — Génie de saison et records définitifs visibles dans l'aperçu.
- [ ] **T1110** — Clôture manuelle gèle la gamification.
- [ ] **T1111** — Réouverture exige un motif et produit un audit.
## 0.7.1

### Blasons Team

- [ ] **T1112** — aucun carré/plaque interne dans le grand blason ;
- [ ] **T1113** — aucun mini-rappel Team en bas à droite ;
- [ ] **T1114** — rendu propre sur accueil mobile, classement, profil et page Team.
### LIVE joueur

- [ ] **T1115** — le statut LIVE apparaît sans F5 ;
- [ ] **T1116** — chaque changement de score apparaît sans F5 ;
- [ ] **T1117** — retour d'onglet / retour réseau déclenche une resynchronisation ;
- [ ] **T1118** — le filet de sécurité corrige un événement Realtime manqué en moins de 4 secondes.
### Classement LIVE TEST

- [ ] **T1119** — onglet TEST visible lorsqu'un calendrier TEST actif existe ;
- [ ] **T1120** — bascule automatique vers TEST si seuls des matchs TEST sont LIVE ;
- [ ] **T1121** — points provisoires recalculés avec le score LIVE ;
- [ ] **T1122** — bouton « Voir le classement LIVE TEST » opérationnel ;
- [ ] **T1123** — classement officiel inchangé.
## 0.7.2

### Général

- [ ] **T1124** — Le bouton « Vider tous les matchs » renvoie `ties_deleted` et vide la phase finale.
- [ ] **T1125** — L'écran Phase finale n'affiche plus les anciennes confrontations après rechargement.
- [ ] **T1126** — `sync-football-data` interroge `season=2026` pour `ucl-2026-27`.
- [ ] **T1127** — Aucune fonction de décalage d'un an n'est utilisée.
- [ ] **T1128** — `odds_source_season` vaut `2026/27` et `odds_is_test_shifted=false`.
- [ ] **T1129** — Si le calendrier de ligue n'est pas complet, l'import refuse proprement sans charger 2025/26.
- [ ] **T1130** — Lorsque les 144 matchs sont disponibles, dates, clubs et journées sont ceux de 2026/27.
- [ ] **T1131** — Le front affiche « saison réelle 2026/27 ».
## 0.7.3

### Général

- [ ] **T1132** — Un compte `player` voit le bouton **Créer une Team**.
- [ ] **T1133** — La création réussit sans erreur « Type de logo invalide ».
- [ ] **T1134** — `profiles.role` reste `player` après la création.
- [ ] **T1135** — `teams.captain_user_id` correspond au créateur.
- [ ] **T1136** — Une adhésion active `join_type='creator'` existe.
- [ ] **T1137** — Le créateur dispose des commandes de capitaine.
- [ ] **T1138** — Il conserve les fonctions joueur : pronostics, profil, classement, notifications.
- [ ] **T1139** — Un Admin/Super Admin conserve son rôle global s'il crée une Team.
- [ ] **T1140** — Aucun logo/pictogramme Team n'est réintroduit visuellement.
## 0.8.0

### Installation

- [ ] **T1141** — Exécuter HOTFIX_V0.8.0_EXISTING_DB.sql sans erreur.
- [ ] **T1142** — Redéployer sync-football-data.
- [ ] **T1143** — Vérifier APP_VERSION = 0.8.0 et le cache PWA V0.8.0 avant passage en 0.8.1.
### Centre Ligue des champions

- [ ] **T1144** — L’onglet Ligue des champions apparaît sur desktop et mobile.
- [ ] **T1145** — Les onglets Vue d’ensemble / Classement / Calendrier & résultats / Phases finales / Clubs fonctionnent.
- [ ] **T1146** — Admin > Compétition > Centre C1 synchronise la saison 2026/27 quand Football-Data la publie.
- [ ] **T1147** — Une saison 2025/26 renvoyée par le fournisseur n’est jamais utilisée à la place de 2026/27.
- [ ] **T1148** — Si Football-Data renvoie 404 pour 2026/27, la base reste vide et aucun match 2025/26 n’est importé.
- [ ] **T1149** — Le classement affiche les zones 1–8 / 9–24 / 25–36.
- [ ] **T1150** — Cliquer sur un club ouvre sa fiche.
- [ ] **T1151** — La fiche club affiche classement, points, V-N-D, différence, forme, 5 derniers et 5 prochains matchs.
- [ ] **T1152** — Les résultats réels du Centre C1 n’altèrent pas directement le barème de pronostics.
### Soirées européennes

- [ ] **T1153** — L’onglet Soirées s’ouvre sur la soirée pertinente.
- [ ] **T1154** — Avant soirée : compteur de pronostics affiché.
- [ ] **T1155** — Pendant : classement provisoire et points de soirée visibles.
- [ ] **T1156** — Après : score, rang, exacts et narration du Hibou visibles.
- [ ] **T1157** — Le meilleur joueur est présenté comme Hibou de la nuit.
- [ ] **T1158** — Les statistiques collectives affichent joueurs, pronostics, exacts, moyenne de points, casseroles, Génies et choix solitaires.
- [ ] **T1159** — Le carrousel Moments du Nid affiche uniquement les événements réellement présents.
- [ ] **T1160** — La carte contextuelle de soirée apparaît sur l’accueil dans la fenêtre prévue (36 h avant / LIVE / 48 h après).
- [ ] **T1161** — Les soirées précédentes sont accessibles dans Archives.
### Hibou solitaire

- [ ] **T1162** — Choix unique correct = 10 points parallèles.
- [ ] **T1163** — Deux joueurs corrects = 7 points parallèles chacun.
- [ ] **T1164** — Groupe <= 5 % correct = 5 points parallèles.
- [ ] **T1165** — Un mauvais choix minoritaire ne rapporte rien.
- [ ] **T1166** — Les points Hibou solitaire ne changent jamais le classement officiel.
### Votes mensuels

- [ ] **T1167** — Super Admin peut ouvrir un vote Casserole ou Génie depuis Admin > Gamification.
- [ ] **T1168** — Au moins deux candidats sont requis.
- [ ] **T1169** — Un joueur ne possède qu’un vote par sondage mais peut le changer tant que le vote est ouvert.
- [ ] **T1170** — Le Super Admin peut fermer le vote.
### Mobile

- [ ] **T1171** — Barre de navigation inférieure défilable horizontalement.
- [ ] **T1172** — Centre C1 lisible à 360–430 px.
- [ ] **T1173** — Tableau de classement défile horizontalement sans casser la page.
- [ ] **T1174** — Fiche club et soirées restent utilisables sans zoom manuel.
## 0.8.1

### Correctif Football-Data

- [ ] **T1175** — Une réponse Football-Data 404 est interprétée comme season_not_available et non comme une fonction Supabase absente.
- [ ] **T1176** — Le message utilisateur indique que la saison 2026/27 n’est pas encore disponible chez Football-Data.
- [ ] **T1177** — Le 404 Football-Data ne réimporte jamais silencieusement 2025/26.
- [ ] **T1178** — Un vrai défaut de déploiement/connexion reste distinguable dans les logs et le message de secours.
- [ ] **T1179** — FOOTBALL_DATA_API_KEY reste uniquement dans les secrets Supabase.
### Système de test

- [ ] **T1180** — node tests/run-all-v0.8.1.mjs termine sans FAIL sur le dossier livré.
- [ ] **T1181** — Le Centre de tests web s’ouvre depuis tests/test-center-v0.8.1.html.
- [ ] **T1182** — Le Centre de tests récupère la session Supabase courante quand il est servi sur le même domaine que l’application.
- [ ] **T1183** — Le diagnostic SQL V0.8.1 est accessible uniquement au Super Admin.
- [ ] **T1184** — Le rapport de tests peut être exporté en JSON et CSV.
- [ ] **T1185** — Les états manuels OK / KO / N/A sont conservés localement et peuvent être réinitialisés.
## 0.9.0

### Installation / migration

- [ ] **T1186** — Le dossier livré annonce VERSION = 0.9.0.
- [ ] **T1187** — config.js annonce APP_VERSION = 0.9.0.
- [ ] **T1188** — Le Service Worker utilise un cache nid-champions-v0.9.0.
- [ ] **T1189** — index.html charge css/career.css et js/career.js.
- [ ] **T1190** — HOTFIX_V0.9.0_EXISTING_DB.sql s'exécute sans erreur sur une base V0.8.1.
- [ ] **T1191** — Le HOTFIX conserve les données V0.8.1 existantes (joueurs, pronostics, Teams, badges, notifications, Centre C1).
- [ ] **T1192** — La table player_rank_history est créée.
- [ ] **T1193** — Les tables player_distinctions, polls, poll_options, poll_votes et season_memory_events sont créées.
- [ ] **T1194** — Les RPC V0.9.0 sont présents après migration.
- [ ] **T1195** — admin_run_diagnostics_v090 retourne zéro FAIL structurel avec un compte Super Admin.
### Multi-saisons

- [ ] **T1196** — Admin > Application affiche le panneau de gestion multi-saisons.
- [ ] **T1197** — Le Super Admin peut créer une nouvelle saison en préparation.
- [ ] **T1198** — Le slug proposé automatiquement est propre et modifiable.
- [ ] **T1199** — Deux saisons ne peuvent pas partager le même slug.
- [ ] **T1200** — La création peut copier le barème et les phases depuis la saison courante.
- [ ] **T1201** — Sans copie, les phases LEAGUE, barrages, huitièmes, quarts, demies et finale sont créées.
- [ ] **T1202** — Une nouvelle saison ne devient pas active automatiquement.
- [ ] **T1203** — Le Super Admin peut activer une saison.
- [ ] **T1204** — L'activation désactive automatiquement l'ancienne saison active.
- [ ] **T1205** — Une saison activée prend le statut En cours.
- [ ] **T1206** — Le Super Admin peut passer une saison en Préparation, En cours, Terminée ou Archivée.
- [ ] **T1207** — Une saison terminée/archivée n'est plus marquée active.
- [ ] **T1208** — Au démarrage de l'application, la saison active est prioritaire.
- [ ] **T1209** — Le sélecteur Saison affiche toutes les saisons avec leur statut.
- [ ] **T1210** — Changer de saison recharge matchs, pronostics, phases, Teams, classement, champions et mémoire de la bonne saison.
- [ ] **T1211** — Les données d'une saison ne se mélangent jamais à celles d'une autre saison.
### Profil saison

- [ ] **T1212** — L'onglet Saison > Ma saison affiche le rang actuel.
- [ ] **T1213** — Le meilleur rang de la saison est affiché.
- [ ] **T1214** — Le pire rang est calculé dans l'historique.
- [ ] **T1215** — La plus grosse remontée est calculée.
- [ ] **T1216** — La plus grosse chute est calculée.
- [ ] **T1217** — Les jours passés en tête évoluent avec l'historique de rang.
- [ ] **T1218** — Les jours en tête d'une saison terminée restent figés et ne continuent pas jusqu'à aujourd'hui.
- [ ] **T1219** — Les points de saison correspondent au classement officiel.
- [ ] **T1220** — La moyenne de points par match est correcte.
- [ ] **T1221** — Le pourcentage de précision est correct.
- [ ] **T1222** — Le nombre de scores exacts est correct.
- [ ] **T1223** — Le nombre de qualifiés correctement pronostiqués est correct.
- [ ] **T1224** — Le nombre d'oublis correspond aux matchs officiels terminés sans pronostic.
- [ ] **T1225** — Les Casseroles et leurs points sont comptés.
- [ ] **T1226** — Les coups de Génie et leurs points sont comptés.
- [ ] **T1227** — Les réussites et points Hibou solitaire sont comptés sans modifier le classement officiel.
- [ ] **T1228** — Les badges et records sont comptés.
- [ ] **T1229** — La forme récente affiche les cinq derniers verdicts.
- [ ] **T1230** — La courbe de rang se construit après plusieurs snapshots.
- [ ] **T1231** — Les distinctions permanentes apparaissent sur le profil de saison.
### Carrière

- [ ] **T1232** — L'onglet Carrière affiche un classement distinct du classement de saison.
- [ ] **T1233** — Le classement carrière cumule toutes les saisons réellement jouées.
- [ ] **T1234** — Les points carrière sont la somme des points officiels de chaque saison.
- [ ] **T1235** — Le nombre de saisons jouées ignore les saisons sans match joué ni point.
- [ ] **T1236** — La moyenne carrière est calculée sur l'ensemble des pronostics joués.
- [ ] **T1237** — Les scores exacts carrière sont cumulés.
- [ ] **T1238** — Les podiums ne sont comptés que sur les saisons Terminée/Archivée.
- [ ] **T1239** — Les titres ne sont comptés que sur les saisons Terminée/Archivée.
- [ ] **T1240** — Le nombre de badges carrière est correct.
- [ ] **T1241** — Le nombre de records carrière est correct.
- [ ] **T1242** — Le profil personnel affiche rang carrière, saisons, points, moyenne, podiums et titres.
- [ ] **T1243** — Le profil personnel liste les saisons jouées et permet d'ouvrir une ancienne saison.
- [ ] **T1244** — Le profil rapide d'un autre joueur affiche ses statistiques de saison et de carrière.
- [ ] **T1245** — Les records historiques personnels conservent les meilleures valeurs entre saisons.
### Hall of Fame

- [ ] **T1246** — L'onglet Hall of Fame regroupe les résultats par saison.
- [ ] **T1247** — Le champion, vice-champion et troisième sont affichés.
- [ ] **T1248** — Le meilleur scoreur de chaque saison est affiché.
- [ ] **T1249** — Le joueur avec le plus de scores exacts est affiché.
- [ ] **T1250** — La Poêle d'Or est affichée lorsqu'il existe des Casseroles.
- [ ] **T1251** — Le Génie de la saison est affiché lorsqu'il existe des événements Génie.
- [ ] **T1252** — Le Hibou solitaire de la saison est affiché.
- [ ] **T1253** — La meilleure Team de la saison est affichée.
- [ ] **T1254** — Les records du Nid récents sont conservés dans le Hall of Fame.
- [ ] **T1255** — Une saison sans donnée n'invente aucun héros ni valeur.
### Replay de saison

- [ ] **T1256** — L'onglet Replay affiche une chronologie datée.
- [ ] **T1257** — Un changement réel de leader crée un événement Nouveau leader.
- [ ] **T1258** — Deux snapshots consécutifs avec le même leader ne créent pas de faux changement.
- [ ] **T1259** — Les records du Nid apparaissent dans le replay.
- [ ] **T1260** — Les Casseroles publiques apparaissent dans le replay.
- [ ] **T1261** — Les coups de Génie publics apparaissent dans le replay.
- [ ] **T1262** — Les badges légendaires apparaissent dans le replay.
- [ ] **T1263** — L'élimination d'un choix Champion apparaît dans le replay.
- [ ] **T1264** — La finale terminée crée un événement de clôture.
- [ ] **T1265** — Un Admin peut ajouter un événement éditorial de mémoire via le RPC prévu sans casser le replay.
### Champion en titre / distinctions

- [ ] **T1266** — Sur une nouvelle saison, le vainqueur de la saison précédente est identifié comme Champion en titre.
- [ ] **T1267** — Le Champion en titre provient uniquement d'une saison Terminée/Archivée.
- [ ] **T1268** — Admin > Joueurs permet d'attribuer une distinction permanente.
- [ ] **T1269** — La distinction Champion du Nid 2026 peut être conservée d'une saison à l'autre.
- [ ] **T1270** — Mettre à jour une distinction existante ne crée pas de doublon pour le même code et joueur.
### Sondages généraux

- [ ] **T1271** — L'onglet Saison > Sondages affiche les sondages généraux de la saison.
- [ ] **T1272** — Les votes mensuels Casserole/Génie V0.8 restent séparés des sondages généraux.
- [ ] **T1273** — Le Super Admin peut créer un sondage avec titre, question et au moins deux réponses.
- [ ] **T1274** — Le Super Admin peut définir une durée de sondage.
- [ ] **T1275** — Un joueur authentifié peut voter sur un sondage ouvert.
- [ ] **T1276** — Le joueur peut changer son vote lorsque allow_change est activé.
- [ ] **T1277** — Un sondage fermé refuse tout nouveau vote.
- [ ] **T1278** — Un choix appartenant à un autre sondage est refusé.
- [ ] **T1279** — Les résultats peuvent être masqués avant fermeture.
- [ ] **T1280** — Quand les résultats sont visibles, pourcentages et nombres de votes sont cohérents.
- [ ] **T1281** — Le Super Admin peut fermer manuellement un sondage.
### Archives / intégrité

- [ ] **T1282** — Une saison Terminée/Archivée affiche clairement « Archive en lecture seule ».
- [ ] **T1283** — Un joueur ne peut pas créer ou modifier un pronostic de match dans une archive.
- [ ] **T1284** — Le recalcul serveur des points reste possible sans modifier le score pronostiqué.
- [ ] **T1285** — Un joueur ne peut pas modifier son pronostic qualifié dans une archive.
- [ ] **T1286** — Un joueur ne peut pas modifier son choix Champion dans une archive.
- [ ] **T1287** — Consulter une archive ne crée plus de snapshot quotidien qui ferait dériver les jours en tête.
- [ ] **T1288** — Réactiver explicitement une saison archivée la repasse En cours et la rend active.
### Régression V0.1 → V0.8.1

- [ ] **T1289** — Inscription, validation e-mail et connexion restent fonctionnelles.
- [ ] **T1290** — Les rôles player/admin/super_admin restent inchangés.
- [ ] **T1291** — Les pronostics 0/3/5/7 et l'autosauvegarde restent fonctionnels.
- [ ] **T1292** — Le verrouillage au coup d'envoi reste fonctionnel.
- [ ] **T1293** — Les classements Général/Journée/Soirée/Précision/Exacts restent fonctionnels.
- [ ] **T1294** — Le LIVE et Realtime restent fonctionnels.
- [ ] **T1295** — Les cotes 1N2 restent visibles lorsqu'elles existent.
- [ ] **T1296** — Les phases finales et pronostics qualifiés restent fonctionnels.
- [ ] **T1297** — Les deux choix Champion restent fonctionnels sur la saison active.
- [ ] **T1298** — Les Teams, rôles de capitaine et classements Team restent fonctionnels.
- [ ] **T1299** — Les avatars, notifications, Web Push, Hibou masqué, support et rivalités restent fonctionnels.
- [ ] **T1300** — Le Musée, badges, Casseroles, Génie, records et narrations restent fonctionnels.
- [ ] **T1301** — Le Centre C1 reste séparé du moteur de pronostics.
- [ ] **T1302** — Le 404 Football-Data 2026/27 reste traité comme season_not_available sans fallback 2025/26.
- [ ] **T1303** — Les Soirées européennes et Hibou de la nuit restent fonctionnels.
- [ ] **T1304** — Le Hibou solitaire reste un classement parallèle.
- [ ] **T1305** — Les votes mensuels V0.8 restent fonctionnels.
- [ ] **T1306** — Le système TEST Admin n'altère pas les données officielles.
### Mobile / PWA / robustesse

- [ ] **T1307** — Le nouvel écran Saison reste lisible sur 360–430 px.
- [ ] **T1308** — Le sélecteur de saison reste utilisable sur mobile.
- [ ] **T1309** — Le classement carrière défile horizontalement sans casser la page.
- [ ] **T1310** — Le Hall of Fame passe correctement en une colonne sur petit écran.
- [ ] **T1311** — Le Replay reste lisible sur mobile.
- [ ] **T1312** — Les sondages sont utilisables au toucher.
- [ ] **T1313** — Le panneau multi-saisons Admin reste utilisable sur tablette/mobile.
- [ ] **T1314** — Après déploiement, un Ctrl+F5 charge bien le cache V0.9.0.
- [ ] **T1315** — La PWA installée récupère V0.9.0 après fermeture/réouverture.
- [ ] **T1316** — Le chargement de la mémoire ne bloque pas l'ouverture générale de l'application en cas d'erreur V0.9.
- [ ] **T1317** — Le changement de saison ne laisse pas d'anciennes données visuelles d'une autre saison.
- [ ] **T1318** — Une saison avec beaucoup d'historique reste navigable sans ralentissement anormal.
### Validation de sortie

- [ ] **T1319** — node tests/run-all-v0.9.0.mjs termine avec 0 FAIL sur le dossier livré.
- [ ] **T1320** — Le Centre de tests V0.9.5 s'ouvre et récupère la session Supabase.
- [ ] **T1321** — Le diagnostic automatique V0.9.0 fusionne les contrôles historiques V0.1–V0.8.1 et les contrôles V0.9.
- [ ] **T1322** — Les états manuels OK/KO/N/A sont conservés localement.
- [ ] **T1323** — L'export JSON du Centre de tests contient la version 0.9.0.
- [ ] **T1324** — L'export CSV du Centre de tests contient les nouveaux tests V0.9.0.
- [ ] **T1325** — Le test distant --url vérifie VERSION, config.js, sw.js, index.html et js/career.js déployés.
- [ ] **T1326** — Une sauvegarde base + fichiers a été réalisée avant migration de production.
### Palmarès historique

- [ ] **T1327** — Super Admin > Mémoire permet de choisir manuellement le vainqueur du Nid des Pronos — Coupe du monde 2026.
- [ ] **T1328** — Attribuer le titre à un nouveau joueur désactive automatiquement l’ancien détenteur : un seul vainqueur actif existe.
- [ ] **T1329** — La distinction Vainqueur du Nid des Pronos — Coupe du monde 2026 apparaît sur le profil et dans la carrière du joueur, même en changeant de saison.
- [ ] **T1330** — Le Super Admin peut retirer le titre sans supprimer l’historique de la distinction.
## 0.9.5

### Admin UX / recherche

- [ ] **T1331** — Le champ « Trouver une option… » est visible immédiatement en haut de l’Admin.
- [ ] **T1332** — Ctrl+K place le focus dans la recherche Admin lorsque l’écran Admin est ouvert.
- [ ] **T1333** — La touche / place le focus dans la recherche Admin hors champ de saisie.
- [ ] **T1334** — Rechercher « sauvegarde » propose directement la gestion des sauvegardes.
- [ ] **T1335** — Rechercher « C1 » propose les synchronisations Ligue des champions pertinentes.
- [ ] **T1336** — Rechercher « joueur » propose la recherche joueur et les actions associées.
- [ ] **T1337** — Appuyer sur Entrée ouvre le premier résultat de recherche et fait défiler jusqu’à l’option.
- [ ] **T1338** — Échap ferme la recherche Admin et rend la navigation normale.
- [ ] **T1339** — Cliquer hors de la palette referme les résultats sans changer d’écran.
- [ ] **T1340** — Une recherche sans résultat affiche une aide compréhensible plutôt qu’une zone vide.
### Admin navigation / hiérarchie

- [ ] **T1341** — La navigation Admin est regroupée en Pilotage, Communauté et Technique.
- [ ] **T1342** — Dashboard est l’entrée par défaut et expose les actions prioritaires.
- [ ] **T1343** — Joueurs & accès regroupe comptes, inscriptions, avatars, aperçu joueur et suppressions.
- [ ] **T1344** — Contenu & Musée regroupe gamification et sondages sans les disperser.
- [ ] **T1345** — Système & sécurité regroupe saisons, réglages, sauvegardes, exports et audit.
- [ ] **T1346** — Laboratoire/Test est placé à part des fonctions de production.
- [ ] **T1347** — Le libellé de chaque entrée reste compréhensible sans connaître le nom interne de la fonction.
- [ ] **T1348** — Changer de rubrique Admin ne provoque pas de rechargement complet de la PWA.
- [ ] **T1349** — Le retour vers Dashboard est accessible en un clic depuis toute rubrique Admin.
- [ ] **T1350** — La rubrique courante est visuellement identifiable sur desktop et mobile.
### Dashboard / centre d’action

- [ ] **T1351** — Le Dashboard affiche l’état réseau, maintenance, API et saison courante.
- [ ] **T1352** — Les inscriptions en attente remontent dans « À traiter » avec le bon compteur.
- [ ] **T1353** — Les avatars en attente remontent dans « À traiter » avec le bon compteur.
- [ ] **T1354** — Les tickets ouverts remontent dans « À traiter » avec le bon compteur.
- [ ] **T1355** — Les échecs Push des dernières 24 h remontent dans « À traiter ».
- [ ] **T1356** — Les demandes de suppression remontent dans « À traiter ».
- [ ] **T1357** — Cliquer un signal du centre d’action ouvre directement l’écran concerné.
- [ ] **T1358** — En l’absence d’alerte, le Dashboard affiche clairement que rien n’est urgent.
- [ ] **T1359** — Les actions rapides Score, C1, Joueur, Hibou, Sauvegarde et Réglages sont accessibles sans fouille de menus.
- [ ] **T1360** — Les compteurs du Dashboard se rafraîchissent après une opération Admin importante.
### Réglages / feature flags

- [ ] **T1361** — Le Super Admin peut ouvrir ou fermer les inscriptions depuis Système & sécurité.
- [ ] **T1362** — Un Admin non Super Admin peut voir les réglages mais ne peut pas les modifier.
- [ ] **T1363** — Désactiver Teams masque l’accès Teams côté joueur sans supprimer les données.
- [ ] **T1364** — Réactiver Teams réaffiche les données existantes sans perte.
- [ ] **T1365** — Désactiver Musée & gamification masque l’accès concerné sans supprimer badges/événements.
- [ ] **T1366** — Désactiver Sondages masque les sondages généraux sans supprimer les votes existants.
- [ ] **T1367** — Désactiver les synchronisations API désactive les boutons Football-Data/cotes avec une explication.
- [ ] **T1368** — Le flag Rivalités conserve les données existantes lors de sa désactivation/réactivation.
- [ ] **T1369** — Le flag Hibou solitaire conserve les données existantes lors de sa désactivation/réactivation.
- [ ] **T1370** — Chaque modification de réglage crée une trace dans audit_logs.
### Maintenance / inscriptions

- [ ] **T1371** — Activer Maintenance demande une confirmation explicite.
- [ ] **T1372** — Un joueur connecté voit l’écran de maintenance et ne peut plus modifier les données.
- [ ] **T1373** — Le Super Admin conserve l’accès pendant la maintenance.
- [ ] **T1374** — La désactivation Maintenance rend immédiatement l’application utilisable aux joueurs après actualisation/synchronisation.
- [ ] **T1375** — Un nouvel utilisateur ne peut pas lancer une inscription lorsque registration_open=false.
- [ ] **T1376** — Le message d’inscriptions fermées est clair et ne ressemble pas à une panne Supabase.
- [ ] **T1377** — Réouvrir les inscriptions rétablit le formulaire sans migration SQL supplémentaire.
- [ ] **T1378** — La maintenance ne déconnecte pas silencieusement un joueur sans explication.
- [ ] **T1379** — Le bouton Déconnexion de l’écran Maintenance fonctionne.
- [ ] **T1380** — Maintenance et fermeture des inscriptions sont deux réglages indépendants.
### Joueurs / pagination / aperçu

- [ ] **T1381** — La liste Admin des joueurs affiche au maximum 25 joueurs par page.
- [ ] **T1382** — Précédent/Suivant parcourent tous les joueurs sans doublon ni saut.
- [ ] **T1383** — Une nouvelle recherche joueur revient automatiquement à la première page.
- [ ] **T1384** — La recherche trouve un joueur au-delà de la première page.
- [ ] **T1385** — Les actions de rôle/statut continuent de fonctionner sur une page autre que la première.
- [ ] **T1386** — Le Super Admin peut ouvrir un aperçu lecture seule d’un joueur actif.
- [ ] **T1387** — L’aperçu affiche profil, pronostics, champions, Team et notifications non lues utiles au diagnostic.
- [ ] **T1388** — L’aperçu ne permet jamais d’enregistrer un pronostic ou une action au nom du joueur.
- [ ] **T1389** — L’ouverture de l’aperçu crée une trace impersonation_start dans l’audit.
- [ ] **T1390** — La fermeture de l’aperçu crée une trace impersonation_stop dans l’audit.
### Sauvegardes / restauration

- [ ] **T1391** — Le Super Admin peut créer une sauvegarde nommée de la saison active.
- [ ] **T1392** — La sauvegarde affiche date, nombre de matchs, pronostics et Teams.
- [ ] **T1393** — Le JSON d’une sauvegarde peut être téléchargé localement.
- [ ] **T1394** — Le snapshot inclut calendrier, matchs, pronostics, champions et phases finales.
- [ ] **T1395** — Le snapshot inclut Teams, membres, invitations et demandes d’adhésion.
- [ ] **T1396** — Le snapshot inclut gamification, paramètres de gamification et mémoire de saison.
- [ ] **T1397** — Le snapshot inclut sondages généraux et votes mensuels Casserole/Génie.
- [ ] **T1398** — Une restauration est refusée si le mode maintenance n’est pas activé.
- [ ] **T1399** — La restauration exige de taper exactement RESTAURER et remplace uniquement les données de la saison sauvegardée.
- [ ] **T1400** — Après restauration, les données chargées et les compteurs correspondent au snapshot et une trace backup_restore existe.
### Audit / traçabilité

- [ ] **T1401** — Le journal d’audit est paginé par blocs de 25 entrées.
- [ ] **T1402** — La recherche audit filtre par acteur, action, type ou identifiant d’entité.
- [ ] **T1403** — Le filtre Action permet de réduire le journal sans perdre les autres traces.
- [ ] **T1404** — Les détails Avant/Après sont consultables sans encombrer la liste principale.
- [ ] **T1405** — Une modification de réglage apparaît dans l’audit avec l’acteur.
- [ ] **T1406** — Créer puis supprimer une sauvegarde produit les traces attendues.
- [ ] **T1407** — Une attribution manuelle de distinction existante reste traçable.
- [ ] **T1408** — Une opération d’aperçu joueur est traçable.
- [ ] **T1409** — Le traitement d’une suppression de compte est traçable.
- [ ] **T1410** — Un joueur normal ne peut pas lire le journal Admin via l’interface ou la RPC.
### Exports

- [ ] **T1411** — L’export Annuaire joueurs génère un CSV lisible avec pseudo, rôle, statut et club.
- [ ] **T1412** — L’export Classement génère un CSV correspondant à la saison sélectionnée.
- [ ] **T1413** — L’export Audit génère les lignes actuellement chargées/filtrées sans erreur d’encodage.
- [ ] **T1414** — Les CSV utilisent un encodage compatible avec les accents français dans Excel/LibreOffice.
- [ ] **T1415** — Les valeurs contenant guillemets ou séparateurs sont correctement échappées.
- [ ] **T1416** — Le nom de fichier exporté ne contient pas de caractères invalides Windows.
- [ ] **T1417** — L’export Saison complète crée d’abord un snapshot serveur.
- [ ] **T1418** — L’export Saison complète est réservé au Super Admin.
- [ ] **T1419** — Le JSON exporté contient schema_version=0.9.5 et l’identifiant de saison.
- [ ] **T1420** — Les exports n’altèrent aucune donnée de production.
### Compte / confidentialité

- [ ] **T1421** — Un joueur connecté voit l’option de demande de suppression dans son profil.
- [ ] **T1422** — La demande demande une confirmation avant envoi.
- [ ] **T1423** — Un motif facultatif peut accompagner la demande.
- [ ] **T1424** — Deux demandes ouvertes simultanées pour le même joueur ne peuvent pas être créées.
- [ ] **T1425** — Le Super Admin voit les demandes requested/reviewing dans Joueurs & accès.
- [ ] **T1426** — Le Super Admin peut passer une demande à En cours.
- [ ] **T1427** — Le Super Admin peut refuser une demande avec une note administrative.
- [ ] **T1428** — Le traitement final anonymise le pseudo applicatif et le club de cœur.
- [ ] **T1429** — Le traitement final désactive les abonnements Push du joueur.
- [ ] **T1430** — L’interface rappelle explicitement que la suppression Auth Supabase reste une opération distincte si nécessaire.
### Sécurité / rôles / RLS

- [ ] **T1431** — admin_backups_v095 a la RLS activée.
- [ ] **T1432** — Seul le Super Admin peut créer, lire, restaurer ou supprimer les sauvegardes serveur.
- [ ] **T1433** — account_deletion_requests_v095 a la RLS activée.
- [ ] **T1434** — Un joueur ne peut consulter que ses propres demandes de suppression.
- [ ] **T1435** — admin_set_app_setting_v095 refuse un utilisateur non Super Admin.
- [ ] **T1436** — admin_restore_backup_v095 refuse un utilisateur non Super Admin.
- [ ] **T1437** — admin_player_preview_v095 refuse un joueur normal.
- [ ] **T1438** — admin_audit_v095 refuse un joueur normal.
- [ ] **T1439** — Une clé de réglage non autorisée est refusée par admin_set_app_setting_v095.
- [ ] **T1440** — Le rôle Team captain ne confère aucun privilège Admin applicatif.
### Réseau / erreurs

- [ ] **T1441** — Passer hors ligne affiche un bandeau réseau explicite.
- [ ] **T1442** — Le retour en ligne retire le bandeau et confirme le rétablissement.
- [ ] **T1443** — Une erreur réseau lors d’une action Admin produit un message lisible et non une erreur brute incompréhensible.
- [ ] **T1444** — Une erreur RPC dans le cockpit ne rend pas toute la page Admin blanche.
- [ ] **T1445** — Un échec de chargement des statistiques Admin laisse les autres rubriques utilisables.
- [ ] **T1446** — Le bouton API désactivé par Feature flag explique pourquoi il est indisponible.
- [ ] **T1447** — Une restauration échouée laisse la sauvegarde existante disponible.
- [ ] **T1448** — Un export local reste possible si les données nécessaires sont déjà chargées.
- [ ] **T1449** — Les erreurs 401/403 ne sont pas présentées comme des indisponibilités Football-Data.
- [ ] **T1450** — Le correctif season_not_available V0.8.1 reste intact après la V0.9.5.
### Accessibilité / clavier

- [ ] **T1451** — La recherche Admin possède un aria-label explicite.
- [ ] **T1452** — Le bandeau réseau utilise role=status et aria-live.
- [ ] **T1453** — Les boutons principaux restent atteignables au clavier.
- [ ] **T1454** — Le focus clavier reste visible sur les contrôles Admin.
- [ ] **T1455** — Ctrl+K et / n’interceptent pas la saisie lorsqu’un input/textarea/select est actif.
- [ ] **T1456** — Les interrupteurs de réglage sont utilisables au clavier.
- [ ] **T1457** — La palette de recherche peut être fermée avec Échap.
- [ ] **T1458** — Le mode prefers-reduced-motion réduit les animations de mise en évidence.
- [ ] **T1459** — Le mode forced-colors conserve des bordures/états perceptibles.
- [ ] **T1460** — Les libellés essentiels ne reposent pas uniquement sur une icône ou une couleur.
### Mobile / responsive

- [ ] **T1461** — L’Admin reste utilisable sur une largeur de 360 px sans débordement horizontal global.
- [ ] **T1462** — La recherche Admin reste visible et exploitable sur mobile.
- [ ] **T1463** — Les groupes de navigation Admin restent lisibles sur petit écran.
- [ ] **T1464** — Le centre d’action passe proprement en une colonne sur mobile.
- [ ] **T1465** — Les actions rapides sont suffisamment grandes pour le tactile.
- [ ] **T1466** — Les réglages/Feature flags ne se chevauchent pas sur mobile.
- [ ] **T1467** — La liste des sauvegardes garde ses actions accessibles sur petit écran.
- [ ] **T1468** — Le journal d’audit reste lisible et ses détails peuvent être ouverts au toucher.
- [ ] **T1469** — La pagination joueurs reste accessible sur téléphone.
- [ ] **T1470** — L’aperçu joueur reste lisible sans couper score, Team ou bouton de fermeture.
### Charge / multi-utilisateur

- [ ] **T1471** — La liste joueurs reste fluide avec au moins 100 profils grâce à la pagination.
- [ ] **T1472** — La recherche Admin ne déclenche pas de requête serveur à chaque frappe pour la palette d’options.
- [ ] **T1473** — Le journal d’audit ne charge pas plus de 100 lignes par appel RPC.
- [ ] **T1474** — Deux Admin consultant le Dashboard simultanément obtiennent des compteurs cohérents.
- [ ] **T1475** — Deux Super Admin modifiant le même réglage aboutissent à une dernière valeur cohérente et deux traces auditables.
- [ ] **T1476** — Une sauvegarde peut être créée pendant que des joueurs consultent l’application sans modifier leurs données.
- [ ] **T1477** — Une restauration n’est effectuée qu’en mode maintenance afin d’éviter les écritures concurrentes normales.
- [ ] **T1478** — Le Dashboard ne provoque pas de boucle de render/load ou de rafale continue de RPC.
- [ ] **T1479** — Le passage entre rubriques Admin reste réactif avec un audit volumineux.
- [ ] **T1480** — Le chargement de la V0.9.5 ne ralentit pas perceptiblement les écrans joueur hors Admin.
### Régression / sortie V0.9.5

- [ ] **T1481** — Toutes les fonctions V0.1.x → V0.9.0 restent présentes après installation de V0.9.5.
- [ ] **T1482** — La gestion multi-saisons V0.9.0 reste opérationnelle depuis le nouvel Admin.
- [ ] **T1483** — Le vainqueur manuel Coupe du monde 2026 reste attribuable et visible.
- [ ] **T1484** — Centre C1, Soirées, Hibou solitaire et votes mensuels V0.8 restent fonctionnels.
- [ ] **T1485** — Pronostics, points 0/3/5/7, LIVE, classements et phases finales restent inchangés.
- [ ] **T1486** — Teams, avatars, Push, rivalités, Musée et support restent accessibles lorsque leurs Feature flags sont actifs.
- [ ] **T1487** — node tests/run-all-v0.9.5.mjs termine avec 0 FAIL sur le dossier livré.
- [ ] **T1488** — Le test distant --url valide VERSION, config.js, sw.js, index.html, admin095.js et admin095.css déployés.
- [ ] **T1489** — Le Centre de tests V0.9.5 contient exactement 1490 contrôles uniques jusqu’à T1490.
- [ ] **T1490** — Une sauvegarde de production a été réalisée avant passage aux versions V0.9.8/V0.9.9.
## 0.9.8

### PDF / impression A4

- [ ] **T1491** — La page finale.html s’ouvre depuis Saison sans erreur JavaScript.
- [ ] **T1492** — La page diplome.html s’ouvre depuis Saison sans erreur JavaScript.
- [ ] **T1493** — Le bouton Imprimer / PDF ouvre la boîte d’impression du navigateur.
- [ ] **T1494** — Le format d’impression du collector est A4 portrait.
- [ ] **T1495** — Le diplôme est A4 paysage.
- [ ] **T1496** — Les pages imprimées n’affichent pas la barre d’outils web.
- [ ] **T1497** — Les fonds, bordures et contrastes restent lisibles à l’impression.
- [ ] **T1498** — Aucun contenu important n’est coupé horizontalement en A4.
- [ ] **T1499** — Les tableaux longs passent proprement sur les pages suivantes.
- [ ] **T1500** — Les titres de page ne se retrouvent pas seuls en bas de page.
- [ ] **T1501** — Les avatars restent nets et proportionnés dans les documents.
- [ ] **T1502** — Le Hibou / branding est présent sans masquer le contenu.
- [ ] **T1503** — Les accents français sont correctement rendus dans le PDF.
- [ ] **T1504** — Les symboles 🏆 / 🦉 / médailles restent compréhensibles dans le PDF.
- [ ] **T1505** — Le PDF généré depuis Chrome est lisible à 100 % de zoom.
- [ ] **T1506** — Le PDF généré depuis Edge est lisible à 100 % de zoom.
- [ ] **T1507** — Le collector reste utilisable sur écran mobile avant impression.
- [ ] **T1508** — Le diplôme reste utilisable sur écran mobile avant impression.
- [ ] **T1509** — Le bouton Retour ramène vers Le Nid sans perdre la session.
- [ ] **T1510** — Le bouton Actualiser recharge les données du document.
- [ ] **T1511** — Le paramètre de saison dans l’URL ouvre la bonne saison.
- [ ] **T1512** — Une saison inexistante affiche une erreur claire et non une page blanche.
- [ ] **T1513** — Un utilisateur non connecté est invité à revenir dans l’application / se connecter.
- [ ] **T1514** — Aucune adresse e-mail ou donnée privée n’apparaît dans les documents.
- [ ] **T1515** — La mention de version affichée sur les documents est V0.9.8.
### Collector saison

- [ ] **T1516** — Le Collector saison affiche le nom de la saison et sa période/contexte.
- [ ] **T1517** — La couverture du Collector affiche le nombre de joueurs.
- [ ] **T1518** — La couverture affiche le nombre de matchs officiels.
- [ ] **T1519** — La couverture affiche le nombre de pronostics.
- [ ] **T1520** — La couverture affiche le nombre de scores exacts.
- [ ] **T1521** — Le podium affiche correctement #1, #2 et #3.
- [ ] **T1522** — Le podium reste cohérent avec le classement Général de l’application.
- [ ] **T1523** — Le tableau du classement affiche rang, joueur, points, exacts, précision, moyenne et joués.
- [ ] **T1524** — Un classement de plus de 15 joueurs crée les pages complémentaires attendues.
- [ ] **T1525** — Tous les joueurs du classement apparaissent une fois dans le Collector.
- [ ] **T1526** — Les joueurs ex æquo restent départagés selon le classement serveur existant.
- [ ] **T1527** — Les statistiques finales affichent points distribués, badges, records, casseroles et génie.
- [ ] **T1528** — Le nombre de Teams du Collector correspond aux Teams de la saison.
- [ ] **T1529** — Le classement Teams du Collector correspond au classement Teams de l’application.
- [ ] **T1530** — Le Hall of Fame affiche les catégories disponibles sans inventer de gagnant.
- [ ] **T1531** — Le champion / podium du Hall of Fame correspond aux données de la saison.
- [ ] **T1532** — Poêle d’Or, Génie et Hibou solitaire sont affichés lorsqu’ils existent.
- [ ] **T1533** — Les badges rares/épiques/légendaires disponibles apparaissent dans le Collector.
- [ ] **T1534** — Les records affichés appartiennent uniquement à la saison sélectionnée.
- [ ] **T1535** — Le Replay reprend les événements de la bonne saison dans l’ordre chronologique.
- [ ] **T1536** — Les messages publiés du Livre d’or apparaissent dans le Collector.
- [ ] **T1537** — Les messages masqués du Livre d’or n’apparaissent pas dans le Collector.
- [ ] **T1538** — Une saison pauvre en données affiche des états vides propres, sans erreur.
- [ ] **T1539** — Les matchs marqués TEST n’entrent pas dans les statistiques finales officielles.
- [ ] **T1540** — Changer de saison puis rouvrir le Collector ne mélange aucune donnée de l’autre saison.
### Carnet joueur A4

- [ ] **T1541** — Mon carnet A4 ouvre le profil du joueur connecté.
- [ ] **T1542** — Un joueur normal ne peut pas ouvrir le carnet privé d’un autre joueur via l’URL.
- [ ] **T1543** — Un Admin peut prévisualiser le carnet d’un autre joueur.
- [ ] **T1544** — Le carnet affiche pseudo et avatar corrects.
- [ ] **T1545** — Le carnet affiche le club de cœur lorsqu’il existe.
- [ ] **T1546** — Le carnet affiche la Team de la saison lorsqu’elle existe.
- [ ] **T1547** — Le carnet affiche le rang de saison correct.
- [ ] **T1548** — Le carnet affiche les points de saison corrects.
- [ ] **T1549** — Le carnet affiche les scores exacts corrects.
- [ ] **T1550** — Le carnet affiche précision et moyenne cohérentes avec le profil.
- [ ] **T1551** — Le carnet affiche le meilleur rang et les jours en tête disponibles.
- [ ] **T1552** — Le carnet affiche le nombre d’oublis disponible.
- [ ] **T1553** — La courbe de rang suit l’historique enregistré sans inverser les dates.
- [ ] **T1554** — Un joueur sans historique de rang obtient un état vide lisible.
- [ ] **T1555** — Les badges du carnet appartiennent au joueur et à la saison sélectionnée.
- [ ] **T1556** — Les records du carnet appartiennent au joueur et à la saison sélectionnée.
- [ ] **T1557** — Les distinctions persistantes du joueur apparaissent dans son palmarès.
- [ ] **T1558** — La distinction Vainqueur du Nid des Pronos — Coupe du monde 2026 apparaît si attribuée.
- [ ] **T1559** — Les récompenses Hall of Fame du joueur apparaissent dans son carnet.
- [ ] **T1560** — Le carnet d’une saison archivée reste consultable en lecture seule.
### Diplôme

- [ ] **T1561** — Mon diplôme reprend le bon pseudo.
- [ ] **T1562** — Mon diplôme reprend la bonne saison.
- [ ] **T1563** — Le diplôme affiche le rang correct.
- [ ] **T1564** — Le diplôme affiche les points corrects.
- [ ] **T1565** — Le diplôme affiche les scores exacts corrects.
- [ ] **T1566** — Le diplôme affiche précision et moyenne correctes.
- [ ] **T1567** — Le diplôme affiche le meilleur rang disponible.
- [ ] **T1568** — Le diplôme reste élégant lorsqu’une statistique est absente.
- [ ] **T1569** — Le diplôme ne contient aucune donnée privée.
- [ ] **T1570** — Un joueur normal ne peut générer que son propre diplôme.
- [ ] **T1571** — L’export de tous les diplômes est réservé au Super Admin.
- [ ] **T1572** — L’export de tous les diplômes crée un diplôme par joueur classé.
- [ ] **T1573** — Aucun joueur n’est dupliqué dans l’export de diplômes.
- [ ] **T1574** — L’impression multiple conserve une page paysage par diplôme.
- [ ] **T1575** — Le diplôme affiche V0.9.8 et une date d’émission.
### Livre d’or

- [ ] **T1576** — Le Livre d’or est visible dans l’espace Fin de saison.
- [ ] **T1577** — Avant la fin de saison, un joueur ne peut pas publier dans le Livre d’or.
- [ ] **T1578** — Une saison au statut finished ouvre le Livre d’or aux joueurs.
- [ ] **T1579** — Un message de moins de 2 caractères est refusé.
- [ ] **T1580** — Un message de plus de 500 caractères est empêché/refusé.
- [ ] **T1581** — Un message valide est enregistré avec le bon joueur et la bonne saison.
- [ ] **T1582** — Chaque joueur ne possède qu’une contribution active par saison.
- [ ] **T1583** — Modifier son message remplace sa contribution sans créer de doublon.
- [ ] **T1584** — Un message sauvegardé reste présent après actualisation.
- [ ] **T1585** — Les messages publiés sont visibles par les autres joueurs connectés.
- [ ] **T1586** — Le pseudo et l’avatar affichés correspondent à l’auteur.
- [ ] **T1587** — L’ordre des messages est stable et compréhensible.
- [ ] **T1588** — Un Admin voit les messages publiés et masqués pour modération.
- [ ] **T1589** — Un Admin peut masquer un message.
- [ ] **T1590** — Un message masqué disparaît de la vue publique.
- [ ] **T1591** — L’auteur voit encore son message masqué avec son statut.
- [ ] **T1592** — Un Admin peut republier un message masqué.
- [ ] **T1593** — La modération du Livre d’or est journalisée dans audit_logs.
- [ ] **T1594** — Un joueur ne peut pas appeler directement la RPC de modération.
- [ ] **T1595** — Une saison archivée fige le Livre d’or pour les joueurs.
- [ ] **T1596** — Un joueur ne peut plus modifier son mot après archivage.
- [ ] **T1597** — Les messages d’une saison ne sont jamais visibles dans le Livre d’or d’une autre saison.
- [ ] **T1598** — Le Collector n’exporte que les messages publiés.
- [ ] **T1599** — Le Livre d’or affiche proprement l’état vide lorsqu’il n’y a aucun message.
- [ ] **T1600** — Les caractères accentués, apostrophes et emojis ne cassent pas l’affichage du Livre d’or.
### Export global & archive

- [ ] **T1601** — Le panneau Admin Fin de saison affiche l’état de préparation de la saison sélectionnée.
- [ ] **T1602** — Le compteur de matchs officiels exclut les matchs TEST.
- [ ] **T1603** — Une saison sans match officiel n’est pas déclarée prête à archiver.
- [ ] **T1604** — Une saison avec un match scheduled n’est pas prête à archiver.
- [ ] **T1605** — Une saison avec un match postponed n’est pas prête à archiver.
- [ ] **T1606** — Une saison avec un match live n’est pas prête à archiver.
- [ ] **T1607** — Une saison avec uniquement des matchs finished/cancelled est déclarée prête.
- [ ] **T1608** — Le motif de non-préparation est compréhensible dans l’Admin.
- [ ] **T1609** — Export global JSON produit un fichier exploitable.
- [ ] **T1610** — L’export JSON indique schema_version 0.9.8.
- [ ] **T1611** — L’export JSON contient saison, classement, Teams, Hall of Fame et Replay.
- [ ] **T1612** — L’export JSON contient badges, records et statistiques finales.
- [ ] **T1613** — L’export JSON contient uniquement les messages publiés du Livre d’or.
- [ ] **T1614** — L’export JSON ne contient aucune adresse e-mail.
- [ ] **T1615** — Construire l’archive est réservé au Super Admin.
- [ ] **T1616** — Construire une archive préparatoire n’archive pas immédiatement la saison.
- [ ] **T1617** — Une archive préparatoire enregistre un hash de snapshot.
- [ ] **T1618** — Reconstruire l’archive remplace le snapshot de la même saison sans doublon.
- [ ] **T1619** — Le snapshot indique schema_version 0.9.8.
- [ ] **T1620** — L’action de construction d’archive est journalisée.
- [ ] **T1621** — Le bouton Archiver définitivement reste désactivé tant que la saison n’est pas prête.
- [ ] **T1622** — La clôture définitive exige exactement la confirmation ARCHIVER.
- [ ] **T1623** — Une confirmation incorrecte est refusée côté serveur.
- [ ] **T1624** — Un Admin non Super Admin ne peut pas archiver définitivement.
- [ ] **T1625** — L’archivage final passe la saison au statut archived.
- [ ] **T1626** — L’archivage final désactive is_active pour cette saison.
- [ ] **T1627** — L’archive finale est marquée is_final=true avec finalized_at.
- [ ] **T1628** — L’action d’archivage final est journalisée.
- [ ] **T1629** — Après archivage, pronostics/champions/qualifiés/Teams restent protégés en lecture seule.
- [ ] **T1630** — Une saison archivée conserve Collector, diplômes, Hall of Fame, Replay et Livre d’or consultables.
### Admin / UX / sécurité V0.9.8

- [ ] **T1631** — La recherche Admin trouve « Fin de saison & PDF » avec les mots PDF, collector, diplôme, Livre d’or ou archive.
- [ ] **T1632** — Le panneau Fin de saison est rangé dans Admin > Application de façon visible.
- [ ] **T1633** — Le panneau Admin sépare clairement prévisualisation, export, préparation et archivage destructif.
- [ ] **T1634** — Les actions dangereuses utilisent un style visuel distinct.
- [ ] **T1635** — Le bouton d’archivage définitif n’est visible/utilisable que selon les droits prévus.
- [ ] **T1636** — Les erreurs RPC de fin de saison sont traduites en message lisible dans l’interface.
- [ ] **T1637** — Le chargement de la fin de saison ne bloque pas le reste de l’application.
- [ ] **T1638** — Changer de saison rafraîchit les données de clôture.
- [ ] **T1639** — Le panneau de fin de saison reste utilisable sur mobile.
- [ ] **T1640** — La navigation clavier atteint les boutons Collector, diplôme et archive.
- [ ] **T1641** — Les pages imprimables disposent d’un contraste suffisant.
- [ ] **T1642** — Le Centre de tests V0.9.8 est accessible depuis Admin > Laboratoire.
- [ ] **T1643** — La recherche Admin trouve le Centre de tests V0.9.8.
- [ ] **T1644** — Les anciens centres de tests V0.8.1, V0.9.0 et V0.9.5 restent accessibles.
- [ ] **T1645** — Les RPC d’administration V0.9.8 contrôlent les rôles côté serveur, pas seulement côté interface.
### Régression / sortie V0.9.8

- [ ] **T1646** — VERSION, config.js, Service Worker et manifest d’assets annoncent tous 0.9.8.
- [ ] **T1647** — Le site démarre sans erreur après passage V0.9.5 → V0.9.8.
- [ ] **T1648** — Le cockpit Admin V0.9.5 et sa recherche globale restent fonctionnels.
- [ ] **T1649** — Les sauvegardes/restaurations V0.9.5 restent fonctionnelles.
- [ ] **T1650** — Le multi-saisons V0.9.0 reste fonctionnel.
- [ ] **T1651** — Le Hall of Fame V0.9.0 reste fonctionnel.
- [ ] **T1652** — Le Replay V0.9.0 reste fonctionnel.
- [ ] **T1653** — Le vainqueur Coupe du monde 2026 reste conservé.
- [ ] **T1654** — Le Centre C1 V0.8.x reste fonctionnel et n’importe pas 2025/26 en fallback.
- [ ] **T1655** — Les pronostics, classements, LIVE et Teams restent accessibles après la migration.
- [ ] **T1656** — Le Service Worker pré-cache les nouveaux assets/pages de fin de saison.
- [ ] **T1657** — Le runner automatique V0.9.8 termine avec 0 FAIL en local.
- [ ] **T1658** — Le runner automatique V0.9.8 termine avec 0 FAIL sur GitHub Pages.
- [ ] **T1659** — Le Centre de tests V0.9.8 contient exactement 1660 contrôles uniques jusqu’à T1660.
- [ ] **T1660** — Une sauvegarde de production est réalisée avant le passage à V0.9.9 et la répétition générale.

## 0.9.9

### Release / migration

- [ ] **T1661** — VERSION contient 0.9.9.
- [ ] **T1662** — config.js et config.example.js annoncent 0.9.9.
- [ ] **T1663** — Le cache Service Worker utilise nid-champions-v0.9.9.
- [ ] **T1664** — Le manifest d’assets annonce 0.9.9.
- [ ] **T1665** — HOTFIX_V0.9.9_EXISTING_DB.sql s’exécute sans erreur sur une base V0.9.8.
- [ ] **T1666** — La migration V0.9.9 conserve les tables et RPC V0.9.8.
- [ ] **T1667** — Le site démarre sans erreur JavaScript après migration.
- [ ] **T1668** — Le Centre de tests V0.9.9 s’ouvre depuis Admin > Laboratoire.
- [ ] **T1669** — Le Grand road-check V1 s’ouvre depuis Admin > Laboratoire.
- [ ] **T1670** — Aucune Edge Function n’a besoin d’être redéployée pour V0.9.9.
### Bac à sable / isolation

- [ ] **T1671** — Créer une répétition générale ne crée aucun profil réel.
- [ ] **T1672** — Créer une répétition générale ne crée aucun match dans public.matches.
- [ ] **T1673** — Créer une répétition générale ne crée aucun pronostic dans public.predictions.
- [ ] **T1674** — Les joueurs virtuels restent dans preseason_virtual_players_v099.
- [ ] **T1675** — Les matchs virtuels restent dans preseason_virtual_matches_v099.
- [ ] **T1676** — Les pronostics virtuels restent dans preseason_virtual_predictions_v099.
- [ ] **T1677** — Les Teams virtuelles restent dans les tables preseason_* V0.9.9.
- [ ] **T1678** — Plusieurs répétitions peuvent coexister sans mélanger leurs données.
- [ ] **T1679** — Changer de répétition dans Admin affiche uniquement les données du run sélectionné.
- [ ] **T1680** — Une répétition est toujours rattachée à la saison choisie sans la modifier.
### Faux utilisateurs

- [ ] **T1681** — Le scénario par défaut crée 48 joueurs virtuels.
- [ ] **T1682** — Le nombre de joueurs virtuels est configurable entre 4 et 250.
- [ ] **T1683** — Chaque joueur virtuel possède un pseudo unique dans son scénario.
- [ ] **T1684** — Les joueurs virtuels n’apparaissent pas dans l’administration des vrais joueurs.
- [ ] **T1685** — Les joueurs virtuels n’apparaissent pas dans le classement officiel.
- [ ] **T1686** — Les joueurs virtuels n’apparaissent pas dans les notifications des vrais joueurs.
- [ ] **T1687** — Les joueurs virtuels peuvent être répartis dans plusieurs Teams virtuelles.
- [ ] **T1688** — Un capitaine virtuel est identifié pour chaque Team virtuelle.
- [ ] **T1689** — Le capitanat virtuel ne modifie aucun rôle applicatif réel.
- [ ] **T1690** — Supprimer le scénario supprime tous les joueurs virtuels associés.
### Faux matchs / scores

- [ ] **T1691** — Le scénario par défaut crée 24 matchs virtuels.
- [ ] **T1692** — Le nombre de matchs virtuels est configurable entre 8 et 80.
- [ ] **T1693** — Les matchs virtuels couvrent phase de ligue et phases finales.
- [ ] **T1694** — Chaque match virtuel possède deux clubs TEST distinctement libellés.
- [ ] **T1695** — Chaque match virtuel possède un coup d’envoi.
- [ ] **T1696** — L’étape LIVE passe exactement trois matchs virtuels en live lorsqu’ils sont disponibles.
- [ ] **T1697** — L’étape scores termine la phase de ligue virtuelle.
- [ ] **T1698** — Les scores virtuels restent absents des matchs officiels.
- [ ] **T1699** — La finale virtuelle se termine avec un score exploitable.
- [ ] **T1700** — Le journal de répétition conserve les étapes de scores exécutées.
### Barème / classement simulé

- [ ] **T1701** — Un faux résultat incorrect rapporte 0 point dans le bac à sable.
- [ ] **T1702** — Un bon résultat rapporte 3 points dans le bac à sable.
- [ ] **T1703** — Un bon résultat avec bon écart rapporte 5 points dans le bac à sable.
- [ ] **T1704** — Un score exact rapporte 7 points dans le bac à sable.
- [ ] **T1705** — La distribution 0/3/5/7 est visible dans le panneau Admin.
- [ ] **T1706** — Le recalcul des scores ne crée pas de points dans public.predictions.
- [ ] **T1707** — Le recalcul peut être rejoué sans dupliquer les pronostics virtuels.
- [ ] **T1708** — Les points virtuels sont rattachés au bon joueur et au bon match.
- [ ] **T1709** — Les points de phases finales virtuelles sont recalculés après la finale.
- [ ] **T1710** — Le barème officiel de production reste inchangé.
### LIVE / temps réel

- [ ] **T1711** — Le bouton Passer 3 matchs LIVE est visible dans la répétition.
- [ ] **T1712** — Après LIVE, le compteur LIVE du scénario augmente.
- [ ] **T1713** — Les matchs LIVE virtuels conservent leurs scores courants.
- [ ] **T1714** — L’étape scores transforme les matchs de ligue LIVE en terminés.
- [ ] **T1715** — Le scénario permet de contrôler visuellement la gestion des états scheduled/live/finished.
- [ ] **T1716** — Le LIVE virtuel ne déclenche aucun classement officiel.
- [ ] **T1717** — Le LIVE virtuel ne déclenche aucun badge officiel.
- [ ] **T1718** — Le LIVE virtuel ne déclenche aucun push global.
- [ ] **T1719** — Le journal indique le démarrage LIVE.
- [ ] **T1720** — Le road-check demande un test multi-session du vrai LIVE avant GO V1.
### Champion

- [ ] **T1721** — Chaque joueur virtuel reçoit un Champion n°1.
- [ ] **T1722** — Chaque joueur virtuel peut disposer d’un Champion n°2.
- [ ] **T1723** — L’étape Champion résout un vainqueur virtuel.
- [ ] **T1724** — Le bonus virtuel Champion n°1 vaut 100 pour les bons choix.
- [ ] **T1725** — Un mauvais Champion virtuel reste à 0 bonus.
- [ ] **T1726** — Le test Champion ne modifie pas champion_predictions.
- [ ] **T1727** — Le choix Champion réel reste secret selon les règles existantes.
- [ ] **T1728** — Le road-check contient le verrouillage Champion n°1.
- [ ] **T1729** — Le road-check contient l’ouverture/verrouillage Champion n°2.
- [ ] **T1730** — La distinction Coupe du monde 2026 reste indépendante du Champion de saison.
### Teams

- [ ] **T1731** — Le scénario par défaut crée 8 Teams virtuelles.
- [ ] **T1732** — Le nombre de Teams virtuelles est configurable entre 2 et 32.
- [ ] **T1733** — Chaque Team virtuelle possède un capitaine.
- [ ] **T1734** — Chaque joueur virtuel appartient à au plus une Team virtuelle.
- [ ] **T1735** — L’étape Teams écrit un checkpoint dans le journal.
- [ ] **T1736** — Les Teams virtuelles n’apparaissent pas dans public.teams.
- [ ] **T1737** — Les Teams réelles restent modifiables hors archive.
- [ ] **T1738** — Les Teams réelles restent figées dans une saison archivée.
- [ ] **T1739** — Le capitaine réel reste un rôle de Team et non un rôle profiles.role.
- [ ] **T1740** — Le nettoyage supprime toutes les Teams virtuelles du scénario.
### Badges / Casseroles / Génie

- [ ] **T1741** — L’étape Badges génère des récompenses virtuelles.
- [ ] **T1742** — Le scénario génère au moins un badge virtuel.
- [ ] **T1743** — Le scénario génère au moins une Casserole virtuelle.
- [ ] **T1744** — Le scénario génère au moins un Coup de Génie virtuel.
- [ ] **T1745** — Les récompenses virtuelles n’écrivent pas dans player_badges.
- [ ] **T1746** — Les récompenses virtuelles n’écrivent pas dans gamification_events officiels.
- [ ] **T1747** — Le catalogue officiel conserve au moins 100 badges.
- [ ] **T1748** — La banque narrative officielle conserve au moins 1360 textes historiques.
- [ ] **T1749** — Les badges officiels restent testables via le laboratoire Gamification existant.
- [ ] **T1750** — Le nettoyage supprime toutes les récompenses virtuelles.
### Notifications / Push

- [ ] **T1751** — L’étape Notifications envoie une notification TEST uniquement au Super Admin courant.
- [ ] **T1752** — La notification TEST utilise le mécanisme de notification V0.7 existant.
- [ ] **T1753** — La notification de répétition est marquée comme TEST.
- [ ] **T1754** — Aucune notification de répétition n’est diffusée à tous les joueurs.
- [ ] **T1755** — L’étape Notifications fonctionne sans demander de Push navigateur par défaut.
- [ ] **T1756** — Le road-check prévoit un Push réel ciblé sur un appareil de test.
- [ ] **T1757** — Les préférences de notification du joueur restent respectées hors laboratoire.
- [ ] **T1758** — Les quiet hours restent contrôlables dans le road-check.
- [ ] **T1759** — La cloche de notifications reste accessible après V0.9.9.
- [ ] **T1760** — Le nettoyage du scénario ne supprime aucune notification métier existante.
### Charge / performance

- [ ] **T1761** — Le test de charge accepte au moins 20 000 lignes.
- [ ] **T1762** — Le test de charge peut monter jusqu’à 100 000 lignes maximum.
- [ ] **T1763** — Les données de charge restent dans preseason_load_samples_v099.
- [ ] **T1764** — Le temps d’écriture est mesuré en millisecondes.
- [ ] **T1765** — Le nombre de lignes écrites est affiché dans Admin.
- [ ] **T1766** — Relancer le test de charge remplace les anciennes lignes du même scénario.
- [ ] **T1767** — Le test de charge ne verrouille pas les tables de pronostics officielles.
- [ ] **T1768** — Le test de charge ne crée aucun utilisateur Auth.
- [ ] **T1769** — Le road-check prévoit un contrôle mobile après charge.
- [ ] **T1770** — Le nettoyage du scénario supprime toutes les lignes de charge.
### Phases finales / finale

- [ ] **T1771** — Le scénario contient des matchs QUARTER_FINAL.
- [ ] **T1772** — Le scénario contient des matchs SEMI_FINAL.
- [ ] **T1773** — Le scénario contient exactement un match FINAL.
- [ ] **T1774** — L’étape Finale termine les matchs virtuels de phases finales.
- [ ] **T1775** — La finale virtuelle possède un vainqueur.
- [ ] **T1776** — Les points virtuels sont recalculés après la finale.
- [ ] **T1777** — La vraie logique aller-retour reste couverte par le road-check.
- [ ] **T1778** — La vraie prolongation reste couverte par le road-check.
- [ ] **T1779** — Les vrais tirs au but restent couverts par le road-check.
- [ ] **T1780** — La vraie propagation des qualifiés reste couverte par le road-check.
### PDF / fin de saison

- [ ] **T1781** — Le bouton Smoke test PDF ouvre le Collector V0.9.8.
- [ ] **T1782** — Le road-check couvre le Collector A4.
- [ ] **T1783** — Le road-check couvre le carnet joueur A4.
- [ ] **T1784** — Le road-check couvre le diplôme A4.
- [ ] **T1785** — Le road-check couvre la génération groupée de diplômes.
- [ ] **T1786** — Le road-check couvre le Livre d’or.
- [ ] **T1787** — Le road-check couvre l’export global JSON.
- [ ] **T1788** — Le road-check couvre la construction de l’archive préparatoire.
- [ ] **T1789** — L’archivage définitif de la vraie saison n’est jamais déclenché automatiquement par la répétition.
- [ ] **T1790** — L’étape PDF du bac à sable ne modifie aucune archive réelle.
### Nettoyage

- [ ] **T1791** — Le nettoyage exige exactement NETTOYER.
- [ ] **T1792** — Une confirmation différente de NETTOYER est refusée côté serveur.
- [ ] **T1793** — Le nettoyage est réservé au Super Admin.
- [ ] **T1794** — Le nettoyage supprime le run sélectionné.
- [ ] **T1795** — Le nettoyage cascade sur joueurs virtuels.
- [ ] **T1796** — Le nettoyage cascade sur matchs et pronostics virtuels.
- [ ] **T1797** — Le nettoyage cascade sur Teams virtuelles.
- [ ] **T1798** — Le nettoyage cascade sur événements et récompenses virtuelles.
- [ ] **T1799** — Le nettoyage cascade sur données de charge.
- [ ] **T1800** — Le nettoyage ne supprime aucune donnée officielle de la saison.
### Onboarding / tutoriel

- [ ] **T1801** — Un utilisateur peut ouvrir le tutoriel depuis son Profil.
- [ ] **T1802** — Le tutoriel contient 10 étapes.
- [ ] **T1803** — Le tutoriel explique les pronostics.
- [ ] **T1804** — Le tutoriel explique les classements et le LIVE.
- [ ] **T1805** — Le tutoriel explique les Teams et le capitanat.
- [ ] **T1806** — Le tutoriel explique les Champions.
- [ ] **T1807** — Le tutoriel explique badges, records et Hibou.
- [ ] **T1808** — Le tutoriel explique notifications et carrière.
- [ ] **T1809** — Le bouton Plus tard mémorise le report du tutoriel.
- [ ] **T1810** — Terminer le tutoriel mémorise la complétion et permet de le revoir.
### Textes du Hibou

- [ ] **T1811** — Au moins 10 textes spécifiques V0.9.9 sont actifs.
- [ ] **T1812** — Un texte d’accueil du Hibou existe.
- [ ] **T1813** — Un texte premier pronostic existe.
- [ ] **T1814** — Un texte LIVE existe.
- [ ] **T1815** — Un texte score exact existe.
- [ ] **T1816** — Un texte Casserole existe.
- [ ] **T1817** — Un texte Coup de Génie existe.
- [ ] **T1818** — Un texte Champion verrouillé existe.
- [ ] **T1819** — Un texte finale / fin de saison existe.
- [ ] **T1820** — Les textes V0.9.9 n’écrasent pas les 1360 textes historiques.
### Admin UX

- [ ] **T1821** — La recherche Admin trouve Répétition générale avec pré-saison.
- [ ] **T1822** — La recherche Admin trouve Répétition générale avec charge.
- [ ] **T1823** — La répétition générale est située dans Admin > Laboratoire.
- [ ] **T1824** — Le panneau explique clairement que les données sont isolées.
- [ ] **T1825** — Créer un scénario demande joueurs, matchs et Teams dans un seul bloc.
- [ ] **T1826** — Les étapes déjà exécutées sont visuellement marquées.
- [ ] **T1827** — Les KPI joueurs/Teams/matchs/pronostics/LIVE/terminés sont visibles sans scroll excessif.
- [ ] **T1828** — Les liens Centre de tests et Grand road-check sont visibles dans le panneau.
- [ ] **T1829** — Le bouton Nettoyer est visuellement séparé des actions normales.
- [ ] **T1830** — Le panneau reste utilisable sur mobile.
### PWA / mobile

- [ ] **T1831** — Le Service Worker pré-cache preseason099.css.
- [ ] **T1832** — Le Service Worker pré-cache preseason099.js.
- [ ] **T1833** — La V0.9.9 se recharge sans conserver un ancien cache V0.9.8.
- [ ] **T1834** — Le tutoriel est lisible sur smartphone.
- [ ] **T1835** — Le panneau pré-saison est utilisable sur smartphone.
- [ ] **T1836** — Le Grand road-check est utilisable sur smartphone.
- [ ] **T1837** — Les boutons de la répétition restent suffisamment grands au tactile.
- [ ] **T1838** — Le mode prefers-reduced-motion est respecté par le tutoriel.
- [ ] **T1839** — La PWA redémarre après fermeture complète en V0.9.9.
- [ ] **T1840** — La session utilisateur reste restaurée normalement après mise à jour.
### Sécurité / RLS

- [ ] **T1841** — Les tables preseason_* ont RLS activée.
- [ ] **T1842** — Un joueur normal ne peut pas lire les données du bac à sable Admin.
- [ ] **T1843** — Un Admin non Super Admin ne peut pas créer une répétition.
- [ ] **T1844** — Un Admin non Super Admin ne peut pas lancer le test de charge.
- [ ] **T1845** — Un Admin non Super Admin ne peut pas nettoyer une répétition.
- [ ] **T1846** — Les RPC V0.9.9 recontrôlent is_super_admin côté serveur.
- [ ] **T1847** — L’onboarding d’un joueur n’est modifiable que via ses RPC dédiés.
- [ ] **T1848** — Aucune adresse e-mail n’est stockée dans les joueurs virtuels.
- [ ] **T1849** — Le bac à sable ne contient aucun secret API.
- [ ] **T1850** — Le diagnostic V0.9.9 vérifie les composants critiques avant GO.
### Multi-session / navigateur

- [ ] **T1851** — Le road-check prévoit deux sessions navigateur simultanées.
- [ ] **T1852** — Un changement LIVE réel apparaît dans la seconde session sans refresh.
- [ ] **T1853** — Un score LIVE réel se met à jour dans la seconde session.
- [ ] **T1854** — Une fin de match réelle se met à jour dans la seconde session.
- [ ] **T1855** — Les pronostics adverses réels restent cachés avant verrouillage.
- [ ] **T1856** — Les pronostics adverses réels deviennent visibles après verrouillage.
- [ ] **T1857** — Le changement de saison ne mélange pas les données entre sessions.
- [ ] **T1858** — Une notification interne ciblée apparaît sur le bon compte.
- [ ] **T1859** — Un joueur normal ne voit jamais le panneau pré-saison.
- [ ] **T1860** — La répétition virtuelle reste invisible dans une session joueur.
### Régression critique V1

- [ ] **T1861** — Inscription, validation et connexion par pseudo restent fonctionnelles.
- [ ] **T1862** — Pronostics et autosauvegarde restent fonctionnels.
- [ ] **T1863** — Barème officiel 0/3/5/7 reste fonctionnel.
- [ ] **T1864** — Classements Général/Journée/Soirée/Précision/Exacts restent fonctionnels.
- [ ] **T1865** — Champions 1 et 2 restent fonctionnels.
- [ ] **T1866** — Phases finales, cumul, prolongation, TAB et qualifié restent fonctionnels.
- [ ] **T1867** — Teams et rivalités restent fonctionnelles.
- [ ] **T1868** — Gamification, Musée, Hibou solitaire et sondages restent fonctionnels.
- [ ] **T1869** — Multi-saisons, carrière, Hall of Fame et Replay restent fonctionnels.
- [ ] **T1870** — Admin, sauvegardes, PDF et archives restent fonctionnels.
### GO / répétition générale

- [ ] **T1871** — Le runner V0.9.9 termine avec 0 FAIL en local.
- [ ] **T1872** — Le runner V0.9.9 termine avec 0 FAIL sur GitHub Pages.
- [ ] **T1873** — Le diagnostic SQL V0.9.9 termine avec 0 FAIL.
- [ ] **T1874** — Le Centre de tests V0.9.9 contient exactement 1880 contrôles uniques.
- [ ] **T1875** — Les 24 missions du Grand road-check ont été parcourues.
- [ ] **T1876** — Aucun KO critique n’est laissé sans correction ou décision documentée.
- [ ] **T1877** — Une sauvegarde de production existe avant la répétition destructrice éventuelle.
- [ ] **T1878** — Tous les scénarios preseason_* sont nettoyés après validation.
- [ ] **T1879** — La saison réelle ne contient aucune donnée TEST involontaire après nettoyage.
- [ ] **T1880** — La répétition générale est déclarée terminée avant création de V1.0.0.

## 0.9.10 — Sécurisation pré-production

### Installation

- [ ] **T1881** — Le HOTFIX V0.9.10 s’exécute sans erreur sur la base V0.9.9.
- [ ] **T1882** — sync-football-data V0.9.10 est redéployée après le SQL.

### Calendrier hybride

- [ ] **T1883** — Le fichier UEFA intégré contient exactement 144 matchs.
- [ ] **T1884** — Les 144 matchs sont répartis en 8 journées de 18.
- [ ] **T1885** — Les 36 clubs jouent chacun exactement huit rencontres.
- [ ] **T1886** — Le bouton Charger les 144 matchs UEFA crée ou met à jour le calendrier sans doublon.
- [ ] **T1887** — Une seconde exécution du chargement UEFA est idempotente.
- [ ] **T1888** — Une réponse Football-Data partielle est acceptée sans erreur fonctionnelle.
- [ ] **T1889** — Une réponse Football-Data partielle ne supprime aucun match local absent du lot reçu.
- [ ] **T1890** — Une réponse Football-Data d’une autre saison reste refusée.
- [ ] **T1891** — Un match UEFA local est rapproché de Football-Data par équipes quand son external_match_id est encore absent.
- [ ] **T1892** — Après rapprochement, external_match_id est enregistré pour les mises à jour suivantes.

### Édition match

- [ ] **T1893** — Un Admin peut modifier domicile, extérieur, journée, date, stade et pays du stade.
- [ ] **T1894** — Une correction manuelle peut être verrouillée contre Football-Data.
- [ ] **T1895** — Football-Data ne modifie pas la date/équipes/stade d’un match verrouillé.
- [ ] **T1896** — Un Admin peut retirer le verrou pour rendre le match à nouveau pilotable par Football-Data.

### Équipes

- [ ] **T1897** — Un Admin peut ajouter manuellement une équipe au catalogue C1.
- [ ] **T1898** — Un Admin peut corriger nom, nom court, sigle, pays, stade et logo.
- [ ] **T1899** — Une correction d’équipe peut être protégée des métadonnées Football-Data.
- [ ] **T1900** — Football-Data peut toujours rattacher son external_id à une équipe protégée.

### Cotes 1N2

- [ ] **T1901** — Le bouton Cotes 1N2 n’exige plus la présence des 144 matchs chez Football-Data.
- [ ] **T1902** — Les cotes présentes dans un lot Football-Data partiel sont appliquées aux matchs reconnus.
- [ ] **T1903** — Un lot sans cotes affiche un message métier et ne fait pas croire à une panne de clé API.
- [ ] **T1904** — Une vraie panne de transport de l’Edge Function est distinguée d’une erreur fournisseur.

### Champion 1

- [ ] **T1905** — Le choix Champion 1 est ouvert avant le premier coup d’envoi.
- [ ] **T1906** — Les 36 clubs C1 sont proposés même si Football-Data n’a encore fourni aucun match.
- [ ] **T1907** — La fermeture du Champion 1 utilise la première date UEFA connue si nécessaire.

### Reset pré-production

- [ ] **T1908** — Le Super Admin peut prévisualiser les données qui seront nettoyées.
- [ ] **T1909** — Le reset exige exactement RESET AVANT OUVERTURE.
- [ ] **T1910** — Le reset supprime les pronostics et choix champions de recette.
- [ ] **T1911** — Le reset supprime les badges obtenus sans supprimer le catalogue des 100 succès.
- [ ] **T1912** — Le reset supprime casseroles, génies, records et répétitions générales.
- [ ] **T1913** — Le reset conserve comptes, Teams, clubs et calendrier réel.
- [ ] **T1914** — Le reset remet les scores/statuts des matchs réels à un état neutre.
- [ ] **T1915** — Le reset est bloqué après le premier coup d’envoi officiel.

### UI publique

- [ ] **T1916** — Centre Ligue des champions n’affiche plus de numéro de version technique.
- [ ] **T1917** — Soirée européenne n’affiche plus de numéro de version technique.
- [ ] **T1918** — Le Musée n’affiche plus V0.7.0 dans son en-tête public.

### Non-régression

- [ ] **T1919** — Les 100 images de succès intégrées à la base V0.9.9 sont toujours présentes.

### GO V0.9.10

- [ ] **T1920** — Runner local et distant V0.9.10 terminent avec 0 FAIL avant reprise du road-check.


## 0.9.11

### Installation

- [ ] **T1921** — Le HOTFIX V0.9.11 s’exécute sans erreur et app_settings.app_version devient 0.9.11.
- [ ] **T1922** — La Function sync-betclic-odds est déployée avec verify_jwt=true.
### Betclic expérimental

- [ ] **T1923** — Le bouton Tester Betclic lit le flux sans modifier les matchs locaux.
- [ ] **T1924** — Une panne Betclic n’empêche ni l’affichage du Nid ni la saisie manuelle des cotes.
- [ ] **T1925** — Une cote 1N2 saisie manuellement n’est jamais écrasée par Betclic.
- [ ] **T1926** — Le rapprochement Betclic tient compte des alias de clubs, dont AEK Athens / AEK Athènes / PAE AEK.
- [ ] **T1927** — Une synchronisation Betclic met à jour uniquement les matchs locaux reconnus.
- [ ] **T1928** — L’Admin affiche le nombre de matchs rapprochés, mis à jour et sans marché 1N2.
### Ouverture progressive

- [ ] **T1929** — Quand Teams est verrouillé, un joueur ne voit plus l’onglet Teams.
- [ ] **T1930** — Quand Musée & gamification est verrouillé, un joueur ne voit plus l’onglet Musée ni ses cartes d’accueil.
- [ ] **T1931** — Quand Messages & notifications est verrouillé, un joueur ne voit plus la cloche, les messages du Hibou ni l’activation Push.
- [ ] **T1932** — Quand Phases finales est verrouillé, un joueur ne voit plus l’onglet et un accès direct est refusé.
- [ ] **T1933** — Quand Centre C1 ou Soirées européennes est verrouillé, les écrans correspondants disparaissent pour les joueurs.
- [ ] **T1934** — Le Super Admin garde toutes les fonctions visibles même lorsqu’elles sont verrouillées aux joueurs.
- [ ] **T1935** — Le Super Admin voit un indicateur OUVERT / VERROUILLÉ sur les fonctions principales.
- [ ] **T1936** — Un changement d’interrupteur app_settings est répercuté aux clients connectés via Realtime.
### Communication

- [ ] **T1937** — Le bouton Supprimer tous les messages est réservé au Super Admin et exige la phrase exacte.
- [ ] **T1938** — La purge supprime messages, notifications et données de support de test sans supprimer les comptes ni préférences Push.
### Pré-production

- [ ] **T1939** — Le reset avant ouverture ne déclenche plus l’erreur DELETE requires a WHERE clause.
### GO V0.9.11

- [ ] **T1940** — Runner local et distant V0.9.11 terminent avec 0 FAIL avant validation de la release.
