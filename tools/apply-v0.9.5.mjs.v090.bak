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
    const backup=`${dest}.v090.bak`;
    if(!fs.existsSync(backup))fs.copyFileSync(dest,backup);
  }
  fs.copyFileSync(src,dest);
}

const versionFile=path.join(root,"VERSION");
if(!fs.existsSync(versionFile)){
  console.error("ERREUR: VERSION introuvable. Extrais le patch à la racine de l'application.");
  process.exit(1);
}
const current=read(versionFile).trim();
if(!["0.9.0","0.9.5"].includes(current)){
  console.error(`ERREUR: ce patch attend V0.9.0 (version détectée: ${current||"inconnue"}).`);
  process.exit(1);
}
if(!fs.existsSync(patchDir)){
  console.error("ERREUR: dossier PATCH_FILES introuvable. Extrais tout le ZIP du patch à la racine du Nid.");
  process.exit(1);
}

for(const src of walk(patchDir)){
  const rel=path.relative(patchDir,src);
  if(rel.toLowerCase()==="config.js")continue;
  copyWithBackup(src,path.join(root,rel));
}

// config.js appartient au déploiement : on garde URL / clé publique / options et on change uniquement la version.
const configPath=path.join(root,"config.js");
if(!fs.existsSync(configPath)){
  console.error("ERREUR: config.js introuvable. Aucun secret/configuration n'a été recréé automatiquement.");
  process.exit(1);
}
const backup=`${configPath}.v090.bak`;
if(!fs.existsSync(backup))fs.copyFileSync(configPath,backup);
let config=read(configPath);
if(!/APP_VERSION\s*:\s*["'][^"']+["']/.test(config)){
  console.error("ERREUR: APP_VERSION introuvable dans config.js. Le fichier n'a pas été modifié.");
  process.exit(1);
}
config=config.replace(/APP_VERSION\s*:\s*["'][^"']+["']/,'APP_VERSION: "0.9.5"');
fs.writeFileSync(configPath,config,"utf8");

console.log("✅ Patch V0.9.0 → V0.9.5 appliqué.");
console.log("1) Exécute sql/HOTFIX_V0.9.5_EXISTING_DB.sql dans Supabase.");
console.log("2) Lance: node tests\\run-all-v0.9.5.mjs");
console.log("3) Déploie le frontend puis contrôle aussi avec --url=https://TON-SITE");
console.log("Aucun redéploiement de sync-football-data n'est requis depuis une V0.9.0 fonctionnelle.");
console.log("Le grand road-check manuel cumulatif reste prévu pour la V0.9.9.");
