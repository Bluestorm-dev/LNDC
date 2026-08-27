# Matrice complète de validation — Le Nid des Champions V0.1.x → V0.8.1

Cette matrice consolide **1185 contrôles** issus des checklists historiques du projet, puis ajoute les contrôles V0.8.0 et V0.8.1.

## Légende

- **OK** : conforme.
- **KO** : anomalie à corriger.
- **N/A** : non applicable dans l’environnement testé.
- Les tests destructifs doivent être réalisés uniquement avec les outils TEST prévus par l’application ou après sauvegarde.

## V0.1.x

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
## V0.2.0

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
## V0.3.0

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
## V0.3.1

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
## V0.3.2

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
## V0.3.3

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
## V0.3.4

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
## V0.4.0

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
## V0.4.1

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
## V0.4.2

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
## V0.5.0

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
## V0.5.2

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
## V0.5.3

### 1. Migration Supabase

- [ ] **T0700** — `sql/HOTFIX_V0.5.3_EXISTING_DB.sql` s’exécute sans erreur avec le rôle `postgres`.
- [ ] **T0701** — `app_settings.app_version` vaut `0.5.3`.
- [ ] **T0702** — Le bucket `player-avatars` existe, est privé, limité à 3 Mo et aux MIME PNG/JPEG/WebP.
- [ ] **T0703** — Les colonnes avatar V0.5.3 existent dans `profiles`.
- [ ] **T0704** — Les quatre RPC `*avatar*v053` sont visibles après reload du schéma.
### 2. Bibliothèque officielle

- [ ] **T0705** — Le Profil affiche 9 catégories / 90 avatars.
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
## V0.5.4

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
## V0.5.5

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
## V0.5.5a

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
## V0.6.0

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
## V0.6.0a

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
## V0.6.2

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
## V0.6.3

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
## V0.6.4

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
## V0.6.7

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
## V0.6.8

### Général

- [ ] **T1021** — Plus aucun logo/pictogramme dans les blasons Team.
- [ ] **T1022** — Le blason Team repose uniquement sur les couleurs et motifs.
- [ ] **T1023** — L'avatar du joueur est légèrement réduit dans le blason.
- [ ] **T1024** — L'avatar d'accueil mobile est légèrement réduit.
- [ ] **T1025** — Une Team existante peut être mise à jour sans SQL supplémentaire.
## V0.7.0

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
## V0.7.1

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
## V0.7.2

### Général

- [ ] **T1124** — Le bouton « Vider tous les matchs » renvoie `ties_deleted` et vide la phase finale.
- [ ] **T1125** — L'écran Phase finale n'affiche plus les anciennes confrontations après rechargement.
- [ ] **T1126** — `sync-football-data` interroge `season=2026` pour `ucl-2026-27`.
- [ ] **T1127** — Aucune fonction de décalage d'un an n'est utilisée.
- [ ] **T1128** — `odds_source_season` vaut `2026/27` et `odds_is_test_shifted=false`.
- [ ] **T1129** — Si le calendrier de ligue n'est pas complet, l'import refuse proprement sans charger 2025/26.
- [ ] **T1130** — Lorsque les 144 matchs sont disponibles, dates, clubs et journées sont ceux de 2026/27.
- [ ] **T1131** — Le front affiche « saison réelle 2026/27 ».
## V0.7.3

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
## V0.8.0

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
## V0.8.1

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
