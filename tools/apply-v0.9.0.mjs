import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const toolDir = path.dirname(__filename);
const root = path.resolve(toolDir, "..");
const patchDir = path.join(root, "PATCH_FILES");

const read = p => fs.readFileSync(p, "utf8");
const copyFile = (src, dest) => {
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  if (fs.existsSync(dest)) {
    const backup = `${dest}.v081.bak`;
    if (!fs.existsSync(backup)) fs.copyFileSync(dest, backup);
  }
  fs.copyFileSync(src, dest);
};
const walk = dir => fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
  const full = path.join(dir, entry.name);
  return entry.isDirectory() ? walk(full) : [full];
});

const versionFile = path.join(root, "VERSION");
if (!fs.existsSync(versionFile)) {
  console.error("ERREUR: VERSION introuvable. Lance ce script depuis la racine du Nid après avoir extrait le patch.");
  process.exit(1);
}
const current = read(versionFile).trim();
if (current !== "0.8.1" && current !== "0.9.0") {
  console.error(`ERREUR: ce patch attend V0.8.1 (version détectée: ${current || "inconnue"}).`);
  process.exit(1);
}
if (!fs.existsSync(patchDir)) {
  console.error("ERREUR: dossier PATCH_FILES introuvable. Extrais tout le ZIP du patch à la racine de l'application.");
  process.exit(1);
}

const files = walk(patchDir);
for (const src of files) {
  const rel = path.relative(patchDir, src);
  if (rel.toLowerCase() === "config.js") continue;
  copyFile(src, path.join(root, rel));
}

// config.js contient la configuration propre au déploiement : on conserve tout et on ne modifie que la version.
const configPath = path.join(root, "config.js");
if (fs.existsSync(configPath)) {
  const backup = `${configPath}.v081.bak`;
  if (!fs.existsSync(backup)) fs.copyFileSync(configPath, backup);
  let config = read(configPath);
  if (/APP_VERSION\s*:\s*["'][^"']+["']/.test(config)) {
    config = config.replace(/APP_VERSION\s*:\s*["'][^"']+["']/, 'APP_VERSION: "0.9.0"');
  } else {
    console.error("ERREUR: APP_VERSION introuvable dans config.js. Le fichier n'a pas été modifié.");
    process.exit(1);
  }
  fs.writeFileSync(configPath, config, "utf8");
}

console.log("✅ Patch V0.8.1 → V0.9.0 appliqué.");
console.log("1) Exécute sql/HOTFIX_V0.9.0_EXISTING_DB.sql dans Supabase.");
console.log("2) Lance: node tests\\run-all-v0.9.0.mjs");
console.log("3) Déploie le frontend puis lance le road-check manuel V0.9.0.");
console.log("Aucun redéploiement Edge Function n'est requis depuis une V0.8.1 fonctionnelle.");
