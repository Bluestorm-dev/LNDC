import { createClient } from "npm:@supabase/supabase-js@^2";
import { corsHeaders } from "npm:@supabase/supabase-js@^2/cors";

type ClubRef = { name?: string | null; short_name?: string | null; tla?: string | null };
type NidMatch = {
  id: string;
  kickoff_at: string;
  status: string;
  home_club: ClubRef | null;
  away_club: ClubRef | null;
};
type OddsEvent = {
  id: number | string;
  home: string;
  away: string;
  date: string;
  status?: string;
  bookmakers?: Record<string, Array<{
    name?: string;
    label?: string;
    updatedAt?: string;
    odds?: Array<{ home?: string | number; draw?: string | number; away?: string | number }>;
  }>>;
};

const json = (body: unknown, status = 200) => Response.json(body, { status, headers: corsHeaders });

function normalizeName(input: string | null | undefined): string {
  return String(input || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/\b(fc|cf|afc|ac|ssc|club|football|futbol|calcio|1900|1899|1909|04|05)\b/g, " ")
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\s+/g, " ");
}

function namesMatch(a: string, b: string): boolean {
  const na = normalizeName(a);
  const nb = normalizeName(b);
  if (!na || !nb) return false;
  if (na === nb) return true;
  if (na.length >= 6 && nb.length >= 6 && (na.includes(nb) || nb.includes(na))) return true;
  const ta = new Set(na.split(" ").filter(t => t.length > 2));
  const tb = new Set(nb.split(" ").filter(t => t.length > 2));
  const common = [...ta].filter(t => tb.has(t)).length;
  return common >= Math.min(2, Math.min(ta.size, tb.size));
}

function matchEvent(match: NidMatch, event: OddsEvent): boolean {
  const home = match.home_club?.name || match.home_club?.short_name || match.home_club?.tla || "";
  const away = match.away_club?.name || match.away_club?.short_name || match.away_club?.tla || "";
  if (!namesMatch(home, event.home) || !namesMatch(away, event.away)) return false;
  const delta = Math.abs(new Date(match.kickoff_at).getTime() - new Date(event.date).getTime());
  return Number.isFinite(delta) && delta <= 12 * 3600_000;
}

