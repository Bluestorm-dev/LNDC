-- Le Nid des Champions V1.0.2
-- Palmarès C1 manuel, données clubs enrichies et saisie Super Admin des buteurs/cartons.
begin;

alter table public.clubs add column if not exists ucl_titles integer not null default 0;
alter table public.clubs add column if not exists ucl_best_result text;
alter table public.clubs add column if not exists ucl_history text;

create or replace function public.admin_save_club_c1_v102(
  p_club_id uuid,
  p_short_name text,
  p_tla text,
  p_country text,
  p_venue text,
  p_address text,
  p_website text,
  p_founded integer,
  p_club_colors text,
  p_coach_name text,
  p_coach_nationality text,
  p_squad jsonb,
  p_ucl_titles integer,
  p_ucl_best_result text,
  p_ucl_history text
) returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  update public.clubs
  set short_name=nullif(trim(p_short_name),''),
      tla=nullif(trim(p_tla),''),
      country=nullif(trim(p_country),''),
      venue=nullif(trim(p_venue),''),
      address=nullif(trim(p_address),''),
      website=nullif(trim(p_website),''),
      founded=p_founded,
      club_colors=nullif(trim(p_club_colors),''),
      coach_name=nullif(trim(p_coach_name),''),
      coach_nationality=nullif(trim(p_coach_nationality),''),
      squad=coalesce(p_squad,'[]'::jsonb),
      ucl_titles=greatest(0,coalesce(p_ucl_titles,0)),
      ucl_best_result=nullif(trim(p_ucl_best_result),''),
      ucl_history=nullif(trim(p_ucl_history),''),
      manual_metadata_lock=true,
      metadata_source='manual',
      manual_metadata_updated_at=now(),
      updated_at=now()
  where id=p_club_id;
  if not found then raise exception 'Club introuvable.'; end if;
end;
$$;
grant execute on function public.admin_save_club_c1_v102(uuid,text,text,text,text,text,text,integer,text,text,text,jsonb,integer,text,text) to authenticated;

create or replace function public.admin_upsert_ucl_player_v102(
  p_season_id uuid,
  p_club_id uuid,
  p_player_name text,
  p_position text default null,
  p_nationality text default null,
  p_played_matches integer default 0,
  p_goals integer default 0,
  p_assists integer default 0,
  p_penalties integer default 0,
  p_yellow_cards integer default 0,
  p_yellow_red_cards integer default 0,
  p_red_cards integer default 0,
  p_player_external_id bigint default null
) returns bigint
language plpgsql
security definer
set search_path=public
as $$
declare
  v_id bigint;
  v_name text:=nullif(trim(p_player_name),'');
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if v_name is null then raise exception 'Nom du joueur obligatoire.'; end if;
  v_id:=p_player_external_id;
  if v_id is null then
    select player_external_id into v_id from public.ucl_player_stats
    where season_id=p_season_id and club_id=p_club_id and lower(player_name)=lower(v_name) limit 1;
  end if;
  if v_id is null then
    select player_external_id into v_id from public.ucl_discipline_stats
    where season_id=p_season_id and club_id=p_club_id and lower(player_name)=lower(v_name) limit 1;
  end if;
  if v_id is null then
    v_id := -(1000000000::bigint + abs(hashtext(v_name||':'||coalesce(p_club_id::text,'')))::bigint);
  end if;

  insert into public.ucl_player_stats(season_id,player_external_id,player_name,club_id,position,nationality,played_matches,goals,assists,penalties,updated_at)
  values(p_season_id,v_id,v_name,p_club_id,nullif(trim(p_position),''),nullif(trim(p_nationality),''),greatest(0,coalesce(p_played_matches,0)),greatest(0,coalesce(p_goals,0)),greatest(0,coalesce(p_assists,0)),greatest(0,coalesce(p_penalties,0)),now())
  on conflict(season_id,player_external_id) do update set
    player_name=excluded.player_name,club_id=excluded.club_id,position=excluded.position,nationality=excluded.nationality,
    played_matches=excluded.played_matches,goals=excluded.goals,assists=excluded.assists,penalties=excluded.penalties,updated_at=now();

  insert into public.ucl_discipline_stats(season_id,player_external_id,player_name,club_id,yellow_cards,red_cards,yellow_red_cards,updated_at)
  values(p_season_id,v_id,v_name,p_club_id,greatest(0,coalesce(p_yellow_cards,0)),greatest(0,coalesce(p_red_cards,0)),greatest(0,coalesce(p_yellow_red_cards,0)),now())
  on conflict(season_id,player_external_id) do update set
    player_name=excluded.player_name,club_id=excluded.club_id,yellow_cards=excluded.yellow_cards,
    red_cards=excluded.red_cards,yellow_red_cards=excluded.yellow_red_cards,updated_at=now();

  return v_id;
end;
$$;
grant execute on function public.admin_upsert_ucl_player_v102(uuid,uuid,text,text,text,integer,integer,integer,integer,integer,integer,integer,bigint) to authenticated;

create or replace function public.admin_delete_ucl_player_v102(
  p_season_id uuid,
  p_player_external_id bigint
) returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  delete from public.ucl_player_stats where season_id=p_season_id and player_external_id=p_player_external_id;
  delete from public.ucl_discipline_stats where season_id=p_season_id and player_external_id=p_player_external_id;
end;
$$;
grant execute on function public.admin_delete_ucl_player_v102(uuid,bigint) to authenticated;

insert into public.app_settings(key,value,description,updated_at)
values('app_version','"1.0.2"'::jsonb,'Version applicative',now())
on conflict(key) do update set value=excluded.value,updated_at=now();

commit;
