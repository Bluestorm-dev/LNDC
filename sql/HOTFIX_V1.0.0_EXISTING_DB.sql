-- Le Nid des Champions — HOTFIX V1.0.0
-- À appliquer sur une base V0.9.14 / V0.9.14b existante.
-- Corrige l'enregistrement Push joueur, active les records pendant une journée en cours,
-- nettoie les doublons de notifications de classement et recale leur état de référence.

begin;

-- =============================================================================
-- 1. Push : n'importe quel joueur ACTIF peut enregistrer l'appareil qu'il possède.
-- Un endpoint Web Push est propre au profil navigateur ; il peut survivre à un changement
-- de compte. V1.0.0 le réattribue au compte actuellement authentifié.
-- =============================================================================
create or replace function public.register_my_push_subscription_v100(
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
  v_id uuid;
begin
  if v_uid is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=v_uid and status='active') then
    raise exception 'Compte inactif.';
  end if;
  if nullif(trim(p_endpoint),'') is null or nullif(trim(p_p256dh),'') is null or nullif(trim(p_auth_key),'') is null then
    raise exception 'Abonnement Push incomplet.';
  end if;

  insert into public.push_subscriptions(
    user_id,endpoint,p256dh,auth_key,device_name,user_agent,platform,active,disabled_at,failure_count,last_failure_at
  ) values(
    v_uid,trim(p_endpoint),p_p256dh,p_auth_key,nullif(trim(p_device_name),''),p_user_agent,p_platform,true,null,0,null
  )
  on conflict(endpoint) do update set
    user_id=excluded.user_id,
    p256dh=excluded.p256dh,
    auth_key=excluded.auth_key,
    device_name=excluded.device_name,
    user_agent=excluded.user_agent,
    platform=excluded.platform,
    active=true,
    disabled_at=null,
    failure_count=0,
    last_failure_at=null,
    updated_at=now()
  returning id into v_id;

  insert into public.notification_preferences(user_id,notifications_enabled,push_enabled)
  values(v_uid,true,true)
  on conflict(user_id) do update set notifications_enabled=true,push_enabled=true,updated_at=now();

  return v_id;
end;
$$;

revoke all on function public.register_my_push_subscription_v100(text,text,text,text,text,text) from public,anon;
grant execute on function public.register_my_push_subscription_v100(text,text,text,text,text,text) to authenticated;

-- =============================================================================
-- 2. Records : la vitrine du Musée vit dès les premiers résultats terminés.
-- Le détenteur actif peut donc évoluer pendant la journée UEFA.
-- =============================================================================
create or replace function public.refresh_records_v070(p_season_id uuid,p_matchday_id uuid,p_is_test boolean default false)
returns void language plpgsql security definer set search_path=public as $$
declare r record; finished_matches int;
begin
  select count(*) into finished_matches
  from public.matches m
  where m.matchday_id=p_matchday_id
    and m.status='finished'
    and coalesce(m.is_test,false)=p_is_test
    and (not p_is_test or coalesce(m.test_enabled,true)=true);
  if finished_matches=0 then return; end if;

  for r in
    select p.user_id,sum(coalesce(p.points,0))::numeric points,
           count(*) filter(where p.home_score=m.home_score and p.away_score=m.away_score)::numeric exacts
    from public.predictions p join public.matches m on m.id=p.match_id
    where p.season_id=p_season_id and m.matchday_id=p_matchday_id and m.status='finished'
      and coalesce(m.is_test,false)=p_is_test
      and (not p_is_test or coalesce(m.test_enabled,true)=true)
    group by p.user_id order by p.user_id
  loop
    perform public.upsert_personal_record_v070(p_season_id,'personal_best_matchday_points','Record personnel · meilleure journée','performance',r.user_id,r.points,p_matchday_id,p_is_test);
    perform public.upsert_personal_record_v070(p_season_id,'personal_best_matchday_exacts','Record personnel · exacts sur une journée','precision',r.user_id,r.exacts,p_matchday_id,p_is_test);
  end loop;

  for r in
    select p.user_id,sum(coalesce(p.points,0))::numeric value
    from public.predictions p join public.matches m on m.id=p.match_id
    where p.season_id=p_season_id and m.matchday_id=p_matchday_id and m.status='finished'
      and coalesce(m.is_test,false)=p_is_test
      and (not p_is_test or coalesce(m.test_enabled,true)=true)
    group by p.user_id order by value desc,p.user_id
  loop
    perform public.upsert_record_candidate_v070(p_season_id,'best_matchday_points','Meilleure journée en cours','performance',r.user_id,r.value,p_matchday_id,p_is_test);
  end loop;

  for r in
    select p.user_id,count(*) filter(where p.home_score=m.home_score and p.away_score=m.away_score)::numeric value
    from public.predictions p join public.matches m on m.id=p.match_id
    where p.season_id=p_season_id and m.matchday_id=p_matchday_id and m.status='finished'
      and coalesce(m.is_test,false)=p_is_test
      and (not p_is_test or coalesce(m.test_enabled,true)=true)
    group by p.user_id order by value desc,p.user_id
  loop
    perform public.upsert_record_candidate_v070(p_season_id,'best_matchday_exacts','Scores exacts · journée en cours','precision',r.user_id,r.value,p_matchday_id,p_is_test);
  end loop;
end;$$;

-- =============================================================================
-- 3. Nettoyage des doublons de classement déjà créés par les actualisations LIVE.
-- On garde le plus récent d'un message identique émis dans la même minute.
-- =============================================================================
with duplicate_rank_notifications as (
  select id,
         row_number() over(
           partition by user_id,season_id,title,body,date_trunc('minute',created_at)
           order by created_at desc,id desc
         ) as rn
  from public.notifications
  where category='ranking' and deleted_at is null
)
update public.notifications n
set deleted_at=now()
from duplicate_rank_notifications d
where n.id=d.id and d.rn>1;

-- Recalage sur le classement OFFICIEL, sans score LIVE, pour que le prochain bilan
-- compare une situation stable à une situation stable.
do $$
declare v_season uuid;
begin
  select id into v_season from public.seasons where is_active=true order by created_at desc limit 1;
  if v_season is not null then
    insert into public.ranking_notification_state(season_id,user_id,rank,points,updated_at)
    select v_season,l.user_id,l.rank::int,round(coalesce(l.points,0))::int,now()
    from public.get_leaderboard_v040(v_season,'general',null,null,false) l
    on conflict(season_id,user_id) do update
      set rank=excluded.rank,points=excluded.points,updated_at=now();
  end if;
end $$;

-- Lance un premier calcul des records sur les journées ayant déjà au moins un match fini.
do $$
declare r record;
begin
  for r in
    select distinct m.season_id,m.matchday_id
    from public.matches m join public.seasons s on s.id=m.season_id
    where s.is_active=true and m.matchday_id is not null and m.status='finished' and coalesce(m.is_test,false)=false
  loop
    perform public.refresh_records_v070(r.season_id,r.matchday_id,false);
  end loop;
end $$;

insert into public.app_settings(key,value)
values ('app_version','"1.0.0"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
