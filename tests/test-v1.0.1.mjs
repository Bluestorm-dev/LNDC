import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = p => fs.readFileSync(path.join(root,p), "utf8");
let pass=0,fail=0;
const check=(name,ok,detail="")=>{console.log(`${ok?"PASS":"FAIL"} ${name}${detail?` — ${detail}`:""}`);ok?pass++:fail++;};

const index=read("index.html");
const rel=read("js/release101.js");
const css=read("css/release101.css");
const realtime=read("js/realtime.js");
const sync=read("supabase/functions/sync-football-data/index.ts");
const sql=read("sql/HOTFIX_V1.0.1_EXISTING_DB.sql");
const data=read("js/data.js");
const sw=read("sw.js");

check("version.file", read("VERSION").trim()==="1.0.1");
check("version.config", read("config.js").includes('APP_VERSION: "1.0.1"'));
check("version.cache", sw.includes("nid-champions-v1.0.1"));
check("release.wired", index.includes("css/release101.css") && index.includes("js/release101.js"));
check("release.cached", sw.includes("release101.css") && sw.includes("release101.js"));
check("cache.avatar-path", sw.includes("./assets/avatars/nid/humour/personnages/avatar-hibou-humour-personnages-chanceux.png"));
check("tests.windows-path-safe", read("tests/test-v1.0.0.mjs").includes("fileURLToPath") && import.meta.url.startsWith("file:"));

check("ucl.realtime-overlay", realtime.includes("syncUclLiveFromMatchesV101") && rel.includes("liveUclStandingsV101"));
check("ucl.live-render", realtime.includes('renderUclCenter()') && rel.includes("classement provisoire"));
check("ucl.scorers-tab", rel.includes("Classement des buteurs") && rel.includes("Buteurs & cartons"));
check("ucl.cards-tab", rel.includes("Discipline") && rel.includes("yellow_red_cards"));
check("provider.scorers", sync.includes('/scorers?season=${sourceSeasonYear}&limit=100') && sync.includes('ucl_player_stats'));
check("provider.bookings", sync.includes('X-Unfold-Bookings') && sync.includes('ucl_discipline_stats'));
check("provider.rich-clubs", sync.includes("coach_name") && sync.includes("provider_details_updated_at") && data.includes("coach_name") && data.includes("squad"));
check("provider.rich-details-preserved", sync.includes("hasRichTeamDetails") && sync.includes("On n'écrase donc jamais les détails riches"));

check("club.rich-modal", rel.includes("Fiche club · Ligue des champions") && rel.includes("Composition & joueurs") && rel.includes("Historique C1 dans le Nid") && rel.includes("Meilleur buteur C1"));
check("club.details", rel.includes("Entraîneur") && rel.includes("Couleurs") && rel.includes("Fondé") && rel.includes("club.address"));
check("club.old-handlers-overridden", rel.includes("window.openClubSheetV0913=openClubSheetV101") && rel.includes("baseRenderMatchPanelsV101"));

check("ticker.flash", rel.includes("live-flash-track-v101") && css.includes("flashTickerV101") && rel.includes("data-flash-match-v101"));
check("carousel.team-theme", rel.includes("applyTeamCarouselV101") && rel.includes("teamVisualVars") && css.includes("team-carousel-v101"));
check("carousel.transition", css.includes("transition:opacity .52s") && rel.includes("active-auto-v0912"));

check("movement.zero-streak", rel.includes("Série de zéro") && sql.includes("zero_streak"));
check("movement.casserole-genius", rel.includes("pts casserole") && rel.includes("pts génie") && sql.includes("casserole_points") && sql.includes("genius_points"));
check("movement.records", rel.includes("Record du Nid") && rel.includes("gamificationRecords"));
check("player.form-readable", rel.includes("Ce que signifient les 5 derniers résultats") && rel.includes("Bon résultat") && rel.includes("Bon écart"));

check("ranking.live-delta", rel.includes("ranking-live-delta-v101") && rel.includes("official_points") && rel.includes("LIVE</em>"));
check("ranking.bottom-clean", css.includes("ranking-row-v101") && css.includes("collective-card") && css.includes("z-index:5"));

check("rivals.db-trigger", sql.includes("matches_refresh_rivals_v101") && sql.includes("refresh_rival_duels_v060"));
check("rivals.realtime-refresh", realtime.includes("maybeRefreshRivalsAfterMatchV101") && rel.includes("loadRivalData"));
check("predictions.auto-next-day", rel.includes('if(name==="matches")') && rel.includes("selectMatchday(next.id)"));

check("sql.player-stats", sql.includes("create table if not exists public.ucl_player_stats"));
check("sql.discipline-stats", sql.includes("create table if not exists public.ucl_discipline_stats"));
check("sql.movement-rpc", sql.includes("get_nid_movement_v101"));
check("sql.version", sql.includes("'app_version','\"1.0.1\"'::jsonb"));

// Parse every browser JS file with Node's syntax checker. Browser globals do not execute.
const jsFiles=[];
const walk=dir=>{for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory())walk(p);else if(e.isFile()&&e.name.endsWith(".js"))jsFiles.push(p);}};
walk(path.join(root,"js"));
let syntaxOk=true,syntaxDetail="";
for(const f of jsFiles){const r=spawnSync(process.execPath,["--check",f],{encoding:"utf8"});if(r.status!==0){syntaxOk=false;syntaxDetail=`${path.relative(root,f)}: ${(r.stderr||r.stdout||"").trim().split("\n")[0]}`;break;}}
check("javascript.syntax-all",syntaxOk,syntaxDetail||`${jsFiles.length} fichiers`);

console.log(`\nRésumé V1.0.1: ${pass} PASS · ${fail} FAIL`);
process.exitCode=fail?1:0;
