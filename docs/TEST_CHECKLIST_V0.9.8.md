# Le Nid des Champions — Checklist V0.9.8

170 contrôles spécifiques au bloc **PDF & fin de saison**. Le grand road-check complet V0.1.x → V0.9.9 reste volontairement prévu pour la V0.9.9.

## PDF / impression A4

- [ ] **T1491** — La page finale.html s’ouvre depuis Saison sans erreur JavaScript.
- [ ] **T1492** — La page diplome.html s’ouvre depuis Saison sans erreur JavaScript.
- [ ] **T1493** — Le bouton Imprimer / PDF ouvre la boîte d’impression du navigateur.
- [ ] **T1494** — Le format d’impression du collector est A4 portrait.
- [ ] **T1495** — Le diplôme est A4 paysage.
- [ ] **T1496** — Les pages imprimées n’affichent pas la barre d’outils web.
- [ ] **T1497** — Les fonds, bordures et contrastes restent lisibles à l’impression.
- [ ] **T1498** — Aucun contenu important n’est coupé horizontalement en A4.
- [ ] **T1499** — Les tableaux longs passent proprement sur les pages suivantes.
- [ ] **T1500** — Les titres de page ne se retrouvent pas seuls en bas de page.
- [ ] **T1501** — Les avatars restent nets et proportionnés dans les documents.
- [ ] **T1502** — Le Hibou / branding est présent sans masquer le contenu.
- [ ] **T1503** — Les accents français sont correctement rendus dans le PDF.
- [ ] **T1504** — Les symboles 🏆 / 🦉 / médailles restent compréhensibles dans le PDF.
- [ ] **T1505** — Le PDF généré depuis Chrome est lisible à 100 % de zoom.
- [ ] **T1506** — Le PDF généré depuis Edge est lisible à 100 % de zoom.
- [ ] **T1507** — Le collector reste utilisable sur écran mobile avant impression.
- [ ] **T1508** — Le diplôme reste utilisable sur écran mobile avant impression.
- [ ] **T1509** — Le bouton Retour ramène vers Le Nid sans perdre la session.
- [ ] **T1510** — Le bouton Actualiser recharge les données du document.
- [ ] **T1511** — Le paramètre de saison dans l’URL ouvre la bonne saison.
- [ ] **T1512** — Une saison inexistante affiche une erreur claire et non une page blanche.
- [ ] **T1513** — Un utilisateur non connecté est invité à revenir dans l’application / se connecter.
- [ ] **T1514** — Aucune adresse e-mail ou donnée privée n’apparaît dans les documents.
- [ ] **T1515** — La mention de version affichée sur les documents est V0.9.8.
## Collector saison

- [ ] **T1516** — Le Collector saison affiche le nom de la saison et sa période/contexte.
- [ ] **T1517** — La couverture du Collector affiche le nombre de joueurs.
- [ ] **T1518** — La couverture affiche le nombre de matchs officiels.
- [ ] **T1519** — La couverture affiche le nombre de pronostics.
- [ ] **T1520** — La couverture affiche le nombre de scores exacts.
- [ ] **T1521** — Le podium affiche correctement #1, #2 et #3.
- [ ] **T1522** — Le podium reste cohérent avec le classement Général de l’application.
- [ ] **T1523** — Le tableau du classement affiche rang, joueur, points, exacts, précision, moyenne et joués.
- [ ] **T1524** — Un classement de plus de 15 joueurs crée les pages complémentaires attendues.
- [ ] **T1525** — Tous les joueurs du classement apparaissent une fois dans le Collector.
- [ ] **T1526** — Les joueurs ex æquo restent départagés selon le classement serveur existant.
- [ ] **T1527** — Les statistiques finales affichent points distribués, badges, records, casseroles et génie.
- [ ] **T1528** — Le nombre de Teams du Collector correspond aux Teams de la saison.
- [ ] **T1529** — Le classement Teams du Collector correspond au classement Teams de l’application.
- [ ] **T1530** — Le Hall of Fame affiche les catégories disponibles sans inventer de gagnant.
- [ ] **T1531** — Le champion / podium du Hall of Fame correspond aux données de la saison.
- [ ] **T1532** — Poêle d’Or, Génie et Hibou solitaire sont affichés lorsqu’ils existent.
- [ ] **T1533** — Les badges rares/épiques/légendaires disponibles apparaissent dans le Collector.
- [ ] **T1534** — Les records affichés appartiennent uniquement à la saison sélectionnée.
- [ ] **T1535** — Le Replay reprend les événements de la bonne saison dans l’ordre chronologique.
- [ ] **T1536** — Les messages publiés du Livre d’or apparaissent dans le Collector.
- [ ] **T1537** — Les messages masqués du Livre d’or n’apparaissent pas dans le Collector.
- [ ] **T1538** — Une saison pauvre en données affiche des états vides propres, sans erreur.
- [ ] **T1539** — Les matchs marqués TEST n’entrent pas dans les statistiques finales officielles.
- [ ] **T1540** — Changer de saison puis rouvrir le Collector ne mélange aucune donnée de l’autre saison.
## Carnet joueur A4

