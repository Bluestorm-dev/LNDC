-- V0.7.2 — Nettoyage immédiat de la saison 2026/27
-- À utiliser uniquement si tu souhaites réellement repartir avec un calendrier vide.
select public.admin_delete_all_matches_v067(id)
from public.seasons
where slug='ucl-2026-27';
