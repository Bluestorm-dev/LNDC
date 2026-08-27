import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename=fileURLToPath(import.meta.url);
const toolDir=path.dirname(__filename);
const root=path.resolve(toolDir,"..");
const patchDir=path.join(root,"PATCH_FILES");
const read=p=>fs.readFileSync(p,"utf8");

function walk(dir){
  return fs.readdirSync(dir,{withFileTypes:true}).flatMap(entry=>{
    const full=path.join(dir,entry.name);
    return entry.isDirectory()?walk(full):[full];
  });
}
function copyWithBackup(src,dest){
  fs.mkdirSync(path.dirname(dest),{recursive:true});
  if(fs.existsSync(dest)){
    const backup=`${dest}.v095.bak`;
    if(!fs.existsSync(backup))fs.copyFileSync(dest,backup);
  }
  fs.copyFileSync(src,dest);
}

const versionFile=path.join(root,"VERSION");
if(!fs.existsSync(versionFile)){
  console.error("ERREUR: VERSION introuvable. Décompresse le patch à la racine de l'application.");
  process.exit(1);
}
const current=read(versionFile).trim();
if(!["0.9.5","0.9.8"].includes(current)){
  console.error(`ERREUR: ce patch attend V0.9.5 (version détectée: ${current||"inconnue"}).`);
  process.exit(1);
}
if(!fs.existsSync(patchDir)){
  console.error("ERREUR: PATCH_FILES introuvable. Décompresse TOUT le ZIP du patch à la racine du Nid.");
  process.exit(1);
}

console.log("🦉 Le Nid des Champions — mise à jour V0.9.5 → V0.9.8");
console.log("Le script va :");
console.log("- sauvegarder chaque fichier remplacé en .v095.bak ;");
console.log("- copier les nouveaux fichiers PDF / fin de saison ;");
console.log("- conserver ton URL et ta clé publique Supabase ;");
console.log("- changer uniquement APP_VERSION dans config.js.");
console.log("");

let copied=0;
for(const src of walk(patchDir)){
  const rel=path.relative(patchDir,src);
  if(rel.toLowerCase()==="config.js")continue;
  copyWithBackup(src,path.join(root,rel));copied++;
}

const configPath=path.join(root,"config.js");
if(!fs.existsSync(configPath)){
  console.error("ERREUR: config.js introuvable. La configuration Supabase n'a pas été recréée.");
  process.exit(1);
}
const backup=`${configPath}.v095.bak`;
if(!fs.existsSync(backup))fs.copyFileSync(configPath,backup);
let config=read(configPath);
if(!/APP_VERSION\s*:\s*["'][^"']+["']/.test(config)){
  console.error("ERREUR: APP_VERSION introuvable dans config.js. Le fichier n'a pas été modifié.");
  process.exit(1);
}
config=config.replace(/APP_VERSION\s*:\s*["'][^"']+["']/,'APP_VERSION: "0.9.8"');
fs.writeFileSync(configPath,config,"utf8");

console.log(`✅ ${copied} fichier(s) de patch appliqué(s).`);
console.log("✅ config.js conservé ; APP_VERSION = 0.9.8.");
console.log("");
console.log("Étapes restantes :");
console.log("1) Supabase SQL Editor : sql/HOTFIX_V0.9.8_EXISTING_DB.sql");
console.log("2) Test local : node tests\\run-all-v0.9.8.mjs");
console.log("3) Déploie le frontend sur GitHub Pages");
console.log("4) Test distant : node tests\\run-all-v0.9.8.mjs --url=https://bluestorm-dev.github.io/LNDC/");
console.log("Aucune Edge Function à redéployer pour cette version.");
console.log("Le grand road-check manuel complet reste prévu pour V0.9.9.");
