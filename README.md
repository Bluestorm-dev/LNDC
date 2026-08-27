# Le Nid des Champions — V0.9.0

PWA de pronostics UEFA Champions League avec Teams, rivalités, gamification, Centre C1 et désormais une vraie mémoire multi-saisons.

## Nouveautés V0.9.0 — Saison, carrière & mémoire

- **Multi-saisons** : consulter une saison ancienne ou active sans mélanger les données.
- **Archives en lecture seule** : une saison terminée reste visible mais ses pronostics et Teams sont figés côté joueurs.
- **Profil saison enrichi** : rang, meilleur rang, remontées, jours en tête, forme, précision et historique de classement.
- **Carrière** : saisons jouées, statistiques cumulées et classement carrière.
- **Hall of Fame** : champions, podiums, Teams, scoreurs, exacts, Poêle d'Or, Génie, Hibou solitaire et records.
- **Replay de saison** : chronologie des événements et performances mémorables.
- **Champion en titre & distinctions** persistantes.
- **Sondages généraux** administrables.
- **Road-check V0.1.x → V0.9.0** : 1330 contrôles + diagnostic SQL + runner local.

Les fonctions V0.8.1 restent conservées, notamment la synchronisation Football-Data strictement 2026/27 sans fallback 2025/26.

## Mise à jour depuis V0.8.1

Voir `INSTALLATION_V0.9.0.txt`.

## Tests

- `README_TEST_SYSTEM_V0.9.0.md`
- `docs/TEST_CHECKLIST_V0.9.0.md`
- `docs/TEST_MATRIX_V0.9.0.md`

V0.9.0 — Palmarès historique
- Le Super Admin peut désigner ou retirer manuellement le « Vainqueur du Nid des Pronos — Coupe du monde 2026 ».
- Cette distinction est unique, persistante entre les saisons et visible dans le profil/carrière.
