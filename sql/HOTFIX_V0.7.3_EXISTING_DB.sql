-- Le Nid des Champions — V0.7.3
-- Correction : le rôle applicatif (player/admin/super_admin) est indépendant du capitanat Team.
-- Un joueur crée une Team sans changer public.profiles.role.

begin;

-- La colonne historique logo_type reste obligatoire en base, même si l'UI n'affiche plus de logo.
-- La fonction accepte donc l'absence de logo côté client et stocke la valeur technique 'library'.
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
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_id uuid;
  v_name text:=trim(p_name);
  v_slug text;
  v_app_role text;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;

  select role into v_app_role
  from public.profiles
  where id=auth.uid() and status='active'
  for update;

  if not found then raise exception 'Compte inactif.'; end if;
  if v_app_role not in ('player','admin','super_admin') then
    raise exception 'Rôle applicatif invalide.';
  end if;

  if exists(
    select 1 from public.team_memberships
    where season_id=p_season_id and user_id=auth.uid() and left_at is null
  ) then raise exception 'Tu appartiens déjà à une Team.'; end if;

  if char_length(v_name) not between 3 and 30 then raise exception 'Le nom doit contenir entre 3 et 30 caractères.'; end if;
  if coalesce(char_length(p_slogan),0)>80 then raise exception 'Slogan trop long.'; end if;
  if coalesce(char_length(p_description),0)>160 then raise exception 'Description trop longue.'; end if;
  if p_visibility not in ('public','private') then raise exception 'Visibilité invalide.'; end if;
  if p_background_style not in ('solid','vertical','horizontal','diagonal','radial','halo') then raise exception 'Fond invalide.'; end if;

  v_slug:=public.slugify_team_v050(v_name)||'-'||substr(replace(gen_random_uuid()::text,'-',''),1,6);

  insert into public.teams(
    season_id,name,slug,slogan,description,favorite_club_id,visibility,captain_user_id,
    logo_type,logo_asset_key,logo_url,shape,frame_style,primary_color,secondary_color,background_style
  ) values(
    p_season_id,v_name,v_slug,nullif(trim(p_slogan),''),nullif(trim(p_description),''),
    p_favorite_club_id,p_visibility,auth.uid(),
    'library',null,null,
    coalesce(nullif(p_shape,''),'shield-classic'),
    coalesce(nullif(p_frame_style,''),'champions'),
    coalesce(nullif(p_primary_color,''),'#315cff'),
    coalesce(nullif(p_secondary_color,''),'#7454ff'),
    p_background_style
  ) returning id into v_id;

  insert into public.team_memberships(season_id,team_id,user_id,join_type)
  values(p_season_id,v_id,auth.uid(),'creator');

  perform public.log_team_event_v050(
    v_id,'team_created',auth.uid(),
    jsonb_build_object('name',v_name,'application_role',v_app_role,'team_role','captain'),
    auth.uid()
  );

  -- Garde-fou : la création d'une Team ne doit jamais modifier le rôle global.
  if (select role from public.profiles where id=auth.uid()) is distinct from v_app_role then
    update public.profiles set role=v_app_role where id=auth.uid();
    raise exception 'La création a tenté de modifier le rôle du compte. Opération annulée.';
  end if;

  return v_id;
exception when unique_violation then
  raise exception 'Ce nom de Team est déjà utilisé pour cette saison.';
end;
$$;

grant execute on function public.create_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;

-- Fonction de diagnostic : rôle global + rôle Team, volontairement séparés.
create or replace function public.get_my_roles_v073(p_season_id uuid)
returns table(application_role text, team_role text, team_id uuid)
language sql
stable
security definer
set search_path=public
as $$
  select
    p.role,
    case when t.captain_user_id=p.id then 'captain'
         when tm.id is not null then 'member'
         else null end,
    tm.team_id
  from public.profiles p
  left join public.team_memberships tm
    on tm.user_id=p.id and tm.season_id=p_season_id and tm.left_at is null
  left join public.teams t on t.id=tm.team_id and t.status='active'
  where p.id=auth.uid();
$$;

grant execute on function public.get_my_roles_v073(uuid) to authenticated;

insert into public.app_settings(key,value)
values('app_version','"0.7.3"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;
