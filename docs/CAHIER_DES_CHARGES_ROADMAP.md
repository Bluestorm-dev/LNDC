# Le Nid des Champions
## Cahier des charges produit & roadmap vers la V1.0.0

> **Statut : cadrage validé**
>
> Nouvelle PWA indépendante du *Nid des Pronos 2026*, avec nouvelle base Supabase, nouvelle charte graphique inspirée de l'univers de la Ligue des champions, architecture multi-saisons et nouveau système de jeu.
>
> Le projet conserve l'ADN du Nid : **le Hibou masqué, l'humour, les badges, les casseroles, les records, le live et la gamification**.

---

# 1. Vision du produit

Le Nid des Champions n'est pas une simple copie du Nid des Pronos avec un nouveau thème.

L'objectif est de créer une application de pronostics plus ambitieuse, plus propre techniquement et plus riche en animation, conçue pour une compétition longue d'environ neuf mois.

Principe UX central :

> **L'expérience autour du pronostic peut être très riche, mais faire son pronostic doit rester extrêmement rapide.**

Le projet est pensé dès le départ pour être :
- public ;
- multi-saisons ;
- responsive ;
- PWA ;
- administrable ;
- évolutif ;
- compatible à terme avec une API football ;
- exploitable plusieurs années sans reconstruire la base.

---

# 2. Identité

## Nom
**Le Nid des Champions**

## Univers graphique
- ambiance Ligue des champions premium ;
- environ 70 % prestige européen / 30 % esport ;
- fond sombre / bleu nuit ;
- bleu électrique, violet, or et argent ;
- étoiles, halos, lumière de stade ;
- animations spectaculaires ;
- interface sombre uniquement ;
- Hibou masqué conservé ;
- Nid conservé mais traité comme un emblème sportif premium.

## Son
Pas de sons dans la première version.

---

# 3. Architecture technique

Projet entièrement nouveau :
- nouvelle PWA ;
- nouveau dépôt ;
- nouvelle base Supabase ;
- nouveau service worker ;
- nouveau cache ;
- nouvelle architecture SQL ;
- aucune dépendance fonctionnelle au Supabase du Nid 2026.

Architecture **multi-saisons dès le départ**.

Exemples :
- 2026-27 ;
- 2027-28 ;
- 2028-29.

Chaque donnée métier importante devra être rattachée à une `season_id`.

Préparation dès la V1 pour deux sources de données match :
- `manual`
- `api`

Une donnée API pourra toujours être corrigée manuellement par un administrateur.

Toutes les modifications sensibles seront journalisées.

---

# 4. Comptes et authentification

## Inscription
- inscription publique ;
- validation par e-mail ;
- possibilité de fermer les inscriptions depuis l'administration ;
- protection anti-abus prévue.

## Connexion
L'utilisateur se connecte avec :
- son pseudo ;
- son mot de passe.

Une véritable adresse e-mail est stockée pour :
- validation ;
- récupération de mot de passe.

Elle n'est jamais affichée publiquement.

## Mot de passe oublié
Deux possibilités :
1. récupération automatique par e-mail ;
2. demande au Hibou masqué / Super Admin.

## Pseudo
- modifiable ;
- identité principale visible de l'utilisateur.

## Prénom réel
- facultatif ;
- visible uniquement par Admin / Super Admin.

## Profil public
Le profil peut afficher :
- pseudo ;
- avatar ;
- club de cœur ;
- team ;
- classement ;
- points ;
- moyenne ;
- badges ;
- records ;
- casseroles ;
- coups de génie ;
- Hibou solitaire ;
- historique de classement ;
- statistiques de saison ;
- statistiques carrière.

---

# 5. Avatars

Deux possibilités :
- upload personnel ;
- bibliothèque officielle d'avatars du Nid des Champions.

Une bibliothèque spécifique au thème Ligue des champions sera créée.

Les avatars uploadés sont libres mais modérables par Admin / Super Admin.

---

# 6. Club de cœur

Chaque joueur peut choisir un club de cœur indépendamment des clubs engagés dans la compétition.

