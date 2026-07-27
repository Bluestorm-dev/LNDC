-- Le Nid des Champions — V0.6.0
-- Hibou masqué, rivalités, tickets, notifications internes + Web Push.
-- À exécuter après V0.5.5a avec le rôle postgres dans Supabase SQL Editor.

begin;

-- =============================================================================
-- 1. Préférences de notifications / caractère du Hibou
-- =============================================================================
create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  notifications_enabled boolean not null default true,
  push_enabled boolean not null default true,
  category_matches boolean not null default true,
  category_champion boolean not null default true,
  category_results boolean not null default true,
  category_rival boolean not null default true,
  category_team boolean not null default true,
  category_owl boolean not null default true,
  category_support boolean not null default true,
  category_system boolean not null default true,
  category_ranking boolean not null default true,
  reminder_24h boolean not null default false,
  reminder_3h boolean not null default true,
  reminder_1h boolean not null default false,
  reminder_30m boolean not null default true,
  quiet_hours_enabled boolean not null default true,
  quiet_start time not null default '23:00',
  quiet_end time not null default '08:00',
  urgent_bypass_quiet boolean not null default true,
  owl_tone text not null default 'automatic' check (owl_tone in ('sage','piquant','sans_pitie','automatic')),
  timezone text not null default 'Europe/Paris',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists notification_preferences_updated_at on public.notification_preferences;
create trigger notification_preferences_updated_at before update on public.notification_preferences
for each row execute function public.set_updated_at();

insert into public.notification_preferences(user_id)
select id from public.profiles
on conflict(user_id) do nothing;

create or replace function public.seed_notification_preferences_v060()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.notification_preferences(user_id) values(new.id) on conflict(user_id) do nothing;
  return new;
end;
$$;
drop trigger if exists seed_notification_preferences_v060 on public.profiles;
create trigger seed_notification_preferences_v060 after insert on public.profiles
for each row execute function public.seed_notification_preferences_v060();

-- =============================================================================
-- 2. Centre de notifications
-- =============================================================================
alter table public.notification_preferences add column if not exists category_support boolean not null default true;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  season_id uuid references public.seasons(id) on delete cascade,
  category text not null check (category in ('matches','champion','results','rival','team','owl','system','ranking','support')),
  title text not null,
  body text not null,
  importance text not null default 'normal' check (importance in ('normal','info','important','urgent')),
  deep_link text,
  payload jsonb not null default '{}'::jsonb,
  source_key text,
  push_requested boolean not null default false,
  push_not_before timestamptz,
  push_sent_at timestamptz,
  read_at timestamptz,
  deleted_at timestamptz,
  expires_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create unique index if not exists notifications_user_source_unique_idx
  on public.notifications(user_id,source_key) where source_key is not null;
create index if not exists notifications_user_created_idx on public.notifications(user_id,created_at desc);
create index if not exists notifications_pending_push_idx on public.notifications(push_requested,push_sent_at,created_at)
  where push_requested=true and push_sent_at is null;

-- =============================================================================
-- 3. Abonnements Web Push + journal de livraison
-- =============================================================================
create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth_key text not null,
  device_name text,
  user_agent text,
  platform text,
  active boolean not null default true,
  last_success_at timestamptz,
  last_failure_at timestamptz,
  failure_count integer not null default 0,
  disabled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists push_subscriptions_user_active_idx on public.push_subscriptions(user_id,active,created_at desc);
drop trigger if exists push_subscriptions_updated_at on public.push_subscriptions;
create trigger push_subscriptions_updated_at before update on public.push_subscriptions
for each row execute function public.set_updated_at();

create table if not exists public.push_delivery_logs (
  id bigint generated always as identity primary key,
  notification_id uuid references public.notifications(id) on delete set null,
  user_id uuid references public.profiles(id) on delete set null,
  subscription_id uuid references public.push_subscriptions(id) on delete set null,
  delivery_kind text not null default 'notification',
  status text not null check (status in ('sent','failed','expired','skipped')),
  response_code integer,
  error_message text,
  created_at timestamptz not null default now()
);
create index if not exists push_delivery_logs_created_idx on public.push_delivery_logs(created_at desc);
create index if not exists push_delivery_logs_user_idx on public.push_delivery_logs(user_id,created_at desc);

-- =============================================================================
-- 4. Rivalités
-- =============================================================================
create table if not exists public.player_rivals (
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rival_user_id uuid not null references public.profiles(id) on delete cascade,
  changed_matchday_id uuid references public.matchdays(id) on delete set null,
  changed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key(season_id,user_id),
  check (user_id <> rival_user_id)
);
create index if not exists player_rivals_rival_idx on public.player_rivals(season_id,rival_user_id);

