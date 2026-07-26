import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const exists=p=>fs.existsSync(path.join(root,p));

assert.equal(read('VERSION').trim(),'0.5.4');
assert.match(read('config.example.js'),/APP_VERSION:\s*"0\.5\.4"/);
assert.match(read('config.js'),/APP_VERSION:\s*"0\.5\.4"/);
assert.equal(JSON.parse(read('assets/assets-manifest.json')).version,'0.5.4');

const js=['core.js','avatars.js','teams.js','auth.js','data.js','champions.js','profile.js','predictions.js','ranking.js','admin.js','realtime.js','app.js'];
const css=['base.css','predictions.css','ranking.css','clubs.css','champions.css','layout.css','teams.css','avatars.css'];
for(const f of js) assert.ok(exists(`js/${f}`),`js/${f} absent`);
for(const f of css) assert.ok(exists(`css/${f}`),`css/${f} absent`);
assert.ok(!exists('assets/js/app.js'),'ancien assets/js/app.js encore présent');
assert.ok(!exists('assets/css/app.css'),'ancien assets/css/app.css encore présent');

const html=read('index.html');
for(const f of js) assert.match(html,new RegExp(`js/${f.replace('.','\\.')}`));
for(const f of css) assert.match(html,new RegExp(`css/${f.replace('.','\\.')}`));
assert.ok(html.indexOf('js/realtime.js') < html.indexOf('js/app.js'),'app.js doit être chargé après realtime.js');
assert.doesNotMatch(html,/assets\/(?:js|css)\//);

const sw=read('sw.js');
assert.match(sw,/nid-champions-v0\.5\.4/);
for(const f of js) assert.match(sw,new RegExp(`\\./js/${f.replace('.','\\.')}`));
for(const f of css) assert.match(sw,new RegExp(`\\./css/${f.replace('.','\\.')}`));

const installs=fs.readdirSync(path.join(root,'installation')).filter(n=>/^INSTALLATION_V.*\.txt$/i.test(n));
assert.ok(installs.length>=16,'notices installation manquantes');
assert.ok(exists('installation/INSTALLATION_V0.5.4.txt'));
assert.ok(exists('docs/TEST_CHECKLIST_V0.5.4.md'));


// Les scripts classiques partagent volontairement le même environnement global.
// Ce test reproduit ce comportement et vérifie que le découpage n'a pas cassé les dépendances croisées.
const store=new Map();
const context=vm.createContext({
  console,
  window:{NIDC_CONFIG:{SUPABASE_URL:'https://YOUR_PROJECT.supabase.co',SUPABASE_ANON_KEY:'YOUR_SUPABASE_ANON_KEY',DEMO_WHEN_UNCONFIGURED:true}},
  localStorage:{getItem:k=>store.has(k)?store.get(k):null,setItem:(k,v)=>store.set(k,String(v)),removeItem:k=>store.delete(k)},
  document:{querySelector(){return null;},querySelectorAll(){return[];}},
  navigator:{}, Intl, Date, Map, Set, URL, Blob, setTimeout, clearTimeout,
  confirm:()=>true, prompt:()=>null
});
for(const f of js){
  let code=read(`js/${f}`);
  if(f==='app.js') code=code.replace(/boot\(\)\.catch[\s\S]*$/m,'');
  new vm.Script(code,{filename:f}).runInContext(context);
}
const smoke=new vm.Script(`
  state.user={id:'demo-parkaf'};
  state.profile=state.demoUsers[0];
  demoInit();
  loadDemoChampionState();
  ensureDemoTeams();
  ({matches:state.allMatches.length,avatars:OFFICIAL_AVATARS.length,teamShapes:TEAM_SHAPES.length,koPhases:KO_PHASES.length,avatarOk:avatarHTML(state.profile).includes('player-avatar-core'),bootOk:typeof boot==='function',adminOk:typeof renderAdmin==='function'});
`).runInContext(context);
assert.deepEqual({...smoke},{matches:8,avatars:90,teamShapes:12,koPhases:5,avatarOk:true,bootOk:true,adminOk:true});

console.log('V0.5.4 release tests: OK');
