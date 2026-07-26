-- Le Nid des Champions — V0.5.5
-- Finitions Teams : nouveaux motifs deux couleurs type blason.
-- À exécuter après V0.5.3/V0.5.4 avec le rôle postgres dans Supabase SQL Editor.

begin;

alter table public.teams
  drop constraint if exists teams_background_style_check;

alter table public.teams
  add constraint teams_background_style_check
  check (background_style in (
    'solid','vertical','horizontal','diagonal','radial','halo',
    'split-vertical','split-horizontal','split-diagonal',
    'stripes-vertical','stripes-horizontal','stripes-diagonal','quarters'
  ));

create or replace function public.create_team_v050(
  p_season_id uuid,
  p_name text,
  p_slogan text,
  p_description text,
  p_favorite_club_id uuid,
  p_visibility text,
  p_logo_type text,
  p_logo_asset_key text,
  p_logo_url text,
  p_shape text,
  p_frame_style text,
  p_primary_color text,
  p_secondary_color text,
  p_background_style text
)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;v_name text:=trim(p_name);v_slug text;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if not exists(select 1 from public.profiles where id=auth.uid() and status='active') then raise exception 'Compte inactif.'; end if;
  if exists(select 1 from public.team_memberships where season_id=p_season_id and user_id=auth.uid() and left_at is null) then raise exception 'Tu appartiens déjà à une Team.'; end if;
  if char_length(v_name) not between 3 and 30 then raise exception 'Le nom doit contenir entre 3 et 30 caractères.'; end if;
  if coalesce(char_length(p_slogan),0)>80 then raise exception 'Slogan trop long.'; end if;
  if coalesce(char_length(p_description),0)>160 then raise exception 'Description trop longue.'; end if;
  if p_visibility not in ('public','private') then raise exception 'Visibilité invalide.'; end if;
  if p_background_style not in (
    'solid','vertical','horizontal','diagonal','radial','halo',
    'split-vertical','split-horizontal','split-diagonal',
    'stripes-vertical','stripes-horizontal','stripes-diagonal','quarters'
  ) then raise exception 'Fond invalide.'; end if;
  if p_logo_type not in ('library','upload') then raise exception 'Type de logo invalide.'; end if;
  v_slug:=public.slugify_team_v050(v_name)||'-'||substr(replace(gen_random_uuid()::text,'-',''),1,6);

  insert into public.teams(season_id,name,slug,slogan,description,favorite_club_id,visibility,captain_user_id,logo_type,logo_asset_key,logo_url,shape,frame_style,primary_color,secondary_color,background_style)
  values(p_season_id,v_name,v_slug,nullif(trim(p_slogan),''),nullif(trim(p_description),''),p_favorite_club_id,p_visibility,auth.uid(),p_logo_type,nullif(p_logo_asset_key,''),nullif(p_logo_url,''),coalesce(nullif(p_shape,''),'shield-classic'),coalesce(nullif(p_frame_style,''),'champions'),coalesce(nullif(p_primary_color,''),'#315cff'),coalesce(nullif(p_secondary_color,''),'#7454ff'),p_background_style)
  returning id into v_id;

  insert into public.team_memberships(season_id,team_id,user_id,join_type) values(p_season_id,v_id,auth.uid(),'creator');
  perform public.log_team_event_v050(v_id,'team_created',auth.uid(),jsonb_build_object('name',v_name),auth.uid());
  return v_id;
exception when unique_violation then
  raise exception 'Ce nom de Team est déjà utilisé pour cette saison.';
end;
$$;

grant execute on function public.create_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;

insert into public.app_settings(key,value)
values ('app_version','"0.5.5"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
select conname,pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid='public.teams'::regclass and conname='teams_background_style_check';
