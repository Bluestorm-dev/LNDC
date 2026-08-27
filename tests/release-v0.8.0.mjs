import fs from "node:fs";
import path from "node:path";
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),"..");
const must=[
  "VERSION","config.js","index.html","sw.js","js/ucl.js","js/evenings.js","css/ucl.css","css/evenings.css","css/v080.css",
  "sql/HOTFIX_V0.8.0_EXISTING_DB.sql","sql/024_patch_v0.8.0_evenings_ucl_center.sql","sql/000_INSTALL_FRESH_V0.8.0.sql",
  "supabase/functions/sync-football-data/index.ts","installation/INSTALLATION_V0.8.0.txt","docs/TEST_CHECKLIST_V0.8.0.md"
];
for(const rel of must){if(!fs.existsSync(path.join(root,rel)))throw new Error(`Absent: ${rel}`);}
const read=rel=>fs.readFileSync(path.join(root,rel),"utf8");
if(read("VERSION").trim()!=="0.8.0")throw new Error("VERSION incorrecte");
if(!read("config.js").includes('APP_VERSION: "0.8.0"'))throw new Error("config version incorrecte");
const html=read("index.html");
for(const token of ['data-view="ucl"','data-view="evenings"','id="uclCenterRoot"','id="eveningHubRoot"','id="homeEveningCard"','js/ucl.js','js/evenings.js'])if(!html.includes(token))throw new Error(`UI V0.8.0 absente: ${token}`);
const evenings=read("js/evenings.js");
for(const token of ['eveningStatsHTML','eveningMomentsHTML','renderHomeEveningCard','Hibou de la nuit'])if(!evenings.includes(token))throw new Error(`Soirées V0.8.0 incomplètes: ${token}`);
const sql=read("sql/HOTFIX_V0.8.0_EXISTING_DB.sql");
for(const token of ['public.ucl_matches','public.ucl_standings','get_hibou_solitaire_events_v080','get_hibou_solitaire_leaderboard_v080','public.monthly_polls','cast_monthly_vote_v080'])if(!sql.includes(token))throw new Error(`SQL V0.8.0 incomplet: ${token}`);
const edge=read("supabase/functions/sync-football-data/index.ts");
for(const token of ['"center"','/standings?season=${sourceSeasonYear}','from("ucl_matches")','from("ucl_standings")','sourceSeasonYear = requestedSeasonYear'])if(!edge.includes(token))throw new Error(`Centre C1 incomplet: ${token}`);
if(edge.includes('sourceSeasonYear = 2025')||edge.includes('shiftTestDate'))throw new Error("Fallback/décalage d’ancienne saison détecté");
const sw=read("sw.js");
for(const token of ['nid-champions-v0.8.0','./js/ucl.js','./js/evenings.js','./css/ucl.css'])if(!sw.includes(token))throw new Error(`Cache PWA incomplet: ${token}`);
console.log("V0.8.0 release checks: OK");