Exemple :
> Club de cœur : Stade Brestois

Le club de cœur :
- est purement identitaire ;
- n'influence pas les points ;
- peut ne pas participer à la Ligue des champions.

---

# 7. Rôles

Rôles applicatifs :

1. **Joueur**
2. **Capitaine**
3. **Admin**
4. **Super Admin**

Un Admin ou Super Admin peut également être capitaine.

Les admins ont globalement les mêmes droits administratifs.

Le Super Admin conserve les fonctions réservées :
- gestion générale ;
- réponses officielles du Hibou ;
- opérations sensibles ;
- distinctions manuelles ;
- gestion des admins ;
- maintenance ;
- export / sauvegardes.

---

# 8. Pronostics — barème principal

Barème de base :

| Résultat | Points |
|---|---:|
| Mauvais résultat | 0 |
| Bon vainqueur ou bon match nul | 3 |
| Bon résultat + bon écart | 5 |
| Score exact | 7 |

Exemple :
- prono 2-0, réel 3-1 : 5 points ;
- prono 1-1, réel 3-3 : 5 points ;
- prono 2-1, réel 2-1 : 7 points.

Le système n'additionne pas plusieurs bonus pour un même score : chaque match entre dans une catégorie principale.

---

# 9. Multiplicateurs de phases

Le Super Admin peut configurer un multiplicateur pour certaines phases ou certains matchs.

Exemple :
- ×1 ;
- ×2 ;
- ×3 ;
- ×4.

La finale peut donc être doublée, triplée ou quadruplée sans modifier le code.

Le multiplicateur doit être visible clairement avant verrouillage.

---

# 10. Saisie des pronostics

Interaction conservée depuis le Nid 2026 :
- boutons `+` et `-` ;
- autosauvegarde ;
- indicateur `✓ enregistré`.

## Ergonomie score
Lorsque le joueur atteint 5 buts pour une équipe :
- le focus passe automatiquement au score adverse ;
- le joueur peut néanmoins revenir et continuer jusqu'à 15-0 ou plus.

## Verrouillage
- modification autorisée jusqu'au coup d'envoi ;
- verrouillage automatique en temps réel ;
- compte à rebours visible dans les 10 dernières minutes.

Un badge secret pourra récompenser un pronostic modifié dans les toutes dernières secondes.

## Complétion
Chaque journée affiche :
> 14 / 18 pronostics enregistrés

Lorsque tous les matchs sont remplis :
- animation ;
- message humoristique du Hibou.

---

# 11. Journées UEFA

Les matchs sont organisés par **journée de championnat**, et non simplement par jour calendaire.

Navigation :
- J1 ;
- J2 ;
- J3 ;
- …
- J8.

À l'intérieur :
- mardi ;
- mercredi ;
- éventuellement autres dates si calendrier exceptionnel.

Filtres :
- Tous ;
- À pronostiquer ;
- Live ;
- Terminés.

Bouton rapide :
> **Pronostiquer toute la journée**

---

# 12. Matchs reportés et annulés

## Reporté
- le prono existant est conservé ;
- le match est déverrouillé ;
- nouvelle échéance calculée à partir de la nouvelle date.

## Annulé
- pronostic neutralisé ;
- aucune incidence sur points, moyenne, records ou statistiques.

---

# 13. Matchs à élimination directe

Les confrontations aller-retour disposent de :
- score aller ;
- score retour ;
- score cumulé ;
- qualifié ;
- statistiques cumulées ;
- historique des pronostics.

## Score pronostiqué
Pour un match pouvant aller en prolongation :
- le pronostic porte sur le score à 120 minutes ;
- en cas d'égalité, sélection obligatoire du qualifié.

## Bonus qualifié
Base actuelle :
> **+3 points**

Le système exact reste volontairement configurable avant lancement.

Piste privilégiée :
- choix du qualifié avant l'aller = valeur maximale ;
- possibilité de changer avant le retour = valeur réduite.

Cette mécanique pourra faire l'objet d'un sondage avant activation.

---

# 14. Champions de la compétition

