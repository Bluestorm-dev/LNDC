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
