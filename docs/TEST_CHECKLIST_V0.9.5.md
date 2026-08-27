# Checklist de validation — Le Nid des Champions V0.9.5

La V0.9.5 est la version **Administration & durcissement**. Le grand road-check historique sera réalisé en V0.9.9 ; cette checklist conserve néanmoins tous les contrôles spécifiques V0.9.5 pour la répétition générale.

Avant tout test destructif : créer une sauvegarde V0.9.5 et activer le mode maintenance si une restauration est testée.

## Admin UX / recherche

- [ ] Le champ « Trouver une option… » est visible immédiatement en haut de l’Admin.
- [ ] Ctrl+K place le focus dans la recherche Admin lorsque l’écran Admin est ouvert.
- [ ] La touche / place le focus dans la recherche Admin hors champ de saisie.
- [ ] Rechercher « sauvegarde » propose directement la gestion des sauvegardes.
- [ ] Rechercher « C1 » propose les synchronisations Ligue des champions pertinentes.
- [ ] Rechercher « joueur » propose la recherche joueur et les actions associées.
- [ ] Appuyer sur Entrée ouvre le premier résultat de recherche et fait défiler jusqu’à l’option.
- [ ] Échap ferme la recherche Admin et rend la navigation normale.
- [ ] Cliquer hors de la palette referme les résultats sans changer d’écran.
- [ ] Une recherche sans résultat affiche une aide compréhensible plutôt qu’une zone vide.

## Admin navigation / hiérarchie

- [ ] La navigation Admin est regroupée en Pilotage, Communauté et Technique.
- [ ] Dashboard est l’entrée par défaut et expose les actions prioritaires.
- [ ] Joueurs & accès regroupe comptes, inscriptions, avatars, aperçu joueur et suppressions.
- [ ] Contenu & Musée regroupe gamification et sondages sans les disperser.
- [ ] Système & sécurité regroupe saisons, réglages, sauvegardes, exports et audit.
- [ ] Laboratoire/Test est placé à part des fonctions de production.
- [ ] Le libellé de chaque entrée reste compréhensible sans connaître le nom interne de la fonction.
- [ ] Changer de rubrique Admin ne provoque pas de rechargement complet de la PWA.
- [ ] Le retour vers Dashboard est accessible en un clic depuis toute rubrique Admin.
- [ ] La rubrique courante est visuellement identifiable sur desktop et mobile.

## Dashboard / centre d’action

- [ ] Le Dashboard affiche l’état réseau, maintenance, API et saison courante.
- [ ] Les inscriptions en attente remontent dans « À traiter » avec le bon compteur.
- [ ] Les avatars en attente remontent dans « À traiter » avec le bon compteur.
- [ ] Les tickets ouverts remontent dans « À traiter » avec le bon compteur.
- [ ] Les échecs Push des dernières 24 h remontent dans « À traiter ».
- [ ] Les demandes de suppression remontent dans « À traiter ».
- [ ] Cliquer un signal du centre d’action ouvre directement l’écran concerné.
- [ ] En l’absence d’alerte, le Dashboard affiche clairement que rien n’est urgent.
- [ ] Les actions rapides Score, C1, Joueur, Hibou, Sauvegarde et Réglages sont accessibles sans fouille de menus.
- [ ] Les compteurs du Dashboard se rafraîchissent après une opération Admin importante.

## Réglages / feature flags

- [ ] Le Super Admin peut ouvrir ou fermer les inscriptions depuis Système & sécurité.
- [ ] Un Admin non Super Admin peut voir les réglages mais ne peut pas les modifier.
- [ ] Désactiver Teams masque l’accès Teams côté joueur sans supprimer les données.
- [ ] Réactiver Teams réaffiche les données existantes sans perte.
- [ ] Désactiver Musée & gamification masque l’accès concerné sans supprimer badges/événements.
- [ ] Désactiver Sondages masque les sondages généraux sans supprimer les votes existants.
- [ ] Désactiver les synchronisations API désactive les boutons Football-Data/cotes avec une explication.
- [ ] Le flag Rivalités conserve les données existantes lors de sa désactivation/réactivation.
- [ ] Le flag Hibou solitaire conserve les données existantes lors de sa désactivation/réactivation.
- [ ] Chaque modification de réglage crée une trace dans audit_logs.

## Maintenance / inscriptions

- [ ] Activer Maintenance demande une confirmation explicite.
- [ ] Un joueur connecté voit l’écran de maintenance et ne peut plus modifier les données.
- [ ] Le Super Admin conserve l’accès pendant la maintenance.
- [ ] La désactivation Maintenance rend immédiatement l’application utilisable aux joueurs après actualisation/synchronisation.
- [ ] Un nouvel utilisateur ne peut pas lancer une inscription lorsque registration_open=false.
- [ ] Le message d’inscriptions fermées est clair et ne ressemble pas à une panne Supabase.
- [ ] Réouvrir les inscriptions rétablit le formulaire sans migration SQL supplémentaire.
- [ ] La maintenance ne déconnecte pas silencieusement un joueur sans explication.
- [ ] Le bouton Déconnexion de l’écran Maintenance fonctionne.
- [ ] Maintenance et fermeture des inscriptions sont deux réglages indépendants.

