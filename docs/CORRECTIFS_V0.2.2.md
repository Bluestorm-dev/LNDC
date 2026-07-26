# Correctifs V0.2.2 intégrés aux V0.3.x

La V0.2.2 n'a pas été publiée comme archive complète. Ses corrections sont intégrées à la release V0.3.0 puis conservées dans les versions V0.3.x, y compris V0.3.3.

## Football-Data

- saison source forcée à 2025/26 ;
- 36 clubs strictement ;
- chaque club doit avoir une source de logo exploitable ;
- 144 matchs strictement ;
- 8 journées de 18 matchs ;
- filtre privilégiant explicitement le stage `LEAGUE` ;
- déduplication par identifiant Football-Data ;
- suppression des imports parasites antérieurs ;
- transposition de chaque date d'un an vers 2026/27 ;
- `FINISHED` de la source devient `scheduled` dans la saison test ;
- aucun score historique n'est importé ;
- un résultat final déjà saisi manuellement dans le Nid n'est pas écrasé par une resynchronisation.

## Logos

- priorité au blason football-data.org ;
- copie dans le bucket public `club-logos` lorsque possible ;
- secours TheSportsDB si nécessaire ;
- fallback vers l'URL externe ;
- les 36 clubs synchronisés sont visibles dans l'aperçu Admin.

## Saisie pronostics

- frappe d'un chiffre dans le score domicile : remplacement de la valeur et focus extérieur ;
- frappe d'un chiffre dans le score extérieur : remplacement de la valeur et focus domicile ;
- `+ / −` incrémente/décrémente sans déplacer le focus ;
- scores de 0 à 99 ;
- autosauvegarde temporisée conservée ;
- rôles `player`, `admin` et `super_admin` actifs autorisés à jouer.