- [ ] **T1541** — Mon carnet A4 ouvre le profil du joueur connecté.
- [ ] **T1542** — Un joueur normal ne peut pas ouvrir le carnet privé d’un autre joueur via l’URL.
- [ ] **T1543** — Un Admin peut prévisualiser le carnet d’un autre joueur.
- [ ] **T1544** — Le carnet affiche pseudo et avatar corrects.
- [ ] **T1545** — Le carnet affiche le club de cœur lorsqu’il existe.
- [ ] **T1546** — Le carnet affiche la Team de la saison lorsqu’elle existe.
- [ ] **T1547** — Le carnet affiche le rang de saison correct.
- [ ] **T1548** — Le carnet affiche les points de saison corrects.
- [ ] **T1549** — Le carnet affiche les scores exacts corrects.
- [ ] **T1550** — Le carnet affiche précision et moyenne cohérentes avec le profil.
- [ ] **T1551** — Le carnet affiche le meilleur rang et les jours en tête disponibles.
- [ ] **T1552** — Le carnet affiche le nombre d’oublis disponible.
- [ ] **T1553** — La courbe de rang suit l’historique enregistré sans inverser les dates.
- [ ] **T1554** — Un joueur sans historique de rang obtient un état vide lisible.
- [ ] **T1555** — Les badges du carnet appartiennent au joueur et à la saison sélectionnée.
- [ ] **T1556** — Les records du carnet appartiennent au joueur et à la saison sélectionnée.
- [ ] **T1557** — Les distinctions persistantes du joueur apparaissent dans son palmarès.
- [ ] **T1558** — La distinction Vainqueur du Nid des Pronos — Coupe du monde 2026 apparaît si attribuée.
- [ ] **T1559** — Les récompenses Hall of Fame du joueur apparaissent dans son carnet.
- [ ] **T1560** — Le carnet d’une saison archivée reste consultable en lecture seule.
## Diplôme

- [ ] **T1561** — Mon diplôme reprend le bon pseudo.
- [ ] **T1562** — Mon diplôme reprend la bonne saison.
- [ ] **T1563** — Le diplôme affiche le rang correct.
- [ ] **T1564** — Le diplôme affiche les points corrects.
- [ ] **T1565** — Le diplôme affiche les scores exacts corrects.
- [ ] **T1566** — Le diplôme affiche précision et moyenne correctes.
- [ ] **T1567** — Le diplôme affiche le meilleur rang disponible.
- [ ] **T1568** — Le diplôme reste élégant lorsqu’une statistique est absente.
- [ ] **T1569** — Le diplôme ne contient aucune donnée privée.
- [ ] **T1570** — Un joueur normal ne peut générer que son propre diplôme.
- [ ] **T1571** — L’export de tous les diplômes est réservé au Super Admin.
- [ ] **T1572** — L’export de tous les diplômes crée un diplôme par joueur classé.
- [ ] **T1573** — Aucun joueur n’est dupliqué dans l’export de diplômes.
- [ ] **T1574** — L’impression multiple conserve une page paysage par diplôme.
- [ ] **T1575** — Le diplôme affiche V0.9.8 et une date d’émission.
## Livre d’or

