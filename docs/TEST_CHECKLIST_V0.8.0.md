# Checklist de validation — V0.8.0

## Installation
- [ ] Exécuter HOTFIX_V0.8.0_EXISTING_DB.sql sans erreur.
- [ ] Redéployer sync-football-data.
- [ ] Vérifier APP_VERSION = 0.8.0 et le cache PWA V0.8.0 avant passage en 0.8.1.

## Centre Ligue des champions
- [ ] L’onglet Ligue des champions apparaît sur desktop et mobile.
- [ ] Les onglets Vue d’ensemble / Classement / Calendrier & résultats / Phases finales / Clubs fonctionnent.
- [ ] Admin > Compétition > Centre C1 synchronise la saison 2026/27 quand Football-Data la publie.
- [ ] Une saison 2025/26 renvoyée par le fournisseur n’est jamais utilisée à la place de 2026/27.
- [ ] Si Football-Data renvoie 404 pour 2026/27, la base reste vide et aucun match 2025/26 n’est importé.
- [ ] Le classement affiche les zones 1–8 / 9–24 / 25–36.
- [ ] Cliquer sur un club ouvre sa fiche.
- [ ] La fiche club affiche classement, points, V-N-D, différence, forme, 5 derniers et 5 prochains matchs.
- [ ] Les résultats réels du Centre C1 n’altèrent pas directement le barème de pronostics.

## Soirées européennes
- [ ] L’onglet Soirées s’ouvre sur la soirée pertinente.
- [ ] Avant soirée : compteur de pronostics affiché.
- [ ] Pendant : classement provisoire et points de soirée visibles.
- [ ] Après : score, rang, exacts et narration du Hibou visibles.
- [ ] Le meilleur joueur est présenté comme Hibou de la nuit.
- [ ] Les statistiques collectives affichent joueurs, pronostics, exacts, moyenne de points, casseroles, Génies et choix solitaires.
- [ ] Le carrousel Moments du Nid affiche uniquement les événements réellement présents.
- [ ] La carte contextuelle de soirée apparaît sur l’accueil dans la fenêtre prévue (36 h avant / LIVE / 48 h après).
- [ ] Les soirées précédentes sont accessibles dans Archives.

## Hibou solitaire
- [ ] Choix unique correct = 10 points parallèles.
- [ ] Deux joueurs corrects = 7 points parallèles chacun.
- [ ] Groupe <= 5 % correct = 5 points parallèles.
- [ ] Un mauvais choix minoritaire ne rapporte rien.
- [ ] Les points Hibou solitaire ne changent jamais le classement officiel.

## Votes mensuels
- [ ] Super Admin peut ouvrir un vote Casserole ou Génie depuis Admin > Gamification.
- [ ] Au moins deux candidats sont requis.
- [ ] Un joueur ne possède qu’un vote par sondage mais peut le changer tant que le vote est ouvert.
- [ ] Le Super Admin peut fermer le vote.

## Mobile
- [ ] Barre de navigation inférieure défilable horizontalement.
- [ ] Centre C1 lisible à 360–430 px.
- [ ] Tableau de classement défile horizontalement sans casser la page.
- [ ] Fiche club et soirées restent utilisables sans zoom manuel.