function extract1N2(event: OddsEvent, preferred: string[]) {
  const books = event.bookmakers || {};
  const names = [...preferred, ...Object.keys(books).filter(name => !preferred.includes(name))];
  for (const bookmaker of names) {
    const markets = books[bookmaker];
    if (!Array.isArray(markets)) continue;
    const market = markets.find(m => {
      const name = String(m?.name || "").toUpperCase();
      const label = String(m?.label || "").toUpperCase();
      return name === "ML" || name === "MONEYLINE" || label.includes("MATCH RESULT");
    });
    const odds = market?.odds?.[0];
    const home = Number(odds?.home), draw = Number(odds?.draw), away = Number(odds?.away);
    if ([home, draw, away].every(v => Number.isFinite(v) && v > 1)) {
      return { home, draw, away, bookmaker, updatedAt: market?.updatedAt || new Date().toISOString() };
    }
  }
  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json({ ok: true });
  if (req.method !== "POST") return json({ ok: false, error: "Méthode non autorisée." }, 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const oddsKey = Deno.env.get("ODDS_API_KEY");
    const bookmakers = String(Deno.env.get("ODDS_API_BOOKMAKERS") || "Bet365,Unibet")
      .split(",").map(v => v.trim()).filter(Boolean).slice(0, 2);
    if (!supabaseUrl || !serviceKey) throw new Error("Configuration Supabase incomplète.");
    if (!oddsKey) return json({ ok: false, code: "missing_odds_api_key", error: "Secret ODDS_API_KEY absent." }, 400);

    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) return json({ ok: false, error: "Authentification requise." }, 401);

    const admin = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: userData, error: userError } = await admin.auth.getUser(token);
    const user = userData?.user;
    if (userError || !user) return json({ ok: false, error: "Session invalide." }, 401);

    const { data: profile } = await admin.from("profiles").select("role,status").eq("id", user.id).maybeSingle();
    if (!profile || profile.status !== "active" || !["admin", "super_admin"].includes(profile.role)) {
      return json({ ok: false, error: "Réservé aux administrateurs." }, 403);
    }

    const payload = await req.json().catch(() => ({}));
    const seasonSlug = String(payload?.seasonSlug || "ucl-2026-27");
    const matchdayId = payload?.matchdayId ? String(payload.matchdayId) : null;

    const { data: season, error: seasonError } = await admin.from("seasons").select("id,slug").eq("slug", seasonSlug).maybeSingle();
    if (seasonError || !season) throw new Error(`Saison ${seasonSlug} introuvable.`);

    let query = admin.from("matches")
      .select("id,kickoff_at,status,home_club:clubs!matches_home_club_id_fkey(name,short_name,tla),away_club:clubs!matches_away_club_id_fkey(name,short_name,tla)")
      .eq("season_id", season.id)
      .in("status", ["scheduled", "postponed"])
      .order("kickoff_at");
    if (matchdayId) query = query.eq("matchday_id", matchdayId);
    const { data: rawMatches, error: matchesError } = await query;
    if (matchesError) throw matchesError;
    const matches = (rawMatches || []) as unknown as NidMatch[];
    if (!matches.length) return json({ ok: true, matched: 0, updated: 0, noOdds: 0, message: "Aucun match à venir dans ce périmètre." });

    const times = matches.map(m => new Date(m.kickoff_at).getTime()).filter(Number.isFinite);
    const from = new Date(Math.min(...times) - 12 * 3600_000).toISOString();
    const to = new Date(Math.max(...times) + 12 * 3600_000).toISOString();
    const params = new URLSearchParams({ apiKey: oddsKey, sport: "football", league: "uefa-champions-league", status: "pending,live", from, to, limit: "100" });
    const eventsResponse = await fetch(`https://api.odds-api.io/v3/events?${params.toString()}`);
    if (!eventsResponse.ok) {
      const body = await eventsResponse.text();
      throw new Error(`Odds-API.io ${eventsResponse.status}: ${body.slice(0, 220)}`);
    }
    const events = (await eventsResponse.json()) as OddsEvent[];

    const pairs: Array<{ match: NidMatch; event: OddsEvent }> = [];
    for (const match of matches) {
      const event = events.find(e => matchEvent(match, e));
      if (event) pairs.push({ match, event });
    }

    let updated = 0;
    let noOdds = 0;
    for (let offset = 0; offset < pairs.length; offset += 10) {
      const chunk = pairs.slice(offset, offset + 10);
      const eventIds = chunk.map(x => String(x.event.id)).join(",");
      const oddsParams = new URLSearchParams({ apiKey: oddsKey, eventIds, bookmakers: bookmakers.join(",") });
      const oddsResponse = await fetch(`https://api.odds-api.io/v3/odds/multi?${oddsParams.toString()}`);
      if (!oddsResponse.ok) {
        const body = await oddsResponse.text();
        throw new Error(`Odds-API.io ${oddsResponse.status}: ${body.slice(0, 220)}`);
      }
      const oddsEvents = (await oddsResponse.json()) as OddsEvent[];
      for (const pair of chunk) {
        const oddsEvent = oddsEvents.find(e => String(e.id) === String(pair.event.id));
        const odds = oddsEvent ? extract1N2(oddsEvent, bookmakers) : null;
        if (!odds) { noOdds++; continue; }
        const { error } = await admin.from("matches").update({
          odds_home: odds.home,
          odds_draw: odds.draw,
          odds_away: odds.away,
          odds_provider: "odds-api.io",
          odds_bookmaker: odds.bookmaker,
          odds_source_season: season.slug,
          odds_is_test_shifted: false,
          odds_updated_at: odds.updatedAt,
          updated_at: new Date().toISOString(),
        }).eq("id", pair.match.id);
        if (error) throw error;
        updated++;
      }
    }

    await admin.from("audit_logs").insert({
      actor_id: user.id,
      action: "odds_sync",
      entity_type: matchdayId ? "matchday" : "season",
      entity_id: matchdayId || season.slug,
      new_data: { provider: "odds-api.io", bookmakers, candidates: matches.length, matched: pairs.length, updated, noOdds },
    });

    return json({ ok: true, provider: "odds-api.io", bookmakers, candidates: matches.length, matched: pairs.length, updated, noOdds });
  } catch (error) {
    console.error(error);
    return json({ ok: false, error: error instanceof Error ? error.message : "Erreur inconnue." }, 500);
  }
});
