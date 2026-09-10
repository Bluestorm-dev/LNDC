# Centre de tests — V1.0.0

La V1.0.0 ajoute un contrôle ciblé sur le fonctionnement en compétition réelle, en particulier quand plusieurs matchs sont LIVE simultanément.

## Test automatique statique

Depuis la racine :

```bash
node tests/run-all-v1.0.0.mjs
```

Résultat attendu : **19 PASS · 0 FAIL**.

Les contrôles vérifient notamment la version/cache, le nouveau rendu accueil LIVE, le carrousel du Nid, le classement en cartes, le tri des matchs terminés, le cockpit Super Admin groupé par journée, la visibilité des champions d'un autre joueur après verrouillage, l'inscription Push joueur, le report/dédoublonnage des notifications de classement et les records actifs pendant la journée.

## Road-check humain

Ouvrir `tests/test-center-v1.0.0.html` puis valider les 10 scénarios.

Le scénario le plus important est le suivant : pendant un match LIVE, saisir plusieurs scores successifs. Le classement peut bouger visuellement, mais **aucune notification de changement de rang ne doit être créée pendant le LIVE**. Après la fin de la séquence LIVE, le système peut émettre un unique bilan de rang si le classement officiel a effectivement changé.

Pour les Push, tester avec un compte joueur standard et, idéalement, sur un navigateur qui a déjà été utilisé avec un autre compte afin de valider la réattribution de l'endpoint.
