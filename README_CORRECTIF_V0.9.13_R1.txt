LE NID DES CHAMPIONS — V0.9.13 R1
=====================================

CORRECTION ONBOARDING
Le bouton « Terminer » pouvait rester bloqué parce que la modale n'était
fermée qu'après le rechargement du profil, du Champion et des notifications.

R1 :
- les choix sont enregistrés ;
- l'onboarding est marqué terminé localement ;
- la fenêtre est fermée immédiatement ;
- l'activation Push ne bloque plus la fermeture ;
- les rechargements de données se font ensuite en arrière-plan ;
- aucun échec de rafraîchissement ne peut rouvrir la fenêtre.

Aucun SQL.
Aucune Edge Function.
À appliquer par-dessus V0.9.13.
