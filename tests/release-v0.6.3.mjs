import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const exists=p=>fs.existsSync(path.join(root,p));

assert.equal(read('VERSION').trim(),'0.6.3');
assert.match(read('config.js'),/APP_VERSION:\s*"0\.6\.3"/);
assert.match(read('config.example.js'),/APP_VERSION:\s*"0\.6\.3"/);
assert.equal(JSON.parse(read('assets/assets-manifest.json')).version,'0.6.3');

const js=['core.js','avatars.js','teams.js','notifications.js','social.js','rivals.js','support.js','owl.js','auth.js','data.js','champions.js','profile.js','predictions.js','ranking.js','admin.js','realtime.js','app.js'];
const css=['base.css','predictions.css','ranking.css','clubs.css','champions.css','layout.css','teams.css','avatars.css','communication.css','social.css','admin.css'];
for(const f of js)assert.ok(exists(`js/${f}`),`js/${f} absent`);
for(const f of css)assert.ok(exists(`css/${f}`),`css/${f} absent`);

const html=read('index.html');
for(const f of js)assert.match(html,new RegExp(`js/${f.replace('.','\\.')}`));
for(const f of css)assert.match(html,new RegExp(`css/${f.replace('.','\\.')}`));
assert.match(html,/id="notificationBell"/);
assert.match(html,/id="homePushPrompt"/);
assert.match(html,/id="view-rival"/);
assert.match(html,/id="notificationPreferencesPanel"/);
assert.match(html,/id="adminNotificationsPanel"/);
assert.match(html,/V0\.6\.3/);
for(const section of ["dashboard","matches","competition","players","teams","communication","application"])assert.match(html,new RegExp(`data-admin-(?:section|panel)="${section}"`));
assert.match(html,/id="adminPlayersPanel"/);
assert.match(html,/id="adminReloadDataBtn"/);
assert.match(html,/id="adminRefreshPwaBtn"/);

