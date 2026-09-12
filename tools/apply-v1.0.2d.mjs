import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const read = p => fs.readFileSync(p, "utf8");
const write = (p,s) => { fs.writeFileSync(p,s,"utf8"); console.log("OK", path.relative(root,p)); };
const must = rel => { const p=path.join(root,rel); if(!fs.existsSync(p)) throw new Error(`Fichier introuvable: ${rel}`); return p; };

["index.html","js/app.js","js/release101.js","js/release102.js","js/release102c.js","js/release102d.js","css/release102d.css","sw.js","supabase/functions/sync-football-data/index.ts"].forEach(must);

// 1) index.html
{
  const p=must("index.html"); let s=read(p);
  if(!s.includes('css/release102d.css')){
    const a=s.includes('<link rel="stylesheet" href="css/release102a.css" />')?'<link rel="stylesheet" href="css/release102a.css" />':'<link rel="stylesheet" href="css/release102.css" />';
    s=s.replace(a,`${a}\n  <link rel="stylesheet" href="css/release102d.css" />`);
  }
  if(!s.includes('js/release102d.js')){
    const a=s.includes('<script src="js/release102c.js"></script>')?'<script src="js/release102c.js"></script>':'<script src="js/release102.js"></script>';
    s=s.replace(a,`${a}\n  <script src="js/release102d.js"></script>`);
  }
  write(p,s);
}

// 2) release101.js : dédoublonnage au cœur du renderer + un seul affichage des cartons
{
  const p=must("js/release101.js"); let s=read(p);
  const old=`  function scorerRowsV101(){return safe(state.uclScorersV101).filter(x=>Number(x.goals||0)>0||Number(x.assists||0)>0);}\n  function cardScoreV101(x){return Number(x.red_cards||0)*100+Number(x.yellow_red_cards||0)*20+Number(x.yellow_cards||0);}\n  function playerStatClubV101(row){return clubById(row.club_id);}`;
  const neu=`  function scorerRowsV101(){const rows=typeof window.uclDedupeRowsV102d==="function"?window.uclDedupeRowsV102d(state.uclScorersV101,"scorers"):safe(state.uclScorersV101);return rows.filter(x=>Number(x.goals||0)>0||Number(x.assists||0)>0);}\n  function disciplineRowsV102d(){return typeof window.uclDedupeRowsV102d==="function"?window.uclDedupeRowsV102d(state.uclDisciplineV101,"discipline"):safe(state.uclDisciplineV101);}\n  function cardScoreV101(x){return Number(x.red_cards||0)*100+Number(x.yellow_red_cards||0)*20+Number(x.yellow_cards||0);}\n  function disciplineLabelV102d(x){if(typeof window.uclDisciplineLabelV102d==="function")return window.uclDisciplineLabelV102d(x);const parts=[],y=Number(x.yellow_cards||0),yr=Number(x.yellow_red_cards||0),r=Number(x.red_cards||0);if(y>0)parts.push(y+" 🟨");if(yr>0)parts.push(yr+" 🟨🟥");if(r>0)parts.push(r+" 🟥");return parts.join(" · ")||"0";}\n  function playerStatClubV101(row){return clubById(row.club_id);}`;
  if(s.includes(old)) s=s.replace(old,neu);
  else if(!s.includes("function disciplineRowsV102d()")) throw new Error("release101: bloc helpers non reconnu");

  s=s.replace(
    `const scorers=scorerRowsV101().slice(0,30),cards=safe(state.uclDisciplineV101).filter(x=>cardScoreV101(x)>0).sort((a,b)=>cardScoreV101(b)-cardScoreV101(a)).slice(0,30);`,
    `const scorers=scorerRowsV101().slice(0,30),cards=disciplineRowsV102d().filter(x=>cardScoreV101(x)>0).sort((a,b)=>cardScoreV101(b)-cardScoreV101(a)).slice(0,30);`
  );

  const oldCard=`<button type="button" class="ucl-player-row-v101" \${c?\`data-ucl-club-v101="\${esc(c.id)}"\`:""}><span class="ucl-player-rank-v101">\${i+1}</span>\${c?crestHTML(c):'<span></span>'}<span><strong>\${esc(x.player_name)}</strong><small>\${esc(c?.short_name||c?.name||"")}</small></span><b class="cards-v101">\${Number(x.yellow_cards||0)} 🟨</b><small>\${Number(x.yellow_red_cards||0)} 🟨🟥 · \${Number(x.red_cards||0)} 🟥</small></button>`;
  const newCard=`<button type="button" class="ucl-player-row-v101 ucl-discipline-row-v102d" \${c?\`data-ucl-club-v101="\${esc(c.id)}"\`:""}><span class="ucl-player-rank-v101">\${i+1}</span>\${c?crestHTML(c):'<span></span>'}<span><strong>\${esc(x.player_name)}</strong><small>\${esc(c?.short_name||c?.name||"")}</small></span><b class="cards-v101">\${esc(disciplineLabelV102d(x))}</b></button>`;
  if(s.includes(oldCard)) s=s.replace(oldCard,newCard);
  else if(!s.includes("ucl-discipline-row-v102d")) throw new Error("release101: template cartons non reconnu");

  s=s.replace(
    `const cards=safe(state.uclDisciplineV101).filter(x=>String(x.club_id)===String(clubId));const totals=cards.reduce((a,x)=>({y:a.y+Number(x.yellow_cards||0),yr:a.yr+Number(x.yellow_red_cards||0),r:a.r+Number(x.red_cards||0)}),{y:0,yr:0,r:0});`,
    `const cards=disciplineRowsV102d().filter(x=>String(x.club_id)===String(clubId));const totals=cards.reduce((a,x)=>({y:a.y+Number(x.yellow_cards||0),yr:a.yr+Number(x.yellow_red_cards||0),r:a.r+Number(x.red_cards||0)}),{y:0,yr:0,r:0});`
  );
  write(p,s);
}

