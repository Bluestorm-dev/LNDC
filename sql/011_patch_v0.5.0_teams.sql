-- Le Nid des Champions — V0.5.0 Teams
-- À exécuter après V0.4.2 avec le rôle postgres dans Supabase SQL Editor.
-- Teams publiques/privées, capitaine unique, identité visuelle, historique, classements et Realtime.

begin;

-- =============================================================================
-- 1. Tables Teams
-- =============================================================================
create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  name text not null,
  slug text not null,
  slogan text,
  description text,
  favorite_club_id uuid references public.clubs(id) on delete set null,
  visibility text not null default 'public' check (visibility in ('public','private')),
  status text not null default 'active' check (status in ('active','dissolved')),
  captain_user_id uuid not null references public.profiles(id) on delete restrict,
  logo_type text not null default 'library' check (logo_type in ('library','upload')),
  logo_asset_key text,
  logo_url text,
  shape text not null default 'shield-classic',
  frame_style text not null default 'champions',
  primary_color text not null default '#315cff',
  secondary_color text not null default '#7454ff',
  background_style text not null default 'diagonal' check (background_style in ('solid','vertical','horizontal','diagonal','radial','halo')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  dissolved_at timestamptz,
  check (char_length(trim(name)) between 3 and 30),
  check (slogan is null or char_length(slogan) <= 80),
  check (description is null or char_length(description) <= 160)
);

create unique index if not exists teams_active_name_unique_idx on public.teams(season_id,lower(name)) where status='active';
create index if not exists teams_season_status_idx on public.teams(season_id,status,name);
create index if not exists teams_captain_idx on public.teams(captain_user_id,status);

drop trigger if exists teams_updated_at on public.teams;
create trigger teams_updated_at before update on public.teams
for each row execute function public.set_updated_at();

create table if not exists public.team_memberships (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  join_type text not null default 'public' check (join_type in ('creator','public','request','code','admin')),
  leave_type text check (leave_type in ('left','kicked','dissolved','admin')),
  created_at timestamptz not null default now(),
  check (left_at is null or left_at >= joined_at)
);
create unique index if not exists team_memberships_one_active_team_idx on public.team_memberships(season_id,user_id) where left_at is null;
create index if not exists team_memberships_team_active_idx on public.team_memberships(team_id,left_at,user_id);
create index if not exists team_memberships_history_idx on public.team_memberships(season_id,user_id,joined_at,left_at);

create table if not exists public.team_join_requests (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','rejected','cancelled')),
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  processed_by uuid references public.profiles(id) on delete set null
);
create unique index if not exists team_join_requests_one_pending_idx on public.team_join_requests(team_id,user_id) where status='pending';
create index if not exists team_join_requests_team_idx on public.team_join_requests(team_id,status,requested_at desc);

create table if not exists public.team_invites (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  code text not null unique,
  active boolean not null default true,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz
);
create index if not exists team_invites_active_idx on public.team_invites(team_id,active,created_at desc);

create table if not exists public.team_events (
  id bigint generated always as identity primary key,
  season_id uuid not null references public.seasons(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  target_user_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists team_events_team_idx on public.team_events(team_id,created_at desc);

-- =============================================================================
-- 2. Stockage des logos uploadés
-- =============================================================================
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('team-logos','team-logos',true,3145728,array['image/png','image/jpeg','image/webp','image/svg+xml'])
on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists team_logos_public_read on storage.objects;
create policy team_logos_public_read on storage.objects for select using (bucket_id='team-logos');

drop policy if exists team_logos_own_insert on storage.objects;
create policy team_logos_own_insert on storage.objects for insert to authenticated
with check (bucket_id='team-logos' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists team_logos_own_update on storage.objects;
create policy team_logos_own_update on storage.objects for update to authenticated
using (bucket_id='team-logos' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()))
with check (bucket_id='team-logos' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));

drop policy if exists team_logos_own_delete on storage.objects;
create policy team_logos_own_delete on storage.objects for delete to authenticated
using (bucket_id='team-logos' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));

-- =============================================================================
-- 3. Helpers
-- =============================================================================
create or replace function public.slugify_team_v050(p_value text)
returns text language sql immutable as $$
  select trim(both '-' from regexp_replace(lower(coalesce(p_value,'')),'[^a-z0-9]+','-','g'));
$$;

