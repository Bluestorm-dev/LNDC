import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(__dirname,"..");
const read=p=>fs.readFileSync(p,"utf8");
const write=(p,s)=>{fs.writeFileSync(p,s,"utf8");console.log("OK",path.relative(root,p));};
const must=p=>{if(!fs.existsSync(p))throw new Error(`Fichier introuvable: ${path.relative(root,p)}`);};

for(const rel of ["index.html","js/app.js","js/release101.js","js/release102.js","js/release102c.js","sw.js","supabase/functions/sync-football-data/index.ts"]){must(path.join(root,rel));}

// 1) Branche réellement les releases récentes dans index.html.
const indexPath=path.join(root,"index.html");
let html=read(indexPath);
if(fs.existsSync(path.join(root,"css/release102a.css"))&&!html.includes('css/release102a.css')){
  html=html.replace('<link rel="stylesheet" href="css/release102.css" />','<link rel="stylesheet" href="css/release102.css" />\n  <link rel="stylesheet" href="css/release102a.css" />');
}
if(fs.existsSync(path.join(root,"js/release102a.js"))&&!html.includes('js/release102a.js')){
  html=html.replace('<script src="js/release102.js"></script>','<script src="js/release102.js"></script>\n  <script src="js/release102a.js"></script>');
}
if(!html.includes('js/release102c.js')){
  const anchor=html.includes('<script src="js/release102a.js"></script>')?'<script src="js/release102a.js"></script>':'<script src="js/release102.js"></script>';
  html=html.replace(anchor,`${anchor}\n  <script src="js/release102c.js"></script>`);
}
write(indexPath,html);

// 2) Appelle explicitement les hooks de release au rendu global.
const appPath=path.join(root,"js/app.js");
let app=read(appPath);
if(!app.includes('renderRelease102a()') && fs.existsSync(path.join(root,"js/release102a.js"))){
  app=app.replace('if(typeof renderRelease102==="function")renderRelease102();','if(typeof renderRelease102==="function")renderRelease102(); if(typeof renderRelease102a==="function")renderRelease102a();');
}
if(!app.includes('renderRelease102c()')){
  const anchor=app.includes('if(typeof renderRelease102a==="function")renderRelease102a();')?'if(typeof renderRelease102a==="function")renderRelease102a();':'if(typeof renderRelease102==="function")renderRelease102();';
  app=app.replace(anchor,`${anchor} if(typeof renderRelease102c==="function")renderRelease102c();`);
}
write(appPath,app);

// 3) Corrige l'interprétation des valeurs de cartes Football-Data.
const edgePath=path.join(root,"supabase/functions/sync-football-data/index.ts");
let edge=read(edgePath);
const oldBlock=`            const card = String(booking?.card || "").toUpperCase();\n            if (card === "RED") current.red++;\n            else if (card === "YELLOW_RED") current.yellowRed++;\n            else if (card === "YELLOW") current.yellow++;\n            current.teamId = Number(booking?.team?.id || current.teamId || 0) || null;\n            discipline.set(pid,current); bookingCount++;`;
const newBlock=`            const card = String(booking?.card || "").trim().toUpperCase().replace(/[\\s-]+/g, "_");\n            let recognized = true;\n            if (["RED","RED_CARD"].includes(card)) current.red++;\n            else if (["YELLOW_RED","YELLOW_RED_CARD","SECOND_YELLOW","SECOND_YELLOW_CARD"].includes(card)) current.yellowRed++;\n            else if (["YELLOW","YELLOW_CARD"].includes(card)) current.yellow++;\n            else recognized = false;\n            current.teamId = Number(booking?.team?.id || current.teamId || 0) || null;\n            discipline.set(pid,current);\n            if (recognized) bookingCount++;`;
if(edge.includes(oldBlock)) edge=edge.replace(oldBlock,newBlock);
else if(!edge.includes('SECOND_YELLOW_CARD')) console.warn('ATTENTION: bloc cartons non reconnu automatiquement; vérifie sync-football-data/index.ts.');
write(edgePath,edge);

// 4) Version / cache PWA.
for(const name of ["config.js","config.example.js"]){
  const p=path.join(root,name);if(!fs.existsSync(p))continue;
  let s=read(p).replace(/APP_VERSION\s*:\s*["'][^"']+["']/,'APP_VERSION: "1.0.2c"');write(p,s);
}
write(path.join(root,"VERSION"),"1.0.2c\n");
const swPath=path.join(root,"sw.js");
let sw=read(swPath).replace(/^const CACHE = .*;$/m,'const CACHE = "nid-champions-v1.0.2c-player-stats";');
if(fs.existsSync(path.join(root,"css/release102a.css"))&&!sw.includes('./css/release102a.css')) sw=sw.replace('"./css/release102.css"','"./css/release102.css","./css/release102a.css"');
if(fs.existsSync(path.join(root,"js/release102a.js"))&&!sw.includes('./js/release102a.js')) sw=sw.replace('"./js/release102.js"','"./js/release102.js","./js/release102a.js"');
if(!sw.includes('./js/release102c.js')){
  if(sw.includes('"./js/release102a.js"')) sw=sw.replace('"./js/release102a.js"','"./js/release102a.js","./js/release102c.js"');
  else sw=sw.replace('"./js/release102.js"','"./js/release102.js","./js/release102c.js"');
}
write(swPath,sw);

console.log("\nV1.0.2c appliquée.");
console.log("1. Exécute sql/HOTFIX_V1.0.2c_PLAYER_STATS.sql dans Supabase.");
console.log("2. Redéploie: npx supabase functions deploy sync-football-data");
console.log("3. Lance: node tests/test-v1.0.2c.mjs");
