import fs from "node:fs";
import path from "node:path";
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),"..");
const must=[
  "VERSION","config.js","index.html","sw.js","js/admin.js","js/admin-test.js",
  "supabase/functions/sync-football-data/index.ts",
  "sql/HOTFIX_V0.7.2_EXISTING_DB.sql","installation/INSTALLATION_V0.7.2.txt"
];
for(const rel of must){if(!fs.existsSync(path.join(root,rel)))throw new Error(`Absent: ${rel}`);}
const read=rel=>fs.readFileSync(path.join(root,rel),"utf8");
if(read("VERSION").trim()!=="0.7.2")throw new Error("VERSION incorrecte");
if(!read("config.js").includes('APP_VERSION: "0.7.2"'))throw new Error("config version incorrecte");
const edge=read("supabase/functions/sync-football-data/index.ts");
if(edge.includes("TEST_SOURCE_SEASON_YEAR")||edge.includes("shiftTestDate"))throw new Error("Ancien décalage 2025/26 encore actif");
if(!edge.includes("sourceSeasonYear = requestedSeasonYear"))throw new Error("Saison réelle non utilisée");
if(!edge.includes("odds_is_test_shifted: false"))throw new Error("Cotes encore marquées décalées");
const sql=read("sql/HOTFIX_V0.7.2_EXISTING_DB.sql");
if(!sql.includes("delete from public.knockout_ties where season_id=p_season_id"))throw new Error("Nettoyage phase finale absent");
if(!read("js/admin-test.js").includes("ties_deleted"))throw new Error("Compteur confrontations absent");
console.log("V0.7.2 release checks: OK");
