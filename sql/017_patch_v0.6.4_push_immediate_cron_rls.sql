-- Le Nid des Champions — V0.6.4
-- Correctif Web Push :
-- - réattribution sûre d'un abonnement navigateur lors d'un changement de compte ;
-- - envoi immédiat centralisé pour toute notification push non programmée ;
-- - test Cron Super Admin à heure réglable ;
-- - réveil Cron toutes les minutes.
-- À exécuter avec le rôle postgres dans Supabase SQL Editor après V0.6.2.

begin;

create extension if not exists pg_net;
create extension if not exists pg_cron;

-- -----------------------------------------------------------------------------
-- 1. Enregistrement sûr de l'appareil Push du compte connecté.
-- Le navigateur peut réutiliser le même endpoint quand un autre compte se connecte
-- sur le même profil Chrome. On autorise le transfert uniquement si les deux clés
-- cryptographiques de l'abonnement sont identiques à celles déjà enregistrées.
-- -----------------------------------------------------------------------------
create or replace function public.register_my_push_subscription_v064(
  p_endpoint text,
  p_p256dh text,
  p_auth_key text,
  p_device_name text default null,
  p_user_agent text default null,
  p_platform text default null
) returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_uid uuid := auth.uid();
  v_existing public.push_subscriptions%rowtype;
  v_id uuid;
begin
  if v_uid is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=v_uid and status='active') then
    raise exception 'Compte inactif.';
  end if;
  if nullif(trim(p_endpoint),'') is null or nullif(trim(p_p256dh),'') is null or nullif(trim(p_auth_key),'') is null then
    raise exception 'Abonnement Push incomplet.';
  end if;

  select * into v_existing
  from public.push_subscriptions
  where endpoint=trim(p_endpoint)
  for update;

  if found then
    if v_existing.user_id is distinct from v_uid
       and (v_existing.p256dh is distinct from p_p256dh or v_existing.auth_key is distinct from p_auth_key) then
      raise exception 'Cet abonnement Push appartient à un autre appareil.';
    end if;

    update public.push_subscriptions
    set user_id=v_uid,
        p256dh=p_p256dh,
        auth_key=p_auth_key,
        device_name=nullif(trim(p_device_name),''),
        user_agent=p_user_agent,
        platform=p_platform,
        active=true,
        disabled_at=null,
        failure_count=0,
        last_failure_at=null,
        updated_at=now()
    where id=v_existing.id
    returning id into v_id;
  else
    insert into public.push_subscriptions(
      user_id,endpoint,p256dh,auth_key,device_name,user_agent,platform,active
    ) values(
      v_uid,trim(p_endpoint),p_p256dh,p_auth_key,nullif(trim(p_device_name),''),p_user_agent,p_platform,true
    ) returning id into v_id;
  end if;

  return v_id;
end;
$$;

revoke all on function public.register_my_push_subscription_v064(text,text,text,text,text,text) from public,anon;
grant execute on function public.register_my_push_subscription_v064(text,text,text,text,text,text) to authenticated;

-- RLS reste stricte : un utilisateur ne lit/modifie directement que ses appareils.
drop policy if exists push_subscriptions_own on public.push_subscriptions;
drop policy if exists push_subscriptions_own_select_v064 on public.push_subscriptions;
drop policy if exists push_subscriptions_own_insert_v064 on public.push_subscriptions;
drop policy if exists push_subscriptions_own_update_v064 on public.push_subscriptions;
drop policy if exists push_subscriptions_own_delete_v064 on public.push_subscriptions;

create policy push_subscriptions_own_select_v064 on public.push_subscriptions
for select to authenticated
using(user_id=auth.uid() or public.is_super_admin());

create policy push_subscriptions_own_insert_v064 on public.push_subscriptions
for insert to authenticated
with check(user_id=auth.uid() or public.is_super_admin());

create policy push_subscriptions_own_update_v064 on public.push_subscriptions
for update to authenticated
using(user_id=auth.uid() or public.is_super_admin())
with check(user_id=auth.uid() or public.is_super_admin());

create policy push_subscriptions_own_delete_v064 on public.push_subscriptions
for delete to authenticated
using(user_id=auth.uid() or public.is_super_admin());

-- -----------------------------------------------------------------------------
-- 2. Envoi immédiat centralisé.
-- Toute notification avec push_requested=true et sans push_not_before appelle
-- push-dispatch dès le COMMIT. Si Vault/pg_net sont momentanément indisponibles,
-- la notification reste en attente et le Cron joue le rôle de filet de secours.
-- -----------------------------------------------------------------------------
create or replace function public.dispatch_immediate_push_v064()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  v_url text;
  v_secret text;