## Premier champion
- choisi avant le coup d'envoi du premier match ;
- valeur : **100 points** ;
- rappel à chaque connexion tant qu'il manque.

Si aucun champion n'a été choisi au verrouillage :
> **Olympique de Marseille** est attribué automatiquement.

## Deuxième champion
- ouverture après la phase de ligue ;
- verrouillage avant les barrages ;
- valeur : **50 points**.

Le même club peut être choisi deux fois.

Donc un joueur peut faire un all-in potentiel à **150 points**.

## Confidentialité
Les choix sont cachés jusqu'à leur verrouillage.

## Élimination
Message humoristique automatique du Hibou.

Exemple :
> « Tu aurais dû choisir Marseille. Au moins, tu étais sûr dès le départ de n'avoir aucune chance. »

---

# 15. Teams personnalisées — cadrage V0.5.0 verrouillé

Les anciens systèmes Bureau et Famille disparaissent.

Chaque joueur ne peut appartenir qu'à **une seule Team active par saison**.
Le changement de Team est libre pour la première saison mais toutes les périodes d'appartenance sont historisées.
Les points d'un joueur restent attribués à la Team dont il faisait partie **au coup d'envoi du match** : aucun transfert de points rétroactif.

## Création
- nom obligatoire et unique dans la saison (3 à 30 caractères) ;
- slogan facultatif (80 caractères max.) ;
- description courte facultative (160 caractères max.) ;
- équipe fétiche facultative, choisie dans toute la bibliothèque de clubs, même hors Ligue des champions ;
- Team publique ou privée ;
- logo issu de la bibliothèque du Nid ou upload personnel ;
- aperçu visuel en direct.

L'équipe fétiche est purement identitaire : elle ne donne aucun point et ne modifie pas les clubs de cœur personnels.

## Identité visuelle
La Team doit être reconnaissable immédiatement autour de l'avatar de chacun de ses membres.

Le capitaine choisit :
- une forme : cercle, médaillon, carré arrondi, carré prestige, losange, hexagone, écusson classique, écusson pointu, bouclier moderne, bannière, blason royal ou carte prestige ;
- un cadre / une matière : bois, bronze, argent, or, or royal, acier, cuir, obsidienne, néon, Champions, Royal bleu/or ou Nuit européenne ;
- une couleur principale ;
- une couleur secondaire ;
- un fond : uni, vertical, horizontal, diagonal, radial ou halo ;
- un logo Team.

L'avatar personnel reste au premier plan. Le cadre, la forme et les couleurs de la Team constituent son habillage de fond.
Une modification de l'identité Team se propage automatiquement à tous les membres.
La lisibilité du pseudo et des informations reste contrôlée par l'interface.

## Capitaine
Le créateur devient automatiquement capitaine.
Il n'y a **qu'un seul capitaine** par Team.
Le capitanat est un statut de Team, pas un rôle global de compte.

Le capitaine peut :
- modifier l'identité et l'apparence ;
- gérer l'équipe fétiche ;
- accepter/refuser les demandes privées ;
- générer/révoquer un code d'invitation ;
- exclure un membre ;
- transférer le capitanat ;
- dissoudre la Team.

Pour quitter sa Team, le capitaine doit d'abord transférer son rôle, sauf s'il dissout une Team dont il est le dernier membre.

## Public / privé
### Publique
Un joueur sans Team peut la rejoindre immédiatement.

### Privée
Deux entrées possibles :
1. demande d'adhésion acceptée/refusée par le capitaine ;
2. code d'invitation actif fourni par le capitaine.

## Taille et changements
- pas de limite de membres pour la première saison ;
- une seule Team active par joueur ;
- pas de mercato en V1 ;
- toutes les entrées/sorties, exclusions et transferts de capitanat sont historisés.

## Historique
Conserver au minimum :
- création ;
- arrivée ;
- départ ;
- exclusion ;
- demande acceptée/refusée ;
- transfert de capitanat ;
- modification d'identité ;
- changement d'équipe fétiche ;
- public/privé ;
- dissolution.

## Dissolution
Une Team dissoute n'est jamais physiquement supprimée.
Elle conserve son historique et son palmarès avec le statut :
> **Team dissoute**