## Joueurs / pagination / aperçu

- [ ] La liste Admin des joueurs affiche au maximum 25 joueurs par page.
- [ ] Précédent/Suivant parcourent tous les joueurs sans doublon ni saut.
- [ ] Une nouvelle recherche joueur revient automatiquement à la première page.
- [ ] La recherche trouve un joueur au-delà de la première page.
- [ ] Les actions de rôle/statut continuent de fonctionner sur une page autre que la première.
- [ ] Le Super Admin peut ouvrir un aperçu lecture seule d’un joueur actif.
- [ ] L’aperçu affiche profil, pronostics, champions, Team et notifications non lues utiles au diagnostic.
- [ ] L’aperçu ne permet jamais d’enregistrer un pronostic ou une action au nom du joueur.
- [ ] L’ouverture de l’aperçu crée une trace impersonation_start dans l’audit.
- [ ] La fermeture de l’aperçu crée une trace impersonation_stop dans l’audit.

## Sauvegardes / restauration

- [ ] Le Super Admin peut créer une sauvegarde nommée de la saison active.
- [ ] La sauvegarde affiche date, nombre de matchs, pronostics et Teams.
- [ ] Le JSON d’une sauvegarde peut être téléchargé localement.
- [ ] Le snapshot inclut calendrier, matchs, pronostics, champions et phases finales.
- [ ] Le snapshot inclut Teams, membres, invitations et demandes d’adhésion.
- [ ] Le snapshot inclut gamification, paramètres de gamification et mémoire de saison.
- [ ] Le snapshot inclut sondages généraux et votes mensuels Casserole/Génie.
- [ ] Une restauration est refusée si le mode maintenance n’est pas activé.
- [ ] La restauration exige de taper exactement RESTAURER et remplace uniquement les données de la saison sauvegardée.
- [ ] Après restauration, les données chargées et les compteurs correspondent au snapshot et une trace backup_restore existe.

## Audit / traçabilité

- [ ] Le journal d’audit est paginé par blocs de 25 entrées.
- [ ] La recherche audit filtre par acteur, action, type ou identifiant d’entité.
- [ ] Le filtre Action permet de réduire le journal sans perdre les autres traces.
- [ ] Les détails Avant/Après sont consultables sans encombrer la liste principale.
- [ ] Une modification de réglage apparaît dans l’audit avec l’acteur.
- [ ] Créer puis supprimer une sauvegarde produit les traces attendues.
- [ ] Une attribution manuelle de distinction existante reste traçable.
- [ ] Une opération d’aperçu joueur est traçable.
- [ ] Le traitement d’une suppression de compte est traçable.
- [ ] Un joueur normal ne peut pas lire le journal Admin via l’interface ou la RPC.

## Exports

- [ ] L’export Annuaire joueurs génère un CSV lisible avec pseudo, rôle, statut et club.
- [ ] L’export Classement génère un CSV correspondant à la saison sélectionnée.
- [ ] L’export Audit génère les lignes actuellement chargées/filtrées sans erreur d’encodage.
- [ ] Les CSV utilisent un encodage compatible avec les accents français dans Excel/LibreOffice.
- [ ] Les valeurs contenant guillemets ou séparateurs sont correctement échappées.
- [ ] Le nom de fichier exporté ne contient pas de caractères invalides Windows.
- [ ] L’export Saison complète crée d’abord un snapshot serveur.
- [ ] L’export Saison complète est réservé au Super Admin.
- [ ] Le JSON exporté contient schema_version=0.9.5 et l’identifiant de saison.
- [ ] Les exports n’altèrent aucune donnée de production.

## Compte / confidentialité

- [ ] Un joueur connecté voit l’option de demande de suppression dans son profil.
- [ ] La demande demande une confirmation avant envoi.
- [ ] Un motif facultatif peut accompagner la demande.
- [ ] Deux demandes ouvertes simultanées pour le même joueur ne peuvent pas être créées.
- [ ] Le Super Admin voit les demandes requested/reviewing dans Joueurs & accès.
- [ ] Le Super Admin peut passer une demande à En cours.
- [ ] Le Super Admin peut refuser une demande avec une note administrative.
- [ ] Le traitement final anonymise le pseudo applicatif et le club de cœur.
- [ ] Le traitement final désactive les abonnements Push du joueur.
- [ ] L’interface rappelle explicitement que la suppression Auth Supabase reste une opération distincte si nécessaire.

## Sécurité / rôles / RLS

- [ ] admin_backups_v095 a la RLS activée.
- [ ] Seul le Super Admin peut créer, lire, restaurer ou supprimer les sauvegardes serveur.
- [ ] account_deletion_requests_v095 a la RLS activée.
- [ ] Un joueur ne peut consulter que ses propres demandes de suppression.
- [ ] admin_set_app_setting_v095 refuse un utilisateur non Super Admin.
- [ ] admin_restore_backup_v095 refuse un utilisateur non Super Admin.
- [ ] admin_player_preview_v095 refuse un joueur normal.
- [ ] admin_audit_v095 refuse un joueur normal.
- [ ] Une clé de réglage non autorisée est refusée par admin_set_app_setting_v095.
- [ ] Le rôle Team captain ne confère aucun privilège Admin applicatif.

