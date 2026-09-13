import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
function findRepoRoot(start){
  let cur=path.resolve(start);
  for(let i=0;i<5;i++){
    if(fs.existsSync(path.join(cur,"index.html")) && fs.existsSync(path.join(cur,"js","core.js")) && fs.existsSync(path.join(cur,"assets","icons","runtime"))) return cur;
    const up=path.dirname(cur); if(up===cur) break; cur=up;
  }
  return null;
}
const root = findRepoRoot(__dirname);
if(!root){
  console.error("ERREUR: dépôt LNDC introuvable. Décompresse le patch dans le dépôt LNDC puis relance.");
  process.exit(1);
}
const exists = p => fs.existsSync(path.join(root,p));
const read = p => fs.readFileSync(path.join(root,p),"utf8");
const write = (p,s) => fs.writeFileSync(path.join(root,p),s,"utf8");
const rm = p => fs.rmSync(path.join(root,p),{recursive:true,force:true});

console.log("Le Nid des Champions — nettoyage V1.0.2g");
console.log("Dépôt détecté :",root,"\n");

// 1) Anciennes bibliothèques d'icônes remplacées par assets/icons/runtime.
for(const p of ["assets/icons/app","assets/icons/ui","assets/icons/football","assets/icons/icon-catalog.json","ICON_PACK_2026-08.txt"]){
  if(exists(p)){ rm(p); console.log("SUPPRIME",p); }
}

// 2) Alias d'icônes racine historiques. On conserve uniquement les 4 icônes PWA.
const iconDir=path.join(root,"assets/icons");
const keep=new Set(["icon-192.png","icon-512.png","icon-maskable-192.png","icon-maskable-512.png"]);
for(const name of fs.readdirSync(iconDir)){
  if(/^icon-.*\.png$/i.test(name) && !keep.has(name)){
    fs.rmSync(path.join(iconDir,name),{force:true});
    console.log("SUPPRIME assets/icons/"+name);
  }
}

// 3) Planches sources lourdes : jamais chargées par l'application.
for(const p of ["assets/avatars/source-sheets","assets/badges/source-sheets","assets/source-sheets"]){
  if(exists(p)){ rm(p); console.log("SUPPRIME",p); }
}

// 4) Backups de développement historiques (*.bak), dont d'anciens config.js.
function removeBak(dir){
  for(const ent of fs.readdirSync(dir,{withFileTypes:true})){
    const full=path.join(dir,ent.name);
    if(ent.isDirectory() && ent.name!==".git") removeBak(full);
    else if(ent.isFile() && ent.name.endsWith(".bak")){
      fs.rmSync(full,{force:true});
      console.log("SUPPRIME",path.relative(root,full));
    }
  }
}
removeBak(root);

// 5) Ukraine + Shakhtar : mapping global et filet de sécurité si la DB est vide/ancienne.
{
  let s=read("js/core.js");
  if(!s.includes('Ukraine:["Ukraine","ua"]')){
    const a='    Kazakhstan:["Kazakhstan","kz"]\n  };';
    const b='    Kazakhstan:["Kazakhstan","kz"],\n    Ukraine:["Ukraine","ua"]\n  };';
    if(!s.includes(a)) throw new Error("Ancre COUNTRY_DISPLAY introuvable dans js/core.js");
    s=s.replace(a,b);
  }
  if(!s.includes('identity.includes("shakhtar")')){
    const a='    if (identity.includes("monaco")) return {name:"France",code:"fr"};';
    const b='    if (identity.includes("monaco")) return {name:"France",code:"fr"};\n    // Le Shakhtar Donetsk est ukrainien : force le drapeau même si une ancienne donnée Supabase a laissé le pays vide.\n    if (identity.includes("shakhtar") || identity.includes("chakhtar")) return {name:"Ukraine",code:"ua"};';
    if(!s.includes(a)) throw new Error("Ancre clubCountry introuvable dans js/core.js");
    s=s.replace(a,b);
  }
  write("js/core.js",s);
}

// 6) assets-manifest : retire les références aux sources supprimées.
{
  const p="assets/assets-manifest.json";
  const data=JSON.parse(read(p));
  data.version="1.0.2g";
  if(data.avatars && typeof data.avatars==="object") delete data.avatars.source_sheets;
  delete data.icon_pack_2026_08;
  data.repository_cleanup={
    version:"1.0.2g",
    runtime_only_assets:true,
    removed:["legacy icon packs","raw source sheets","*.bak backups"]
  };
  write(p,JSON.stringify(data,null,2)+"\n");
}

// 7) Version + cache PWA.
write("VERSION","1.0.2g\n");
for(const p of ["config.js","config.example.js"]){
  if(exists(p)){
    let s=read(p);
    s=s.replace(/APP_VERSION\s*:\s*"[^"]+"/, 'APP_VERSION: "1.0.2g"');
    write(p,s);
  }
}
{
  let s=read("sw.js");
  s=s.replace(/const CACHE = "[^"]+";/,'const CACHE = "nid-champions-v1.0.2g-clean-assets-ukraine";');
  write("sw.js",s);
}
{
  let s=read("index.html");
  s=s.replaceAll("V1.0.2b","V1.0.2g").replaceAll("1.0.2b","1.0.2g");
  write("index.html",s);
}

console.log("\nOK — nettoyage V1.0.2g appliqué.");
console.log("Conservé : assets/icons/runtime + les 4 icônes PWA + avatars/badges réellement utilisés.");
console.log("Étape suivante : exécuter sql/HOTFIX_V1.0.2g_SHAKHTAR_UKRAINE.sql dans Supabase, puis le test V1.0.2g.");