---

# 16. Classements Teams

Trois modes V0.5.0 :
- **moyenne globale** : classement principal, pour ne pas favoriser mécaniquement les gros effectifs ;
- **Top 3** : somme des trois meilleurs contributeurs (ou de tous les membres disponibles si moins de trois) ;
- **journée UEFA** : performance Team limitée à la journée sélectionnée.

Les points gagnés avant un changement de Team restent attachés à l'ancienne Team.

---

# 17. Classement individuel

Classements prévus :
- général ;
- phase de ligue ;
- barrages ;
- huitièmes ;
- quarts ;
- demi-finales ;
- finale ;
- mois ;
- journée UEFA ;
- soirée ;
- précision ;
- scores exacts ;
- teams.

## Départage
1. points ;
2. scores exacts ;
3. moyenne ;
4. bons écarts ;
5. nombre de pronostics joués.

Les rangs restent uniques : #1, #2, #3…

## Live
- rang actuel ;
- évolution ;
- écart avec les voisins ;
- projection live ;
- ligne personnelle sticky.

## Historique
- rang après chaque journée ;
- plus grosse remontée ;
- plus grosse chute ;
- meilleure position ;
- pire position ;
- durée sur le podium ;
- durée en tête.

---

# 18. Rival principal

Chaque joueur peut choisir **un rival principal**.

Le rival :
- n'a pas besoin d'accepter ;
- est visible publiquement ;
- ne donne aucun point.

Fonctions :
- comparaison directe ;
- score de soirée ;
- classement ;
- exacts ;
- casseroles ;
- génie ;
- historique des duels ;
- courbes superposées.

---

# 19. Soirées européennes

Élément majeur du nouveau Nid.

## Avant
> Journée 4  
> 13/18 pronostics  
> Prochain verrouillage dans 3 h 42

## Pendant
> 7 matchs en cours  
> #4 provisoire ▲2

## Après
> 29 points  
> #3 de la soirée  
> +2 places  
> 1 score exact  
> 1 casserole

Le résumé reste accessible environ **1 à 2 jours**, puis est archivé dans Saison.

## Classements
- classement de soirée ;
- classement de journée UEFA.

## Hibou de la nuit
Distinction temporaire du meilleur joueur de la soirée.

## Résumé automatique
> 18 matchs  
> 267 pronostics  
> 21 scores exacts  
> 43 casseroles  
> 1 Hibou solitaire victorieux

---

# 20. Pronostics des autres

Avant verrouillage :
- cachés.

Après verrouillage :
- visibles ;
- répartition victoire / nul / défaite ;
- scores les plus joués ;
- choix individuels ;
- statistiques du Nid.

---

# 21. Hibou solitaire

Deux situations :
- seul joueur à faire un choix ;
- groupe très minoritaire.

Aucun effet sur les vrais points.

## Score parallèle
Exemple :
- seul : 10 ;
- 2 joueurs : 7 ;
- ≤ 5 % : 5.

Classement dédié.

---

# 22. Casseroles 2.0

Les casseroles deviennent une mécanique parallèle.

Types possibles :
- résultat inversé ;
- écart monumental ;
- favori massacré ;
- mauvais choix solitaire ;
- champion éliminé ;
- série de zéros ;
- énorme retournement ;
- mauvaise foi ;
- événement humoristique manuel.

## Attribution
- automatique ;
- manuelle par Super Admin.

## Points fictifs
Exemple :
- petite : +1 ;
- belle : +3 ;
- industrielle : +5 ;
- nucléaire : +10.

## Titres
- Casserole de la soirée ;
- Casserole du mois ;
- Musée des casseroles ;
- **Poêle d'Or** de fin de saison.

La Casserole du mois peut être choisie par vote.

---

# 23. Coups de génie

Mécanique miroir :
- score improbable exact ;
- victoire outsider ;
- unique bon résultat ;
- retournement anticipé ;
- performance rare.

Points de génie séparés.

Coup de génie du mois soumis au vote.

---

# 24. Badges

Objectif : environ **100 badges**.

