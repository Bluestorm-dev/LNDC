# Le Nid des Champions — Checklist V0.9.11

**40 contrôles spécifiques** à Betclic expérimental, l’ouverture progressive et le nettoyage pré-production.

## Installation

- [ ] **T1921** — Le HOTFIX V0.9.11 s’exécute sans erreur et app_settings.app_version devient 0.9.11.
- [ ] **T1922** — La Function sync-betclic-odds est déployée avec verify_jwt=true.
## Betclic expérimental

- [ ] **T1923** — Le bouton Tester Betclic lit le flux sans modifier les matchs locaux.
- [ ] **T1924** — Une panne Betclic n’empêche ni l’affichage du Nid ni la saisie manuelle des cotes.
- [ ] **T1925** — Une cote 1N2 saisie manuellement n’est jamais écrasée par Betclic.
- [ ] **T1926** — Le rapprochement Betclic tient compte des alias de clubs, dont AEK Athens / AEK Athènes / PAE AEK.
- [ ] **T1927** — Une synchronisation Betclic met à jour uniquement les matchs locaux reconnus.
- [ ] **T1928** — L’Admin affiche le nombre de matchs rapprochés, mis à jour et sans marché 1N2.
## Ouverture progressive

- [ ] **T1929** — Quand Teams est verrouillé, un joueur ne voit plus l’onglet Teams.
- [ ] **T1930** — Quand Musée & gamification est verrouillé, un joueur ne voit plus l’onglet Musée ni ses cartes d’accueil.
- [ ] **T1931** — Quand Messages & notifications est verrouillé, un joueur ne voit plus la cloche, les messages du Hibou ni l’activation Push.
- [ ] **T1932** — Quand Phases finales est verrouillé, un joueur ne voit plus l’onglet et un accès direct est refusé.
- [ ] **T1933** — Quand Centre C1 ou Soirées européennes est verrouillé, les écrans correspondants disparaissent pour les joueurs.
- [ ] **T1934** — Le Super Admin garde toutes les fonctions visibles même lorsqu’elles sont verrouillées aux joueurs.
- [ ] **T1935** — Le Super Admin voit un indicateur OUVERT / VERROUILLÉ sur les fonctions principales.
- [ ] **T1936** — Un changement d’interrupteur app_settings est répercuté aux clients connectés via Realtime.
## Communication

- [ ] **T1937** — Le bouton Supprimer tous les messages est réservé au Super Admin et exige la phrase exacte.
- [ ] **T1938** — La purge supprime messages, notifications et données de support de test sans supprimer les comptes ni préférences Push.
## Pré-production

- [ ] **T1939** — Le reset avant ouverture ne déclenche plus l’erreur DELETE requires a WHERE clause.
## GO V0.9.11

- [ ] **T1940** — Runner local et distant V0.9.11 terminent avec 0 FAIL avant validation de la release.
## Betclic expérimental

- [ ] **X01** — Une requête Betclic n’est lancée que depuis une action Admin explicite.
- [ ] **X02** — Aucun compte Betclic et aucun secret Betclic n’est stocké dans le Nid.
- [ ] **X03** — Le marché demandé est limité au résultat 1N2 ca_ftb_rslt.
- [ ] **X04** — Les matchs déjà marqués odds_provider=manual sont ignorés par la synchro Betclic.
## Ouverture progressive

- [ ] **X05** — Rivalités peut être masqué indépendamment.
- [ ] **X06** — Sondages peut être masqué indépendamment.
- [ ] **X07** — Hibou solitaire peut être masqué indépendamment.
- [ ] **X08** — Le Super Admin peut activer une fonction sans redéployer le site.
- [ ] **X09** — Un joueur ne peut pas forcer un écran verrouillé avec un accès direct.
- [ ] **X10** — Accueil, Pronostics, Classements, Saison et Profil restent accessibles.
## Communication

- [ ] **X11** — Chaque DELETE de la purge contient un WHERE explicite.
- [ ] **X12** — Le compteur communication est disponible avant la purge.
- [ ] **X13** — Les push subscriptions ne sont pas supprimées.
- [ ] **X14** — Les préférences de notification ne sont pas supprimées.
- [ ] **X15** — Une trace audit est ajoutée après la purge.
## Pré-production

- [ ] **X16** — La RPC de fusion de clubs est présente après le HOTFIX V0.9.11.
- [ ] **X17** — Les alias AEK empêchent la recréation AEK Athènes / PAE AEK.
- [ ] **X18** — Le correctif de modales R4 reste présent.
- [ ] **X19** — Les 100 succès et leurs images restent présents.
- [ ] **X20** — Les cotes manuelles V0.9.10 restent modifiables depuis un match.
