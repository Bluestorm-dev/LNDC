-- Le Nid des Champions — V0.7.2
-- Nettoyage complet du calendrier/tableau final + import strict de la vraie saison 2026/27.
-- La logique d'import réelle se trouve dans supabase/functions/sync-football-data/index.ts.

begin;

create or replace function public.admin_delete_test_schedule_v067(p_season_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_matches integer:=0;v_days integer:=0;v_ties integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;

  -- Supprime aussi les matchs éventuellement rattachés à un tableau TEST, même si
  -- une ancienne version n'avait pas correctement positionné matches.is_test.
  delete from public.matches m
   where m.season_id=p_season_id
     and (coalesce(m.is_test,false)=true or m.tie_id in (
       select t.id from public.knockout_ties t
        where t.season_id=p_season_id and coalesce(t.is_test,false)=true
     ));
  get diagnostics v_matches=row_count;

  delete from public.knockout_ties
   where season_id=p_season_id and coalesce(is_test,false)=true;
  get diagnostics v_ties=row_count;

  delete from public.matchdays
   where season_id=p_season_id and coalesce(is_test,false)=true;
  get diagnostics v_days=row_count;

  return jsonb_build_object('ok',true,'matches_deleted',v_matches,'matchdays_deleted',v_days,'ties_deleted',v_ties);
end;
$$;

grant execute on function public.admin_delete_test_schedule_v067(uuid) to authenticated;

create or replace function public.admin_delete_all_matches_v067(p_season_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_matches integer:=0;v_days integer:=0;v_ties integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;

  -- Ordre volontaire : les matchs sont retirés avant les confrontations. Les
  -- pronostics de qualifiés liés aux ties sont ensuite supprimés par cascade.
  delete from public.matches where season_id=p_season_id;
  get diagnostics v_matches=row_count;

  delete from public.knockout_ties where season_id=p_season_id;
  get diagnostics v_ties=row_count;

  delete from public.matchdays where season_id=p_season_id;
  get diagnostics v_days=row_count;

  return jsonb_build_object('ok',true,'matches_deleted',v_matches,'matchdays_deleted',v_days,'ties_deleted',v_ties);
end;
$$;

grant execute on function public.admin_delete_all_matches_v067(uuid) to authenticated;

insert into public.app_settings(key,value) values('app_version','"0.7.2"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

commit;