## Réseau / erreurs

- [ ] Passer hors ligne affiche un bandeau réseau explicite.
- [ ] Le retour en ligne retire le bandeau et confirme le rétablissement.
- [ ] Une erreur réseau lors d’une action Admin produit un message lisible et non une erreur brute incompréhensible.
- [ ] Une erreur RPC dans le cockpit ne rend pas toute la page Admin blanche.
- [ ] Un échec de chargement des statistiques Admin laisse les autres rubriques utilisables.
- [ ] Le bouton API désactivé par Feature flag explique pourquoi il est indisponible.
- [ ] Une restauration échouée laisse la sauvegarde existante disponible.
- [ ] Un export local reste possible si les données nécessaires sont déjà chargées.
- [ ] Les erreurs 401/403 ne sont pas présentées comme des indisponibilités Football-Data.
- [ ] Le correctif season_not_available V0.8.1 reste intact après la V0.9.5.

## Accessibilité / clavier

- [ ] La recherche Admin possède un aria-label explicite.
- [ ] Le bandeau réseau utilise role=status et aria-live.
- [ ] Les boutons principaux restent atteignables au clavier.
- [ ] Le focus clavier reste visible sur les contrôles Admin.
- [ ] Ctrl+K et / n’interceptent pas la saisie lorsqu’un input/textarea/select est actif.
- [ ] Les interrupteurs de réglage sont utilisables au clavier.
- [ ] La palette de recherche peut être fermée avec Échap.
- [ ] Le mode prefers-reduced-motion réduit les animations de mise en évidence.
- [ ] Le mode forced-colors conserve des bordures/états perceptibles.
- [ ] Les libellés essentiels ne reposent pas uniquement sur une icône ou une couleur.

## Mobile / responsive

- [ ] L’Admin reste utilisable sur une largeur de 360 px sans débordement horizontal global.
- [ ] La recherche Admin reste visible et exploitable sur mobile.
- [ ] Les groupes de navigation Admin restent lisibles sur petit écran.
- [ ] Le centre d’action passe proprement en une colonne sur mobile.
- [ ] Les actions rapides sont suffisamment grandes pour le tactile.
- [ ] Les réglages/Feature flags ne se chevauchent pas sur mobile.
- [ ] La liste des sauvegardes garde ses actions accessibles sur petit écran.
- [ ] Le journal d’audit reste lisible et ses détails peuvent être ouverts au toucher.
- [ ] La pagination joueurs reste accessible sur téléphone.
- [ ] L’aperçu joueur reste lisible sans couper score, Team ou bouton de fermeture.

## Charge / multi-utilisateur

- [ ] La liste joueurs reste fluide avec au moins 100 profils grâce à la pagination.
- [ ] La recherche Admin ne déclenche pas de requête serveur à chaque frappe pour la palette d’options.
- [ ] Le journal d’audit ne charge pas plus de 100 lignes par appel RPC.
- [ ] Deux Admin consultant le Dashboard simultanément obtiennent des compteurs cohérents.
- [ ] Deux Super Admin modifiant le même réglage aboutissent à une dernière valeur cohérente et deux traces auditables.
- [ ] Une sauvegarde peut être créée pendant que des joueurs consultent l’application sans modifier leurs données.
- [ ] Une restauration n’est effectuée qu’en mode maintenance afin d’éviter les écritures concurrentes normales.
- [ ] Le Dashboard ne provoque pas de boucle de render/load ou de rafale continue de RPC.
- [ ] Le passage entre rubriques Admin reste réactif avec un audit volumineux.
- [ ] Le chargement de la V0.9.5 ne ralentit pas perceptiblement les écrans joueur hors Admin.

## Régression / sortie V0.9.5

- [ ] Toutes les fonctions V0.1.x → V0.9.0 restent présentes après installation de V0.9.5.
- [ ] La gestion multi-saisons V0.9.0 reste opérationnelle depuis le nouvel Admin.
- [ ] Le vainqueur manuel Coupe du monde 2026 reste attribuable et visible.
- [ ] Centre C1, Soirées, Hibou solitaire et votes mensuels V0.8 restent fonctionnels.
- [ ] Pronostics, points 0/3/5/7, LIVE, classements et phases finales restent inchangés.
- [ ] Teams, avatars, Push, rivalités, Musée et support restent accessibles lorsque leurs Feature flags sont actifs.
- [ ] node tests/run-all-v0.9.5.mjs termine avec 0 FAIL sur le dossier livré.
- [ ] Le test distant --url valide VERSION, config.js, sw.js, index.html, admin095.js et admin095.css déployés.
- [ ] Le Centre de tests V0.9.5 contient exactement 1490 contrôles uniques jusqu’à T1490.
- [ ] Une sauvegarde de production a été réalisée avant passage aux versions V0.9.8/V0.9.9.