const sw=read('sw.js');
assert.match(sw,/nid-champions-v0\.6\.3/);
assert.match(sw,/addEventListener\("push"/);
assert.match(sw,/addEventListener\("notificationclick"/);
assert.match(sw,/nidc-deep-link/);
for(const f of js)assert.match(sw,new RegExp(`\\./js/${f.replace('.','\\.')}`));
for(const f of css)assert.match(sw,new RegExp(`\\./css/${f.replace('.','\\.')}`));

for(const f of ['sql/HOTFIX_V0.6.0_EXISTING_DB.sql','sql/015_patch_v0.6.0_hibou_rivals_notifications.sql','sql/000_INSTALL_FRESH_V0.6.0.sql','sql/ENABLE_PUSH_CRON_V0.6.0_TEMPLATE.sql','installation/INSTALLATION_V0.6.0.txt','docs/TEST_CHECKLIST_V0.6.0.md','tools/generate-vapid-keys.mjs','supabase/functions/push-dispatch/index.ts'])assert.ok(exists(f),`${f} absent`);
for(const f of ['sql/HOTFIX_V0.6.2_EXISTING_DB.sql','sql/016_patch_v0.6.2_reactions_team_avatar.sql','sql/000_INSTALL_FRESH_V0.6.2.sql','installation/INSTALLATION_V0.6.2.txt','docs/TEST_CHECKLIST_V0.6.2.md'])assert.ok(exists(f),`${f} absent`);

const sql=read('sql/HOTFIX_V0.6.0_EXISTING_DB.sql');
for(const pattern of [
  /create table if not exists public\.notification_preferences/,
  /category_support boolean/,
  /create table if not exists public\.notifications/,
  /create table if not exists public\.push_subscriptions/,
  /create table if not exists public\.push_delivery_logs/,
  /create table if not exists public\.player_rivals/,
  /create table if not exists public\.rival_duels/,
  /create table if not exists public\.owl_messages/,
  /create table if not exists public\.support_tickets/,
  /support-captures/,
  /create or replace function public\.set_my_rival_v060/,
  /create or replace function public\.refresh_rival_duels_v060/,
  /create or replace function public\.admin_send_system_message_v060/,
  /create or replace function public\.notify_team_event_v060/,
  /Réservé au Super Admin/,
  /revoke execute on function public\.create_notification_v060/,
  /grant update\(read_at,deleted_at\)/,
  /grant execute on function public\.refresh_rival_duels_v060\(uuid\) to service_role/,
  /values \('app_version','"0\.6\.0"'::jsonb\)/
]) assert.match(sql,pattern);


const sql062=read('sql/HOTFIX_V0.6.2_EXISTING_DB.sql');
for(const pattern of [
  /create table if not exists public\.player_reactions/,
  /category_social boolean/,
  /'social'/,
  /create or replace function public\.send_player_reaction_v062/,
  /30 then raise exception/,
  /interval '8 seconds'/,
  /values \('app_version','"0\.6\.2"'::jsonb\)/
]) assert.match(sql062,pattern);
const notifications=read('js/notifications.js');
for(const pattern of [/defaultNotificationPreferences/,/reminder_3h:true/,/reminder_30m:true/,/reminder_24h:false/,/quiet_start:"23:00"/,/quiet_end:"08:00"/,/Notification\.requestPermission\(\)/,/renderHomePushPrompt/,/sendAdminPushTest/,/sendCriticalSystemMessage/,/category_support/,/category_social/,/if\(n\?\.category===\"system\"\)return true/,/value\.startsWith\(\"matches:\"\)/,/value\.startsWith\(\"player:\"\)/])assert.match(notifications,pattern);
const rivals=read('js/rivals.js');
for(const pattern of [/nextRivalChoiceMatchday/,/openRivalPicker/,/RIVALITÉ MUTUELLE/,/rivalTrendHTML/,/renderRivalRecords/,/openFormerRival/])assert.match(rivals,pattern);
const support=read('js/support.js');
for(const pattern of [/3 captures maximum/,/5\*1024\*1024/,/technicalTicketContext/,/admin_update_support_ticket_v060/,/role!=="super_admin"/])assert.match(support,pattern);
const owl=read('js/owl.js');
assert.match(owl,/openAdminOwlMessageForPlayer/);
const ranking=read('js/ranking.js');
assert.match(ranking,/data-current-rival/);
assert.match(ranking,/data-player-profile/);
assert.match(ranking,/reactionButtonHTML/);
assert.match(ranking,/sticky-player-copy/);
const social=read('js/social.js');
for(const pattern of [/PLAYER_REACTION_EMOJIS/,/openPlayerReactionPicker/,/send_player_reaction_v062/,/bindPlayerReactionButtons/])assert.match(social,pattern);
const teamCss=read('css/teams.css');assert.match(teamCss,/V0\.6\.2 — Cartes Team lisibles/);assert.match(teamCss,/opacity:\.16/);


const edge=read('supabase/functions/push-dispatch/index.ts');
for(const pattern of [/npm:@supabase\/supabase-js@2/,/npm:web-push@3\.6\.7/,/PUSH_VAPID_PUBLIC_KEY/,/PUSH_CRON_SECRET/,/action==="test"/,/createReminderNotifications/,/createChampionReminders/,/createRivalPreMatchNotifications/,/createCompletedMatchdaySummaries/,/updateRankingNotifications/,/404 \|\| code === 410/,/deliverNotification\(n,"test"\)/])assert.match(edge,pattern);
assert.match(edge,/social: "category_social"/);
assert.match(read('supabase/config.toml'),/\[functions\.push-dispatch\][\s\S]*verify_jwt = false/);

// Contrainte pratique de l'upload GitHub Web : chaque bloc reste sous 100 fichiers.
function countFiles(dirPath){
  let count=0;
  for(const entry of fs.readdirSync(dirPath,{withFileTypes:true})){
    const p=path.join(dirPath,entry.name);
    count += entry.isDirectory() ? countFiles(p) : 1;
  }
  return count;
}
for(const dir of ['assets','css','js','installation','docs','sql','supabase','tests','tools']){
  const count=countFiles(path.join(root,dir));
  assert.ok(count<=100,`${dir}/ contient ${count} fichiers (>100)`);
}

// Les scripts classiques doivent continuer à partager le même contexte global après le découpage V0.5.4.
const store=new Map();
const sink={appendChild(){},classList:{add(){},remove(){},toggle(){}},remove(){}};
const context=vm.createContext({
  console,
  window:{
    NIDC_CONFIG:{SUPABASE_URL:'https://YOUR_PROJECT.supabase.co',SUPABASE_ANON_KEY:'YOUR_SUPABASE_ANON_KEY',DEMO_WHEN_UNCONFIGURED:true,APP_VERSION:'0.6.3'},
    __nidcErrors:[],addEventListener(){},innerWidth:412,innerHeight:915
  },
  localStorage:{getItem:k=>store.has(k)?store.get(k):null,setItem:(k,v)=>store.set(k,String(v)),removeItem:k=>store.delete(k)},
  sessionStorage:{getItem(){return null;},setItem(){},removeItem(){}},
  document:{querySelector(sel){return sel==='#toastStack'?sink:null;},querySelectorAll(){return[];},createElement(){return{className:'',textContent:'',remove(){},appendChild(){},classList:{add(){},remove(){},toggle(){}}};}},
  navigator:{userAgent:'Mozilla/5.0 Android Chrome',platform:'Android'},
  Notification:{permission:'default',requestPermission:async()=> 'granted'},
  Intl, Date, Map, Set, URL, Blob, Uint8Array, atob, btoa,
  location:{href:'https://example.test/',pathname:'/',search:'',hash:''},history:{replaceState(){}},
  setTimeout:()=>0,clearTimeout(){},confirm:()=>true,prompt:()=>"SUPPRIMER"
});
for(const f of js){let code=read(`js/${f}`);if(f==='app.js')code=code.replace(/boot\(\)\.catch[\s\S]*$/m,'');new vm.Script(code,{filename:f}).runInContext(context);}
const smoke=new vm.Script(`
  state.user={id:'demo-parkaf'};
  state.profile=state.demoUsers[0];
  demoInit();
  loadDemoChampionState();
  ensureDemoTeams();
  refreshDemoTeamState();
  state.profileDirectory=new Map(state.demoUsers.map(u=>[String(u.id),u]));
  state.notificationPreferences=defaultNotificationPreferences();
  ({matches:state.allMatches.length,avatars:OFFICIAL_AVATARS.length,teamShapes:TEAM_SHAPES.length,teamBackgrounds:TEAM_BACKGROUNDS.length,notif3h:state.notificationPreferences.reminder_3h,notif30:state.notificationPreferences.reminder_30m,notif24:state.notificationPreferences.reminder_24h,quietStart:state.notificationPreferences.quiet_start,rivalOk:typeof renderRivalView==='function',supportOk:typeof openSupportCenter==='function',owlOk:typeof renderOwlHome==='function',pushTestOk:typeof sendAdminPushTest==='function',profileMessageOk:typeof openAdminOwlMessageForPlayer==='function',reactionOk:typeof openPlayerReactionPicker==='function',socialPref:state.notificationPreferences.category_social});
`).runInContext(context);
assert.deepEqual({...smoke},{matches:8,avatars:90,teamShapes:12,teamBackgrounds:13,notif3h:true,notif30:true,notif24:false,quietStart:'23:00',rivalOk:true,supportOk:true,owlOk:true,pushTestOk:true,profileMessageOk:true,reactionOk:true,socialPref:true});



// L'identité avatar de profileDirectory doit gagner sur une valeur ancienne issue d'un classement.
const canonicalAvatar=new vm.Script(`(()=>{state.profileDirectory.set('demo-ju',{id:'demo-ju',user_id:'demo-ju',username:'Ju',avatar_key:'avatar-hibou-saphir',avatar_source:'library',avatar_moderation_status:'approved'});return profileForUser({user_id:'demo-ju',username:'Ju',avatar_key:'avatar-hibou-or'}).avatar_key;})()`).runInContext(context);
assert.equal(canonicalAvatar,'avatar-hibou-saphir');

// V0.6.3 : le même joueur doit produire le même composant public, même si la ligne métier contient un ancien avatar.
const canonicalHTML=new vm.Script(`(()=>{state.teamDirectoryMap.set('demo-ju',{team_id:'t-ju',team_name:'Team Ju',name:'Team Ju',shape:'shield-classic',frame_style:'gold',primary_color:'#e10016',secondary_color:'#ffffff',background_style:'stripes-diagonal',logo_type:'library',logo_asset_key:'owl'});const a=avatarHTML({user_id:'demo-ju',username:'Ju',avatar_key:'avatar-hibou-or'});const b=avatarHTML(state.profileDirectory.get('demo-ju'));return {a,b};})()`).runInContext(context);
assert.equal(canonicalHTML.a,canonicalHTML.b);
assert.match(canonicalHTML.a,/unified-player-avatar/);
assert.match(canonicalHTML.a,/player-avatar-image/);

// Régression Teams V0.5.5a : quitter une Team solo ne doit toujours pas la détruire.
new vm.Script(`(()=>{const id='solo-team';localStorage.setItem('nidc_demo_teams',JSON.stringify([{id,season_id:state.season.id,name:'Solo',slug:'solo',slogan:'',description:'',visibility:'public',status:'active',captain_user_id:state.user.id,logo_type:'library',logo_asset_key:'owl',shape:'shield-classic',frame_style:'champions',primary_color:'#ff0000',secondary_color:'#ffffff',background_style:'stripes-diagonal',created_at:new Date().toISOString()}]));localStorage.setItem('nidc_demo_team_memberships',JSON.stringify([{id:'m1',season_id:state.season.id,team_id:id,user_id:state.user.id,joined_at:new Date().toISOString(),left_at:null,join_type:'creator'}]));localStorage.setItem('nidc_demo_team_events','[]');localStorage.setItem('nidc_demo_team_requests','[]');localStorage.setItem('nidc_demo_team_invites','{}');refreshDemoTeamState();})()`).runInContext(context);
await new vm.Script(`leaveMyTeam()`).runInContext(context);
let teamFlow=new vm.Script(`({my:state.myTeam,cap:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].captain_user_id,status:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].status})`).runInContext(context);
assert.equal(teamFlow.my,null); assert.equal(teamFlow.cap,null); assert.equal(teamFlow.status,'active');
await new vm.Script(`reclaimTeam('solo-team')`).runInContext(context);
teamFlow=new vm.Script(`({my:state.myTeam?.id,cap:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].captain_user_id})`).runInContext(context);
assert.equal(teamFlow.my,'solo-team'); assert.equal(teamFlow.cap,'demo-parkaf');
await new vm.Script(`dissolveMyTeam()`).runInContext(context);
teamFlow=new vm.Script(`({my:state.myTeam,status:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].status})`).runInContext(context);
assert.equal(teamFlow.my,null); assert.equal(teamFlow.status,'dissolved');
await new vm.Script(`reclaimTeam('solo-team')`).runInContext(context);
teamFlow=new vm.Script(`({my:state.myTeam?.id,status:JSON.parse(localStorage.getItem('nidc_demo_teams'))[0].status})`).runInContext(context);
assert.equal(teamFlow.my,'solo-team'); assert.equal(teamFlow.status,'active');
await new vm.Script(`superAdminDeleteTeam('solo-team',state.teamDirectory.find(x=>x.team_id==='solo-team'))`).runInContext(context);
assert.equal(JSON.parse(store.get('nidc_demo_teams')||'[]').length,0);

const admin=read('js/admin.js');
for(const pattern of [/ADMIN_SECTIONS/,/setAdminSection/,/renderAdminDashboard/,/renderAdminPlayers/,/reloadAdminData/,/refreshAdminPwa/])assert.match(admin,pattern);
assert.ok(exists('installation/INSTALLATION_V0.6.3.txt'));
assert.ok(exists('docs/TEST_CHECKLIST_V0.6.3.md'));
console.log('V0.6.3 release tests: OK');