- [ ] **T1576** — Le Livre d’or est visible dans l’espace Fin de saison.
- [ ] **T1577** — Avant la fin de saison, un joueur ne peut pas publier dans le Livre d’or.
- [ ] **T1578** — Une saison au statut finished ouvre le Livre d’or aux joueurs.
- [ ] **T1579** — Un message de moins de 2 caractères est refusé.
- [ ] **T1580** — Un message de plus de 500 caractères est empêché/refusé.
- [ ] **T1581** — Un message valide est enregistré avec le bon joueur et la bonne saison.
- [ ] **T1582** — Chaque joueur ne possède qu’une contribution active par saison.
- [ ] **T1583** — Modifier son message remplace sa contribution sans créer de doublon.
- [ ] **T1584** — Un message sauvegardé reste présent après actualisation.
- [ ] **T1585** — Les messages publiés sont visibles par les autres joueurs connectés.
- [ ] **T1586** — Le pseudo et l’avatar affichés correspondent à l’auteur.
- [ ] **T1587** — L’ordre des messages est stable et compréhensible.
- [ ] **T1588** — Un Admin voit les messages publiés et masqués pour modération.
- [ ] **T1589** — Un Admin peut masquer un message.
- [ ] **T1590** — Un message masqué disparaît de la vue publique.
- [ ] **T1591** — L’auteur voit encore son message masqué avec son statut.
- [ ] **T1592** — Un Admin peut republier un message masqué.
- [ ] **T1593** — La modération du Livre d’or est journalisée dans audit_logs.
- [ ] **T1594** — Un joueur ne peut pas appeler directement la RPC de modération.
- [ ] **T1595** — Une saison archivée fige le Livre d’or pour les joueurs.
- [ ] **T1596** — Un joueur ne peut plus modifier son mot après archivage.
- [ ] **T1597** — Les messages d’une saison ne sont jamais visibles dans le Livre d’or d’une autre saison.
- [ ] **T1598** — Le Collector n’exporte que les messages publiés.
- [ ] **T1599** — Le Livre d’or affiche proprement l’état vide lorsqu’il n’y a aucun message.
- [ ] **T1600** — Les caractères accentués, apostrophes et emojis ne cassent pas l’affichage du Livre d’or.
## Export global & archive

- [ ] **T1601** — Le panneau Admin Fin de saison affiche l’état de préparation de la saison sélectionnée.
- [ ] **T1602** — Le compteur de matchs officiels exclut les matchs TEST.
- [ ] **T1603** — Une saison sans match officiel n’est pas déclarée prête à archiver.
- [ ] **T1604** — Une saison avec un match scheduled n’est pas prête à archiver.
- [ ] **T1605** — Une saison avec un match postponed n’est pas prête à archiver.
- [ ] **T1606** — Une saison avec un match live n’est pas prête à archiver.
- [ ] **T1607** — Une saison avec uniquement des matchs finished/cancelled est déclarée prête.
- [ ] **T1608** — Le motif de non-préparation est compréhensible dans l’Admin.
- [ ] **T1609** — Export global JSON produit un fichier exploitable.
- [ ] **T1610** — L’export JSON indique schema_version 0.9.8.
- [ ] **T1611** — L’export JSON contient saison, classement, Teams, Hall of Fame et Replay.
- [ ] **T1612** — L’export JSON contient badges, records et statistiques finales.
- [ ] **T1613** — L’export JSON contient uniquement les messages publiés du Livre d’or.
- [ ] **T1614** — L’export JSON ne contient aucune adresse e-mail.
- [ ] **T1615** — Construire l’archive est réservé au Super Admin.
- [ ] **T1616** — Construire une archive préparatoire n’archive pas immédiatement la saison.
- [ ] **T1617** — Une archive préparatoire enregistre un hash de snapshot.
- [ ] **T1618** — Reconstruire l’archive remplace le snapshot de la même saison sans doublon.
- [ ] **T1619** — Le snapshot indique schema_version 0.9.8.
- [ ] **T1620** — L’action de construction d’archive est journalisée.
- [ ] **T1621** — Le bouton Archiver définitivement reste désactivé tant que la saison n’est pas prête.
- [ ] **T1622** — La clôture définitive exige exactement la confirmation ARCHIVER.
- [ ] **T1623** — Une confirmation incorrecte est refusée côté serveur.
- [ ] **T1624** — Un Admin non Super Admin ne peut pas archiver définitivement.
- [ ] **T1625** — L’archivage final passe la saison au statut archived.
- [ ] **T1626** — L’archivage final désactive is_active pour cette saison.
- [ ] **T1627** — L’archive finale est marquée is_final=true avec finalized_at.
- [ ] **T1628** — L’action d’archivage final est journalisée.
- [ ] **T1629** — Après archivage, pronostics/champions/qualifiés/Teams restent protégés en lecture seule.
- [ ] **T1630** — Une saison archivée conserve Collector, diplômes, Hall of Fame, Replay et Livre d’or consultables.
## Admin / UX / sécurité V0.9.8