## ⚪ Communs
Premiers pas, premiers pronostics, premiers exacts, première journée complète, première team, première casserole…

## 🔵 Rares
Séries, précision, régularité, bonnes phases, remontées, outsiders…

## 🟣 Épiques
Très grosses performances, longues séries, Hibou solitaire victorieux, domination de phase…

## 🟡 Légendaires
Exemples :

### Le Prophète
5 scores exacts lors d'une même journée UEFA.

### Seul contre le Nid
Être l'unique joueur à choisir un vainqueur et avoir raison.

### Le Nid t'appartient
Cumuler 100 jours en tête.

### Nuit parfaite
Obtenir des points sur tous les matchs d'une grande soirée avec plusieurs scores exacts.

### Oracle européen
Enchaîner plusieurs résultats très improbables correctement.

### Immortel
Compléter plusieurs saisons sans abandonner de pronostics.

Certains légendaires pourront ne jamais être débloqués.

## Secrets
La majorité des badges spéciaux sont cachés.

Avant obtention :
> ???

Après :
- nom ;
- description ;
- date ;
- rareté ;
- contexte.

## Progression
Pour les badges connus :
> 7 / 10 scores exacts

## Saisonnier
Certains badges sont exclusifs à une saison.

## Carrière
Certains récompensent plusieurs saisons.

Un badge gagné n'est jamais retiré.

Pas de badges équipés.

---

# 25. Mini-records

Prévoir :
- points ;
- moyenne ;
- exacts ;
- bons résultats ;
- bons écarts ;
- qualifiés ;
- séries ;
- meilleure journée ;
- meilleur mardi ;
- meilleur mercredi ;
- meilleur mois ;
- présence en tête ;
- remontée ;
- chute ;
- aller-retour ;
- outsider ;
- Hibou solitaire ;
- génie ;
- casserole.

Notification :
> **RECORD DU NID**

---

# 26. Le Hibou masqué

Personnalité :
- sarcastique ;
- taquine ;
- chaleureuse ;
- parfois mordante.

Zone dédiée sur l'accueil, séparée du carrousel.

## Messages
- prioritaire ;
- historique ;
- automatiques ;
- manuels ;
- personnalisés.

## Écrire au Hibou
Types :
- bug ;
- suggestion ;
- question ;
- demande de modification ;
- autre.

Avec :
- sujet ;
- message ;
- capture.

Statuts :
- reçu ;
- lu ;
- en cours ;
- corrigé ;
- clos / rejeté.

Le Super Admin répond sous l'identité du Hibou masqué.

Une suggestion peut être transformée en sondage.

---

# 27. Sondages

Conservés mais utilisés avec parcimonie :
- multiplicateur ;
- règle qualifié ;
- suggestion ;
- Casserole du mois ;
- Coup de génie du mois.

---

# 28. Notifications PWA

Catégories :
- pronostics manquants ;
- champion absent ;
- journée imminente ;
- match imminent ;
- résultat ;
- record ;
- badge ;
- rival ;
- classement ;
- team ;
- Hibou ;
- réponse du Hibou ;
- sondage.

Rappels configurables :
- 24 h ;
- 3 h ;
- 1 h ;
- 30 min.

Un rappel de pronostic n'est envoyé que s'il manque réellement quelque chose.

Quiet hours activables.

---

# 29. Live et scores

Au démarrage :
> **saisie manuelle**

Préparation pour API future.

Admin / Super Admin peut mettre à jour :
- score ;
- but ;
- carton ;
- mi-temps ;
- prolongation ;
- fin ;
- tirs au but ;
- qualifié.

Classement live recalculé en Realtime.

Mention :
> 🔴 LIVE — classement provisoire

---

# 30. Pages match

## Avant
- clubs ;
- logos ;
- heure française ;
- stade ;
- prono ;
- verrouillage ;
- compte à rebours.

Pas de chaîne TV.

## Pendant
- score live ;
- répartition des pronos ;
- scores les plus joués ;
- pronostics des autres ;
- rival ;
- statistiques du Nid.

