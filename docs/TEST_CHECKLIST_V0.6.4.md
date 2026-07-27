# Checklist V0.6.4 — Web Push immédiat & Cron

- [ ] `VERSION` affiche `0.6.4`.
- [ ] `app_settings.app_version` vaut `0.6.4` après le HOTFIX.
- [ ] `push-dispatch` V0.6.4 est redéployée.
- [ ] Le job `nid-champions-push-v060` affiche `* * * * *`.
- [ ] Un compte joueur non Super Admin peut activer le Push sans erreur RLS.
- [ ] Le même navigateur peut être réaffecté au compte connecté sans ouvrir les droits RLS aux autres appareils.
- [ ] Le Test Push envoie exactement le titre personnalisé.
- [ ] Le Test Push envoie exactement le corps personnalisé.
- [ ] Un message Hibou avec Push arrive immédiatement.
- [ ] Un message Hibou sans Push reste uniquement dans le Nid.
- [ ] Un message système critique avec Push arrive immédiatement.
- [ ] Une réaction / notification Team / rivalité demandant un Push passe par le déclencheur immédiat.
- [ ] Le Test Cron peut être programmé à une heure future.
- [ ] Le Test Cron n'est pas envoyé immédiatement au moment de la programmation.
- [ ] Le Test Cron est reçu à l'heure choisie, avec une tolérance d'environ 1 minute.
- [ ] Le journal Push distingue `immediate`, `test`, `cron-test` et les livraisons ordinaires.
- [ ] Un abonnement 404/410 est toujours désactivé automatiquement.
- [ ] Le cache PWA est `nid-champions-v0.6.4`.
