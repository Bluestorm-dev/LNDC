# Le Nid des Champions — Checklist V0.9.10

**40 contrôles spécifiques** à la sécurisation pré-production.


## Installation

- [ ] **T1881** — Le HOTFIX V0.9.10 s’exécute sans erreur sur la base V0.9.9.
- [ ] **T1882** — sync-football-data V0.9.10 est redéployée après le SQL.

## Calendrier hybride

- [ ] **T1883** — Le fichier UEFA intégré contient exactement 144 matchs.
- [ ] **T1884** — Les 144 matchs sont répartis en 8 journées de 18.
- [ ] **T1885** — Les 36 clubs jouent chacun exactement huit rencontres.
- [ ] **T1886** — Le bouton Charger les 144 matchs UEFA crée ou met à jour le calendrier sans doublon.
- [ ] **T1887** — Une seconde exécution du chargement UEFA est idempotente.
- [ ] **T1888** — Une réponse Football-Data partielle est acceptée sans erreur fonctionnelle.
- [ ] **T1889** — Une réponse Football-Data partielle ne supprime aucun match local absent du lot reçu.
- [ ] **T1890** — Une réponse Football-Data d’une autre saison reste refusée.
- [ ] **T1891** — Un match UEFA local est rapproché de Football-Data par équipes quand son external_match_id est encore absent.
- [ ] **T1892** — Après rapprochement, external_match_id est enregistré pour les mises à jour suivantes.

## Édition match

- [ ] **T1893** — Un Admin peut modifier domicile, extérieur, journée, date, stade et pays du stade.
- [ ] **T1894** — Une correction manuelle peut être verrouillée contre Football-Data.
- [ ] **T1895** — Football-Data ne modifie pas la date/équipes/stade d’un match verrouillé.
- [ ] **T1896** — Un Admin peut retirer le verrou pour rendre le match à nouveau pilotable par Football-Data.

## Équipes

- [ ] **T1897** — Un Admin peut ajouter manuellement une équipe au catalogue C1.
- [ ] **T1898** — Un Admin peut corriger nom, nom court, sigle, pays, stade et logo.
- [ ] **T1899** — Une correction d’équipe peut être protégée des métadonnées Football-Data.
- [ ] **T1900** — Football-Data peut toujours rattacher son external_id à une équipe protégée.

## Cotes 1N2

- [ ] **T1901** — Le bouton Cotes 1N2 n’exige plus la présence des 144 matchs chez Football-Data.
- [ ] **T1902** — Les cotes présentes dans un lot Football-Data partiel sont appliquées aux matchs reconnus.
- [ ] **T1903** — Un lot sans cotes affiche un message métier et ne fait pas croire à une panne de clé API.
- [ ] **T1904** — Une vraie panne de transport de l’Edge Function est distinguée d’une erreur fournisseur.

## Champion 1

- [ ] **T1905** — Le choix Champion 1 est ouvert avant le premier coup d’envoi.
- [ ] **T1906** — Les 36 clubs C1 sont proposés même si Football-Data n’a encore fourni aucun match.
- [ ] **T1907** — La fermeture du Champion 1 utilise la première date UEFA connue si nécessaire.

## Reset pré-production

- [ ] **T1908** — Le Super Admin peut prévisualiser les données qui seront nettoyées.
- [ ] **T1909** — Le reset exige exactement RESET AVANT OUVERTURE.
- [ ] **T1910** — Le reset supprime les pronostics et choix champions de recette.
- [ ] **T1911** — Le reset supprime les badges obtenus sans supprimer le catalogue des 100 succès.
- [ ] **T1912** — Le reset supprime casseroles, génies, records et répétitions générales.
- [ ] **T1913** — Le reset conserve comptes, Teams, clubs et calendrier réel.
- [ ] **T1914** — Le reset remet les scores/statuts des matchs réels à un état neutre.
- [ ] **T1915** — Le reset est bloqué après le premier coup d’envoi officiel.

## UI publique

- [ ] **T1916** — Centre Ligue des champions n’affiche plus de numéro de version technique.
- [ ] **T1917** — Soirée européenne n’affiche plus de numéro de version technique.
- [ ] **T1918** — Le Musée n’affiche plus V0.7.0 dans son en-tête public.

## Non-régression

- [ ] **T1919** — Les 100 images de succès intégrées à la base V0.9.9 sont toujours présentes.

## GO V0.9.10

- [ ] **T1920** — Runner local et distant V0.9.10 terminent avec 0 FAIL avant reprise du road-check.