- [ ] **T1631** — La recherche Admin trouve « Fin de saison & PDF » avec les mots PDF, collector, diplôme, Livre d’or ou archive.
- [ ] **T1632** — Le panneau Fin de saison est rangé dans Admin > Application de façon visible.
- [ ] **T1633** — Le panneau Admin sépare clairement prévisualisation, export, préparation et archivage destructif.
- [ ] **T1634** — Les actions dangereuses utilisent un style visuel distinct.
- [ ] **T1635** — Le bouton d’archivage définitif n’est visible/utilisable que selon les droits prévus.
- [ ] **T1636** — Les erreurs RPC de fin de saison sont traduites en message lisible dans l’interface.
- [ ] **T1637** — Le chargement de la fin de saison ne bloque pas le reste de l’application.
- [ ] **T1638** — Changer de saison rafraîchit les données de clôture.
- [ ] **T1639** — Le panneau de fin de saison reste utilisable sur mobile.
- [ ] **T1640** — La navigation clavier atteint les boutons Collector, diplôme et archive.
- [ ] **T1641** — Les pages imprimables disposent d’un contraste suffisant.
- [ ] **T1642** — Le Centre de tests V0.9.8 est accessible depuis Admin > Laboratoire.
- [ ] **T1643** — La recherche Admin trouve le Centre de tests V0.9.8.
- [ ] **T1644** — Les anciens centres de tests V0.8.1, V0.9.0 et V0.9.5 restent accessibles.
- [ ] **T1645** — Les RPC d’administration V0.9.8 contrôlent les rôles côté serveur, pas seulement côté interface.
## Régression / sortie V0.9.8

- [ ] **T1646** — VERSION, config.js, Service Worker et manifest d’assets annoncent tous 0.9.8.
- [ ] **T1647** — Le site démarre sans erreur après passage V0.9.5 → V0.9.8.
- [ ] **T1648** — Le cockpit Admin V0.9.5 et sa recherche globale restent fonctionnels.
- [ ] **T1649** — Les sauvegardes/restaurations V0.9.5 restent fonctionnelles.
- [ ] **T1650** — Le multi-saisons V0.9.0 reste fonctionnel.
- [ ] **T1651** — Le Hall of Fame V0.9.0 reste fonctionnel.
- [ ] **T1652** — Le Replay V0.9.0 reste fonctionnel.
- [ ] **T1653** — Le vainqueur Coupe du monde 2026 reste conservé.
- [ ] **T1654** — Le Centre C1 V0.8.x reste fonctionnel et n’importe pas 2025/26 en fallback.
- [ ] **T1655** — Les pronostics, classements, LIVE et Teams restent accessibles après la migration.
- [ ] **T1656** — Le Service Worker pré-cache les nouveaux assets/pages de fin de saison.
- [ ] **T1657** — Le runner automatique V0.9.8 termine avec 0 FAIL en local.
- [ ] **T1658** — Le runner automatique V0.9.8 termine avec 0 FAIL sur GitHub Pages.
- [ ] **T1659** — Le Centre de tests V0.9.8 contient exactement 1660 contrôles uniques jusqu’à T1660.
- [ ] **T1660** — Une sauvegarde de production est réalisée avant le passage à V0.9.9 et la répétition générale.

**Critère de sortie V0.9.8 :** collector, diplôme, Livre d’or, export et archivage sont prêts avant le lancement de la saison.