create table if not exists public.rival_changes (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  matchday_id uuid not null references public.matchdays(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  old_rival_user_id uuid references public.profiles(id) on delete set null,
  rival_user_id uuid not null references public.profiles(id) on delete cascade,
  changed_at timestamptz not null default now(),
  unique(season_id,user_id,matchday_id),
  check (user_id <> rival_user_id)
);
create index if not exists rival_changes_user_idx on public.rival_changes(season_id,user_id,changed_at desc);

create table if not exists public.rival_duels (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  matchday_id uuid not null references public.matchdays(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rival_user_id uuid not null references public.profiles(id) on delete cascade,
  user_points integer not null default 0,
  rival_points integer not null default 0,
  result text check (result in ('win','draw','loss')),
  is_mutual boolean not null default false,
  locked_at timestamptz not null default now(),
  finalized_at timestamptz,
  created_at timestamptz not null default now(),
  unique(season_id,matchday_id,user_id),
  check (user_id <> rival_user_id)
);
create index if not exists rival_duels_user_idx on public.rival_duels(season_id,user_id,matchday_id);
create index if not exists rival_duels_pair_idx on public.rival_duels(season_id,user_id,rival_user_id);

create table if not exists public.ranking_notification_state (
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rank integer,
  points integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key(season_id,user_id)
);

-- =============================================================================
-- 5. Messages du Hibou
-- =============================================================================
create table if not exists public.owl_messages (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete cascade,
  title text not null default 'Message du Hibou masqué',
  body text not null,
  importance text not null default 'info' check (importance in ('normal','info','important','urgent')),
  target_scope text not null default 'all' check (target_scope in ('all','team','player')),
  target_id uuid,
  push_enabled boolean not null default false,
  automated boolean not null default false,
  show_in_history boolean not null default true,
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(title) between 1 and 120),
  check (char_length(body) between 1 and 4000)
);
create index if not exists owl_messages_active_idx on public.owl_messages(starts_at desc,expires_at);
drop trigger if exists owl_messages_updated_at on public.owl_messages;
create trigger owl_messages_updated_at before update on public.owl_messages
for each row execute function public.set_updated_at();

-- =============================================================================
-- 6. Tickets au Hibou + conversations + captures
-- =============================================================================
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  season_id uuid references public.seasons(id) on delete set null,
  ticket_type text not null check (ticket_type in ('bug','suggestion','question','modification','other')),
  subject text not null,
  status text not null default 'received' check (status in ('received','read','in_progress','fixed','resolved','closed','rejected')),
  priority text not null default 'normal' check (priority in ('normal','important','urgent')),
  technical_context jsonb not null default '{}'::jsonb,
  resolved_by_user_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(subject) between 3 and 160)
);
create index if not exists support_tickets_user_idx on public.support_tickets(user_id,created_at desc);
create index if not exists support_tickets_status_idx on public.support_tickets(status,priority,created_at desc);
drop trigger if exists support_tickets_updated_at on public.support_tickets;
create trigger support_tickets_updated_at before update on public.support_tickets
for each row execute function public.set_updated_at();

create table if not exists public.support_ticket_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  author_id uuid references public.profiles(id) on delete set null,
  author_kind text not null check (author_kind in ('player','owl')),
  body text not null,
  created_at timestamptz not null default now(),
  check (char_length(body) between 1 and 6000)
);
create index if not exists support_ticket_messages_ticket_idx on public.support_ticket_messages(ticket_id,created_at);

