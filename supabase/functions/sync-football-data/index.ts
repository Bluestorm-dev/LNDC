import { createClient } from "npm:@supabase/supabase-js@^2";
import { corsHeaders } from "npm:@supabase/supabase-js@^2/cors";

type Action = "clubs" | "catalog" | "calendar" | "odds" | "full";

type FDTeam = {
  id: number;
  name: string;
  shortName?: string | null;
  tla?: string | null;
  crest?: string | null;
  venue?: string | null;
  area?: { name?: string | null } | null;
};

type FDMatch = {
  id: number;
  utcDate: string;
  status: string;
  matchday?: number | null;
  stage?: string | null;
  venue?: string | null;
  odds?: {
    homeWin?: number | null;
    draw?: number | null;
    awayWin?: number | null;
  } | null;
  homeTeam: FDTeam;
  awayTeam: FDTeam;
};

const json = (body: unknown, status = 200) =>
  Response.json(body, { status, headers: corsHeaders });

function apiStatusToNid(status: string): "scheduled" | "postponed" | "cancelled" {
  switch (String(status || "").toUpperCase()) {
    case "POSTPONED": return "postponed";
    case "CANCELLED": return "cancelled";
    default: return "scheduled";
  }
}

function safeSlug(input: string): string {
  return input
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80) || "club";
}

// Correctif V0.2.2 : la saison test est volontairement figée sur la vraie
// Champions League 2025/26. Les dates sont ensuite transposées d'un an vers
// la saison de test 2026/27 du Nid. Les résultats historiques ne sont jamais importés.
const TEST_SOURCE_SEASON_YEAR = 2025;
const EXPECTED_CLUBS = 36;
const EXPECTED_MATCHDAYS = 8;
const EXPECTED_MATCHES_PER_MATCHDAY = 18;
const EXPECTED_LEAGUE_MATCHES = EXPECTED_MATCHDAYS * EXPECTED_MATCHES_PER_MATCHDAY;

// V0.3.3 : bibliothèque indépendante destinée notamment au « club de cœur ».
// Les codes sont ceux de football-data.org. L'endpoint /teams sans filtre de saison
// suit la saison courante du fournisseur et évite de coupler ce catalogue à la saison TEST C1.
const CLUB_CATALOG_COMPETITIONS = [
  { code: "FL1", name: "Ligue 1", country: "France" },
  { code: "PL", name: "Premier League", country: "England" },
  { code: "PD", name: "La Liga", country: "Spain" },
  { code: "SA", name: "Serie A", country: "Italy" },
  { code: "BL1", name: "Bundesliga", country: "Germany" },
] as const;

// V0.3.1 : clubs historiques de la Journée TEST créés avant la synchro Football-Data.
// Après import, leurs matchs sont rattachés aux clubs canoniques afin d'utiliser
// exactement les mêmes noms et blasons que le calendrier officiel.
const LEGACY_TEST_CLUBS = [
  { legacyName: "Paris SG", externalId: 524 },
  { legacyName: "Bayern Munich", externalId: 5 },
  { legacyName: "Real Madrid", externalId: 86 },
  { legacyName: "Arsenal", externalId: 57 },
  { legacyName: "Inter Milan", externalId: 108 },
  { legacyName: "FC Barcelone", externalId: 81 },
  { legacyName: "Liverpool", externalId: 64 },
  { legacyName: "Dortmund", externalId: 4 },
] as const;