// 3) release102c.js : son ancien post-traitement ne doit plus doubler l'icône
{
  const p=must("js/release102c.js"); let s=read(p);
  s=s.replace(
`        let primary="";
        if(r>0) primary=\`\${r} 🟥\`;
        else if(yr>0) primary=\`\${yr} 🟨🟥\`;
        else primary=\`\${y} 🟨\`;
        if(main) main.textContent=primary;
        const all=[];`,
`        const all=[];`
  );
  s=s.replace(
`        if(detail) detail.textContent=all.join(" · ");
        button.title=all.join(" · ");`,
`        if(main) main.textContent=all.join(" · ")||"0";
        if(detail) detail.remove();
        button.title=all.join(" · ");`
  );
  write(p,s);
}

// 4) Admin C1 : utiliser les tableaux déjà dédoublonnés
{
  const p=must("js/release102.js"); let s=read(p);
  const old=`  function clubStatRowsV102(clubId){const s=new Map(),d=new Map();safe(state.uclScorersV101).filter(x=>String(x.club_id)===String(clubId)).forEach(x=>s.set(String(x.player_external_id),x));safe(state.uclDisciplineV101).filter(x=>String(x.club_id)===String(clubId)).forEach(x=>d.set(String(x.player_external_id),x));return [...new Set([...s.keys(),...d.keys()])].map(id=>({...s.get(id),...d.get(id),player_external_id:id})).sort((a,b)=>Number(b.goals||0)-Number(a.goals||0)||String(a.player_name||"").localeCompare(String(b.player_name||""),"fr"));}`;
  const neu=`  function clubStatRowsV102(clubId){const dedupe=typeof window.uclDedupeRowsV102d==="function"?window.uclDedupeRowsV102d:(rows=>safe(rows));const scorers=dedupe(state.uclScorersV101,"scorers").filter(x=>String(x.club_id)===String(clubId)),cards=dedupe(state.uclDisciplineV101,"discipline").filter(x=>String(x.club_id)===String(clubId));const key=x=>typeof window.uclPlayerKeyV102d==="function"?window.uclPlayerKeyV102d(x.player_name):String(x.player_name||"").toLowerCase().trim();const map=new Map();scorers.forEach(x=>map.set(key(x),{...x}));cards.forEach(x=>{const k=key(x),cur=map.get(k)||{};map.set(k,{...cur,...x,player_external_id:cur.player_external_id||x.player_external_id,player_name:cur.player_name||x.player_name,club_id:cur.club_id||x.club_id});});return [...map.values()].sort((a,b)=>Number(b.goals||0)-Number(a.goals||0)||String(a.player_name||"").localeCompare(String(b.player_name||""),"fr"));}`;
  if(s.includes(old)) s=s.replace(old,neu);
  write(p,s);
}