## Après
- points ;
- exacts ;
- Hibou solitaire ;
- casserole ;
- coup de génie ;
- statistiques finales.

---

# 31. Accueil dynamique

## Avant
- journée ;
- progression ;
- matchs manquants ;
- compte à rebours ;
- bouton principal.

## Live
- matchs en cours ;
- classement provisoire ;
- variation.

## Après
- performance ;
- rang soirée ;
- mouvement ;
- exacts ;
- casseroles ;
- badge éventuel.

## Carrousel
- records ;
- badges ;
- performances ;
- casseroles ;
- génie ;
- Hibou solitaire.

Le Hibou reste hors carrousel.

---

# 32. Navigation

## Desktop
Base envisagée :
- Accueil ;
- Pronostics ;
- Classements ;
- Saison ;
- Teams ;
- Records.

## Mobile
Barre basse :
- Accueil ;
- Matchs ;
- Classement ;
- Saison ;
- Profil.

Badge de navigation pour pronostics manquants.

Bouton flottant :
> **7 pronostics manquants**

---

# 33. Visiteur non connecté

Peut consulter :
- classement ;
- résultats ;
- records.

---

# 34. Podium et champion en titre

Top 3 premium.

La saison suivante :
> 🏆 Champion en titre

Reconnaissance possible du gagnant Coupe du monde 2026.

---

# 35. Statistiques collectives

- fiabilité du Nid ;
- score le plus joué ;
- club préféré ;
- club maudit ;
- bourreau du Nid ;
- majorité collective ;
- grosses erreurs collectives.

---

# 36. Statistiques personnelles

- points ;
- moyenne ;
- exacts ;
- bons résultats ;
- bons écarts ;
- qualifiés ;
- journées ;
- oublis ;
- rang ;
- forme ;
- historique ;
- meilleures / pires périodes ;
- casseroles ;
- génie ;
- Hibou solitaire ;
- records ;
- rival.

Forme récente ludique, sans effet sur les vrais points.

---

# 37. Multi-saisons et carrière

Profil carrière :
- saisons jouées ;
- points carrière ;
- moyenne carrière ;
- scores exacts carrière ;
- badges carrière ;
- records ;
- podiums ;
- titres.

Classement carrière prévu.

Records séparés :
- record saison ;
- record historique.

---

# 38. Hall of Fame

- champion ;
- podium ;
- meilleure team ;
- meilleur scoreur ;
- meilleur exact ;
- Poêle d'Or ;
- génie ;
- Hibou solitaire ;
- records ;
- champions historiques.

---

# 39. Replay de saison

Timeline septembre → juin :
- records ;
- changements de leader ;
- soirées historiques ;
- casseroles ;
- badges légendaires ;
- champions éliminés ;
- finale.

---

# 40. Fin de saison

Prévue dès la conception :
- PDF collector ;
- diplôme ;
- Hall of Fame ;
- replay ;
- Livre d'or ;
- statistiques finales ;
- export administrateur ;
- archivage.

Les PDF seront pensés A4 dès le départ.

---

# 41. Administration

Dashboard :
- joueurs ;
- nouveaux inscrits ;
- actifs ;
- pronostics ;
- journées ;
- matchs ;
- scores ;
- erreurs ;
- notifications ;
- messages Hibou ;
- tickets ;
- sondages ;
- teams.

## Super Admin
- admins ;
- maintenance ;
- feature flags ;
- impersonation ;
- distinctions ;
- multiplicateurs ;
- saison ;
- export ;
- corrections.

## Feature flags
Exemples :
- Rivalités ON/OFF ;
- Sondages ON/OFF ;
- API ON/OFF ;
- Missions OFF ;
- Hibou solitaire ON/OFF.

---

# 42. Impersonation

Admin / Super Admin peut afficher l'application comme un joueur pour débogage.

Aucun mot de passe nécessaire.

Toutes les utilisations sont journalisées.

---

# 43. Logs et audit

Journaliser :
- scores ;
- source API/manuelle ;
- modifications ;
- teams ;
- capitanat ;
- admins ;
- badges manuels ;
- casseroles manuelles ;
- configuration ;
- impersonation.

