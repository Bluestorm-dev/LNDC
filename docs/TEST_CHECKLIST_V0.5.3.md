# Le Nid des Champions — Checklist V0.5.3

## 1. Migration Supabase

- [ ] `sql/HOTFIX_V0.5.3_EXISTING_DB.sql` s’exécute sans erreur avec le rôle `postgres`.
- [ ] `app_settings.app_version` vaut `0.5.3`.
- [ ] Le bucket `player-avatars` existe, est privé, limité à 3 Mo et aux MIME PNG/JPEG/WebP.
- [ ] Les colonnes avatar V0.5.3 existent dans `profiles`.
- [ ] Les quatre RPC `*avatar*v053` sont visibles après reload du schéma.

## 2. Bibliothèque officielle

- [ ] Le Profil affiche 9 catégories / 90 avatars.
- [ ] Chaque vignette charge un PNG sans image cassée.
- [ ] Cliquer un avatar change l’aperçu sans l’enregistrer immédiatement.
- [ ] « Utiliser l’avatar officiel sélectionné » met à jour l’avatar du joueur.
- [ ] Après rechargement, l’avatar sélectionné est conservé.

## 3. Habillage Team

- [ ] Sans Team, l’aperçu affiche uniquement l’avatar.
- [ ] Avec Team, le cadre/forme/couleurs/logo restent autour de l’avatar.
- [ ] L’image personnelle reste au premier plan et n’est pas remplacée par le logo Team.

## 4. Upload joueur

- [ ] PNG accepté.
- [ ] JPG/JPEG accepté.
- [ ] WebP accepté.
- [ ] Un autre format est refusé côté front.
- [ ] Un fichier > 3 Mo est refusé.
- [ ] Le fichier apparaît en aperçu local avant envoi.
- [ ] Après envoi, `profiles.avatar_moderation_status = pending`.
- [ ] Le joueur voit son upload en attente dans son Profil avec l’indicateur ⏳.
- [ ] Les autres vues publiques continuent d’afficher l’avatar officiel tant que l’upload est pending.

## 5. RLS Storage

- [ ] Un joueur peut uploader dans `<son_uuid>/...`.
- [ ] Un joueur ne peut pas uploader dans le dossier UUID d’un autre joueur.
- [ ] Un joueur ne peut pas modifier directement `avatar_moderation_status` via le front.
- [ ] Admin/Super Admin peut modérer l’avatar.

## 6. Modération Admin

- [ ] Administration > « Modération des avatars » liste les uploads pending.
- [ ] « Valider » passe l’avatar en `approved`.
- [ ] L’avatar approuvé apparaît ensuite dans les vues publiques.
- [ ] « Refuser » accepte un motif facultatif et passe en `rejected`.
- [ ] Après refus, l’avatar officiel est utilisé publiquement.
- [ ] Une ligne `audit_logs` est créée pour approve/reject.

## 7. Intégrations

- [ ] Sidebar : avatar correct.
- [ ] Profil : avatar correct.
- [ ] Classement général : avatar correct.
- [ ] Classement journée/soirée/précision/exacts : avatar correct.
- [ ] Classement LIVE : avatar correct pendant un match live.
- [ ] Teams : membres et demandes affichent les avatars.
- [ ] Pronos révélés : après verrouillage, la modale affiche les avatars.
- [ ] Aucun avatar adverse n’est révélé avant le verrouillage via la modale des pronostics.

## 8. PWA / régression

- [ ] Cache `nid-champions-v0.5.3`.
- [ ] Auth, pronostics, Champions, phases finales et Teams V0.5.2 restent fonctionnels.
- [ ] `node tests/release-v0.5.3.mjs` retourne `OK`.
