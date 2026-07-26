# Le Nid des Champions — Checklist V0.6.0

## Release
- [ ] `VERSION` = `0.6.0`.
- [ ] `config.js` conserve les vraies clés publiques Supabase.
- [ ] cache Service Worker = `nid-champions-v0.6.0`.
- [ ] `node tests/release-v0.6.0.mjs` retourne `V0.6.0 release tests: OK`.
- [ ] aucun dossier du projet ne dépasse 100 fichiers pour l'upload GitHub par dossier.

## Migration
- [ ] sauvegarde Supabase réalisée.
- [ ] `sql/HOTFIX_V0.6.0_EXISTING_DB.sql` exécuté avec le rôle postgres.
- [ ] `app_settings.app_version` = `0.6.0`.
- [ ] bucket privé `support-captures` présent.

## Notifications internes
- [ ] cloche visible desktop et mobile.
- [ ] badge = nombre de notifications non lues autorisées par les préférences.
- [ ] ouvrir la cloche ne marque pas tout comme lu.
- [ ] filtres Toutes / Matchs / Rival / Team / Hibou / Système fonctionnels.
- [ ] Lu / Non lu / Supprimer fonctionnent.
- [ ] Tout marquer comme lu fonctionne.
- [ ] liens profonds ouvrent le bon écran.

## Préférences
- [ ] Sage / Piquant / Sans pitié / Automatique, Automatique par défaut.
- [ ] catégories Matchs, Champion, Résultats, Rivalités, Teams, Hibou, Réponses du Hibou, Classement.
- [ ] rappels par défaut : 3 h + 30 min.
- [ ] 24 h et 1 h désactivés par défaut.
- [ ] quiet hours par défaut : 23:00 -> 08:00.
- [ ] fuseau local de l'appareil enregistré.
- [ ] urgence prono peut contourner les quiet hours.

## Opt-in Push
- [ ] aucune permission navigateur demandée automatiquement à la connexion.
- [ ] carte « Ne rate plus tes pronostics » proposée sur l'accueil.
- [ ] la permission navigateur apparaît seulement après clic.
- [ ] refus du Push ne bloque jamais les notifications internes.
- [ ] plusieurs appareils peuvent être actifs sur le même compte.
- [ ] un appareil peut être désactivé individuellement.

## Rappels
- [ ] plusieurs pronostics manquants produisent UNE notification groupée.
- [ ] notification indique le nombre manquant.
- [ ] clic ouvre la journée concernée.
- [ ] aucun rappel si tout est pronostiqué.
- [ ] champion absent produit un rappel uniquement pendant sa fenêtre de choix.

## Rival
- [ ] n'importe quel joueur actif peut être choisi, y compris dans la même Team.
- [ ] impossible de se choisir soi-même.
- [ ] le rival reçoit une notification.
- [ ] un seul changement par journée UEFA.
- [ ] changement impossible après le premier coup d'envoi.
- [ ] rivalité mutuelle détectée.
- [ ] avant la journée, notification de reprise du duel.
- [ ] un duel est figé par journée UEFA.
- [ ] égalité = nul, sans départage.
- [ ] fin de journée -> notification victoire / nul / défaite.
- [ ] niveau de pique respecte le réglage du Hibou.
- [ ] anciens rivaux et duels restent consultables.
- [ ] fiche détaillée affiche bilan, marges, série et trajectoire.
- [ ] rival marqué dans le classement ; comparaison rapide accessible.

## Hibou
- [ ] message global visible.
- [ ] message ciblé Team visible seulement par ses membres actifs.
- [ ] message ciblé joueur visible seulement par le joueur.
- [ ] Super Admin peut envoyer un message depuis le centre Admin.
- [ ] Super Admin peut envoyer depuis le profil rapide d'un joueur.
- [ ] message critique système apparaît dans le centre interne.

## Tickets
- [ ] Bug / Suggestion / Question / Modification / Autre.
- [ ] vraie conversation joueur <-> Hibou.
- [ ] maximum 3 captures.
- [ ] PNG/JPG/WebP uniquement ; 5 Mo maximum par fichier.
- [ ] ticket Bug contient version, navigateur/appareil, résolution, vue, date/fuseau et erreurs JS récentes.
- [ ] joueur peut marquer son ticket résolu.
- [ ] joueur ne choisit pas la priorité.
- [ ] Super Admin choisit priorité et statut.
- [ ] Admin classique ne voit pas les tickets.
- [ ] réponse du Hibou produit une notification essentielle.

## Teams / classement
- [ ] demande d'adhésion prévient le capitaine et ouvre Gestion.
- [ ] acceptation/refus, nouveau membre, capitanat, exclusion, dissolution produisent les notifications prévues.
- [ ] changement d'apparence reste interne, sans Push.
- [ ] prise/perte #1 et entrée/sortie podium peuvent produire un Push.
- [ ] dépassement du rival peut produire un Push.
- [ ] petit changement de rang reste interne.

## Push réel
- [ ] VAPID configuré uniquement dans Supabase Secrets.
- [ ] `push-dispatch` déployée.
- [ ] Cron appelle la fonction toutes les 15 minutes.
- [ ] quiet hours respectées.
- [ ] abonnement 404/410 est désactivé.
- [ ] ancien abonnement désactivé peut être nettoyé après 30 jours.
- [ ] clic Push refocalise une PWA ouverte ou ouvre le site à la bonne destination.

## Super Admin — Test Push
- [ ] destinataire = Moi ou un joueur précis, jamais « tout le monde ».
- [ ] test rapide fonctionne.
- [ ] test personnalisé titre/message/destination fonctionne.
- [ ] journal affiche destinataire, appareil, date, statut et erreur éventuelle.
- [ ] message système critique demande confirmation avant envoi.