---

# 44. Suppression de compte

Demande joueur puis traitement Admin.

Les règles d'anonymisation seront finalisées avant ouverture publique.

---

# 45. Installation PWA

Interface d'installation dédiée :
> **Installer Le Nid des Champions**

Pas de saisie offline en V1.

---

# 46. Fonctions volontairement absentes

- messagerie entre joueurs ;
- Bureau ;
- Famille ;
- coupons ;
- badges équipés ;
- sons ;
- chaînes TV ;
- saisie offline ;
- jokers personnels ;
- prise de pari / mise financière (toujours hors périmètre) ;
- affichage informatif des cotes 1N2 : intégré en V0.3.2.

---

# 47. Points encore ouverts

1. système exact du qualifié aller-retour ;
2. classement Team final ;
3. header final ;
4. API football ;
5. flux exact d'adhésion aux teams privées.

Ces points ne bloquent pas le développement.

---

# 48. Roadmap jusqu'à la V1.0.0

## V0.1.0 — Le nouveau Nid
**Socle technique**
- dépôt ;
- Supabase ;
- PWA ;
- charte ;
- multi-saisons ;
- auth ;
- profils ;
- rôles ;
- navigation ;
- service worker ;
- feature flags.

**Critère de sortie :** on peut s'inscrire, se connecter et entrer dans le Nid.

---

## ✅ V0.2.0 — Phase de ligue & pronostics
- journées UEFA ;
- clubs ;
- calendrier ;
- cartes matchs ;
- saisie ;
- autosauvegarde ;
- verrouillage ;
- progression ;
- reports/annulations ;
- 0/3/5/7 ;
- recalcul serveur ;
- historique.

**Critère de sortie :** une journée complète peut être jouée.

**Statut : livré en V0.2.0.**

---

## ✅ V0.3.0 — Classements & live
- général ;
- départages ;
- variations ;
- sticky player ;
- journée ;
- soirée ;
- précision ;
- exacts ;
- saisie Admin ;
- Realtime ;
- live ;
- statistiques collectives.

**Critère de sortie :** une soirée peut être vécue en direct.

**Statut : livré en V0.3.0.**

---

## V0.4.0 — Champions & phases finales
- champion 100 ;
- OM par défaut ;
- deuxième champion 50 ;
- choix cachés ;
- éliminations ;
- aller-retour ;
- cumul ;
- 120 minutes ;
- tirs au but ;
- qualifié ;
- bonus ;
- multiplicateurs.

**Critère de sortie :** toute la compétition est couverte.

---

## V0.5.0 — Teams
- création et annuaire ;
- une seule Team active par joueur ;
- équipe fétiche facultative ;
- logo bibliothèque ou upload ;
- 12 formes ;
- 12 cadres / matières (bois, or, argent, bronze, acier, cuir, obsidienne, néon...) ;
- couleurs et fonds/dégradés ;
- habillage Team autour des avatars des membres ;
- capitaine unique ;
- transfert de capitanat ;
- Teams publiques ;
- Teams privées par demande ou code ;
- historique complet ;
- changements sans transfert rétroactif des points ;
- dissolution archivée ;
- classements moyenne / Top 3 / journée ;
- Admin Teams ;
- Realtime ;
- Hibou masqué officiel intégré au site et au manifeste des assets.

**Critère de sortie :** une Team peut être créée, personnalisée, rejointe, gérée et classée, avec identité visuelle propagée aux membres et historique cohérent.

---

## V0.6.0 — Hibou, rivalités & notifications
- Hibou ;
- messages ;
- rival ;
- comparaison ;
- duels ;
- tickets ;
- captures ;
- réponses ;
- notifications push ;
- rappels ;
- quiet hours.

**Critère de sortie :** le Nid réagit et communique.

---

## V0.7.0 — Badges, records & casseroles
- moteur badges ;
- raretés ;
- secrets ;
- progression ;
- saisonniers ;
- carrière ;
- ~100 badges ;
- records ;
- casseroles ;
- points casserole ;
- Poêle d'Or ;
- génie ;
- Musée.

