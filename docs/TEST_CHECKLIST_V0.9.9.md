# Le Nid des Champions — Checklist V0.9.9

220 contrôles spécifiques à la **pré-saison / répétition générale** avant V1.0.0.

## Release / migration

- [ ] **T1661** — VERSION contient 0.9.9.
- [ ] **T1662** — config.js et config.example.js annoncent 0.9.9.
- [ ] **T1663** — Le cache Service Worker utilise nid-champions-v0.9.9.
- [ ] **T1664** — Le manifest d’assets annonce 0.9.9.
- [ ] **T1665** — HOTFIX_V0.9.9_EXISTING_DB.sql s’exécute sans erreur sur une base V0.9.8.
- [ ] **T1666** — La migration V0.9.9 conserve les tables et RPC V0.9.8.
- [ ] **T1667** — Le site démarre sans erreur JavaScript après migration.
- [ ] **T1668** — Le Centre de tests V0.9.9 s’ouvre depuis Admin > Laboratoire.
- [ ] **T1669** — Le Grand road-check V1 s’ouvre depuis Admin > Laboratoire.
- [ ] **T1670** — Aucune Edge Function n’a besoin d’être redéployée pour V0.9.9.

## Bac à sable / isolation

- [ ] **T1671** — Créer une répétition générale ne crée aucun profil réel.
- [ ] **T1672** — Créer une répétition générale ne crée aucun match dans public.matches.
- [ ] **T1673** — Créer une répétition générale ne crée aucun pronostic dans public.predictions.
- [ ] **T1674** — Les joueurs virtuels restent dans preseason_virtual_players_v099.
- [ ] **T1675** — Les matchs virtuels restent dans preseason_virtual_matches_v099.
- [ ] **T1676** — Les pronostics virtuels restent dans preseason_virtual_predictions_v099.
- [ ] **T1677** — Les Teams virtuelles restent dans les tables preseason_* V0.9.9.
- [ ] **T1678** — Plusieurs répétitions peuvent coexister sans mélanger leurs données.
- [ ] **T1679** — Changer de répétition dans Admin affiche uniquement les données du run sélectionné.
- [ ] **T1680** — Une répétition est toujours rattachée à la saison choisie sans la modifier.

## Faux utilisateurs

- [ ] **T1681** — Le scénario par défaut crée 48 joueurs virtuels.
- [ ] **T1682** — Le nombre de joueurs virtuels est configurable entre 4 et 250.
- [ ] **T1683** — Chaque joueur virtuel possède un pseudo unique dans son scénario.
- [ ] **T1684** — Les joueurs virtuels n’apparaissent pas dans l’administration des vrais joueurs.
- [ ] **T1685** — Les joueurs virtuels n’apparaissent pas dans le classement officiel.
- [ ] **T1686** — Les joueurs virtuels n’apparaissent pas dans les notifications des vrais joueurs.
- [ ] **T1687** — Les joueurs virtuels peuvent être répartis dans plusieurs Teams virtuelles.
- [ ] **T1688** — Un capitaine virtuel est identifié pour chaque Team virtuelle.
- [ ] **T1689** — Le capitanat virtuel ne modifie aucun rôle applicatif réel.
- [ ] **T1690** — Supprimer le scénario supprime tous les joueurs virtuels associés.

## Faux matchs / scores

- [ ] **T1691** — Le scénario par défaut crée 24 matchs virtuels.
- [ ] **T1692** — Le nombre de matchs virtuels est configurable entre 8 et 80.
- [ ] **T1693** — Les matchs virtuels couvrent phase de ligue et phases finales.
- [ ] **T1694** — Chaque match virtuel possède deux clubs TEST distinctement libellés.
- [ ] **T1695** — Chaque match virtuel possède un coup d’envoi.
- [ ] **T1696** — L’étape LIVE passe exactement trois matchs virtuels en live lorsqu’ils sont disponibles.
- [ ] **T1697** — L’étape scores termine la phase de ligue virtuelle.
- [ ] **T1698** — Les scores virtuels restent absents des matchs officiels.
- [ ] **T1699** — La finale virtuelle se termine avec un score exploitable.
- [ ] **T1700** — Le journal de répétition conserve les étapes de scores exécutées.