create or replace function public.is_team_captain_v050(p_team_id uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.teams t
    where t.id=p_team_id and t.status='active' and t.captain_user_id=auth.uid()
  );
$$;

create or replace function public.current_team_id_v050(p_season_id uuid,p_user_id uuid default null)
returns uuid language sql stable security definer set search_path=public as $$
  select tm.team_id
  from public.team_memberships tm
  join public.teams t on t.id=tm.team_id and t.status='active'
  where tm.season_id=p_season_id and tm.user_id=coalesce(p_user_id,auth.uid()) and tm.left_at is null
  order by tm.joined_at desc limit 1;
$$;

create or replace function public.log_team_event_v050(
  p_team_id uuid,p_event_type text,p_target_user_id uuid default null,p_payload jsonb default '{}'::jsonb,p_actor_id uuid default null
)
returns void language plpgsql security definer set search_path=public as $$
declare v_season uuid;
begin
  select season_id into v_season from public.teams where id=p_team_id;
  if v_season is null then return; end if;
  insert into public.team_events(season_id,team_id,actor_id,target_user_id,event_type,payload)
  values(v_season,p_team_id,coalesce(p_actor_id,auth.uid()),p_target_user_id,p_event_type,coalesce(p_payload,'{}'::jsonb));
end;
$$;

-- =============================================================================
-- 4. Création / modification
-- =============================================================================
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
  if p_background_style not in ('solid','vertical','horizontal','diagonal','radial','halo') then raise exception 'Fond invalide.'; end if;
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

