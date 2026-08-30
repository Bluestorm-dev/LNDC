import { createClient } from "npm:@supabase/supabase-js@^2";
import { corsHeaders } from "npm:@supabase/supabase-js@^2/cors";

type Action = "clubs" | "catalog" | "calendar" | "center" | "odds" | "full";

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
  score?: {
    winner?: string | null;
    duration?: string | null;
    fullTime?: { home?: number | null; away?: number | null } | null;
    halfTime?: { home?: number | null; away?: number | null } | null;
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

function apiStatusToCenterStatus(status: string): "scheduled" | "live" | "finished" | "postponed" | "cancelled" | "suspended" {
  switch (String(status || "").toUpperCase()) {
    case "IN_PLAY": case "PAUSED": return "live";
    case "FINISHED": return "finished";
    case "POSTPONED": return "postponed";
    case "CANCELLED": return "cancelled";
    case "SUSPENDED": return "suspended";
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

// V0.7.4 : la synchronisation vérifie strictement la saison demandée et les dates reçues.
// Aucun calendrier d'une ancienne saison n'est transposé. Pour ucl-2026-27,
// football-data.org est donc interrogé avec season=2026 et les dates restent réelles.
const DEFAULT_SOURCE_SEASON_YEAR = 2026;
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

function sourceKickoffDate(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) throw new Error(`Date football-data invalide : ${iso}`);
  return date.toISOString();
}

function seasonLabel(startYear: number): string {
  return `${startYear}/${String((startYear + 1) % 100).padStart(2, "0")}`;
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
    const action = (["clubs", "catalog", "calendar", "center", "odds", "full"].includes(payload?.action) ? payload.action : "full") as Action;
    const requestedSeasonYear = Number(payload?.seasonYear || DEFAULT_SOURCE_SEASON_YEAR);
    if (!Number.isInteger(requestedSeasonYear) || requestedSeasonYear < 2024 || requestedSeasonYear > 2100) {
      throw new Error("Année de saison invalide.");
    }
    const sourceSeasonYear = requestedSeasonYear;
    const sourceSeasonLabel = seasonLabel(sourceSeasonYear);
    const seasonSlug = String(payload?.seasonSlug || "ucl-2026-27");
    const competitionCode = String(payload?.competitionCode || "CL").toUpperCase();

    const fdFetch = async (path: string) => {
      const response = await fetch(`https://api.football-data.org/v4${path}`, {
        headers: { "X-Auth-Token": footballKey },
      });
      if (!response.ok) {
        const body = await response.text();
        const fdError = new Error(`football-data.org ${response.status}: ${body.slice(0, 220)}`);
        (fdError as any).footballDataStatus = response.status;
        (fdError as any).footballDataBody = body.slice(0, 500);
        throw fdError;
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
      const nowIso = new Date().toISOString();

      let { data: existing } = await admin
        .from("clubs")
        .select("id,logo_storage_path,manual_metadata_lock")
        .eq("external_provider", "football-data")
        .eq("external_id", team.id)
        .maybeSingle();

      // Un club créé manuellement peut être rattaché au fournisseur par son nom exact,
      // mais son verrou manuel reste prioritaire sur les métadonnées Football-Data.
      if (!existing) {
        const byManualName = await admin
          .from("clubs")
          .select("id,logo_storage_path,manual_metadata_lock")
          .eq("name", team.name)
          .is("external_provider", null)
          .maybeSingle();
        existing = byManualName.data || null;
      }

      const providerIdentity = {
        external_provider: "football-data",
        external_id: team.id,
        is_active: true,
        provider_metadata_updated_at: nowIso,
        updated_at: nowIso,
      };
      const providerMetadata = {
        name: team.name,
        short_name: team.shortName || team.tla || team.name,
        tla: team.tla || null,
        country: team.area?.name || null,
        venue: team.venue || null,
        logo_url: team.crest || null,
        logo_source_url: logo.source,
        logo_storage_path: logo.path,
        logo_updated_at: withLogo ? nowIso : null,
        metadata_source: "football-data",
      };

      if (existing) {
        const locked = Boolean(existing.manual_metadata_lock);
        const updateRow: Record<string,unknown> = locked ? { ...providerIdentity } : { ...providerMetadata, ...providerIdentity };
        if (!locked && !updateRow.logo_storage_path && existing.logo_storage_path) updateRow.logo_storage_path = existing.logo_storage_path;
        const { data, error } = await admin.from("clubs").update(updateRow).eq("id", existing.id).select("id").single();
        if (error) throw error;
        return data.id as string;
      }

      const { data, error } = await admin.from("clubs").insert({
        ...providerMetadata, ...providerIdentity, manual_metadata_lock: false,
      }).select("id").single();
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
    let providerReceived = 0;
    let matchedByPair = 0;
    let manualProtected = 0;
    let catalogClubCount = 0;
    let catalogLogoCount = 0;
    let centerMatchCount = 0;
    let standingsCount = 0;
    const catalogByCompetition: Record<string,{clubs:number;logos:number;name:string}> = {};

    if (action === "clubs" || action === "full") {
      const teamsPayload = await fdFetch(`/competitions/${encodeURIComponent(competitionCode)}/teams?season=${sourceSeasonYear}`);
      const teams = [...new Map(((teamsPayload?.teams || []) as FDTeam[]).map(team => [team.id, team])).values()];
      if (teams.length !== EXPECTED_CLUBS) {
        throw new Error(`Import ${sourceSeasonLabel} indisponible ou incomplet : football-data.org doit fournir exactement ${EXPECTED_CLUBS} clubs de phase de ligue. Reçu ${teams.length}. Aucun club d’une ancienne saison n’a été chargé.`);
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

    if (action === "center" || action === "full") {
      const { data: season, error: seasonError } = await admin
        .from("seasons").select("id").eq("slug", seasonSlug).single();
      if (seasonError || !season) throw new Error(`Saison ${seasonSlug} introuvable.`);

      const matchesPayload = await fdFetch(`/competitions/${encodeURIComponent(competitionCode)}/matches?season=${sourceSeasonYear}`);
      let standingsPayload: any = {};
      try {
        standingsPayload = await fdFetch(`/competitions/${encodeURIComponent(competitionCode)}/standings?season=${sourceSeasonYear}`);
      } catch (standingsError) {
        console.warn("Classement Football-Data indisponible ; le front calculera un classement de secours à partir des résultats.", standingsError);
      }
      const providerSeason = Number(matchesPayload?.filters?.season ?? standingsPayload?.filters?.season);
      if (Number.isInteger(providerSeason) && providerSeason !== sourceSeasonYear) {
        throw new Error(`Le fournisseur a renvoyé la saison ${seasonLabel(providerSeason)} au lieu de ${sourceSeasonLabel}. Le Centre C1 n'a pas été modifié.`);
      }

      const centerMatches = (matchesPayload?.matches || []) as FDMatch[];
      const seasonWindowStart = Date.UTC(sourceSeasonYear, 5, 1);
      const seasonWindowEnd = Date.UTC(sourceSeasonYear + 1, 6, 1);
      const invalidDates = centerMatches.filter(match => {
        const kickoff = new Date(match.utcDate).getTime();
        return !Number.isFinite(kickoff) || kickoff < seasonWindowStart || kickoff >= seasonWindowEnd;
      });
      if (invalidDates.length) throw new Error(`Le Centre C1 a reçu ${invalidDates.length} date(s) hors saison ${sourceSeasonLabel}. Import refusé.`);

      for (const match of centerMatches) {
        const homeId = await upsertTeam(match.homeTeam, false);
        const awayId = await upsertTeam(match.awayTeam, false);
        // Le Centre C1 peut contenir les tours qualificatifs : ne pas polluer
        // club_catalog_memberships, réservé aux 36 clubs de la phase de ligue.
        const status = apiStatusToCenterStatus(match.status);
        const row = {
          season_id: season.id,
          external_provider: "football-data",
          external_match_id: match.id,
          competition_code: competitionCode,
          stage: match.stage || null,
          matchday: Number.isInteger(match.matchday) ? Number(match.matchday) : null,
          kickoff_at: sourceKickoffDate(match.utcDate),
          status,
          home_club_id: homeId,
          away_club_id: awayId,
          home_score: match.score?.fullTime?.home ?? null,
          away_score: match.score?.fullTime?.away ?? null,
          half_time_home: match.score?.halfTime?.home ?? null,
          half_time_away: match.score?.halfTime?.away ?? null,
          winner: match.score?.winner || null,
          venue: match.venue || null,
          last_synced_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };
        const { error } = await admin.from("ucl_matches").upsert(row, { onConflict: "external_provider,external_match_id" });
        if (error) throw new Error(`Migration V0.8.0 absente ou ucl_matches indisponible : ${error.message}`);
        centerMatchCount++;
      }

      const totalStanding = (standingsPayload?.standings || []).find((x: any) => String(x?.type || "").toUpperCase() === "TOTAL") || standingsPayload?.standings?.[0];
      const table = totalStanding?.table || [];
      if (table.length) {
        const { error: clearError } = await admin.from("ucl_standings").delete().eq("season_id", season.id).eq("table_type", "TOTAL");
        if (clearError) throw clearError;
      }
      for (const item of table) {
        const clubId = await upsertTeam(item.team as FDTeam, false);
        const { error } = await admin.from("ucl_standings").upsert({
          season_id: season.id,
          club_id: clubId,
          position: Number(item.position || 0),
          played_games: Number(item.playedGames || 0),
          won: Number(item.won || 0),
          draw: Number(item.draw || 0),
          lost: Number(item.lost || 0),
          points: Number(item.points || 0),
          goals_for: Number(item.goalsFor || 0),
          goals_against: Number(item.goalsAgainst || 0),
          goal_difference: Number(item.goalDifference || 0),
          form: item.form || null,
          table_type: "TOTAL",
          updated_at: new Date().toISOString(),
        }, { onConflict: "season_id,club_id,table_type" });
        if (error) throw error;
        standingsCount++;
      }
    }

    if (action === "calendar" || action === "odds" || action === "full") {
      const { data: season, error: seasonError } = await admin
        .from("seasons").select("id").eq("slug", seasonSlug).single();
      if (seasonError || !season) throw new Error(`Saison ${seasonSlug} introuvable.`);

      const matchesPayload = await fdFetch(`/competitions/${encodeURIComponent(competitionCode)}/matches?season=${sourceSeasonYear}`);
      const providerSeason = Number(matchesPayload?.filters?.season);
      if (Number.isInteger(providerSeason) && providerSeason !== sourceSeasonYear) {
        throw new Error(`Le fournisseur a renvoyé la saison ${seasonLabel(providerSeason)} au lieu de ${sourceSeasonLabel}. Aucun match n’a été importé.`);
      }

      const matches = (matchesPayload?.matches || []) as FDMatch[];
      const seasonWindowStart = Date.UTC(sourceSeasonYear, 5, 1);
      const seasonWindowEnd = Date.UTC(sourceSeasonYear + 1, 6, 1);
      const outOfSeason = matches.filter(match => {
        const kickoff = new Date(match.utcDate).getTime();
        return !Number.isFinite(kickoff) || kickoff < seasonWindowStart || kickoff >= seasonWindowEnd;
      });
      if (outOfSeason.length) {
        const sample = outOfSeason.slice(0, 3).map(match => String(match.utcDate || "date inconnue")).join(", ");
        throw new Error(`Le calendrier reçu ne correspond pas à la saison ${sourceSeasonLabel} (${outOfSeason.length} date(s) hors saison, ex. ${sample}). Aucun ancien calendrier n’a été importé.`);
      }

      const numbered = matches.filter(m => Number.isInteger(m.matchday) && Number(m.matchday) >= 1 && Number(m.matchday) <= EXPECTED_MATCHDAYS);
      const sourcePool = numbered.filter(m => /LEAGUE|REGULAR_SEASON/i.test(String(m.stage || "")));
      const leagueMatches = [...new Map(sourcePool.map(m => [m.id, m])).values()]
        .sort((a, b) => Number(a.matchday) - Number(b.matchday) || new Date(a.utcDate).getTime() - new Date(b.utcDate).getTime());
      providerReceived = leagueMatches.length;

      // V0.9.10 : Football-Data est désormais un fournisseur de mise à jour, pas la
      // source unique du calendrier. Un lot partiel (même un seul jour) est accepté.
      // La protection anti-ancienne saison reste stricte et aucune donnée locale absente
      // de la réponse du fournisseur n'est supprimée.
      if (!leagueMatches.length) {
        return json({ ok: true, action, sourceSeasonYear, sourceSeasonLabel, providerReceived: 0,
          partialCalendar: true, expectedLeagueMatches: EXPECTED_LEAGUE_MATCHES, oddsCount: 0,
          message: `Football-Data ne fournit actuellement aucun match de phase de ligue ${sourceSeasonLabel}. Le calendrier local est conservé.` });
      }

      const { data: leaguePhase, error: phaseError } = await admin
        .from("competition_phases")
        .upsert({ season_id: season.id, code: "LEAGUE", name: "Phase de ligue", sort_order: 10, default_multiplier: 1 }, { onConflict: "season_id,code" })
        .select("id").single();
      if (phaseError) throw phaseError;

      const matchdayIds = new Map<number, string>();
      for (const number of [...new Set(leagueMatches.map(m => Number(m.matchday)))].sort((a,b)=>a-b)) {
        const { data: existingMd, error: existingMdError } = await admin.from("matchdays")
          .select("id").eq("season_id", season.id).eq("number", number).maybeSingle();
        if (existingMdError) throw existingMdError;
        if (existingMd?.id) {
          matchdayIds.set(number, existingMd.id);
          const { error } = await admin.from("matchdays").update({ phase_id: leaguePhase.id, name: `Journée ${number}` }).eq("id", existingMd.id);
          if (error) throw error;
        } else {
          const dayMatches = leagueMatches.filter(m => Number(m.matchday) === number);
          const times = dayMatches.map(m => new Date(sourceKickoffDate(m.utcDate)).getTime()).filter(Number.isFinite);
          const { data: md, error } = await admin.from("matchdays").insert({
            season_id: season.id, phase_id: leaguePhase.id, number, name: `Journée ${number}`,
            starts_at: times.length ? new Date(Math.min(...times)).toISOString() : null,
            ends_at: times.length ? new Date(Math.max(...times) + 3 * 3600_000).toISOString() : null,
          }).select("id").single();
          if (error) throw error;
          matchdayIds.set(number, md.id);
        }
      }

      for (const match of leagueMatches) {
        const homeId = await upsertTeam(match.homeTeam, false);
        const awayId = await upsertTeam(match.awayTeam, false);
        await upsertMembership(homeId, "CL", "UEFA Champions League", match.homeTeam.area?.name || null, sourceSeasonYear);
        await upsertMembership(awayId, "CL", "UEFA Champions League", match.awayTeam.area?.name || null, sourceSeasonYear);

        const rawHomeOdds = Number(match.odds?.homeWin), rawDrawOdds = Number(match.odds?.draw), rawAwayOdds = Number(match.odds?.awayWin);
        const hasOdds = [rawHomeOdds, rawDrawOdds, rawAwayOdds].every(value => Number.isFinite(value) && value > 1);

        let { data: existing, error: existingError } = await admin.from("matches")
          .select("id,status,manual_schedule_lock,external_match_id")
          .eq("season_id", season.id).eq("external_provider", "football-data").eq("external_match_id", match.id).maybeSingle();
        if (existingError) throw existingError;
        if (!existing) {
          const byPair = await admin.from("matches")
            .select("id,status,manual_schedule_lock,external_match_id")
            .eq("season_id", season.id).eq("home_club_id", homeId).eq("away_club_id", awayId).eq("is_test", false)
            .order("created_at", { ascending: true }).limit(1).maybeSingle();
          if (byPair.error) throw byPair.error;
          existing = byPair.data || null;
          if (existing) matchedByPair++;
        }

        const nowIso = new Date().toISOString();
        const identityAndOdds: Record<string,unknown> = {
          external_provider: "football-data", external_match_id: match.id, external_stage: match.stage || null,
          provider_schedule_updated_at: nowIso, updated_at: nowIso,
          ...(hasOdds ? { odds_home: rawHomeOdds, odds_draw: rawDrawOdds, odds_away: rawAwayOdds,
            odds_provider: "football-data", odds_bookmaker: "football-data.org", odds_source_season: sourceSeasonLabel,
            odds_is_test_shifted: false, odds_updated_at: nowIso } : {}),
        };
        if (hasOdds) oddsCount++;

        if (action === "odds") {
          if (existing) {
            const { error } = await admin.from("matches").update(identityAndOdds).eq("id", existing.id);
            if (error) throw error;
          }
          continue;
        }

        if (existing) {
          const locked = Boolean(existing.manual_schedule_lock);
          if (locked) manualProtected++;
          const schedule = locked || existing.status === "finished" ? {} : {
            phase_id: leaguePhase.id, matchday_id: matchdayIds.get(Number(match.matchday)),
            home_club_id: homeId, away_club_id: awayId, kickoff_at: sourceKickoffDate(match.utcDate),
            stadium: match.venue || null, status: apiStatusToNid(match.status), data_source: "api", schedule_source: "football-data",
          };
          const { error } = await admin.from("matches").update({ ...schedule, ...identityAndOdds }).eq("id", existing.id);
          if (error) throw error;
        } else {
          const { error } = await admin.from("matches").insert({
            season_id: season.id, phase_id: leaguePhase.id, matchday_id: matchdayIds.get(Number(match.matchday)),
            home_club_id: homeId, away_club_id: awayId, kickoff_at: sourceKickoffDate(match.utcDate), stadium: match.venue || null,
            status: apiStatusToNid(match.status), data_source: "api", schedule_source: "football-data", manual_schedule_lock: false,
            ...identityAndOdds,
          });
          if (error) throw error;
        }
      }

      const { data: localRows, error: localError } = await admin.from("matches")
        .select("id,matchday_id,odds_home,odds_draw,odds_away").eq("season_id", season.id).eq("is_test", false);
      if (localError) throw localError;
      matchCount = (localRows || []).length;
      matchdayCount = new Set((localRows || []).map(r => r.matchday_id).filter(Boolean)).size;
      if (action === "odds") oddsCount = (localRows || []).filter(m => m.odds_home != null && m.odds_draw != null && m.odds_away != null).length;
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
      new_data: { action, competitionCode, sourceSeasonYear, sourceSeasonLabel, requestedSeasonYear, clubCount, logoCount, matchdayCount, matchCount, oddsCount, centerMatchCount, standingsCount, repairedLegacyClubs, catalogClubCount, catalogLogoCount, catalogByCompetition, providerReceived, matchedByPair, manualProtected, partialCalendar: providerReceived < EXPECTED_LEAGUE_MATCHES, expectedClubs: EXPECTED_CLUBS, expectedLeagueMatches: EXPECTED_LEAGUE_MATCHES },
    });

    return json({ ok: true, action, clubCount, logoCount, matchdayCount, matchCount, oddsCount, centerMatchCount, standingsCount, repairedLegacyClubs, catalogClubCount, catalogLogoCount, catalogByCompetition, providerReceived, matchedByPair, manualProtected, partialCalendar: providerReceived < EXPECTED_LEAGUE_MATCHES, sourceSeasonYear, sourceSeasonLabel, requestedSeasonYear, expectedClubs: EXPECTED_CLUBS, expectedLeagueMatches: EXPECTED_LEAGUE_MATCHES });
  } catch (error) {
    console.error("sync-football-data", error);
    const fdStatus = Number((error as any)?.footballDataStatus || 0);
    if (fdStatus === 404) {
      // V0.8.1 : un 404 Football-Data signifie que la ressource/saison demandée
      // n'est pas encore disponible. On renvoie HTTP 200 afin que le frontend
      // puisse afficher l'erreur métier au lieu d'une panne générique de Function.
      return json({
        ok: false,
        code: "season_not_available",
        provider_status: 404,
        error: "La saison 2026/27 n'est pas encore disponible chez Football-Data. Aucun match 2025/26 n'a été importé. Réessaie après la publication du calendrier."
      }, 200);
    }
    if (fdStatus === 401 || fdStatus === 403) {
      return json({ ok: false, code: "provider_auth_error", provider_status: fdStatus, error: "Football-Data refuse l'accès. Vérifie le secret FOOTBALL_DATA_API_KEY et les droits du compte API." }, 200);
    }
    if (fdStatus === 429) {
      return json({ ok: false, code: "provider_rate_limit", provider_status: 429, error: "Limite de requêtes Football-Data atteinte. Réessaie dans quelques minutes." }, 200);
    }
    if (fdStatus >= 500) {
      return json({ ok: false, code: "provider_unavailable", provider_status: fdStatus, error: `Football-Data est momentanément indisponible (HTTP ${fdStatus}). Le calendrier local reste intact ; les cotes peuvent être saisies manuellement dans le Nid.` }, 200);
    }
    // La Function journalise l'erreur côté Supabase mais répond avec une enveloppe métier
    // pour que l'Admin puisse rester utilisable et basculer sur la saisie manuelle.
    return json({ ok: false, code: "sync_internal_error", error: "La synchronisation Football-Data a rencontré une erreur interne. Le calendrier local reste intact ; consulte les logs sync-football-data. Les cotes peuvent être saisies manuellement." }, 200);
  }
});
