LE NID DES CHAMPIONS — V0.9.11 R6
=====================================

Le diagnostic R5 a montré que la recherche générique « Ligue des Champions »
remonte aussi la Champions Hockey League. Elle est donc supprimée.

NOUVELLE STRATÉGIE
- 4 fixtures C1 locales sans cote par exécution.
- Recherche Betclic par club domicile.
- Filtrage par adversaire + date.
- Détail Betclic revalidé strictement avant écriture.
- Curseur tournant si un lot ne trouve rien.
- Si une cote est trouvée, retour au début des matchs encore sans cote.
- Alias Club Brugge / Club Bruges ajouté.
- Lots de 4 pour éviter HTTP 546.
- Cotes manuelles toujours protégées.

INSTALLATION
Remplacer les 3 fichiers du patch puis :
  supabase functions deploy sync-betclic-odds

Aucun SQL. Aucun nouveau secret.
Version inchangée : V0.9.11.