create or replace function public.update_team_v050(
  p_team_id uuid,
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
returns void language plpgsql security definer set search_path=public as $$
declare old_row public.teams%rowtype;v_name text:=trim(p_name);
begin
  select * into old_row from public.teams where id=p_team_id for update;
  if not found then raise exception 'Team introuvable.'; end if;
  if old_row.status<>'active' then raise exception 'Cette Team est dissoute.'; end if;
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if char_length(v_name) not between 3 and 30 then raise exception 'Le nom doit contenir entre 3 et 30 caractères.'; end if;
  if coalesce(char_length(p_slogan),0)>80 then raise exception 'Slogan trop long.'; end if;
  if coalesce(char_length(p_description),0)>160 then raise exception 'Description trop longue.'; end if;
  if p_visibility not in ('public','private') then raise exception 'Visibilité invalide.'; end if;
  if p_logo_type not in ('library','upload') then raise exception 'Type de logo invalide.'; end if;

  update public.teams set
    name=v_name,
    slogan=nullif(trim(p_slogan),''),
    description=nullif(trim(p_description),''),
    favorite_club_id=p_favorite_club_id,
    visibility=p_visibility,
    logo_type=p_logo_type,
    logo_asset_key=nullif(p_logo_asset_key,''),
    logo_url=nullif(p_logo_url,''),
    shape=coalesce(nullif(p_shape,''),shape),
    frame_style=coalesce(nullif(p_frame_style,''),frame_style),
    primary_color=coalesce(nullif(p_primary_color,''),primary_color),
    secondary_color=coalesce(nullif(p_secondary_color,''),secondary_color),
    background_style=coalesce(nullif(p_background_style,''),background_style)
  where id=p_team_id;

  perform public.log_team_event_v050(p_team_id,'identity_changed',null,jsonb_build_object(
    'old_name',old_row.name,'new_name',v_name,'visibility',p_visibility,'favorite_club_id',p_favorite_club_id,
    'shape',p_shape,'frame_style',p_frame_style,'primary_color',p_primary_color,'secondary_color',p_secondary_color,'background_style',p_background_style
  ));
exception when unique_violation then
  raise exception 'Ce nom de Team est déjà utilisé pour cette saison.';
end;
$$;

-- =============================================================================
-- 5. Adhésions
-- =============================================================================
create or replace function public.join_public_team_v050(p_team_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;
begin
  select * into t from public.teams where id=p_team_id for update;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;
  if t.visibility<>'public' then raise exception 'Cette Team est privée.'; end if;
  if exists(select 1 from public.team_memberships where season_id=t.season_id and user_id=auth.uid() and left_at is null) then raise exception 'Tu appartiens déjà à une Team.'; end if;
  insert into public.team_memberships(season_id,team_id,user_id,join_type) values(t.season_id,t.id,auth.uid(),'public');
  update public.team_join_requests set status='cancelled',processed_at=now(),processed_by=auth.uid() where season_id=t.season_id and user_id=auth.uid() and status='pending';
  perform public.log_team_event_v050(t.id,'member_joined',auth.uid(),jsonb_build_object('join_type','public'));
end;
$$;

create or replace function public.request_team_join_v050(p_team_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;v_id uuid;
begin
  select * into t from public.teams where id=p_team_id;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;
  if t.visibility<>'private' then raise exception 'Cette Team est publique : rejoins-la directement.'; end if;
  if exists(select 1 from public.team_memberships where season_id=t.season_id and user_id=auth.uid() and left_at is null) then raise exception 'Tu appartiens déjà à une Team.'; end if;
  select id into v_id from public.team_join_requests where team_id=t.id and user_id=auth.uid() and status='pending' limit 1;
  if v_id is not null then return v_id; end if;
  insert into public.team_join_requests(season_id,team_id,user_id,status) values(t.season_id,t.id,auth.uid(),'pending') returning id into v_id;
  perform public.log_team_event_v050(t.id,'join_requested',auth.uid(),jsonb_build_object('request_id',v_id));
  return v_id;
end;
$$;

create or replace function public.process_team_join_request_v050(p_request_id uuid,p_accept boolean)
returns void language plpgsql security definer set search_path=public as $$
declare r public.team_join_requests%rowtype;t public.teams%rowtype;
begin
  select * into r from public.team_join_requests where id=p_request_id for update;
  if not found or r.status<>'pending' then raise exception 'Demande introuvable ou déjà traitée.'; end if;
  select * into t from public.teams where id=r.team_id;
  if not (public.is_team_captain_v050(t.id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if p_accept then
    if exists(select 1 from public.team_memberships where season_id=t.season_id and user_id=r.user_id and left_at is null) then raise exception 'Ce joueur appartient déjà à une Team.'; end if;
    insert into public.team_memberships(season_id,team_id,user_id,join_type) values(t.season_id,t.id,r.user_id,'request');
    update public.team_join_requests set status='accepted',processed_at=now(),processed_by=auth.uid() where id=r.id;
    perform public.log_team_event_v050(t.id,'member_joined',r.user_id,jsonb_build_object('join_type','request'));
  else
    update public.team_join_requests set status='rejected',processed_at=now(),processed_by=auth.uid() where id=r.id;
    perform public.log_team_event_v050(t.id,'join_rejected',r.user_id,jsonb_build_object('request_id',r.id));
  end if;
end;
$$;

create or replace function public.regenerate_team_invite_v050(p_team_id uuid)
returns text language plpgsql security definer set search_path=public as $$
declare v_code text;
begin
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if not exists(select 1 from public.teams where id=p_team_id and status='active') then raise exception 'Team introuvable.'; end if;
  update public.team_invites set active=false where team_id=p_team_id and active=true;
  v_code:='NID-'||upper(substr(encode(gen_random_bytes(6),'hex'),1,8));
  insert into public.team_invites(team_id,code,created_by) values(p_team_id,v_code,auth.uid());
  perform public.log_team_event_v050(p_team_id,'invite_regenerated',null,'{}'::jsonb);
  return v_code;
end;
$$;

create or replace function public.join_team_by_code_v050(p_season_id uuid,p_code text)
returns uuid language plpgsql security definer set search_path=public as $$
declare i public.team_invites%rowtype;t public.teams%rowtype;
begin
  select * into i from public.team_invites where upper(code)=upper(trim(p_code)) and active=true and (expires_at is null or expires_at>now()) order by created_at desc limit 1;
  if not found then raise exception 'Code d’invitation invalide ou expiré.'; end if;
  select * into t from public.teams where id=i.team_id and season_id=p_season_id and status='active';
  if not found then raise exception 'Team indisponible.'; end if;
  if exists(select 1 from public.team_memberships where season_id=p_season_id and user_id=auth.uid() and left_at is null) then raise exception 'Tu appartiens déjà à une Team.'; end if;
  insert into public.team_memberships(season_id,team_id,user_id,join_type) values(p_season_id,t.id,auth.uid(),'code');
  update public.team_join_requests set status='cancelled',processed_at=now(),processed_by=auth.uid() where season_id=p_season_id and user_id=auth.uid() and status='pending';
  perform public.log_team_event_v050(t.id,'member_joined',auth.uid(),jsonb_build_object('join_type','code'));
  return t.id;
end;
$$;

create or replace function public.leave_team_v050(p_season_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare tm public.team_memberships%rowtype;t public.teams%rowtype;
begin
  select * into tm from public.team_memberships where season_id=p_season_id and user_id=auth.uid() and left_at is null for update;
  if not found then raise exception 'Tu n’appartiens à aucune Team.'; end if;
  select * into t from public.teams where id=tm.team_id;
  if t.captain_user_id=auth.uid() then raise exception 'Transfère d’abord le capitanat avant de quitter la Team.'; end if;
  update public.team_memberships set left_at=now(),leave_type='left' where id=tm.id;
  perform public.log_team_event_v050(t.id,'member_left',auth.uid(),'{}'::jsonb);
end;
$$;

create or replace function public.kick_team_member_v050(p_team_id uuid,p_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;tm_id uuid;
begin
  select * into t from public.teams where id=p_team_id;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if t.captain_user_id=p_user_id then raise exception 'Le capitaine ne peut pas être exclu.'; end if;
  select id into tm_id from public.team_memberships where team_id=p_team_id and user_id=p_user_id and left_at is null for update;
  if tm_id is null then raise exception 'Ce joueur n’est pas membre de la Team.'; end if;
  update public.team_memberships set left_at=now(),leave_type='kicked' where id=tm_id;
  perform public.log_team_event_v050(p_team_id,'member_kicked',p_user_id,'{}'::jsonb);
end;
$$;

create or replace function public.transfer_team_captain_v050(p_team_id uuid,p_new_captain_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;v_old uuid;
begin
  select * into t from public.teams where id=p_team_id for update;
  if not found or t.status<>'active' then raise exception 'Team introuvable.'; end if;
  if not (t.captain_user_id=auth.uid() or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if not exists(select 1 from public.team_memberships where team_id=p_team_id and user_id=p_new_captain_user_id and left_at is null) then raise exception 'Le nouveau capitaine doit être membre actif.'; end if;
  v_old:=t.captain_user_id;
  if v_old=p_new_captain_user_id then return; end if;
  update public.teams set captain_user_id=p_new_captain_user_id where id=p_team_id;
  perform public.log_team_event_v050(p_team_id,'captain_transferred',p_new_captain_user_id,jsonb_build_object('old_captain_user_id',v_old,'new_captain_user_id',p_new_captain_user_id));
end;
$$;

create or replace function public.dissolve_team_v050(p_team_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare t public.teams%rowtype;
begin
  select * into t from public.teams where id=p_team_id for update;
  if not found then raise exception 'Team introuvable.'; end if;
  if not (t.captain_user_id=auth.uid() or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  if t.status='dissolved' then return; end if;
  perform public.log_team_event_v050(p_team_id,'team_dissolved',null,jsonb_build_object('name',t.name));
  update public.teams set status='dissolved',dissolved_at=now() where id=p_team_id;
  update public.team_memberships set left_at=now(),leave_type='dissolved' where team_id=p_team_id and left_at is null;
  update public.team_invites set active=false where team_id=p_team_id and active=true;
  update public.team_join_requests set status='cancelled',processed_at=now(),processed_by=auth.uid() where team_id=p_team_id and status='pending';
end;
$$;

-- =============================================================================
-- 6. Lecture / annuaire / membres / historique
-- =============================================================================
create or replace function public.get_team_directory_v050(p_season_id uuid)
returns table(
  team_id uuid,name text,slug text,slogan text,description text,visibility text,status text,captain_user_id uuid,captain_username text,
  favorite_club_id uuid,favorite_club_name text,favorite_club_short text,favorite_club_logo_url text,favorite_club_logo_storage_path text,
  logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  member_count bigint,created_at timestamptz
)
language sql stable security definer set search_path=public as $$
  select t.id,t.name,t.slug,t.slogan,t.description,t.visibility,t.status,t.captain_user_id,p.username::text,
    c.id,c.name,c.short_name,coalesce(c.logo_source_url,c.logo_url),c.logo_storage_path,
    t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    count(tm.id) filter(where tm.left_at is null)::bigint,t.created_at
  from public.teams t
  join public.profiles p on p.id=t.captain_user_id
  left join public.clubs c on c.id=t.favorite_club_id
  left join public.team_memberships tm on tm.team_id=t.id
  where t.season_id=p_season_id
  group by t.id,p.username,c.id,c.name,c.short_name,c.logo_source_url,c.logo_url,c.logo_storage_path
  order by (t.status='active') desc,t.name;
$$;

create or replace function public.get_my_team_v050(p_season_id uuid)
returns table(
  team_id uuid,name text,slug text,slogan text,description text,visibility text,status text,captain_user_id uuid,captain_username text,is_captain boolean,
  favorite_club_id uuid,favorite_club_name text,favorite_club_short text,favorite_club_logo_url text,favorite_club_logo_storage_path text,
  logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  joined_at timestamptz,member_count bigint
)
language sql stable security definer set search_path=public as $$
  select t.id,t.name,t.slug,t.slogan,t.description,t.visibility,t.status,t.captain_user_id,cap.username::text,(t.captain_user_id=auth.uid()),
    c.id,c.name,c.short_name,coalesce(c.logo_source_url,c.logo_url),c.logo_storage_path,
    t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    mine.joined_at,(select count(*) from public.team_memberships x where x.team_id=t.id and x.left_at is null)::bigint
  from public.team_memberships mine
  join public.teams t on t.id=mine.team_id
  join public.profiles cap on cap.id=t.captain_user_id
  left join public.clubs c on c.id=t.favorite_club_id
  where mine.season_id=p_season_id and mine.user_id=auth.uid() and mine.left_at is null and t.status='active'
  order by mine.joined_at desc limit 1;
$$;

create or replace function public.get_team_member_directory_v050(p_season_id uuid)
returns table(
  user_id uuid,username text,avatar_key text,club_heart text,team_id uuid,team_name text,is_captain boolean,
  logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text
)
language sql stable security definer set search_path=public as $$
  select p.id,p.username::text,p.avatar_key,p.club_heart,t.id,t.name,(t.captain_user_id=p.id),
    t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style
  from public.team_memberships tm
  join public.teams t on t.id=tm.team_id and t.status='active'
  join public.profiles p on p.id=tm.user_id
  where tm.season_id=p_season_id and tm.left_at is null
  order by t.name,p.username;
$$;

create or replace function public.get_team_members_v050(p_team_id uuid)
returns table(user_id uuid,username text,avatar_key text,club_heart text,is_captain boolean,joined_at timestamptz,points numeric,exact_scores bigint,average numeric,rank bigint)
language sql stable security definer set search_path=public as $$
  with t as (select season_id,captain_user_id from public.teams where id=p_team_id),
  lb as (select * from public.get_leaderboard_v040((select season_id from t),'general',null,null,true))
  select p.id,p.username::text,p.avatar_key,p.club_heart,(p.id=(select captain_user_id from t)),tm.joined_at,
    coalesce(lb.points,0),coalesce(lb.exact_scores,0),coalesce(lb.average,0),lb.rank
  from public.team_memberships tm
  join public.profiles p on p.id=tm.user_id
  left join lb on lb.user_id=p.id
  where tm.team_id=p_team_id and tm.left_at is null
  order by (p.id=(select captain_user_id from t)) desc,coalesce(lb.points,0) desc,p.username;
$$;

create or replace function public.get_team_history_v050(p_team_id uuid)
returns table(event_id bigint,event_type text,actor_id uuid,actor_username text,target_user_id uuid,target_username text,payload jsonb,created_at timestamptz)
language sql stable security definer set search_path=public as $$
  select e.id,e.event_type,e.actor_id,a.username::text,e.target_user_id,t.username::text,e.payload,e.created_at
  from public.team_events e
  left join public.profiles a on a.id=e.actor_id
  left join public.profiles t on t.id=e.target_user_id
  where e.team_id=p_team_id
  order by e.created_at desc,e.id desc limit 300;
$$;

create or replace function public.get_team_join_requests_v050(p_team_id uuid)
returns table(request_id uuid,user_id uuid,username text,avatar_key text,club_heart text,requested_at timestamptz)
language plpgsql stable security definer set search_path=public as $$
begin
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then raise exception 'Réservé au capitaine.'; end if;
  return query
    select r.id,p.id,p.username::text,p.avatar_key,p.club_heart,r.requested_at
    from public.team_join_requests r join public.profiles p on p.id=r.user_id
    where r.team_id=p_team_id and r.status='pending'
    order by r.requested_at;
end;
$$;

create or replace function public.get_team_active_invite_v050(p_team_id uuid)
returns text language plpgsql stable security definer set search_path=public as $$
declare v text;
begin
  if not (public.is_team_captain_v050(p_team_id) or public.is_admin()) then return null; end if;
  select code into v from public.team_invites where team_id=p_team_id and active=true and (expires_at is null or expires_at>now()) order by created_at desc limit 1;
  return v;
end;
$$;

-- =============================================================================
-- 7. Classements Teams : points attribués à la Team au moment du verrouillage.
-- =============================================================================
create or replace function public.get_team_leaderboard_v050(p_season_id uuid,p_matchday_id uuid default null)
returns table(
  team_id uuid,team_name text,logo_type text,logo_asset_key text,logo_url text,shape text,frame_style text,primary_color text,secondary_color text,background_style text,
  current_members bigint,contributors bigint,total_points numeric,average_points numeric,top3_points numeric,rank_average bigint,rank_top3 bigint
)
language sql stable security definer set search_path=public as $$
with match_points as (
  select tm.team_id,p.user_id,sum(p.points)::numeric as pts
  from public.predictions p
  join public.matches m on m.id=p.match_id
  left join public.matchdays md on md.id=m.matchday_id
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=p.user_id
    and m.kickoff_at>=tm.joined_at and (tm.left_at is null or m.kickoff_at<tm.left_at)
  where p.season_id=p_season_id and m.status='finished'
    and (p_matchday_id is null or m.matchday_id=p_matchday_id)
    and (md.number is null or md.number<>0)
  group by tm.team_id,p.user_id
), qualifier_points as (
  select tm.team_id,tp.user_id,sum(case when kt.status='finished' and kt.qualified_club_id=tp.qualified_club_id then case when tp.pick_timing='early' then kt.qualifier_bonus_early else kt.qualifier_bonus_late end else 0 end)::numeric as pts
  from public.tie_predictions tp
  join public.knockout_ties kt on kt.id=tp.tie_id
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=tp.user_id
    and (case when kt.is_single_match then kt.leg1_kickoff_at else kt.leg2_kickoff_at end)>=tm.joined_at
    and (tm.left_at is null or (case when kt.is_single_match then kt.leg1_kickoff_at else kt.leg2_kickoff_at end)<tm.left_at)
  where tp.season_id=p_season_id and p_matchday_id is null
  group by tm.team_id,tp.user_id
), champion_points as (
  select tm.team_id,cp.user_id,sum(cp.points)::numeric as pts
  from public.champion_predictions cp
  join public.team_memberships tm on tm.season_id=p_season_id and tm.user_id=cp.user_id
    and coalesce(cp.locked_at,cp.updated_at)>=tm.joined_at and (tm.left_at is null or coalesce(cp.locked_at,cp.updated_at)<tm.left_at)
  where cp.season_id=p_season_id and p_matchday_id is null and cp.points<>0
  group by tm.team_id,cp.user_id
), user_team_points as (
  select team_id,user_id,sum(pts)::numeric as pts from (
    select * from match_points union all select * from qualifier_points union all select * from champion_points
  ) q group by team_id,user_id
), active_zero as (
  select tm.team_id,tm.user_id,0::numeric pts from public.team_memberships tm join public.teams t on t.id=tm.team_id
  where tm.season_id=p_season_id and tm.left_at is null and t.status='active'
), players as (
  select team_id,user_id,sum(pts)::numeric pts from (
    select * from user_team_points union all select * from active_zero
  ) q group by team_id,user_id
), team_stats as (
  select t.id team_id,t.name team_name,t.logo_type,t.logo_asset_key,t.logo_url,t.shape,t.frame_style,t.primary_color,t.secondary_color,t.background_style,
    (select count(*) from public.team_memberships x where x.team_id=t.id and x.left_at is null)::bigint current_members,
    count(p.user_id)::bigint contributors,coalesce(sum(p.pts),0)::numeric total_points,coalesce(avg(p.pts),0)::numeric average_points,
    coalesce((select sum(z.pts) from (select p2.pts from players p2 where p2.team_id=t.id order by p2.pts desc limit 3) z),0)::numeric top3_points
  from public.teams t left join players p on p.team_id=t.id
  where t.season_id=p_season_id and t.status='active'
  group by t.id
), ranked as (
  select s.*,
    row_number() over(order by average_points desc,top3_points desc,total_points desc,team_name)::bigint rank_average,
    row_number() over(order by top3_points desc,average_points desc,total_points desc,team_name)::bigint rank_top3
  from team_stats s
)
select * from ranked order by rank_average;
$$;

-- =============================================================================
-- 8. RLS + privilèges
-- =============================================================================
alter table public.teams enable row level security;
alter table public.team_memberships enable row level security;
alter table public.team_join_requests enable row level security;
alter table public.team_invites enable row level security;
alter table public.team_events enable row level security;

drop policy if exists teams_read on public.teams;
create policy teams_read on public.teams for select using(true);

drop policy if exists team_memberships_read on public.team_memberships;
create policy team_memberships_read on public.team_memberships for select using(true);

drop policy if exists team_requests_own_or_captain on public.team_join_requests;
create policy team_requests_own_or_captain on public.team_join_requests for select to authenticated using(
  user_id=auth.uid() or public.is_admin() or public.is_team_captain_v050(team_id)
);

drop policy if exists team_invites_captain_read on public.team_invites;
create policy team_invites_captain_read on public.team_invites for select to authenticated using(public.is_admin() or public.is_team_captain_v050(team_id));

drop policy if exists team_events_read on public.team_events;
create policy team_events_read on public.team_events for select using(true);

revoke all on public.teams,public.team_memberships,public.team_join_requests,public.team_invites,public.team_events from anon,authenticated;
grant select on public.teams,public.team_memberships,public.team_events to anon,authenticated;
grant select on public.team_join_requests,public.team_invites to authenticated;

grant execute on function public.is_team_captain_v050(uuid) to authenticated;
grant execute on function public.current_team_id_v050(uuid,uuid) to authenticated;
grant execute on function public.create_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.update_team_v050(uuid,text,text,text,uuid,text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.join_public_team_v050(uuid) to authenticated;
grant execute on function public.request_team_join_v050(uuid) to authenticated;
grant execute on function public.process_team_join_request_v050(uuid,boolean) to authenticated;
grant execute on function public.regenerate_team_invite_v050(uuid) to authenticated;
grant execute on function public.join_team_by_code_v050(uuid,text) to authenticated;
grant execute on function public.leave_team_v050(uuid) to authenticated;
grant execute on function public.kick_team_member_v050(uuid,uuid) to authenticated;
grant execute on function public.transfer_team_captain_v050(uuid,uuid) to authenticated;
grant execute on function public.dissolve_team_v050(uuid) to authenticated;
grant execute on function public.get_team_directory_v050(uuid) to anon,authenticated;
grant execute on function public.get_my_team_v050(uuid) to authenticated;
grant execute on function public.get_team_member_directory_v050(uuid) to authenticated;
grant execute on function public.get_team_members_v050(uuid) to authenticated;
grant execute on function public.get_team_history_v050(uuid) to authenticated;
grant execute on function public.get_team_join_requests_v050(uuid) to authenticated;
grant execute on function public.get_team_active_invite_v050(uuid) to authenticated;
grant execute on function public.get_team_leaderboard_v050(uuid,uuid) to anon,authenticated;

-- =============================================================================
-- 9. Audit léger sur les modifications de Team
-- =============================================================================
create or replace function public.audit_team_change_v050()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if old is distinct from new then
    insert into public.audit_logs(actor_id,action,entity_type,entity_id,old_data,new_data)
    values(auth.uid(),'team_update','team',new.id::text,to_jsonb(old),to_jsonb(new));
  end if;
  return new;
end;
$$;
drop trigger if exists audit_teams_v050 on public.teams;
create trigger audit_teams_v050 after update on public.teams for each row execute function public.audit_team_change_v050();

-- =============================================================================
-- 10. Realtime + version
-- =============================================================================
do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='teams') then execute 'alter publication supabase_realtime add table public.teams'; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='team_memberships') then execute 'alter publication supabase_realtime add table public.team_memberships'; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='team_join_requests') then execute 'alter publication supabase_realtime add table public.team_join_requests'; end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='team_events') then execute 'alter publication supabase_realtime add table public.team_events'; end if;
  end if;
end $$;

insert into public.app_settings(key,value) values('app_version','"0.5.0"'::jsonb)
on conflict(key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

-- Vérifications utiles
select key,value from public.app_settings where key='app_version';
select proname from pg_proc where proname like '%team%v050' order by proname;
select id,name,public from storage.buckets where id='team-logos';
