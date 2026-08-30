LE NID DES CHAMPIONS — V0.9.11 R4
=====================================

RÉSULTAT R3 VALIDÉ
27 résultats Betclic · 1 match rapproché · 1 cote mise à jour.
La chaîne Betclic -> 1N2 -> Supabase fonctionne réellement.

PROBLÈME RESTANT
SearchMatchesWithNotifications peut renvoyer le nom du match sans fournir
les deux objets teams ou la date complète dans le résultat léger.
Le R3 exigeait ces données avant même de demander le détail : beaucoup de
bons résultats pouvaient donc être rejetés trop tôt.

CORRECTION R4
- Si event.teams est absent/incomplet, lecture des équipes depuis :
    Club A - Club B
    Club A – Club B
    Club A — Club B
    Club A vs Club B
- Une date absente du résultat SearchService est autorisée pour un
  rapprochement PROVISOIRE.
- Avant d'enregistrer une cote, GetMatchWithNotification est appelé et
  le détail complet est revalidé STRICTEMENT :
    équipe domicile
    équipe extérieure
    date à +/- 36 heures
- Si le détail ne correspond pas, aucune cote n'est écrite.
- L'Admin affiche les rapprochements provisoires et les rejets après détail.
- Lots de 6 et protections HTTP 546 du R3 conservés.
- Cotes manuelles toujours prioritaires.

INSTALLATION
Remplacer :
- supabase/functions/sync-betclic-odds/index.ts
- js/release0911.js
- tests/run-all-v0.9.11.mjs

Puis :
  supabase functions deploy sync-betclic-odds

AUCUN SQL.
AUCUN NOUVEAU SECRET.
Version inchangée : V0.9.11.