## Barème / classement simulé

- [ ] **T1701** — Un faux résultat incorrect rapporte 0 point dans le bac à sable.
- [ ] **T1702** — Un bon résultat rapporte 3 points dans le bac à sable.
- [ ] **T1703** — Un bon résultat avec bon écart rapporte 5 points dans le bac à sable.
- [ ] **T1704** — Un score exact rapporte 7 points dans le bac à sable.
- [ ] **T1705** — La distribution 0/3/5/7 est visible dans le panneau Admin.
- [ ] **T1706** — Le recalcul des scores ne crée pas de points dans public.predictions.
- [ ] **T1707** — Le recalcul peut être rejoué sans dupliquer les pronostics virtuels.
- [ ] **T1708** — Les points virtuels sont rattachés au bon joueur et au bon match.
- [ ] **T1709** — Les points de phases finales virtuelles sont recalculés après la finale.
- [ ] **T1710** — Le barème officiel de production reste inchangé.

## LIVE / temps réel

- [ ] **T1711** — Le bouton Passer 3 matchs LIVE est visible dans la répétition.
- [ ] **T1712** — Après LIVE, le compteur LIVE du scénario augmente.
- [ ] **T1713** — Les matchs LIVE virtuels conservent leurs scores courants.
- [ ] **T1714** — L’étape scores transforme les matchs de ligue LIVE en terminés.
- [ ] **T1715** — Le scénario permet de contrôler visuellement la gestion des états scheduled/live/finished.
- [ ] **T1716** — Le LIVE virtuel ne déclenche aucun classement officiel.
- [ ] **T1717** — Le LIVE virtuel ne déclenche aucun badge officiel.
- [ ] **T1718** — Le LIVE virtuel ne déclenche aucun push global.
- [ ] **T1719** — Le journal indique le démarrage LIVE.
- [ ] **T1720** — Le road-check demande un test multi-session du vrai LIVE avant GO V1.

## Champion

- [ ] **T1721** — Chaque joueur virtuel reçoit un Champion n°1.
- [ ] **T1722** — Chaque joueur virtuel peut disposer d’un Champion n°2.
- [ ] **T1723** — L’étape Champion résout un vainqueur virtuel.
- [ ] **T1724** — Le bonus virtuel Champion n°1 vaut 100 pour les bons choix.
- [ ] **T1725** — Un mauvais Champion virtuel reste à 0 bonus.
- [ ] **T1726** — Le test Champion ne modifie pas champion_predictions.
- [ ] **T1727** — Le choix Champion réel reste secret selon les règles existantes.
- [ ] **T1728** — Le road-check contient le verrouillage Champion n°1.
- [ ] **T1729** — Le road-check contient l’ouverture/verrouillage Champion n°2.
- [ ] **T1730** — La distinction Coupe du monde 2026 reste indépendante du Champion de saison.

## Teams

- [ ] **T1731** — Le scénario par défaut crée 8 Teams virtuelles.
- [ ] **T1732** — Le nombre de Teams virtuelles est configurable entre 2 et 32.
- [ ] **T1733** — Chaque Team virtuelle possède un capitaine.
- [ ] **T1734** — Chaque joueur virtuel appartient à au plus une Team virtuelle.
- [ ] **T1735** — L’étape Teams écrit un checkpoint dans le journal.
- [ ] **T1736** — Les Teams virtuelles n’apparaissent pas dans public.teams.
- [ ] **T1737** — Les Teams réelles restent modifiables hors archive.
- [ ] **T1738** — Les Teams réelles restent figées dans une saison archivée.
- [ ] **T1739** — Le capitaine réel reste un rôle de Team et non un rôle profiles.role.
- [ ] **T1740** — Le nettoyage supprime toutes les Teams virtuelles du scénario.

## Badges / Casseroles / Génie