begin
  if new.push_requested is distinct from true
     or new.push_sent_at is not null
     or new.push_not_before is not null then
    return new;
  end if;

  begin
    select decrypted_secret into v_url
    from vault.decrypted_secrets
    where name='nid_push_dispatch_url'
    limit 1;

    select decrypted_secret into v_secret
    from vault.decrypted_secrets
    where name='nid_push_cron_secret'
    limit 1;

    if coalesce(v_url,'')<>'' and coalesce(v_secret,'')<>'' then
      perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
          'Content-Type','application/json',
          'x-cron-secret',v_secret
        ),
        body := jsonb_build_object(
          'action','dispatch-one',
          'notification_id',new.id
        )
      );
    end if;
  exception when others then
    -- Ne jamais faire échouer l'action métier à cause du transport Push.
    null;
  end;

  return new;
end;
$$;

revoke all on function public.dispatch_immediate_push_v064() from public,anon,authenticated;

drop trigger if exists dispatch_immediate_push_v064 on public.notifications;
create trigger dispatch_immediate_push_v064
after insert on public.notifications
for each row
when (new.push_requested = true and new.push_not_before is null)
execute function public.dispatch_immediate_push_v064();

-- -----------------------------------------------------------------------------
-- 3. Test Cron Super Admin.
-- L'enregistrement seul ne déclenche aucun Push immédiat grâce à push_not_before.
-- C'est donc bien le Cron qui devra récupérer et livrer cette notification.
-- -----------------------------------------------------------------------------
create or replace function public.admin_schedule_cron_test_v064(
  p_scheduled_at timestamptz,
  p_title text default '🦉 Test Cron du Nid',
  p_body text default 'Le réveil du Hibou fonctionne correctement.'
) returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_id uuid;
  v_when timestamptz := date_trunc('minute',p_scheduled_at);
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if v_when <= now() then raise exception 'Choisis une heure future.'; end if;
  if v_when > now()+interval '48 hours' then raise exception 'Le test Cron doit être programmé dans les 48 prochaines heures.'; end if;

  insert into public.notifications(
    user_id,season_id,category,title,body,importance,deep_link,payload,
    source_key,push_requested,push_not_before,expires_at,created_by
  ) values(
    auth.uid(),null,'system',left(trim(p_title),160),left(trim(p_body),2000),'important','home',
    jsonb_build_object('cron_test',true,'scheduled_at',v_when),
    'cron-test:'||auth.uid()::text||':'||extract(epoch from v_when)::bigint::text||':'||gen_random_uuid()::text,
    true,v_when,v_when+interval '15 minutes',auth.uid()
  ) returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.admin_schedule_cron_test_v064(timestamptz,text,text) from public,anon;
grant execute on function public.admin_schedule_cron_test_v064(timestamptz,text,text) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. Le Cron vérifie désormais chaque minute les événements programmés.
-- On conserve le même nom de job afin de remplacer proprement l'ancien */15.
-- -----------------------------------------------------------------------------
do $$
declare
  v_jobid bigint;
  v_has_url boolean;
  v_has_secret boolean;
begin
  select exists(select 1 from vault.decrypted_secrets where name='nid_push_dispatch_url') into v_has_url;
  select exists(select 1 from vault.decrypted_secrets where name='nid_push_cron_secret') into v_has_secret;

  if v_has_url and v_has_secret then
    select jobid into v_jobid from cron.job where jobname='nid-champions-push-v060' limit 1;
    if v_jobid is not null then perform cron.unschedule(v_jobid); end if;

    perform cron.schedule(
      'nid-champions-push-v060',
      '* * * * *',
      $job$
      select net.http_post(
        url := (select decrypted_secret from vault.decrypted_secrets where name='nid_push_dispatch_url'),
        headers := jsonb_build_object(
          'Content-Type','application/json',
          'x-cron-secret',(select decrypted_secret from vault.decrypted_secrets where name='nid_push_cron_secret')
        ),
        body := '{"action":"run"}'::jsonb
      );
      $job$
    );
  end if;
end $$;

insert into public.app_settings(key,value)
values ('app_version','"0.6.4"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

-- Vérifications finales uniquement : pas de SELECT intermédiaire trompeur.
select key,value from public.app_settings where key='app_version';
select jobid,jobname,schedule,active from cron.job where jobname='nid-champions-push-v060';