**Critère de sortie :** la gamification principale est complète.

---

## V0.8.0 — Hibou solitaire & soirées
- détection ;
- score parallèle ;
- classement ;
- Hibou de la nuit ;
- résumé ;
- accueil contextuel ;
- carrousel ;
- statistiques soirée ;
- votes mensuels.

**Critère de sortie :** chaque soirée produit sa propre histoire.

---

## V0.9.0 — Saison, carrière & mémoire
- profil complet ;
- historique rang ;
- remontées ;
- jours en tête ;
- forme ;
- carrière ;
- classement carrière ;
- moyenne carrière ;
- records historiques ;
- Hall of Fame ;
- replay ;
- champion en titre ;
- distinction 2026 ;
- sondages.

**Critère de sortie :** l'application devient réellement multi-saisons.

---

## V0.9.5 — Administration & durcissement
- dashboard ;
- maintenance ;
- feature flags ;
- impersonation ;
- logs ;
- modération ;
- suppression ;
- exports ;
- sauvegardes ;
- RLS ;
- sécurité ;
- pagination ;
- tests multi-utilisateurs ;
- mobile ;
- accessibilité ;
- erreurs réseau.

**Critère de sortie :** release candidate exploitable publiquement.

---

## V0.9.8 — PDF & fin de saison
- PDF A4 ;
- collector ;
- classements ;
- badges ;
- statistiques ;
- historique ;
- Hall of Fame ;
- diplôme ;
- Livre d'or ;
- export global ;
- archive.

**Critère de sortie :** la fin de saison est prête avant même le lancement.

---

## V0.9.9 — Pré-saison
- faux matchs ;
- faux scores ;
- faux utilisateurs ;
- charge ;
- notifications ;
- champion ;
- teams ;
- badges ;
- live ;
- finale ;
- PDF ;
- nettoyage ;
- onboarding ;
- tutoriel ;
- textes Hibou.

**Critère de sortie :** répétition générale terminée.

---

# V1.0.0 — LE NID DES CHAMPIONS

Version publique officielle.

Doivent être stables :
- pronostics ;
- phase de ligue ;
- classement ;
- live manuel ;
- champions ;
- phases finales ;
- teams ;
- rivalités ;
- ~100 badges ;
- records ;
- casseroles ;
- génie ;
- Hibou solitaire ;
- soirées ;
- Hibou masqué ;
- notifications ;
- sondages ;
- multi-saisons ;
- carrière ;
- administration ;
- Hall of Fame ;
- PDF ;
- diplôme ;
- Livre d'or ;
- replay de saison.

---

# 49. Après la V1.0.0

## V1.1.x
- retours UX ;
- ajustement teams ;
- éventuel mercato ;
- nouveaux badges ;
- nouvelles statistiques.

## V1.2.x
- API football si solution viable ;
- événements live automatiques ;
- résultats automatiques.

## V1.3.x
- enrichissement Hall of Fame ;
- carrière ;
- nouvelles rivalités.

## V1.4.x
- fonctions communautaires issues des suggestions.

---

# 50. Famille des projets

1. **Le Nid des Pronos — Coupe du monde 2026**
   - projet fondateur ;
   - édition hommage.

2. **Le Nid des Champions**
   - Ligue des champions ;
   - nouvelle architecture ;
   - multi-saisons.

3. **Le Nid des Pronos configurable**
   - objectif Euro 2028 ;
   - moteur réutilisable.

4. **Le Nid des Pronos 2030**
   - retour mondial ;
   - réutilisation des innovations développées entre-temps.

---

# Principe final

> **Le Nid des Champions doit être plus riche que Le Nid des Pronos sans être plus compliqué à jouer.**

Un utilisateur doit pouvoir ouvrir l'application, comprendre immédiatement ce qu'il lui reste à faire, saisir ses pronostics en quelques secondes et repartir.

Tout le reste — Hibou, records, teams, badges, casseroles, génie, rivalités, live et carrière — doit lui donner envie de revenir.

**Le pronostic est le geste.  
Le Nid est l'expérience.** 🦉🏆
