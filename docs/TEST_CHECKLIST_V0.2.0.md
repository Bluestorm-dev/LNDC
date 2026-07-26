# Checklist de validation — V0.2.0

## Installation
- [ ] Patch SQL V0.2.0 exécuté sans erreur.
- [ ] `login-by-username` toujours fonctionnelle.
- [ ] `sync-football-data` déployée.
- [ ] `FOOTBALL_DATA_API_KEY` configurée si synchronisation automatique utilisée.
- [ ] Cache PWA renouvelé en V0.2.0.

## Journées
- [ ] Plusieurs journées apparaissent dans le sélecteur.
- [ ] Le changement de journée recharge les bons matchs.
- [ ] La progression est différente pour chaque journée.
- [ ] Le calendrier Saison ouvre la bonne journée.

## Pronostics
- [ ] Joueur peut pronostiquer.
- [ ] Admin peut pronostiquer.
- [ ] Super Admin peut pronostiquer.
- [ ] `+/-` fonctionne.
- [ ] À 5 buts domicile, le focus passe au score extérieur.
- [ ] Il reste possible de dépasser 5.
- [ ] Autosauvegarde visible.
- [ ] Prono bloqué au coup d'envoi.
- [ ] Journée complète affiche le message du Hibou.

## Résultats
- [ ] Admin peut passer LIVE.
- [ ] Admin peut terminer un match.
- [ ] Le résultat recalcule les points.
- [ ] 0 / 3 / 5 / 7 vérifié sur quatre scénarios.
- [ ] Annulation donne 0 impact.
- [ ] Report + nouvelle date conserve le prono et le rend modifiable si la nouvelle date est future.
- [ ] Réouverture remet les points du match à 0 jusqu'au nouveau résultat.

## Historique
- [ ] Match terminé apparaît dans Mon historique.
- [ ] Score pronostiqué correct.
- [ ] Résultat correct.
- [ ] Points corrects.
- [ ] Modification d'un prono crée une entrée dans `prediction_history`.

## Clubs / logos
- [ ] Bouton Clubs + logos fonctionne.
- [ ] Logos apparaissent sur les cartes.
- [ ] Storage `club-logos` contient les images récupérées quand possible.
- [ ] Fallback distant utilisé si aucun fichier local n'a pu être copié.
- [ ] Bouton Calendrier CL crée/import les journées 1 à 8 si l'API les expose.

## Mobile
- [ ] Sélecteur de journées scrollable.
- [ ] Cartes matchs lisibles.
- [ ] `+/-` utilisables sans chevauchement.
- [ ] Historique lisible.
- [ ] Barre basse toujours accessible.