- [ ] **T1741** — L’étape Badges génère des récompenses virtuelles.
- [ ] **T1742** — Le scénario génère au moins un badge virtuel.
- [ ] **T1743** — Le scénario génère au moins une Casserole virtuelle.
- [ ] **T1744** — Le scénario génère au moins un Coup de Génie virtuel.
- [ ] **T1745** — Les récompenses virtuelles n’écrivent pas dans player_badges.
- [ ] **T1746** — Les récompenses virtuelles n’écrivent pas dans gamification_events officiels.
- [ ] **T1747** — Le catalogue officiel conserve au moins 100 badges.
- [ ] **T1748** — La banque narrative officielle conserve au moins 1360 textes historiques.
- [ ] **T1749** — Les badges officiels restent testables via le laboratoire Gamification existant.
- [ ] **T1750** — Le nettoyage supprime toutes les récompenses virtuelles.

## Notifications / Push

- [ ] **T1751** — L’étape Notifications envoie une notification TEST uniquement au Super Admin courant.
- [ ] **T1752** — La notification TEST utilise le mécanisme de notification V0.7 existant.
- [ ] **T1753** — La notification de répétition est marquée comme TEST.
- [ ] **T1754** — Aucune notification de répétition n’est diffusée à tous les joueurs.
- [ ] **T1755** — L’étape Notifications fonctionne sans demander de Push navigateur par défaut.
- [ ] **T1756** — Le road-check prévoit un Push réel ciblé sur un appareil de test.
- [ ] **T1757** — Les préférences de notification du joueur restent respectées hors laboratoire.
- [ ] **T1758** — Les quiet hours restent contrôlables dans le road-check.
- [ ] **T1759** — La cloche de notifications reste accessible après V0.9.9.
- [ ] **T1760** — Le nettoyage du scénario ne supprime aucune notification métier existante.

## Charge / performance

- [ ] **T1761** — Le test de charge accepte au moins 20 000 lignes.
- [ ] **T1762** — Le test de charge peut monter jusqu’à 100 000 lignes maximum.
- [ ] **T1763** — Les données de charge restent dans preseason_load_samples_v099.
- [ ] **T1764** — Le temps d’écriture est mesuré en millisecondes.
- [ ] **T1765** — Le nombre de lignes écrites est affiché dans Admin.
- [ ] **T1766** — Relancer le test de charge remplace les anciennes lignes du même scénario.
- [ ] **T1767** — Le test de charge ne verrouille pas les tables de pronostics officielles.
- [ ] **T1768** — Le test de charge ne crée aucun utilisateur Auth.
- [ ] **T1769** — Le road-check prévoit un contrôle mobile après charge.
- [ ] **T1770** — Le nettoyage du scénario supprime toutes les lignes de charge.

## Phases finales / finale

- [ ] **T1771** — Le scénario contient des matchs QUARTER_FINAL.
- [ ] **T1772** — Le scénario contient des matchs SEMI_FINAL.
- [ ] **T1773** — Le scénario contient exactement un match FINAL.
- [ ] **T1774** — L’étape Finale termine les matchs virtuels de phases finales.
- [ ] **T1775** — La finale virtuelle possède un vainqueur.
- [ ] **T1776** — Les points virtuels sont recalculés après la finale.
- [ ] **T1777** — La vraie logique aller-retour reste couverte par le road-check.
- [ ] **T1778** — La vraie prolongation reste couverte par le road-check.
- [ ] **T1779** — Les vrais tirs au but restent couverts par le road-check.
- [ ] **T1780** — La vraie propagation des qualifiés reste couverte par le road-check.

## PDF / fin de saison

- [ ] **T1781** — Le bouton Smoke test PDF ouvre le Collector V0.9.8.
- [ ] **T1782** — Le road-check couvre le Collector A4.
- [ ] **T1783** — Le road-check couvre le carnet joueur A4.
- [ ] **T1784** — Le road-check couvre le diplôme A4.
- [ ] **T1785** — Le road-check couvre la génération groupée de diplômes.
- [ ] **T1786** — Le road-check couvre le Livre d’or.
- [ ] **T1787** — Le road-check couvre l’export global JSON.
- [ ] **T1788** — Le road-check couvre la construction de l’archive préparatoire.
- [ ] **T1789** — L’archivage définitif de la vraie saison n’est jamais déclenché automatiquement par la répétition.
- [ ] **T1790** — L’étape PDF du bac à sable ne modifie aucune archive réelle.

