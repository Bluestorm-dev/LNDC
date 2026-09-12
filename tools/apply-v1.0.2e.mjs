import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const read = p => fs.readFileSync(p, "utf8");
const write = (p,s) => { fs.writeFileSync(p,s,"utf8"); console.log("OK", path.relative(root,p)); };
const must = rel => { const p=path.join(root,rel); if(!fs.existsSync(p)) throw new Error(`Fichier introuvable: ${rel}`); return p; };

["index.html","js/app.js","js/release101.js","js/release102d.js","js/release102e.js","sw.js"].forEach(must);

// 1. Charger le nouveau correctif après 1.0.2d.
{
  const p=must("index.html"); let s=read(p);
  if(!s.includes('js/release102e.js')){
    const anchor='<script src="js/release102d.js"></script>';
    if(!s.includes(anchor)) throw new Error("index.html: release102d.js introuvable");
    s=s.replace(anchor,`${anchor}\n  <script src="js/release102e.js"></script>`);
  }
  write(p,s);
}

// 2. Le renderer doit utiliser le résolveur de club 1.0.2e.
{
  const p=must("js/release101.js"); let s=read(p);
  const old='function playerStatClubV101(row){return clubById(row.club_id);}';
  const neu='function playerStatClubV101(row){return typeof window.uclResolvePlayerClubV102e==="function"?window.uclResolvePlayerClubV102e(row):clubById(row.club_id);}';
  if(s.includes(old)) s=s.replace(old,neu);
  else if(!s.includes('uclResolvePlayerClubV102e')) throw new Error("release101.js: fonction playerStatClubV101 non reconnue");
  write(p,s);
}

// 3. Hook général de rendu.
{
  const p=must("js/app.js"); let s=read(p);
  if(!s.includes("renderRelease102e()")){
    const anchor='if(typeof renderRelease102d==="function")renderRelease102d();';
    if(!s.includes(anchor)) throw new Error("app.js: hook release102d introuvable");
    s=s.replace(anchor,`${anchor} if(typeof renderRelease102e==="function")renderRelease102e();`);
  }
  write(p,s);
}

// 4. Version.
for(const name of ["config.js","config.example.js"]){
  const p=path.join(root,name); if(!fs.existsSync(p)) continue;
  write(p,read(p).replace(/APP_VERSION\s*:\s*["'][^"']+["']/,'APP_VERSION: "1.0.2e"'));
}
write(path.join(root,"VERSION"),"1.0.2e\n");

// 5. Nouveau cache PWA + fichier 102e précaché.
{
  const p=must("sw.js"); let s=read(p);
  s=s.replace(/^const CACHE = .*;$/m,'const CACHE = "nid-champions-v1.0.2e-ucl-club-repair";');
  if(!s.includes('./js/release102e.js')){
    if(!s.includes('"./js/release102d.js"')) throw new Error("sw.js: release102d.js introuvable dans CORE");
    s=s.replace('"./js/release102d.js"','"./js/release102d.js","./js/release102e.js"');
  }
  write(p,s);
}

console.log("\nV1.0.2e appliquée.");
console.log("1. Supabase SQL : sql/HOTFIX_V1.0.2e_REPAIR_UCL_CLUBS.sql");
console.log("2. node tests/test-v1.0.2e.mjs");
console.log("3. git add . && git commit && git push origin main");