function shiftTestDate(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) throw new Error(`Date football-data invalide : ${iso}`);
  date.setUTCFullYear(date.getUTCFullYear() + 1);
  return date.toISOString();
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json({ ok: true });
  if (req.method !== "POST") return json({ ok: false, error: "Méthode non autorisée." }, 405);

  try {
    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const footballKey = Deno.env.get("FOOTBALL_DATA_API_KEY");
    if (!url || !serviceKey) throw new Error("Configuration Supabase incomplète.");
    if (!footballKey) {
      return json({ ok: false, code: "missing_api_key", error: "Secret FOOTBALL_DATA_API_KEY absent." }, 400);
    }

    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) return json({ ok: false, error: "Authentification requise." }, 401);

    const admin = createClient(url, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: userData, error: userError } = await admin.auth.getUser(token);
    const user = userData?.user;
    if (userError || !user) return json({ ok: false, error: "Session invalide." }, 401);

    const { data: profile } = await admin
      .from("profiles")
      .select("role,status")
      .eq("id", user.id)
      .maybeSingle();
    if (!profile || profile.status !== "active" || !["admin", "super_admin"].includes(profile.role)) {
      return json({ ok: false, error: "Réservé aux administrateurs." }, 403);
    }

    const payload = await req.json().catch(() => ({}));
    const action = (["clubs", "catalog", "calendar", "odds", "full"].includes(payload?.action) ? payload.action : "full") as Action;
    const sourceSeasonYear = TEST_SOURCE_SEASON_YEAR;
    const requestedSeasonYear = Number(payload?.seasonYear || 2026);
    const seasonSlug = String(payload?.seasonSlug || "ucl-2026-27");
    const competitionCode = String(payload?.competitionCode || "CL").toUpperCase();

    const fdFetch = async (path: string) => {
      const response = await fetch(`https://api.football-data.org/v4${path}`, {
        headers: { "X-Auth-Token": footballKey },
      });
      if (!response.ok) {
        const body = await response.text();
        throw new Error(`football-data.org ${response.status}: ${body.slice(0, 220)}`);
      }
      return response.json();
    };

    const uploadLogo = async (team: FDTeam): Promise<{ source: string | null; path: string | null }> => {
      const source = team.crest || null;
      const candidates = [
        source,
        `https://crests.football-data.org/${team.id}.png`,
      ].filter((v, i, a): v is string => Boolean(v) && a.indexOf(v) === i);

      const tryStore = async (logoUrl: string, provider: string) => {
        try {
          const response = await fetch(logoUrl);
          if (!response.ok) return null;
          const type = (response.headers.get("content-type") || "").split(";")[0].trim();
          if (!type.startsWith("image/")) return null;
          const ext = type === "image/png" ? "png"
            : type === "image/webp" ? "webp"
            : type === "image/jpeg" ? "jpg"
            : type === "image/svg+xml" ? "svg" : null;
          if (!ext) return null;
          const path = `${provider}/${team.id}-${safeSlug(team.shortName || team.name)}.${ext}`;
          const buffer = new Uint8Array(await response.arrayBuffer());
          const { error } = await admin.storage.from("club-logos").upload(path, buffer, {
            contentType: type,
            cacheControl: "604800",
            upsert: true,
          });
          // Même si le stockage échoue, l'URL vient d'être téléchargée avec succès :
          // elle constitue donc un fallback externe réellement vérifié pour l'UI.
          return error ? { source: logoUrl, path: null } : { source: logoUrl, path };
        } catch (error) {
          console.warn("logo sync", team.id, error);
          return null;
        }
      };

      for (const logoUrl of candidates) {
        const stored = await tryStore(logoUrl, "football-data");
        if (stored) return stored;
      }

      // Fallback gratuit : TheSportsDB v1. On ne l'utilise que si le blason
      // football-data.org n'a pas pu être récupéré.
      try {
        const searchUrl = `https://www.thesportsdb.com/api/v1/json/123/searchteams.php?t=${encodeURIComponent(team.name)}`;
        const searchResponse = await fetch(searchUrl);
        if (searchResponse.ok) {
          const searchData = await searchResponse.json();
          const badge = searchData?.teams?.[0]?.strBadge;
          if (badge) {
            const stored = await tryStore(String(badge), "thesportsdb");
            if (stored) return stored;
            return { source: String(badge), path: null };
          }
        }
      } catch (error) {
        console.warn("TheSportsDB fallback", team.id, error);
      }

      return { source: null, path: null };
    };

    const upsertTeam = async (team: FDTeam, withLogo: boolean) => {
      let logo = { source: team.crest || null, path: null as string | null };
      if (withLogo) logo = await uploadLogo(team);

      const row = {
        name: team.name,
        short_name: team.shortName || team.tla || team.name,
        tla: team.tla || null,
        country: team.area?.name || null,
        venue: team.venue || null,
        logo_url: team.crest || null,
        logo_source_url: logo.source,
        logo_storage_path: logo.path,
        logo_updated_at: withLogo ? new Date().toISOString() : null,
        external_provider: "football-data",
        external_id: team.id,
        is_active: true,
        updated_at: new Date().toISOString(),
      };

      let { data: existing } = await admin
        .from("clubs")
        .select("id,logo_storage_path")
        .eq("external_provider", "football-data")
        .eq("external_id", team.id)
        .maybeSingle();

      // V0.3.4 — IMPORTANT : un TLA (sigle sur 3 lettres) n'est PAS une identité
      // globale. Exemple réel : Stade Brestois 29 et Brentford FC utilisent tous les
      // deux « BRE ». Une recherche par TLA/nom court fusionnerait donc deux clubs
      // distincts. L'identité canonique est l'ID Football-Data.
      //
      // On n'autorise le rattachement par nom exact que pour une ancienne ligne
      // MANUELLE (external_provider IS NULL). Une ligne déjà liée à un fournisseur
      // ne peut jamais être réattribuée à un autre external_id.
      if (!existing) {
        const byManualName = await admin
          .from("clubs")
          .select("id,logo_storage_path")
          .eq("name", team.name)
          .is("external_provider", null)
          .maybeSingle();
        existing = byManualName.data || null;
      }

      if (existing) {
        if (!row.logo_storage_path && existing.logo_storage_path) row.logo_storage_path = existing.logo_storage_path;
        const { data, error } = await admin.from("clubs").update(row).eq("id", existing.id).select("id").single();
        if (error) throw error;
        return data.id as string;
      }

      const { data, error } = await admin.from("clubs").insert(row).select("id").single();
      if (error) throw error;
      return data.id as string;
    };

    const upsertMembership = async (clubId: string, competitionCode: string, competitionName: string, country: string | null, seasonYear: number) => {
      const { error } = await admin.from("club_catalog_memberships").upsert({
        club_id: clubId,
        competition_code: competitionCode,
        competition_name: competitionName,
        country,
        season_year: seasonYear,
        updated_at: new Date().toISOString(),
      }, { onConflict: "club_id,competition_code,season_year" });
      if (error) throw error;
    };

    const replaceCompetitionMemberships = async (competitionCode: string, seasonYear: number, clubIds: string[]) => {
      const { data: previous, error: previousError } = await admin
        .from("club_catalog_memberships")
        .select("club_id")
        .eq("competition_code", competitionCode)
        .eq("season_year", seasonYear);
      if (previousError) throw previousError;
      const keep = new Set(clubIds);
      const stale = (previous || []).map(row => String(row.club_id)).filter(id => !keep.has(id));
      if (stale.length) {
        const { error } = await admin.from("club_catalog_memberships")
          .delete()
          .eq("competition_code", competitionCode)
          .eq("season_year", seasonYear)
          .in("club_id", stale);
        if (error) throw error;
      }
    };

    const repairLegacyTestClubLinks = async () => {
      let repairedClubs = 0;
      for (const item of LEGACY_TEST_CLUBS) {
        const { data: canonical, error: canonicalError } = await admin
          .from("clubs")
          .select("id")
          .eq("external_provider", "football-data")
          .eq("external_id", item.externalId)
          .maybeSingle();
        if (canonicalError) throw canonicalError;
        if (!canonical?.id) continue;

        const { data: legacyRows, error: legacyError } = await admin
          .from("clubs")
          .select("id")
          .eq("name", item.legacyName)
          .neq("id", canonical.id);
        if (legacyError) throw legacyError;

        for (const legacy of legacyRows || []) {
          const { error: homeError } = await admin
            .from("matches")
            .update({ home_club_id: canonical.id, updated_at: new Date().toISOString() })
            .eq("home_club_id", legacy.id);
          if (homeError) throw homeError;

          const { error: awayError } = await admin
            .from("matches")
            .update({ away_club_id: canonical.id, updated_at: new Date().toISOString() })
            .eq("away_club_id", legacy.id);
          if (awayError) throw awayError;

          const { error: deactivateError } = await admin
            .from("clubs")
            .update({ is_active: false, updated_at: new Date().toISOString() })
            .eq("id", legacy.id);
          if (deactivateError) throw deactivateError;
          repairedClubs++;
        }
      }
      return repairedClubs;
    };

    let clubCount = 0;
    let logoCount = 0;
    let matchCount = 0;
    let matchdayCount = 0;
    let oddsCount = 0;
    let catalogClubCount = 0;
    let catalogLogoCount = 0;
    const catalogByCompetition: Record<string,{clubs:number;logos:number;name:string}> = {};

    if (action === "clubs" || action === "full") {
      const teamsPayload = await fdFetch(`/competitions/${encodeURIComponent(competitionCode)}/teams?season=${sourceSeasonYear}`);
      const teams = [...new Map(((teamsPayload?.teams || []) as FDTeam[]).map(team => [team.id, team])).values()];
      if (teams.length !== EXPECTED_CLUBS) {
        throw new Error(`Import refusé : la saison test doit fournir exactement ${EXPECTED_CLUBS} clubs de phase de ligue. Reçu ${teams.length}.`);
      }

      const canonicalIds: string[] = [];
      for (const team of teams) {
        const clubId = await upsertTeam(team, true);
        canonicalIds.push(clubId);
        await upsertMembership(clubId, "CL", "UEFA Champions League", team.area?.name || null, sourceSeasonYear);
        clubCount++;
        const after = await admin
          .from("clubs")
          .select("logo_storage_path,logo_source_url,logo_url")
          .eq("id", clubId)
          .maybeSingle();
        if (after.error) throw after.error;
        if (after.data?.logo_storage_path || after.data?.logo_source_url || after.data?.logo_url) logoCount++;
      }
      await replaceCompetitionMemberships("CL", sourceSeasonYear, canonicalIds);
      if (logoCount !== EXPECTED_CLUBS) {
        throw new Error(`Import incomplet : ${logoCount}/${EXPECTED_CLUBS} clubs disposent d'un logo exploitable.`);
      }
    }

    if (action === "catalog") {
      const allCatalogIds = new Set<string>();
      const allCatalogLogoIds = new Set<string>();
      for (const competition of CLUB_CATALOG_COMPETITIONS) {
        const teamsPayload = await fdFetch(`/competitions/${encodeURIComponent(competition.code)}/teams`);
        const teams = [...new Map(((teamsPayload?.teams || []) as FDTeam[]).map(team => [team.id, team])).values()];
        if (!teams.length) throw new Error(`Aucune équipe reçue pour ${competition.name} (${competition.code}).`);
        const ids: string[] = [];
        let leagueLogos = 0;
        for (const team of teams) {
          const clubId = await upsertTeam(team, true);
          ids.push(clubId);
          allCatalogIds.add(clubId);
          await upsertMembership(clubId, competition.code, competition.name, competition.country, requestedSeasonYear);
          const after = await admin.from("clubs").select("logo_storage_path,logo_source_url,logo_url").eq("id", clubId).maybeSingle();
          if (after.error) throw after.error;
          if (after.data?.logo_storage_path || after.data?.logo_source_url || after.data?.logo_url) {
            leagueLogos++;
            allCatalogLogoIds.add(clubId);
          }
        }
        await replaceCompetitionMemberships(competition.code, requestedSeasonYear, ids);
        catalogByCompetition[competition.code] = {clubs: ids.length, logos: leagueLogos, name: competition.name};
      }
      catalogClubCount = allCatalogIds.size;
      catalogLogoCount = allCatalogLogoIds.size;
    }

    if (action === "calendar" || action === "odds" || action === "full") {
      const { data: season, error: seasonError } = await admin
        .from("seasons").select("id").eq("slug", seasonSlug).single();
      if (seasonError || !season) throw new Error(`Saison ${seasonSlug} introuvable.`);

      const matchesPayload = await fdFetch(`/competitions/${encodeURIComponent(competitionCode)}/matches?season=${sourceSeasonYear}`);
      const matches = (matchesPayload?.matches || []) as FDMatch[];
      const numbered = matches.filter(m => Number.isInteger(m.matchday) && Number(m.matchday) >= 1 && Number(m.matchday) <= EXPECTED_MATCHDAYS);
      const explicitLeagueStage = numbered.filter(m => /LEAGUE/i.test(String(m.stage || "")));
      const sourcePool = explicitLeagueStage.length ? explicitLeagueStage : numbered;
      const leagueMatches = [...new Map(sourcePool.map(m => [m.id, m])).values()]
        .sort((a, b) => Number(a.matchday) - Number(b.matchday) || new Date(a.utcDate).getTime() - new Date(b.utcDate).getTime());

      const perDay = new Map<number, number>();
      for (const match of leagueMatches) {
        const md = Number(match.matchday);
        perDay.set(md, (perDay.get(md) || 0) + 1);
      }
      const malformedDays = Array.from({ length: EXPECTED_MATCHDAYS }, (_, i) => i + 1)
        .filter(md => perDay.get(md) !== EXPECTED_MATCHES_PER_MATCHDAY);
      if (leagueMatches.length !== EXPECTED_LEAGUE_MATCHES || malformedDays.length) {
        throw new Error(`Import refusé : football-data doit fournir exactement 144 matchs de phase de ligue (8 × 18). Reçu ${leagueMatches.length}; journées invalides : ${malformedDays.join(", ") || "aucune"}.`);
      }

      if (action === "odds") {
        // V0.3.2 : actualisation légère des cotes uniquement. Les scores, statuts,
        // dates et rattachements de clubs ne sont jamais touchés par cette action.
        for (const match of leagueMatches) {
          const rawHomeOdds = Number(match.odds?.homeWin);
          const rawDrawOdds = Number(match.odds?.draw);
          const rawAwayOdds = Number(match.odds?.awayWin);
          const hasFootballDataOdds = [rawHomeOdds, rawDrawOdds, rawAwayOdds]
            .every(value => Number.isFinite(value) && value > 1);
          if (!hasFootballDataOdds) continue;

          const { error: oddsError } = await admin
            .from("matches")
            .update({
              odds_home: rawHomeOdds,
              odds_draw: rawDrawOdds,
              odds_away: rawAwayOdds,
              odds_provider: "football-data",
              odds_bookmaker: "football-data.org",
              odds_source_season: "2025/26",
              odds_is_test_shifted: true,
              odds_updated_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
            })
            .eq("season_id", season.id)
            .eq("external_provider", "football-data")
            .eq("external_match_id", match.id);
          if (oddsError) throw oddsError;
          oddsCount++;
        }
      } else {
        const { data: leaguePhase, error: phaseError } = await admin
          .from("competition_phases")
          .upsert({ season_id: season.id, code: "LEAGUE", name: "Phase de ligue", sort_order: 10, default_multiplier: 1 }, { onConflict: "season_id,code" })
          .select("id").single();
        if (phaseError) throw phaseError;

        const expectedExternalIds = new Set(leagueMatches.map(m => m.id));
        const { data: importedExisting, error: importedError } = await admin
          .from("matches")
          .select("id,external_match_id")
          .eq("season_id", season.id)
          .eq("external_provider", "football-data");
        if (importedError) throw importedError;
        const staleIds = (importedExisting || [])
          .filter(row => !expectedExternalIds.has(Number(row.external_match_id)))
          .map(row => row.id);
        if (staleIds.length) {
          const { error: cleanupError } = await admin.from("matches").delete().in("id", staleIds);
          if (cleanupError) throw cleanupError;
        }

        const matchdayIds = new Map<number, string>();
        for (const number of Array.from({ length: EXPECTED_MATCHDAYS }, (_, i) => i + 1)) {
          const dayMatches = leagueMatches.filter(m => Number(m.matchday) === number);
          const times = dayMatches.map(m => new Date(shiftTestDate(m.utcDate)).getTime()).filter(Number.isFinite);
          const startsAt = times.length ? new Date(Math.min(...times)).toISOString() : null;
          const endsAt = times.length ? new Date(Math.max(...times) + 3 * 3600_000).toISOString() : null;
          const { data: md, error } = await admin.from("matchdays").upsert({
            season_id: season.id,
            phase_id: leaguePhase.id,
            number,
            name: `Journée ${number}`,
            starts_at: startsAt,
            ends_at: endsAt,
          }, { onConflict: "season_id,number" }).select("id").single();
          if (error) throw error;
          matchdayIds.set(number, md.id);
          matchdayCount++;
        }

        for (const match of leagueMatches) {
          const homeId = await upsertTeam(match.homeTeam, false);
          const awayId = await upsertTeam(match.awayTeam, false);
          await upsertMembership(homeId, "CL", "UEFA Champions League", match.homeTeam.area?.name || null, sourceSeasonYear);
          await upsertMembership(awayId, "CL", "UEFA Champions League", match.awayTeam.area?.name || null, sourceSeasonYear);
          const rawHomeOdds = Number(match.odds?.homeWin);
          const rawDrawOdds = Number(match.odds?.draw);
          const rawAwayOdds = Number(match.odds?.awayWin);
          const hasFootballDataOdds = [rawHomeOdds, rawDrawOdds, rawAwayOdds].every(value => Number.isFinite(value) && value > 1);

          const row = {
            season_id: season.id,
            phase_id: leaguePhase.id,
            matchday_id: matchdayIds.get(Number(match.matchday)),
            home_club_id: homeId,
            away_club_id: awayId,
            kickoff_at: shiftTestDate(match.utcDate),
            stadium: match.venue || null,
            status: apiStatusToNid(match.status),
            data_source: "manual",
            external_provider: "football-data",
            external_match_id: match.id,
            external_stage: match.stage || null,
            ...(hasFootballDataOdds ? {
              odds_home: rawHomeOdds,
              odds_draw: rawDrawOdds,
              odds_away: rawAwayOdds,
              odds_provider: "football-data",
              odds_bookmaker: "football-data.org",
              odds_source_season: "2025/26",
              odds_is_test_shifted: true,
              odds_updated_at: new Date().toISOString(),
            } : {}),
            updated_at: new Date().toISOString(),
          };
          if (hasFootballDataOdds) oddsCount++;

          const { data: existing } = await admin.from("matches")
            .select("id,status,home_score,away_score,odds_home,odds_draw,odds_away,odds_provider,odds_bookmaker,odds_updated_at")
            .eq("external_provider", "football-data")
            .eq("external_match_id", match.id)
            .maybeSingle();
          if (existing) {
            const safeRow = existing.status === "finished" ? { ...row, status: existing.status } : row;
            const { error } = await admin.from("matches").update(safeRow).eq("id", existing.id);
            if (error) throw error;
          } else {
            const { error } = await admin.from("matches").insert(row);
            if (error) throw error;
          }
          matchCount++;
        }
      }
    }

    const repairedLegacyClubs = await repairLegacyTestClubLinks();

    // V0.3.3 : les compteurs C1 restent strictement à 36 même après import
    // de la bibliothèque Top 5. Le catalogue est compté séparément.
    const { data: clMemberships, error: clMembershipsError } = await admin
      .from("club_catalog_memberships")
      .select("club_id")
      .eq("competition_code", "CL")
      .eq("season_year", sourceSeasonYear);
    if (clMembershipsError) throw clMembershipsError;
    const clClubIds = [...new Set((clMemberships || []).map(row => String(row.club_id)))];
    if (clClubIds.length) {
      const { data: clClubs, error: clClubsError } = await admin
        .from("clubs")
        .select("id,logo_url,logo_source_url,logo_storage_path")
        .in("id", clClubIds);
      if (clClubsError) throw clClubsError;
      clubCount = (clClubs || []).length;
      logoCount = (clClubs || []).filter(c => c.logo_storage_path || c.logo_source_url || c.logo_url).length;
    }

    const { data: syncedSeason, error: syncedSeasonError } = await admin
      .from("seasons")
      .select("id")
      .eq("slug", seasonSlug)
      .maybeSingle();
    if (syncedSeasonError) throw syncedSeasonError;
    if (syncedSeason?.id) {
      const [{ data: syncedMatchdays, error: matchdaysError }, { data: syncedMatches, error: matchesError }] = await Promise.all([
        admin.from("matchdays").select("id").eq("season_id", syncedSeason.id).gte("number", 1).lte("number", EXPECTED_MATCHDAYS),
        admin.from("matches").select("id,odds_home,odds_draw,odds_away").eq("season_id", syncedSeason.id).eq("external_provider", "football-data"),
      ]);
      if (matchdaysError) throw matchdaysError;
      if (matchesError) throw matchesError;
      matchdayCount = (syncedMatchdays || []).length;
      matchCount = (syncedMatches || []).length;
      oddsCount = (syncedMatches || []).filter(m => m.odds_home != null && m.odds_draw != null && m.odds_away != null).length;
    }

    await admin.from("audit_logs").insert({
      actor_id: user.id,
      action: "football_data_sync",
      entity_type: "season",
      entity_id: seasonSlug,
      new_data: { action, competitionCode, sourceSeasonYear, requestedSeasonYear, clubCount, logoCount, matchdayCount, matchCount, oddsCount, repairedLegacyClubs, catalogClubCount, catalogLogoCount, catalogByCompetition, expectedClubs: EXPECTED_CLUBS, expectedLeagueMatches: EXPECTED_LEAGUE_MATCHES },
    });

    return json({ ok: true, action, clubCount, logoCount, matchdayCount, matchCount, oddsCount, repairedLegacyClubs, catalogClubCount, catalogLogoCount, catalogByCompetition, sourceSeasonYear, requestedSeasonYear, expectedClubs: EXPECTED_CLUBS, expectedLeagueMatches: EXPECTED_LEAGUE_MATCHES });
  } catch (error) {
    console.error("sync-football-data", error);
    return json({ ok: false, error: error instanceof Error ? error.message : "Synchronisation impossible." }, 500);
  }
});