## Nettoyage

- [ ] **T1791** — Le nettoyage exige exactement NETTOYER.
- [ ] **T1792** — Une confirmation différente de NETTOYER est refusée côté serveur.
- [ ] **T1793** — Le nettoyage est réservé au Super Admin.
- [ ] **T1794** — Le nettoyage supprime le run sélectionné.
- [ ] **T1795** — Le nettoyage cascade sur joueurs virtuels.
- [ ] **T1796** — Le nettoyage cascade sur matchs et pronostics virtuels.
- [ ] **T1797** — Le nettoyage cascade sur Teams virtuelles.
- [ ] **T1798** — Le nettoyage cascade sur événements et récompenses virtuelles.
- [ ] **T1799** — Le nettoyage cascade sur données de charge.
- [ ] **T1800** — Le nettoyage ne supprime aucune donnée officielle de la saison.

## Onboarding / tutoriel

- [ ] **T1801** — Un utilisateur peut ouvrir le tutoriel depuis son Profil.
- [ ] **T1802** — Le tutoriel contient 10 étapes.
- [ ] **T1803** — Le tutoriel explique les pronostics.
- [ ] **T1804** — Le tutoriel explique les classements et le LIVE.
- [ ] **T1805** — Le tutoriel explique les Teams et le capitanat.
- [ ] **T1806** — Le tutoriel explique les Champions.
- [ ] **T1807** — Le tutoriel explique badges, records et Hibou.
- [ ] **T1808** — Le tutoriel explique notifications et carrière.
- [ ] **T1809** — Le bouton Plus tard mémorise le report du tutoriel.
- [ ] **T1810** — Terminer le tutoriel mémorise la complétion et permet de le revoir.

## Textes du Hibou

- [ ] **T1811** — Au moins 10 textes spécifiques V0.9.9 sont actifs.
- [ ] **T1812** — Un texte d’accueil du Hibou existe.
- [ ] **T1813** — Un texte premier pronostic existe.
- [ ] **T1814** — Un texte LIVE existe.
- [ ] **T1815** — Un texte score exact existe.
- [ ] **T1816** — Un texte Casserole existe.
- [ ] **T1817** — Un texte Coup de Génie existe.
- [ ] **T1818** — Un texte Champion verrouillé existe.
- [ ] **T1819** — Un texte finale / fin de saison existe.
- [ ] **T1820** — Les textes V0.9.9 n’écrasent pas les 1360 textes historiques.

## Admin UX

- [ ] **T1821** — La recherche Admin trouve Répétition générale avec pré-saison.
- [ ] **T1822** — La recherche Admin trouve Répétition générale avec charge.
- [ ] **T1823** — La répétition générale est située dans Admin > Laboratoire.
- [ ] **T1824** — Le panneau explique clairement que les données sont isolées.
- [ ] **T1825** — Créer un scénario demande joueurs, matchs et Teams dans un seul bloc.
- [ ] **T1826** — Les étapes déjà exécutées sont visuellement marquées.
- [ ] **T1827** — Les KPI joueurs/Teams/matchs/pronostics/LIVE/terminés sont visibles sans scroll excessif.
- [ ] **T1828** — Les liens Centre de tests et Grand road-check sont visibles dans le panneau.
- [ ] **T1829** — Le bouton Nettoyer est visuellement séparé des actions normales.
- [ ] **T1830** — Le panneau reste utilisable sur mobile.

## PWA / mobile

- [ ] **T1831** — Le Service Worker pré-cache preseason099.css.
- [ ] **T1832** — Le Service Worker pré-cache preseason099.js.
- [ ] **T1833** — La V0.9.9 se recharge sans conserver un ancien cache V0.9.8.
- [ ] **T1834** — Le tutoriel est lisible sur smartphone.
- [ ] **T1835** — Le panneau pré-saison est utilisable sur smartphone.
- [ ] **T1836** — Le Grand road-check est utilisable sur smartphone.
- [ ] **T1837** — Les boutons de la répétition restent suffisamment grands au tactile.
- [ ] **T1838** — Le mode prefers-reduced-motion est respecté par le tutoriel.
- [ ] **T1839** — La PWA redémarre après fermeture complète en V0.9.9.
- [ ] **T1840** — La session utilisateur reste restaurée normalement après mise à jour.

