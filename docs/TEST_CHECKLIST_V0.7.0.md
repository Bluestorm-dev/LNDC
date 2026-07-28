# Checklist de validation — V0.7.0

## 1. Version / cache
- [ ] `VERSION`, `config.js`, interface et Service Worker affichent `0.7.0`.
- [ ] Après Ctrl+F5 / relance PWA, aucun ancien asset V0.6.x ne reste affiché.

## 2. Blasons Team / avatars
- [ ] Aucun logo Team ni mini-marque/pastille en bas à droite des avatars.
- [ ] Le blason conserve ses couleurs/motifs.
- [ ] Le Hibou est nettement plus petit au centre du blason.
- [ ] Sur accueil mobile, le Hibou laisse une marge visible autour de lui.

## 3. LIVE sans F5
- [ ] Deux sessions distinctes : Admin + Joueur.
- [ ] Passage `scheduled -> live` visible côté joueur sans rechargement.
- [ ] Modification `0-0 -> 1-0` visible côté joueur sans rechargement.
- [ ] Le ticker LIVE se met à jour.
- [ ] Les points provisoires se mettent à jour.
- [ ] Le classement LIVE officiel se met à jour pour un match officiel.
- [ ] Après une coupure/reprise réseau, le filet de sécurité resynchronise l'écran.

## 4. Classement TEST
- [ ] Un match TEST n'ajoute aucun point au classement officiel.
- [ ] L'onglet `🧪 TEST` apparaît lorsqu'un calendrier TEST actif existe.
- [ ] Le score LIVE TEST modifie le classement LIVE TEST.
- [ ] Les données TEST sont visuellement identifiées et séparées.

## 5. Musée
- [ ] Vue générale : badges, records, points Casserole, points Génie.
- [ ] Sous-vues Badges / Records / Casseroles / Génie fonctionnelles.
- [ ] Recherche et filtres Badges fonctionnent.
- [ ] Obtenus en premier puis progression proche du déblocage.
- [ ] Un secret inconnu reste `???` ou invisible selon sa configuration.
- [ ] Le Musée public d'un autre joueur masque les secrets que le visiteur ne connaît pas.

## 6. Badges
- [ ] Le catalogue contient 100 badges initiaux mais accepte des badges supplémentaires.
- [ ] Création Super Admin avec catégorie, rareté, scope, secret, image et conditions.
- [ ] Condition avancée `ET / OU` évaluable.
- [ ] Upload image PNG/JPG/WebP <= 5 Mo.
- [ ] Visuel générique si aucun visuel spécifique n'est fourni.
- [ ] Duplication, import/export JSON, désactivation et archivage.
- [ ] Attribution manuelle + révocation avec motif/audit.
- [ ] Recalcul en aperçu puis exécution.
- [ ] Plusieurs badges obtenus ensemble => une notification groupée.
- [ ] Animation basée sur la rareté la plus élevée du groupe.
- [ ] Animation Commun < Rare < Épique < Légendaire ; Secret spécifique.

## 7. Secrets
- [ ] La première découverte mondiale est enregistrée.
- [ ] Seule la première découverte mondiale peut déclencher l'annonce globale.
- [ ] L'annonce donne pseudo + Team éventuelle, jamais le nom/condition du secret.
- [ ] Le premier découvreur conserve sa mention historique.
- [ ] Le choix d'annoncer ou non les découvertes rétroactives est configurable.

## 8. Casseroles
- [ ] Calcul uniquement sur match `finished`.
- [ ] Seuils d'erreur par défaut : 3 / 4 / 6 / 8.
- [ ] Points par défaut : +1 / +3 / +5 / +10.
- [ ] Plusieurs labels possibles mais seule la gravité la plus forte donne les points.
- [ ] Joueur unique à se tromper => traitement automatique.
- [ ] Séries de zéros 3 / 5 / 8 par défaut.
- [ ] Journée complète à zéro => gravité configurable.
- [ ] Champion éliminé tôt => règle configurable par phase.
- [ ] Industrielle/Nucléaire peut être annoncée au Nid.
- [ ] Casserole manuelle avec texte, média, points, visibilité et Push.

## 9. Génie
- [ ] Aucun Génie avec moins de 5 pronostics verrouillés par défaut.
- [ ] Bon résultat rare sans exact peut déclencher un Génie.
- [ ] Barème 10-20%=1, 5-10%=3, 2-5%=5, <2%=7, unique=10.
- [ ] Exact rare ajoute +2 sans dépasser 10.
- [ ] Cote fiable peut renforcer le score, plafond 10.
- [ ] Exact courant n'est pas automatiquement un Génie.
- [ ] +7/+10 peut être annoncé au Nid.
- [ ] Classement Génie séparé.

## 10. Records
- [ ] Records personnels et Records du Nid sont distincts.
- [ ] Le premier détenteur conserve une égalité.
- [ ] Le joueur qui égale reçoit `Record égalé`.
- [ ] Lorsqu'un record est battu, le nouveau et l'ancien détenteur sont notifiés.
- [ ] Historique complet conservé ; interface = 5 derniers + Voir tout.
- [ ] Catégories de records modifiables par Super Admin.

## 11. Narration du Hibou
- [ ] Les familles principales possèdent environ 40 formulations chacune.
- [ ] Les phrases de 0 / 3 / 5 / 7 points changent et restent contextuelles.
- [ ] Résumé journée/soirée varie selon performance.
- [ ] Variation de classement peut être commentée.
- [ ] Rivalité victoire/défaite/nul varie.
- [ ] Badges, secrets, records, Casseroles, Génie, champions, Teams et rappels varient.
- [ ] Le moteur évite les formulations récemment utilisées côté joueur.
- [ ] Les boutons/libellés fonctionnels restent fixes.

## 12. Laboratoire Gamification
- [ ] Activation/désactivation TEST.
- [ ] Génération de faux pronostics par pourcentages.
- [ ] Simulation immédiate du score final.
- [ ] Test d'une condition de badge sur un joueur.
- [ ] Notification TEST ciblée Super Admin ou joueur choisi, jamais de blast global réel.
- [ ] Nettoyage supprime badges/événements/records TEST mais garde l'audit.

## 13. Notifications / Push
- [ ] Préférences Badges, Records et Gamification présentes.
- [ ] Deep links vers le Musée.
- [ ] Push immédiat fonctionne après redéploiement de `push-dispatch`.
- [ ] Aucun besoin de régénérer les clés VAPID.

## 14. Clôture saison
- [ ] Prévisualisation avant clôture.
- [ ] Poêle d'Or départagée : points > nucléaires > industrielles > belles ; égalité restante = co-gagnants.
- [ ] Génie de saison et records définitifs visibles dans l'aperçu.
- [ ] Clôture manuelle gèle la gamification.
- [ ] Réouverture exige un motif et produit un audit.

## Limite volontaire de V0.7.0
Certains badges du catalogue initial utilisent des données prévues dans des versions ultérieures (notamment Hibou solitaire/soirées avancées et certains historiques de carrière). Ils restent visibles et administrables, mais leur attribution automatique demeure désactivée tant que leur source métier n'est pas disponible.
