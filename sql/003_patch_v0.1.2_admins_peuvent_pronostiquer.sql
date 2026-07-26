-- Le Nid des Champions — V0.1.2
-- Tous les comptes ACTIFS peuvent pronostiquer, quel que soit leur rôle.
-- Player / Admin / Super Admin jouent avec leur propre compte.
-- À exécuter dans Supabase > SQL Editor avec le rôle postgres / par défaut.

begin;

-- Les privilèges de table sont nécessaires, puis la RLS limite chaque utilisateur
-- à ses propres pronostics. Ceci ne donne AUCUN droit sur les profils/rôles.
grant select, insert, update on public.predictions to authenticated;

-- Réaffirme explicitement que le droit de jouer dépend du statut ACTIVE,
-- et non du rôle player/admin/super_admin.
drop policy if exists predictions_insert_own on public.predictions;
create policy predictions_insert_own on public.predictions
for insert to authenticated
with check (
  user_id = auth.uid()
  and public.is_active_member()
);

drop policy if exists predictions_update_own on public.predictions;
create policy predictions_update_own on public.predictions
for update to authenticated
using (
  user_id = auth.uid()
  and public.is_active_member()
)
with check (
  user_id = auth.uid()
  and public.is_active_member()
);

insert into public.app_settings(key, value)
values ('app_version', '"0.1.2"'::jsonb)
on conflict (key) do update set value = excluded.value, updated_at = now();

commit;

-- Vérification utile : ton compte doit apparaître ACTIVE, mais son rôle peut être
-- player, admin ou super_admin.
select id, username, role, status
from public.profiles
where id = auth.uid()
   or lower(username::text) = lower('Parkaf');