## Sécurité / RLS

- [ ] **T1841** — Les tables preseason_* ont RLS activée.
- [ ] **T1842** — Un joueur normal ne peut pas lire les données du bac à sable Admin.
- [ ] **T1843** — Un Admin non Super Admin ne peut pas créer une répétition.
- [ ] **T1844** — Un Admin non Super Admin ne peut pas lancer le test de charge.
- [ ] **T1845** — Un Admin non Super Admin ne peut pas nettoyer une répétition.
- [ ] **T1846** — Les RPC V0.9.9 recontrôlent is_super_admin côté serveur.
- [ ] **T1847** — L’onboarding d’un joueur n’est modifiable que via ses RPC dédiés.
- [ ] **T1848** — Aucune adresse e-mail n’est stockée dans les joueurs virtuels.
- [ ] **T1849** — Le bac à sable ne contient aucun secret API.
- [ ] **T1850** — Le diagnostic V0.9.9 vérifie les composants critiques avant GO.

## Multi-session / navigateur

- [ ] **T1851** — Le road-check prévoit deux sessions navigateur simultanées.
- [ ] **T1852** — Un changement LIVE réel apparaît dans la seconde session sans refresh.
- [ ] **T1853** — Un score LIVE réel se met à jour dans la seconde session.
- [ ] **T1854** — Une fin de match réelle se met à jour dans la seconde session.
- [ ] **T1855** — Les pronostics adverses réels restent cachés avant verrouillage.
- [ ] **T1856** — Les pronostics adverses réels deviennent visibles après verrouillage.
- [ ] **T1857** — Le changement de saison ne mélange pas les données entre sessions.
- [ ] **T1858** — Une notification interne ciblée apparaît sur le bon compte.
- [ ] **T1859** — Un joueur normal ne voit jamais le panneau pré-saison.
- [ ] **T1860** — La répétition virtuelle reste invisible dans une session joueur.

## Régression critique V1

- [ ] **T1861** — Inscription, validation et connexion par pseudo restent fonctionnelles.
- [ ] **T1862** — Pronostics et autosauvegarde restent fonctionnels.
- [ ] **T1863** — Barème officiel 0/3/5/7 reste fonctionnel.
- [ ] **T1864** — Classements Général/Journée/Soirée/Précision/Exacts restent fonctionnels.
- [ ] **T1865** — Champions 1 et 2 restent fonctionnels.
- [ ] **T1866** — Phases finales, cumul, prolongation, TAB et qualifié restent fonctionnels.
- [ ] **T1867** — Teams et rivalités restent fonctionnelles.
- [ ] **T1868** — Gamification, Musée, Hibou solitaire et sondages restent fonctionnels.
- [ ] **T1869** — Multi-saisons, carrière, Hall of Fame et Replay restent fonctionnels.
- [ ] **T1870** — Admin, sauvegardes, PDF et archives restent fonctionnels.

## GO / répétition générale

- [ ] **T1871** — Le runner V0.9.9 termine avec 0 FAIL en local.
- [ ] **T1872** — Le runner V0.9.9 termine avec 0 FAIL sur GitHub Pages.
- [ ] **T1873** — Le diagnostic SQL V0.9.9 termine avec 0 FAIL.
- [ ] **T1874** — Le Centre de tests V0.9.9 contient exactement 1880 contrôles uniques.
- [ ] **T1875** — Les 24 missions du Grand road-check ont été parcourues.
- [ ] **T1876** — Aucun KO critique n’est laissé sans correction ou décision documentée.
- [ ] **T1877** — Une sauvegarde de production existe avant la répétition destructrice éventuelle.
- [ ] **T1878** — Tous les scénarios preseason_* sont nettoyés après validation.
- [ ] **T1879** — La saison réelle ne contient aucune donnée TEST involontaire après nettoyage.
- [ ] **T1880** — La répétition générale est déclarée terminée avant création de V1.0.0.
