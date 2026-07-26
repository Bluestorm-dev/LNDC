# Checklist V0.4.1 — UX/UI + Champions dans Profil

## Migration
- [ ] Base déjà en V0.4.0
- [ ] Aucun SQL supplémentaire exécuté
- [ ] `VERSION` = `0.4.1`
- [ ] cache service worker = `nid-champions-v0.4.1`

## Navigation desktop
- [ ] sidebar visible
- [ ] Accueil ouvre Accueil
- [ ] Pronostics ouvre la phase de ligue
- [ ] Phases finales ouvre le tableau KO
- [ ] Classements ouvre les classements
- [ ] Saison ouvre la saison
- [ ] Profil ouvre Profil & champions
- [ ] Admin visible uniquement Admin/Super Admin
- [ ] cartouche joueur de sidebar ouvre Profil
- [ ] élément actif clairement visible

## Navigation mobile
- [ ] sidebar masquée
- [ ] barre basse visible
- [ ] 6 entrées utilisables sans scroll horizontal
- [ ] contenu non masqué derrière la barre basse

## Fond / identité visuelle
- [ ] aucun motif répétitif de petits points
- [ ] fond bleu nuit stable au scroll
- [ ] halos/courbes non gênants pour la lecture
- [ ] contraste suffisant des textes et boutons
- [ ] pas d’image de fond externe

## Accueil épuré
- [ ] aucune liste complète de matchs sur Accueil
- [ ] rang affiché
- [ ] points affichés
- [ ] progression de journée affichée
- [ ] prochain match affiché
- [ ] logos des deux clubs visibles
- [ ] prono personnel affiché si déjà saisi
- [ ] bouton vers Pronostics fonctionnel
- [ ] match de phase finale renvoie vers Phases finales
- [ ] résumé Champion 1 visible
- [ ] résumé Champion 2 visible
- [ ] message Hibou visible

## Profil
- [ ] pseudo modifiable
- [ ] club de cœur modifiable
- [ ] bibliothèque de clubs toujours proposée
- [ ] cartouche sidebar mis à jour après sauvegarde du profil

## Champion n°1
- [ ] bloc présent DANS Profil
- [ ] bonus +100 affiché
- [ ] liste des clubs disponible tant que le choix est ouvert
- [ ] enregistrement fonctionnel
- [ ] choix personnel visible après sauvegarde
- [ ] autres choix cachés avant verrouillage
- [ ] OM par défaut clairement expliqué
- [ ] état OM par défaut visible lorsqu'il est attribué
- [ ] état éliminé visible si le club sort

## Champion n°2
- [ ] bloc présent DANS Profil
- [ ] bonus +50 affiché
- [ ] fermé avant sa fenêtre d'ouverture
- [ ] candidats disponibles lorsque la fenêtre s'ouvre
- [ ] enregistrement fonctionnel
- [ ] même club que Champion n°1 autorisé
- [ ] choix caché avant verrouillage

## Non-régression V0.4.0
- [ ] saisie A1 → B1 → A2
- [ ] saisie B1 → A1 → A2
- [ ] +/- ne déplace pas le focus
- [ ] autosave fonctionne
- [ ] logos clubs corrects
- [ ] cotes 1N2 toujours affichées si disponibles
- [ ] classement Realtime fonctionne
- [ ] LIVE Admin fonctionne
- [ ] barrages aller/retour fonctionnent
- [ ] cumul fonctionne
- [ ] score à 120 minutes fonctionne
- [ ] tirs au but fonctionnent
- [ ] qualifié +3/+1 fonctionne
- [ ] multiplicateurs x1/x2/x3/x4 fonctionnent
- [ ] finale match unique fonctionne