// 5) Edge function : dédoublonnage avant insertion pour éviter que ça revienne au prochain sync
{
  const p=must("supabase/functions/sync-football-data/index.ts"); let s=read(p);
  if(!s.includes("uniqueScorersV102d")){
    s=s.replace(
      `      const scorers = (scorersPayload?.scorers || []) as FDScorer[];`,
      `      const normalizePlayerNameV102d = (name: unknown) => String(name || "").normalize("NFD").replace(/[\\u0300-\\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim().replace(/\\s+/g, " ");\n      const scorers = (scorersPayload?.scorers || []) as FDScorer[];\n      const uniqueScorersV102d = new Map<string,FDScorer>();\n      for (const item of scorers) {\n        const key = normalizePlayerNameV102d(item?.player?.name) || String(item?.player?.id || "");\n        const prev = uniqueScorersV102d.get(key);\n        if (!prev || Number(item?.goals || 0) > Number(prev?.goals || 0) || (Number(item?.goals || 0) === Number(prev?.goals || 0) && Number(item?.playedMatches || 0) > Number(prev?.playedMatches || 0))) uniqueScorersV102d.set(key,item);\n      }`
    );
    s=s.replace(`        for (const item of scorers) {`,`        for (const item of uniqueScorersV102d.values()) {`);
  }
  if(!s.includes("uniqueDisciplineV102d")){
    s=s.replace(
      `        for (const [pid,item] of discipline) {`,
      `        const uniqueDisciplineV102d = new Map<string,{pid:number;item:{name:string;teamId:number|null;yellow:number;red:number;yellowRed:number}}>();\n        for (const [pid,item] of discipline) {\n          const key = normalizePlayerNameV102d(item.name) || String(pid);\n          const prev = uniqueDisciplineV102d.get(key);\n          if (!prev) uniqueDisciplineV102d.set(key,{pid,item:{...item}});\n          else {\n            prev.item.yellow = Math.max(prev.item.yellow,item.yellow);\n            prev.item.yellowRed = Math.max(prev.item.yellowRed,item.yellowRed);\n            prev.item.red = Math.max(prev.item.red,item.red);\n            prev.item.teamId = prev.item.teamId || item.teamId;\n            if (pid > 0 && prev.pid <= 0) prev.pid = pid;\n          }\n        }\n        for (const {pid,item} of uniqueDisciplineV102d.values()) {`
    );
  }
  write(p,s);
}

// 6) App hook + version + SW
{
  const p=must("js/app.js"); let s=read(p);
  if(!s.includes("renderRelease102d()")){
    const a=s.includes('if(typeof renderRelease102c==="function")renderRelease102c();')?'if(typeof renderRelease102c==="function")renderRelease102c();':'if(typeof renderRelease102==="function")renderRelease102();';
    s=s.replace(a,`${a} if(typeof renderRelease102d==="function")renderRelease102d();`);
  }
  write(p,s);
}
for(const name of ["config.js","config.example.js"]){
  const p=path.join(root,name); if(!fs.existsSync(p)) continue;
  write(p,read(p).replace(/APP_VERSION\s*:\s*["'][^"']+["']/,'APP_VERSION: "1.0.2d"'));
}
write(path.join(root,"VERSION"),"1.0.2d\n");
{
  const p=must("sw.js"); let s=read(p).replace(/^const CACHE = .*;$/m,'const CACHE = "nid-champions-v1.0.2d-ucl-dedupe";');
  if(!s.includes('./css/release102d.css')){
    if(s.includes('"./css/release102a.css"')) s=s.replace('"./css/release102a.css"','"./css/release102a.css","./css/release102d.css"');
    else s=s.replace('"./css/release102.css"','"./css/release102.css","./css/release102d.css"');
  }
  if(!s.includes('./js/release102d.js')){
    if(s.includes('"./js/release102c.js"')) s=s.replace('"./js/release102c.js"','"./js/release102c.js","./js/release102d.js"');
    else s=s.replace('"./js/release102.js"','"./js/release102.js","./js/release102d.js"');
  }
  write(p,s);
}

console.log("\nV1.0.2d appliquée.");
console.log("1. Supabase SQL: sql/HOTFIX_V1.0.2d_DEDUP_UCL_PLAYERS.sql");
console.log("2. npx supabase functions deploy sync-football-data");
console.log("3. node tests/test-v1.0.2d.mjs");