create table if not exists public.support_ticket_attachments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  message_id uuid references public.support_ticket_messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null,
  size_bytes integer not null check (size_bytes > 0 and size_bytes <= 5242880),
  created_at timestamptz not null default now()
);
create index if not exists support_ticket_attachments_ticket_idx on public.support_ticket_attachments(ticket_id,created_at);

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('support-captures','support-captures',false,5242880,array['image/png','image/jpeg','image/webp'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

-- =============================================================================
-- 7. Helpers notifications
-- =============================================================================
create or replace function public.create_notification_v060(
  p_user_id uuid,
  p_season_id uuid,
  p_category text,
  p_title text,
  p_body text,
  p_importance text default 'normal',
  p_deep_link text default null,
  p_payload jsonb default '{}'::jsonb,
  p_push_requested boolean default false,
  p_source_key text default null
) returns uuid
language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
  if not exists(select 1 from public.profiles where id=p_user_id and status='active') then return null; end if;
  insert into public.notifications(user_id,season_id,category,title,body,importance,deep_link,payload,push_requested,source_key,expires_at)
  values(p_user_id,p_season_id,p_category,left(p_title,160),left(p_body,2000),p_importance,p_deep_link,coalesce(p_payload,'{}'::jsonb),p_push_requested,p_source_key,
    case when p_importance in ('important','urgent') then null else now()+interval '90 days' end)
  on conflict(user_id,source_key) where source_key is not null do nothing
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.mark_all_notifications_read_v060()
returns void language sql security definer set search_path=public as $$
  update public.notifications set read_at=coalesce(read_at,now())
  where user_id=auth.uid() and deleted_at is null and read_at is null;
$$;

-- =============================================================================
-- 8. Rival : choix, verrouillage et duels
-- =============================================================================
create or replace function public.set_my_rival_v060(p_season_id uuid,p_matchday_id uuid,p_rival_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  v_first_kickoff timestamptz;
  v_old uuid;
  v_me text;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if p_rival_user_id=auth.uid() then raise exception 'Tu ne peux pas être ton propre rival.'; end if;
  if not exists(select 1 from public.profiles where id=p_rival_user_id and status='active') then raise exception 'Ce joueur n’est pas disponible.'; end if;
  if not exists(select 1 from public.matchdays where id=p_matchday_id and season_id=p_season_id) then raise exception 'Journée UEFA invalide.'; end if;
  select min(kickoff_at) into v_first_kickoff from public.matches where matchday_id=p_matchday_id and status<>'cancelled';
  if v_first_kickoff is not null and v_first_kickoff<=now() then raise exception 'Rival verrouillé : la journée UEFA a commencé.'; end if;
  if exists(select 1 from public.rival_changes where season_id=p_season_id and user_id=auth.uid() and matchday_id=p_matchday_id) then
    raise exception 'Tu as déjà changé de rival pour cette journée UEFA.';
  end if;
  select rival_user_id into v_old from public.player_rivals where season_id=p_season_id and user_id=auth.uid();
  insert into public.player_rivals(season_id,user_id,rival_user_id,changed_matchday_id,changed_at)
  values(p_season_id,auth.uid(),p_rival_user_id,p_matchday_id,now())
  on conflict(season_id,user_id) do update set rival_user_id=excluded.rival_user_id,changed_matchday_id=excluded.changed_matchday_id,changed_at=now();
  insert into public.rival_changes(season_id,matchday_id,user_id,old_rival_user_id,rival_user_id)
  values(p_season_id,p_matchday_id,auth.uid(),v_old,p_rival_user_id);
  select username::text into v_me from public.profiles where id=auth.uid();
  perform public.create_notification_v060(p_rival_user_id,p_season_id,'rival','⚔️ Tu as été choisi comme rival',
    coalesce(v_me,'Un joueur')||' t’a dans le viseur pour le Nid.','info','rival',jsonb_build_object('rival_user_id',auth.uid()),true,
    'rival-chosen:'||p_season_id::text||':'||p_matchday_id::text||':'||auth.uid()::text);
end;
$$;

create or replace function public.refresh_rival_duels_v060(p_matchday_id uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare
  v_md public.matchdays%rowtype;
  v_first timestamptz;
  v_done boolean;
  v_count integer:=0;
  d record;
  upoints integer;
  rpoints integer;
  v_result text;
  v_uname text;
  v_rname text;
  v_tone text;
  v_title text;
  v_body text;
  v_margin integer;
begin
  select * into v_md from public.matchdays where id=p_matchday_id;
  if not found then return 0; end if;
  select min(kickoff_at) into v_first from public.matches where matchday_id=p_matchday_id and status<>'cancelled';
  if v_first is null or v_first>now() then return 0; end if;

  insert into public.rival_duels(season_id,matchday_id,user_id,rival_user_id,is_mutual,locked_at)
  select pr.season_id,p_matchday_id,pr.user_id,pr.rival_user_id,
    exists(select 1 from public.player_rivals back where back.season_id=pr.season_id and back.user_id=pr.rival_user_id and back.rival_user_id=pr.user_id),
    v_first
  from public.player_rivals pr
  where pr.season_id=v_md.season_id
  on conflict(season_id,matchday_id,user_id) do nothing;

  select not exists(select 1 from public.matches where matchday_id=p_matchday_id and status not in ('finished','cancelled')) into v_done;
  if not v_done then return 0; end if;

  for d in select * from public.rival_duels where matchday_id=p_matchday_id and finalized_at is null loop
    select coalesce(sum(p.points),0)::integer into upoints
      from public.predictions p join public.matches m on m.id=p.match_id
      where p.user_id=d.user_id and m.matchday_id=p_matchday_id and m.status='finished';
    select coalesce(sum(p.points),0)::integer into rpoints
      from public.predictions p join public.matches m on m.id=p.match_id
      where p.user_id=d.rival_user_id and m.matchday_id=p_matchday_id and m.status='finished';
    v_result:=case when upoints>rpoints then 'win' when upoints<rpoints then 'loss' else 'draw' end;
    update public.rival_duels set user_points=upoints,rival_points=rpoints,result=v_result,finalized_at=now() where id=d.id;
    select username::text into v_uname from public.profiles where id=d.user_id;
    select username::text into v_rname from public.profiles where id=d.rival_user_id;
    select coalesce(owl_tone,'automatic') into v_tone from public.notification_preferences where user_id=d.user_id;
    v_tone:=coalesce(v_tone,'automatic');
    v_margin:=abs(upoints-rpoints);
    if v_tone='sage' then
      v_title:=case v_result when 'win' then '🏆 Duel remporté' when 'loss' then '⚔️ Duel perdu' else '🤝 Match nul' end;
      v_body:=coalesce(v_uname,'Toi')||' '||upoints||' — '||rpoints||' '||coalesce(v_rname,'Rival')||'. Rendez-vous à la prochaine journée.';
    elsif v_tone='sans_pitie' or (v_tone='automatic' and v_margin>=10) then
      v_title:=case v_result when 'win' then '🔥 Rival pulvérisé' when 'loss' then '💀 Le Hibou propose de ne pas en parler.' else '🤝 Deux suspects, aucun vainqueur.' end;
      v_body:=coalesce(v_uname,'Toi')||' '||upoints||' — '||rpoints||' '||coalesce(v_rname,'Rival')||case v_result when 'win' then '. Le Hibou cherche encore les morceaux.' when 'loss' then '. Les preuves seront détruites à l’aube.' else '. Vous avez réussi à vous neutraliser mutuellement.' end;
    else
      v_title:=case v_result when 'win' then '🏆 Rival terrassé' when 'loss' then '💀 Ça pique.' else '🤝 Personne n’a gagné.' end;
      v_body:=coalesce(v_uname,'Toi')||' '||upoints||' — '||rpoints||' '||coalesce(v_rname,'Rival')||case v_result when 'win' then '. Le Hibou prend note avec un sourire gênant.' when 'loss' then '. Le Hibou suggère discrètement de te réveiller.' else '. Une élégante manière d’échouer ensemble.' end;
    end if;
    perform public.create_notification_v060(d.user_id,d.season_id,'rival',v_title,v_body,
      'info','rival',jsonb_build_object('duel_id',d.id,'matchday_id',p_matchday_id,'result',v_result),true,'rival-duel-final:'||d.id::text);
    v_count:=v_count+1;
  end loop;
  return v_count;
end;
$$;

create or replace function public.get_rival_summary_v060(p_season_id uuid,p_user_id uuid default null)
returns table(
  user_id uuid,rival_user_id uuid,duels bigint,wins bigint,draws bigint,losses bigint,
  points_for bigint,points_against bigint,best_margin integer,worst_margin integer,current_win_streak integer,
  mutual boolean
)
language sql stable security definer set search_path=public as $$
with target as (select coalesce(p_user_id,auth.uid()) uid), current_r as (
  select pr.user_id,pr.rival_user_id from public.player_rivals pr,target t where pr.season_id=p_season_id and pr.user_id=t.uid
), ds as (
  select d.* from public.rival_duels d,target t,current_r cr where d.season_id=p_season_id and d.user_id=t.uid and d.rival_user_id=cr.rival_user_id and d.finalized_at is not null
), streak as (
  select count(*)::integer n from (
    select result,row_number() over(order by finalized_at desc) rn,
      sum(case when result<>'win' then 1 else 0 end) over(order by finalized_at desc) grp
    from ds
  ) x where grp=0 and result='win'
)
select cr.user_id,cr.rival_user_id,count(ds.id)::bigint,
  count(*) filter(where ds.result='win')::bigint,count(*) filter(where ds.result='draw')::bigint,count(*) filter(where ds.result='loss')::bigint,
  coalesce(sum(ds.user_points),0)::bigint,coalesce(sum(ds.rival_points),0)::bigint,
  coalesce(max(ds.user_points-ds.rival_points),0)::integer,coalesce(min(ds.user_points-ds.rival_points),0)::integer,
  coalesce((select n from streak),0),
  exists(select 1 from public.player_rivals back where back.season_id=p_season_id and back.user_id=cr.rival_user_id and back.rival_user_id=cr.user_id)
from current_r cr left join ds on true
group by cr.user_id,cr.rival_user_id;
$$;

-- =============================================================================
-- 9. Tickets : création, conversation, statut
-- =============================================================================
create or replace function public.create_support_ticket_v060(
  p_season_id uuid,p_type text,p_subject text,p_message text,p_technical_context jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_ticket uuid;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  insert into public.support_tickets(user_id,season_id,ticket_type,subject,technical_context)
  values(auth.uid(),p_season_id,p_type,trim(p_subject),coalesce(p_technical_context,'{}'::jsonb)) returning id into v_ticket;
  insert into public.support_ticket_messages(ticket_id,author_id,author_kind,body)
  values(v_ticket,auth.uid(),'player',trim(p_message));
  return v_ticket;
end;
$$;

create or replace function public.reply_support_ticket_v060(p_ticket_id uuid,p_body text)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_ticket public.support_tickets%rowtype; v_id uuid; v_owl boolean;
begin
  select * into v_ticket from public.support_tickets where id=p_ticket_id;
  if not found then raise exception 'Ticket introuvable.'; end if;
  v_owl:=public.is_super_admin();
  if not v_owl and v_ticket.user_id<>auth.uid() then raise exception 'Accès refusé.'; end if;
  insert into public.support_ticket_messages(ticket_id,author_id,author_kind,body)
  values(p_ticket_id,auth.uid(),case when v_owl then 'owl' else 'player' end,trim(p_body)) returning id into v_id;
  if v_owl then
    update public.support_tickets set status=case when status='received' then 'in_progress' else status end where id=p_ticket_id;
    perform public.create_notification_v060(v_ticket.user_id,v_ticket.season_id,'support','🦉 Le Hibou a répondu',
      'Une nouvelle réponse t’attend dans « '||v_ticket.subject||' ».','important','support:'||p_ticket_id::text,
      jsonb_build_object('ticket_id',p_ticket_id),true,'ticket-reply:'||v_id::text);
  end if;
  return v_id;
end;
$$;

create or replace function public.resolve_my_support_ticket_v060(p_ticket_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  update public.support_tickets set status='resolved',resolved_by_user_at=now()
  where id=p_ticket_id and user_id=auth.uid() and status not in ('closed','rejected');
  if not found then raise exception 'Ticket introuvable ou déjà clos.'; end if;
end;
$$;

create or replace function public.admin_update_support_ticket_v060(p_ticket_id uuid,p_status text,p_priority text)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  update public.support_tickets set status=p_status,priority=p_priority,
    closed_at=case when p_status in ('closed','rejected') then now() else null end
  where id=p_ticket_id;
  if not found then raise exception 'Ticket introuvable.'; end if;
end;
$$;

-- =============================================================================
-- 10. Messages ciblés du Hibou (Super Admin)
-- =============================================================================
create or replace function public.admin_send_owl_message_v060(
  p_season_id uuid,p_title text,p_body text,p_importance text,p_target_scope text,p_target_id uuid default null,p_push boolean default false
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; r record;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  if p_target_scope='player' and p_target_id is null then raise exception 'Choisis un joueur.'; end if;
  if p_target_scope='team' and p_target_id is null then raise exception 'Choisis une Team.'; end if;
  insert into public.owl_messages(season_id,title,body,importance,target_scope,target_id,push_enabled,created_by)
  values(p_season_id,trim(p_title),trim(p_body),p_importance,p_target_scope,p_target_id,p_push,auth.uid()) returning id into v_id;
  for r in
    select p.id user_id from public.profiles p where p.status='active' and (
      p_target_scope='all'
      or (p_target_scope='player' and p.id=p_target_id)
      or (p_target_scope='team' and exists(select 1 from public.team_memberships tm where tm.team_id=p_target_id and tm.user_id=p.id and tm.left_at is null))
    )
  loop
    perform public.create_notification_v060(r.user_id,p_season_id,'owl','🦉 '||trim(p_title),trim(p_body),p_importance,
      'home',jsonb_build_object('owl_message_id',v_id),p_push,'owl-message:'||v_id::text);
  end loop;
  return v_id;
end;
$$;

create or replace function public.admin_send_system_message_v060(
  p_season_id uuid,p_title text,p_body text,p_push boolean default true
) returns integer language plpgsql security definer set search_path=public as $$
declare r record; v_count integer:=0;
begin
  if not public.is_super_admin() then raise exception 'Réservé au Super Admin.'; end if;
  for r in select id from public.profiles where status='active' loop
    perform public.create_notification_v060(r.id,p_season_id,'system','🚨 '||trim(p_title),trim(p_body),'urgent','home',jsonb_build_object('critical',true),p_push,
      'system-critical:'||md5(trim(p_title)||trim(p_body)||now()::date::text));
    v_count:=v_count+1;
  end loop;
  insert into public.audit_logs(actor_id,action,entity_type,new_data) values(auth.uid(),'system_message_send','notification',jsonb_build_object('title',p_title,'recipients',v_count,'push',p_push));
  return v_count;
end;
$$;

-- =============================================================================
-- 10b. Notifications automatiques liées aux Teams
-- =============================================================================
create or replace function public.notify_team_event_v060()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  t public.teams%rowtype;
  actor_name text;
  target_name text;
  r record;
begin
  select * into t from public.teams where id=new.team_id;
  if not found then return new; end if;
  select username::text into actor_name from public.profiles where id=new.actor_id;
  select username::text into target_name from public.profiles where id=new.target_user_id;

  if new.event_type='join_requested' and t.captain_user_id is not null then
    perform public.create_notification_v060(t.captain_user_id,new.season_id,'team','🛡 Nouvelle demande d’adhésion',
      coalesce(target_name,'Un joueur')||' veut rejoindre '||t.name||'.','important','teams:management',jsonb_build_object('team_id',new.team_id,'tab','management'),true,'team-event:'||new.id::text||':captain');
  elsif new.event_type='join_rejected' and new.target_user_id is not null then
    perform public.create_notification_v060(new.target_user_id,new.season_id,'team','Demande refusée',
      t.name||' n’a pas accepté ta demande pour le moment.','info','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':target');
  elsif new.event_type='member_joined' and new.target_user_id is not null then
    if new.actor_id is distinct from new.target_user_id then
      perform public.create_notification_v060(new.target_user_id,new.season_id,'team','🛡 Bienvenue dans la Team',
        'Tu rejoins '||t.name||'.','important','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':target');
    end if;
    for r in select user_id from public.team_memberships where team_id=new.team_id and left_at is null and user_id<>new.target_user_id loop
      perform public.create_notification_v060(r.user_id,new.season_id,'team','🛡 Nouveau membre',
        coalesce(target_name,'Un nouveau joueur')||' rejoint '||t.name||'.','info','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':member:'||r.user_id::text);
    end loop;
  elsif new.event_type='member_kicked' and new.target_user_id is not null then
    perform public.create_notification_v060(new.target_user_id,new.season_id,'team','Tu quittes la Team',
      'Tu as été retiré de '||t.name||'.','important','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':target');
  elsif new.event_type='captain_transferred' and new.target_user_id is not null then
    perform public.create_notification_v060(new.target_user_id,new.season_id,'team','👑 Nouveau capitaine',
      'Le capitanat de '||t.name||' t’est confié.','important','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':target');
  elsif new.event_type='team_dissolved' then
    for r in select user_id from public.team_memberships where team_id=new.team_id and left_at is null loop
      perform public.create_notification_v060(r.user_id,new.season_id,'team','🛡 Team dissoute',
        t.name||' vient d’être dissoute et archivée.','important','teams',jsonb_build_object('team_id',new.team_id),true,'team-event:'||new.id::text||':member:'||r.user_id::text);
    end loop;
  elsif new.event_type='identity_changed' then
    for r in select user_id from public.team_memberships where team_id=new.team_id and left_at is null loop
      perform public.create_notification_v060(r.user_id,new.season_id,'team','🎨 Apparence de Team mise à jour',
        t.name||' a rafraîchi son identité.','normal','teams',jsonb_build_object('team_id',new.team_id),false,'team-event:'||new.id::text||':member:'||r.user_id::text);
    end loop;
  end if;
  return new;
end;
$$;
drop trigger if exists notify_team_event_v060 on public.team_events;
create trigger notify_team_event_v060 after insert on public.team_events
for each row execute function public.notify_team_event_v060();

-- =============================================================================
-- 11. RLS
-- =============================================================================
alter table public.notification_preferences enable row level security;
alter table public.notifications enable row level security;
alter table public.push_subscriptions enable row level security;
alter table public.push_delivery_logs enable row level security;
alter table public.player_rivals enable row level security;
alter table public.rival_changes enable row level security;
alter table public.rival_duels enable row level security;
alter table public.ranking_notification_state enable row level security;
alter table public.owl_messages enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_ticket_messages enable row level security;
alter table public.support_ticket_attachments enable row level security;

drop policy if exists notification_preferences_own on public.notification_preferences;
create policy notification_preferences_own on public.notification_preferences for all to authenticated
using(user_id=auth.uid()) with check(user_id=auth.uid());

drop policy if exists notifications_own_read on public.notifications;
create policy notifications_own_read on public.notifications for select to authenticated using(user_id=auth.uid() or public.is_super_admin());
drop policy if exists notifications_own_update on public.notifications;
create policy notifications_own_update on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

drop policy if exists push_subscriptions_own on public.push_subscriptions;
create policy push_subscriptions_own on public.push_subscriptions for all to authenticated
using(user_id=auth.uid() or public.is_super_admin()) with check(user_id=auth.uid() or public.is_super_admin());
drop policy if exists push_delivery_logs_super on public.push_delivery_logs;
create policy push_delivery_logs_super on public.push_delivery_logs for select to authenticated using(public.is_super_admin());

drop policy if exists player_rivals_read on public.player_rivals;
create policy player_rivals_read on public.player_rivals for select to authenticated using(true);
drop policy if exists rival_changes_read on public.rival_changes;
create policy rival_changes_read on public.rival_changes for select to authenticated using(true);
drop policy if exists rival_duels_read on public.rival_duels;
create policy rival_duels_read on public.rival_duels for select to authenticated using(true);
drop policy if exists ranking_notification_state_own on public.ranking_notification_state;
create policy ranking_notification_state_own on public.ranking_notification_state for select to authenticated using(user_id=auth.uid() or public.is_super_admin());

drop policy if exists owl_messages_target_read on public.owl_messages;
create policy owl_messages_target_read on public.owl_messages for select to authenticated using(
  public.is_super_admin()
  or (starts_at<=now() and (show_in_history=true or expires_at is null or expires_at>now()) and (
    target_scope='all'
    or (target_scope='player' and target_id=auth.uid())
    or (target_scope='team' and exists(select 1 from public.team_memberships tm where tm.team_id=target_id and tm.user_id=auth.uid() and tm.left_at is null))
  ))
);
drop policy if exists owl_messages_super_all on public.owl_messages;
create policy owl_messages_super_all on public.owl_messages for all to authenticated using(public.is_super_admin()) with check(public.is_super_admin());

drop policy if exists support_tickets_private on public.support_tickets;
create policy support_tickets_private on public.support_tickets for select to authenticated using(user_id=auth.uid() or public.is_super_admin());
drop policy if exists support_messages_private on public.support_ticket_messages;
create policy support_messages_private on public.support_ticket_messages for select to authenticated using(
  exists(select 1 from public.support_tickets t where t.id=ticket_id and (t.user_id=auth.uid() or public.is_super_admin()))
);
drop policy if exists support_attachments_private on public.support_ticket_attachments;
create policy support_attachments_private on public.support_ticket_attachments for select to authenticated using(
  exists(select 1 from public.support_tickets t where t.id=ticket_id and (t.user_id=auth.uid() or public.is_super_admin()))
);
drop policy if exists support_attachments_insert_own on public.support_ticket_attachments;
create policy support_attachments_insert_own on public.support_ticket_attachments for insert to authenticated with check(
  user_id=auth.uid() and exists(select 1 from public.support_tickets t where t.id=ticket_id and t.user_id=auth.uid())
);

-- Storage captures : utilisateur propriétaire ou Super Admin.
drop policy if exists support_captures_read on storage.objects;
create policy support_captures_read on storage.objects for select to authenticated using(
  bucket_id='support-captures' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_super_admin())
);
drop policy if exists support_captures_insert on storage.objects;
create policy support_captures_insert on storage.objects for insert to authenticated with check(
  bucket_id='support-captures' and (storage.foldername(name))[1]=auth.uid()::text
);
drop policy if exists support_captures_delete on storage.objects;
create policy support_captures_delete on storage.objects for delete to authenticated using(
  bucket_id='support-captures' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_super_admin())
);

-- =============================================================================
-- 12. Privilèges
-- =============================================================================
revoke execute on function public.create_notification_v060(uuid,uuid,text,text,text,text,text,jsonb,boolean,text) from public,anon,authenticated;
revoke execute on function public.seed_notification_preferences_v060() from public,anon,authenticated;
revoke execute on function public.notify_team_event_v060() from public,anon,authenticated;
revoke execute on function public.refresh_rival_duels_v060(uuid) from public,anon,authenticated;
revoke execute on function public.mark_all_notifications_read_v060() from public,anon;
revoke execute on function public.set_my_rival_v060(uuid,uuid,uuid) from public,anon;
revoke execute on function public.get_rival_summary_v060(uuid,uuid) from public,anon;
revoke execute on function public.create_support_ticket_v060(uuid,text,text,text,jsonb) from public,anon;
revoke execute on function public.reply_support_ticket_v060(uuid,text) from public,anon;
revoke execute on function public.resolve_my_support_ticket_v060(uuid) from public,anon;
revoke execute on function public.admin_update_support_ticket_v060(uuid,text,text) from public,anon;
revoke execute on function public.admin_send_owl_message_v060(uuid,text,text,text,text,uuid,boolean) from public,anon;
revoke execute on function public.admin_send_system_message_v060(uuid,text,text,boolean) from public,anon;

grant select,insert,update on public.notification_preferences to authenticated;
grant select on public.notifications to authenticated;
revoke update on public.notifications from authenticated;
grant update(read_at,deleted_at) on public.notifications to authenticated;
grant select,insert,update,delete on public.push_subscriptions to authenticated;
grant select on public.push_delivery_logs to authenticated;
grant select on public.player_rivals,public.rival_changes,public.rival_duels,public.ranking_notification_state to authenticated;
grant select on public.owl_messages to authenticated;
grant insert,update,delete on public.owl_messages to authenticated;
grant select on public.support_tickets,public.support_ticket_messages,public.support_ticket_attachments to authenticated;
grant insert on public.support_ticket_attachments to authenticated;

grant execute on function public.mark_all_notifications_read_v060() to authenticated;
grant execute on function public.set_my_rival_v060(uuid,uuid,uuid) to authenticated;
grant execute on function public.get_rival_summary_v060(uuid,uuid) to authenticated;
grant execute on function public.create_support_ticket_v060(uuid,text,text,text,jsonb) to authenticated;
grant execute on function public.reply_support_ticket_v060(uuid,text) to authenticated;
grant execute on function public.resolve_my_support_ticket_v060(uuid) to authenticated;
grant execute on function public.admin_update_support_ticket_v060(uuid,text,text) to authenticated;
grant execute on function public.admin_send_owl_message_v060(uuid,text,text,text,text,uuid,boolean) to authenticated;
grant execute on function public.admin_send_system_message_v060(uuid,text,text,boolean) to authenticated;

-- L'Edge Function push-dispatch travaille avec service_role. BYPASSRLS ne remplace
-- pas les privilèges SQL sur les objets ni EXECUTE après révocation de PUBLIC.
grant all on public.notification_preferences,public.notifications,public.push_subscriptions,public.push_delivery_logs,
  public.player_rivals,public.rival_changes,public.rival_duels,public.ranking_notification_state to service_role;
grant usage,select on sequence public.push_delivery_logs_id_seq to service_role;
grant execute on function public.refresh_rival_duels_v060(uuid) to service_role;

insert into public.app_settings(key,value)
values ('app_version','"0.6.0"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

notify pgrst,'reload schema';
commit;

select key,value from public.app_settings where key='app_version';
-- Le Nid des Champions — V0.6.2
-- Correctif UX : réactions joueurs + cohérence des notifications sociales.
-- Les corrections visuelles Team/avatar sont front-only ; ce patch ajoute seulement
-- la mécanique serveur des réactions rapides.

begin;

alter table public.notification_preferences
  add column if not exists category_social boolean not null default true;

-- La contrainte V0.6.0 ne connaissait pas encore la catégorie social.
alter table public.notifications drop constraint if exists notifications_category_check;
alter table public.notifications
  add constraint notifications_category_check
  check (category in ('matches','champion','results','rival','team','owl','system','ranking','support','social'));

create table if not exists public.player_reactions (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id) on delete cascade,
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null check (emoji in ('👏','🔥','😂','😱','🦉','🏆','💀','❤️')),
  created_at timestamptz not null default now(),
  check (sender_user_id <> recipient_user_id)
);
create index if not exists player_reactions_sender_idx on public.player_reactions(sender_user_id,created_at desc);
create index if not exists player_reactions_recipient_idx on public.player_reactions(recipient_user_id,created_at desc);

alter table public.player_reactions enable row level security;
drop policy if exists player_reactions_own_read on public.player_reactions;
create policy player_reactions_own_read on public.player_reactions
for select to authenticated
using (sender_user_id=auth.uid() or recipient_user_id=auth.uid());

grant select on public.player_reactions to authenticated;

create or replace function public.send_player_reaction_v062(
  p_recipient_user_id uuid,
  p_emoji text,
  p_season_id uuid default null
) returns uuid
language plpgsql security definer set search_path=public as $$
declare
  v_id uuid;
  v_sender_name text;
  v_label text;
  v_hour_count integer;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  if p_recipient_user_id is null then raise exception 'Joueur destinataire requis.'; end if;
  if p_recipient_user_id=auth.uid() then raise exception 'Tu ne peux pas t’envoyer une réaction à toi-même.'; end if;
  if p_emoji not in ('👏','🔥','😂','😱','🦉','🏆','💀','❤️') then raise exception 'Réaction non autorisée.'; end if;
  if not exists(select 1 from public.profiles where id=p_recipient_user_id and status='active') then
    raise exception 'Ce joueur n’est pas disponible.';
  end if;

  -- Anti-spam léger : pas deux réactions en rafale et plafond généreux à l'heure.
  if exists(
    select 1 from public.player_reactions
    where sender_user_id=auth.uid() and created_at>now()-interval '8 seconds'
  ) then raise exception 'Doucement sur les plumes : attends quelques secondes.'; end if;

  select count(*) into v_hour_count
  from public.player_reactions
  where sender_user_id=auth.uid() and created_at>now()-interval '1 hour';
  if v_hour_count>=30 then raise exception 'Le Hibou a rangé les confettis : limite de réactions atteinte pour cette heure.'; end if;

  insert into public.player_reactions(season_id,sender_user_id,recipient_user_id,emoji)
  values(p_season_id,auth.uid(),p_recipient_user_id,p_emoji)
  returning id into v_id;

  select username::text into v_sender_name from public.profiles where id=auth.uid();
  v_label:=case p_emoji
    when '👏' then 'Bien joué'
    when '🔥' then 'En feu'
    when '😂' then 'MDR'
    when '😱' then 'Incroyable'
    when '🦉' then 'Hibou'
    when '🏆' then 'Champion'
    when '💀' then 'Ça pique'
    when '❤️' then 'Respect'
    else 'Réaction'
  end;

  perform public.create_notification_v060(
    p_recipient_user_id,
    p_season_id,
    'social',
    p_emoji||' '||coalesce(v_sender_name,'Un joueur')||' réagit',
    v_label||' · réaction rapide du Nid.',
    'info',
    'player:'||auth.uid()::text,
    jsonb_build_object('sender_user_id',auth.uid(),'emoji',p_emoji,'reaction_id',v_id),
    true,
    null
  );

  return v_id;
end;
$$;

grant execute on function public.send_player_reaction_v062(uuid,text,uuid) to authenticated;

insert into public.app_settings(key,value)
values ('app_version','"0.6.2"'::jsonb)
on conflict (key) do update set value=excluded.value,updated_at=now();

commit;
