-- Le Nid des Champions — V0.6.0
-- PLANIFICATION DU MOTEUR PUSH / RAPPELS (modèle)
--
-- 1) Remplace les deux valeurs PLACEHOLDER ci-dessous.
-- 2) Exécute ce script dans Supabase > SQL Editor avec le rôle postgres.
-- 3) Le moteur appellera push-dispatch toutes les 15 minutes.
--
-- Ne mets JAMAIS le service_role dans ce script ni dans GitHub.
-- Le secret cron est stocké dans Supabase Vault.

-- Les modules Cron (pg_cron), pg_net et Vault doivent être activés dans le projet Supabase.
-- Sur la plateforme hébergée, ils peuvent être activés depuis le Dashboard.
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Exemple d'URL : https://abcdefgh.supabase.co/functions/v1/push-dispatch
select vault.create_secret(
  'https://PROJECT_REF.supabase.co/functions/v1/push-dispatch',
  'nid_push_dispatch_url'
)
where not exists (
  select 1 from vault.decrypted_secrets where name='nid_push_dispatch_url'
);

select vault.create_secret(
  'REMPLACE_PAR_LE_MEME_PUSH_CRON_SECRET_QUE_DANS_SUPABASE_SECRETS',
  'nid_push_cron_secret'
)
where not exists (
  select 1 from vault.decrypted_secrets where name='nid_push_cron_secret'
);

-- Supprime l'ancienne tâche portant ce nom avant de la recréer.
do $$
declare v_jobid bigint;
begin
  select jobid into v_jobid from cron.job where jobname='nid-champions-push-v060' limit 1;
  if v_jobid is not null then perform cron.unschedule(v_jobid); end if;
end $$;

select cron.schedule(
  'nid-champions-push-v060',
  '*/15 * * * *',
  $cron$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name='nid_push_dispatch_url'),
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'x-cron-secret',(select decrypted_secret from vault.decrypted_secrets where name='nid_push_cron_secret')
    ),
    body := '{"action":"run"}'::jsonb
  );
  $cron$
);

-- Vérification :
select jobid,jobname,schedule,active from cron.job where jobname='nid-champions-push-v060';
