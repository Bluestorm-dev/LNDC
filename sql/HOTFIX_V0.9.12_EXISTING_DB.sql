-- Le Nid des Champions — V0.9.12
-- Desktop UX/UI + cockpit de saisie des cotes + garde-fou badges classement.
begin;

insert into public.app_settings(key,value,updated_at)
values('app_version','"0.9.12"'::jsonb,now())
on conflict(key) do update set value=excluded.value,updated_at=now();

-- ---------------------------------------------------------------------------
-- 1) Les badges de catégorie "classement" ne peuvent être obtenus qu'après
--    au moins un pronostic réellement confronté à un match officiel terminé.
--    On réutilise la métrique "played" déjà produite par gamification_metrics_v070.
-- ---------------------------------------------------------------------------
update public.gamification_badges b
set condition_json=jsonb_build_object(
  'all',jsonb_build_array(
    b.condition_json,
    jsonb_build_object('metric','played','op','>=','value',1)
  )
),updated_at=now()
where b.category='classement'
  and b.auto_evaluate
  and not exists(
    select 1
    from jsonb_array_elements(coalesce(b.condition_json->'all','[]'::jsonb)) x
    where x->>'metric'='played'
  )
  and coalesce(b.condition_json->>'metric','') <> 'played';

-- Nettoie les éventuels badges classement attribués avant le début réel.
update public.player_badges pb
set revoked_at=now(),
    revoked_by=auth.uid(),
    revoke_reason='V0.9.12 — classement pas encore commencé'
from public.gamification_badges b
where pb.badge_id=b.id
  and b.category='classement'
  and pb.revoked_at is null
  and not pb.is_test
  and pb.season_id is not null
  and not exists(
    select 1
    from public.predictions p
    join public.matches m on m.id=p.match_id
    where p.user_id=pb.user_id
      and m.season_id=pb.season_id
      and m.status='finished'
      and coalesce(m.is_test,false)=false
  );

-- ---------------------------------------------------------------------------
-- 2) Cockpit Admin : saisie atomique de toutes les cotes complètes d'une journée.
--    Si une ligne échoue, la transaction RPC entière est annulée.
-- ---------------------------------------------------------------------------
create or replace function public.admin_save_matchday_odds_v0912(
  p_matchday_id uuid,
  p_rows jsonb
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  r jsonb;
  v_match_id uuid;
  v_count integer:=0;
  v_skipped integer:=0;
begin
  if not public.is_admin() then raise exception 'Réservé aux administrateurs.'; end if;
  if p_matchday_id is null then raise exception 'Journée requise.'; end if;
  if jsonb_typeof(coalesce(p_rows,'[]'::jsonb))<>'array' then raise exception 'Format de lignes invalide.'; end if;

  for r in select value from jsonb_array_elements(coalesce(p_rows,'[]'::jsonb)) loop
    begin
      v_match_id:=(r->>'match_id')::uuid;
    exception when others then
      raise exception 'Identifiant de match invalide.';
    end;

    if not exists(select 1 from public.matches m where m.id=v_match_id and m.matchday_id=p_matchday_id) then
      raise exception 'Le match % n''appartient pas à la journée sélectionnée.',v_match_id;
    end if;

    if nullif(r->>'odds_home','') is null
       or nullif(r->>'odds_draw','') is null
       or nullif(r->>'odds_away','') is null then
      v_skipped:=v_skipped+1;
      continue;
    end if;

    perform public.admin_update_match_odds_v0910(
      v_match_id,
      (r->>'odds_home')::numeric,
      (r->>'odds_draw')::numeric,
      (r->>'odds_away')::numeric,
      nullif(trim(r->>'bookmaker'),''),
      false
    );
    v_count:=v_count+1;
  end loop;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data)
  values(auth.uid(),'matchday_odds_bulk_v0912','matchday',p_matchday_id::text,
    jsonb_build_object('saved',v_count,'skipped',v_skipped));

  return jsonb_build_object('ok',true,'saved',v_count,'skipped',v_skipped);
end;$$;
grant execute on function public.admin_save_matchday_odds_v0912(uuid,jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- 3) Diagnostic courant V0.9.12.
-- ---------------------------------------------------------------------------
create or replace function public.admin_diagnostics_v0912()
returns table(section text,test text,status text,detail text)
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  return query
  select 'Version','Backend',case when coalesce((select value #>> '{}' from public.app_settings where key='app_version'),'')='0.9.12' then 'PASS' else 'FAIL' end,
         'app_settings.app_version='||coalesce((select value #>> '{}' from public.app_settings where key='app_version'),'absent')
  union all
  select 'Admin','Cotes journée',case when to_regprocedure('public.admin_save_matchday_odds_v0912(uuid,jsonb)') is not null then 'PASS' else 'FAIL' end,
         coalesce(to_regprocedure('public.admin_save_matchday_odds_v0912(uuid,jsonb)')::text,'RPC absente')
  union all
  select 'Gamification','Badges classement',case when not exists(
           select 1 from public.gamification_badges b
           where b.category='classement' and b.auto_evaluate
             and not (b.condition_json::text like '%"metric": "played"%' or b.condition_json::text like '%"metric":"played"%')
         ) then 'PASS' else 'FAIL' end,
         'Les badges classement exigent played >= 1';
end;$$;
grant execute on function public.admin_diagnostics_v0912() to authenticated;

commit;
select pg_notify('pgrst','reload schema');
