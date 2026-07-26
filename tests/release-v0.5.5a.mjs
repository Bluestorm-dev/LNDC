import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const exists=p=>fs.existsSync(path.join(root,p));

assert.equal(read('VERSION').trim(),'0.5.5a');
assert.match(read('config.example.js'),/APP_VERSION:\s*"0\.5\.5a"/);
assert.match(read('config.js'),/APP_VERSION:\s*"0\.5\.5a"/);
assert.equal(JSON.parse(read('assets/assets-manifest.json')).version,'0.5.5a');

const js=['core.js','avatars.js','teams.js','auth.js','data.js','champions.js','profile.js','predictions.js','ranking.js','admin.js','realtime.js','app.js'];
const css=['base.css','predictions.css','ranking.css','clubs.css','champions.css','layout.css','teams.css','avatars.css'];
for(const f of js) assert.ok(exists(`js/${f}`),`js/${f} absent`);
for(const f of css) assert.ok(exists(`css/${f}`),`css/${f} absent`);

const html=read('index.html');
for(const f of js) assert.match(html,new RegExp(`js/${f.replace('.','\\.')}`));
for(const f of css) assert.match(html,new RegExp(`css/${f.replace('.','\\.')}`));
assert.match(html,/V0\.5\.5a/);
assert.doesNotMatch(html,/0\.5\.5aa/);

const sw=read('sw.js');
assert.match(sw,/nid-champions-v0\.5\.5a/);
for(const f of js) assert.match(sw,new RegExp(`\\./js/${f.replace('.','\\.')}`));
for(const f of css) assert.match(sw,new RegExp(`\\./css/${f.replace('.','\\.')}`));

assert.ok(exists('installation/INSTALLATION_V0.5.5a.txt'));
assert.ok(exists('docs/TEST_CHECKLIST_V0.5.5a.md'));
assert.ok(exists('sql/HOTFIX_V0.5.5a_EXISTING_DB.sql'));
assert.ok(exists('sql/014_patch_v0.5.5a_team_vacancy_moderation.sql'));
assert.ok(exists('sql/000_INSTALL_FRESH_V0.5.5a.sql'));

const teamsJs=read('js/teams.js');
const teamsCss=read('css/teams.css');
const sql=read('sql/HOTFIX_V0.5.5a_EXISTING_DB.sql');
assert.match(teamsJs,/Reprendre la Team/);
assert.match(teamsJs,/Anciennes Teams/);
assert.match(teamsJs,/team_vacated/);
assert.match(teamsJs,/team_reactivated/);
assert.match(teamsJs,/superAdminDeleteTeam/);
assert.match(teamsJs,/Tape SUPPRIMER/);
assert.match(teamsJs,/state\.profile\?\.role!=="super_admin"/);
assert.match(teamsCss,/team-preview-mini-card:before[^}]*opacity:\.34/);
assert.match(teamsCss,/team-preview-mini-card:after/);
assert.match(teamsCss,/team-directory-card\.vacant/);
assert.match(sql,/alter column captain_user_id drop not null/);
assert.match(sql,/create or replace function public\.reclaim_team_v055a/);
assert.match(sql,/create or replace function public\.super_admin_delete_team_v055a/);
assert.match(sql,/public\.is_super_admin\(\)/);
assert.match(sql,/team_hard_delete/);
assert.match(sql,/team_vacated/);
assert.match(sql,/left join public\.profiles cap/);

// Les scripts classiques doivent toujours partager le même contexte global.
const store=new Map();
const sink={appendChild(){},classList:{add(){},remove(){},toggle(){}},remove(){}};
const context=vm.createContext({
  console,
  window:{NIDC_CONFIG:{SUPABASE_URL:'https://YOUR_PROJECT.supabase.co',SUPABASE_ANON_KEY:'YOUR_SUPABASE_ANON_KEY',DEMO_WHEN_UNCONFIGURED:true}},
  localStorage:{getItem:k=>store.has(k)?store.get(k):null,setItem:(k,v)=>store.set(k,String(v)),removeItem:k=>store.delete(k)},
  document:{querySelector(sel){return sel==='#toastStack'?sink:null;},querySelectorAll(){return[];},createElement(){return{className:'',textContent:'',remove(){}};}},
  navigator:{}, Intl, Date, Map, Set, URL, Blob, setTimeout:()=>0, clearTimeout(){},
  confirm:()=>true, prompt:()=>"SUPPRIMER"
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
  refreshDemoTeamState();
  ({matches:state.allMatches.length,avatars:OFFICIAL_AVATARS.length,teamShapes:TEAM_SHAPES.length,teamBackgrounds:TEAM_BACKGROUNDS.length,reclaimOk:typeof reclaimTeam==='function',hardDeleteOk:typeof superAdminDeleteTeam==='function',adminOk:typeof renderAdmin==='function'});
`).runInContext(context);
assert.deepEqual({...smoke},{matches:8,avatars:90,teamShapes:12,teamBackgrounds:13,reclaimOk:true,hardDeleteOk:true,adminOk:true});


// Workflow démo : capitaine seul -> quitte -> Team vacante -> reprise -> dissolution -> réactivation -> hard delete Super Admin.
new vm.Script(`(()=>{const id='solo-team';localStorage.setItem('nidc_demo_teams',JSON.stringify([{id,season_id:state.season.id,name:'Solo',slug:'solo',slogan:'',description:'',visibility:'public',status:'active',captain_user_id:state.user.id,logo_type:'library',logo_asset_key:'owl',shape:'shield-classic',frame_style:'champions',primary_color:'#ff0000',secondary_color:'#ffffff',background_style:'stripes-diagonal',created_at:new Date().toISOString()}]));localStorage.setItem('nidc_demo_team_memberships',JSON.stringify([{id:'m1',season_id:state.season.id,team_id:id,user_id:state.user.id,joined_at:new Date().toISOString(),left_at:null,join_type:'creator'}]));localStorage.setItem('nidc_demo_team_events','[]');localStorage.setItem('nidc_demo_team_requests','[]');localStorage.setItem('nidc_demo_team_invites','{}');refreshDemoTeamState();})()`).runInContext(context);
await new vm.Script(`leaveMyTeam()`).runInContext(context);
let flow=new vm.Script(`({my:state.myTeam,cap:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].captain_user_id,status:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].status})`).runInContext(context);
assert.equal(flow.my,null);assert.equal(flow.cap,null);assert.equal(flow.status,'active');
await new vm.Script(`reclaimTeam('solo-team')`).runInContext(context);
flow=new vm.Script(`({my:state.myTeam?.id,cap:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].captain_user_id})`).runInContext(context);
assert.equal(flow.my,'solo-team');assert.equal(flow.cap,'demo-parkaf');
await new vm.Script(`dissolveMyTeam()`).runInContext(context);
flow=new vm.Script(`({my:state.myTeam,status:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].status})`).runInContext(context);
assert.equal(flow.my,null);assert.equal(flow.status,'dissolved');
await new vm.Script(`reclaimTeam('solo-team')`).runInContext(context);
flow=new vm.Script(`({my:state.myTeam?.id,status:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].status})`).runInContext(context);
assert.equal(flow.my,'solo-team');assert.equal(flow.status,'active');
await new vm.Script(`superAdminDeleteTeam('solo-team',state.teamDirectory.find(x=>x.team_id==='solo-team'))`).runInContext(context);
assert.equal(JSON.parse(store.get('nidc_demo_teams')||'[]').length,0);

console.log('V0.5.5a release tests: OK');
