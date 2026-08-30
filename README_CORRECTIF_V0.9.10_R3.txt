LE NID DES CHAMPIONS — CORRECTIF V0.9.10 R3
==============================================

Ce correctif complète la V0.9.10 sans changer le numéro de version.
Il est prévu pour une installation ayant déjà reçu la V0.9.10 + R2.

CORRECTIONS
-----------
1. Calendrier Admin
   - Les cartes Journée 1 à Journée 8 deviennent cliquables.
   - Une journée ouvre la liste de ses matchs.
   - Chaque match peut être modifié : équipes, journée, horaire, stade, pays.
   - Le verrou manuel contre Football-Data reste disponible.

2. Cotes 1N2 manuelles
   - Dans l'éditeur d'un match : saisie 1 / N / 2 + bookmaker/source.
   - Les 3 valeurs sont obligatoires et > 1,00.
   - Possibilité d'effacer les cotes.
   - Modification interdite après le coup d'envoi.
   - Source enregistrée comme "manual".

3. Football-Data
   - Une indisponibilité HTTP 5xx du fournisseur n'est plus présentée comme un crash du Nid.
   - Les erreurs sont renvoyées sous forme de message exploitable par l'Admin.
   - Le calendrier local reste intact.
   - L'interface rappelle que les cotes peuvent être saisies manuellement.
   - Les erreurs restent journalisées dans les logs Supabase.

4. Deuxième choix Champion
   - L'interface indique désormais quand il doit se déverrouiller.
   - Le texte précise qu'il s'ouvre après la fin de la J8 / phase de ligue.
   - La date de la dernière rencontre prévue est calculée depuis le calendrier local.

5. Clubs modifiables
   - Le sélecteur Admin ne montre que les clubs C1 de la saison + clubs créés manuellement.
   - La même restriction est contrôlée côté SQL : un club Top 5 hors C1 ne peut pas être modifié par cette fonction.

INSTALLATION
------------
1. Copier le contenu du ZIP à la racine du projet en remplaçant les fichiers.
2. Supabase > SQL Editor : exécuter
   sql/HOTFIX_V0.9.10_R3_ADMIN_CALENDAR_ODDS.sql
3. Redéployer l'Edge Function :
   supabase functions deploy sync-football-data
4. Lancer :
   node tests\run-all-v0.9.10.mjs
   Attendu : 198 PASS · 0 WARN · 0 FAIL
5. Commit / push GitHub Pages.
6. Fermer/réouvrir la PWA ou faire Ctrl+F5.

AUCUNE MODIFICATION DE config.js.
AUCUN NOUVEAU SECRET SUPABASE.
