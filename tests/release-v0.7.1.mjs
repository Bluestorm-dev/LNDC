import fs from "node:fs";
import path from "node:path";
const root=path.resolve(path.dirname(new URL(import.meta.url).pathname),"..");
const must=[
  "VERSION","config.js","index.html","sw.js","js/data.js","js/realtime.js","js/ranking.js","js/teams.js","css/teams.css",
  "sql/HOTFIX_V0.7.1_EXISTING_DB.sql","installation/INSTALLATION_V0.7.1.txt"
];
for(const rel of must){if(!fs.existsSync(path.join(root,rel)))throw new Error(`Absent: ${rel}`);}
const read=rel=>fs.readFileSync(path.join(root,rel),"utf8");
if(read("VERSION").trim()!=="0.7.1")throw new Error("VERSION incorrecte");
if(!read("config.js").includes('APP_VERSION: "0.7.1"'))throw new Error("config version incorrecte");
if(read("css/teams.css").includes('.team-badge-visual.color-only:after{content:""'))throw new Error("Ancien carré Team encore actif");
if(!read("css/teams.css").includes('content:none!important'))throw new Error("Neutralisation du carré absente");
if(!read("js/data.js").includes("get_test_leaderboard_v071"))throw new Error("RPC test V071 absent");
if(!read("js/realtime.js").includes("4000"))throw new Error("Secours LIVE 4 s absent");
if(!read("index.html").includes("openTestLiveRanking"))throw new Error("Bouton LIVE TEST absent");
console.log("V0.7.1 release checks: OK");
