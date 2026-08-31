# Le Nid des Champions — Checklist V0.9.12

**40 contrôles spécifiques** à la refonte desktop UX/UI et au cockpit matchs.

## Installation

- [ ] **T1941** — Le HOTFIX V0.9.12 s’exécute sans erreur et app_settings.app_version devient 0.9.12.
- [ ] **T1942** — Le cache PWA, VERSION, config.js et assets-manifest annoncent tous 0.9.12.
## Navigation desktop

- [ ] **T1943** — La barre latérale desktop affiche Accueil, Pronostics, Classement du Nid, Ligue des champions, Soirées européennes, Teams, Musée et Admin selon les droits.
- [ ] **T1944** — Phases finales, Saison et Profil ne sont plus des entrées autonomes de la navigation desktop.
- [ ] **T1945** — Un clic sur l’avatar/pseudo de la sidebar ouvre directement le Profil.
- [ ] **T1946** — Le haut de page affiche Le Nid est connecté avec V0.9.12 et n’expose plus Supabase LIVE.
## Accueil

- [ ] **T1947** — Le carrousel Mes prochains matchs affiche les prochains rendez-vous.
- [ ] **T1948** — Chaque carte de prochain match indique Prono fait, Prono à faire ou Verrouillé.
- [ ] **T1949** — Un clic sur une carte du carrousel ouvre Pronostics sur la bonne journée et le bon match.
- [ ] **T1950** — Le cartouche Prochain rendez-vous ouvre lui aussi directement le match concerné.
- [ ] **T1951** — Le carrousel Le Nid en mouvement affiche casseroles, badges obtenus et records sans doublons évidents.
- [ ] **T1952** — Avant le premier résultat officiel, le carrousel n’affiche pas de badge de classement.
- [ ] **T1953** — Le message du Hibou masqué est visible sans parcourir une longue page et a une hiérarchie visuelle forte.
## Pronostics desktop

- [ ] **T1954** — Les matchs sont disposés deux par ligne à partir de 901 px.
- [ ] **T1955** — Chaque match affiche son stade et son pays lorsqu’ils sont connus.
- [ ] **T1956** — Chaque équipe affiche son rang C1, ou un tiret tant que le classement n’existe pas.
- [ ] **T1957** — Un clic sur une équipe ouvre sa fiche sans modifier le pronostic.
## Fiche club

- [ ] **T1958** — La fiche club affiche pays, stade, rang C1, points et forme quand ces informations existent.
- [ ] **T1959** — La fiche club affiche les prochains matchs et permet de pronostiquer directement un match à venir.
- [ ] **T1960** — La fiche club affiche les derniers matchs terminés et leurs scores.
## Classement du Nid

- [ ] **T1961** — L’écran et la navigation utilisent le libellé Classement du Nid.
## Badges classement

- [ ] **T1962** — Aucun badge de catégorie classement n’est attribuable avant played >= 1 sur un match officiel terminé.
## Ligue des champions

- [ ] **T1963** — La Vue d’ensemble disparaît du Centre C1 desktop.
- [ ] **T1964** — Le Centre C1 desktop propose uniquement Classement, Phases finales et Infos.
- [ ] **T1965** — La légende 1–8 / 9–24 / 25–36 est située avec le classement.
- [ ] **T1966** — Infos permet d’accéder au calendrier/résultats et aux clubs sans afficher de statistiques fictives avant les premiers résultats.
## Profil desktop

- [ ] **T1967** — Le Profil desktop est organisé en Mon profil, Saison & carrière et Préférences.
- [ ] **T1968** — La bibliothèque complète d’avatars reste masquée jusqu’au clic sur Changer mon avatar.
- [ ] **T1969** — Saison & carrière regroupe les informations de saison auparavant accessibles par l’onglet Saison.
- [ ] **T1970** — La page Profil ne nécessite plus de parcourir immédiatement toute la bibliothèque d’avatars.
## Admin matchs

- [ ] **T1971** — Le cockpit Admin affiche les matchs de la journée dans des lignes compactes.
- [ ] **T1972** — Les cotes 1/N/2 peuvent être saisies au clavier avec une source/bookmaker.
- [ ] **T1973** — Enregistrer toute la journée sauvegarde atomiquement les lignes de cotes complètes et ignore les lignes incomplètes.
- [ ] **T1974** — Une cote manuelle reste protégée contre les fournisseurs automatiques.
- [ ] **T1975** — Score domicile, score extérieur et état du match peuvent être mis à jour depuis la même ligne.
- [ ] **T1976** — La validation ou correction d’un résultat terminé demande une confirmation.
- [ ] **T1977** — Le bouton Paramètres ouvre l’éditeur complet existant pour date, lieu, équipes et autres métadonnées.
## Non-régression mobile

- [ ] **T1978** — Sous 901 px, la navigation et les écrans mobiles existants restent utilisés ; la refonte mobile est volontairement différée.
## Non-régression

- [ ] **T1979** — Betclic R7, calendrier hybride V0.9.10 et les 100 succès restent présents.
## GO V0.9.12

- [ ] **T1980** — Runner local et distant V0.9.12 terminent avec 0 FAIL avant validation desktop.
