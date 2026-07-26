import fs from 'node:fs';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'..');
const read=(p)=>fs.readFileSync(path.join(root,p),'utf8');
const exists=(p)=>fs.existsSync(path.join(root,p));

assert.equal(read('VERSION').trim(),'0.5.0');
assert.match(read('sw.js'),/nid-champions-v0\.5\.0/);
assert.match(read('manifest.webmanifest'),/Teams/i);
assert.match(read('config.example.js'),/0\.5\.0/);

const html=read('index.html');
for(const id of ['view-teams','myTeamPanel','teamLeaderboard','teamDirectory','createTeamBtn','joinByCodeBtn','profileTeamCard','adminTeamsPanel']) assert.ok(html.includes(`id="${id}"`),`missing #${id}`);
assert.match(html,/data-view="teams"/);
assert.match(html,/owl-masked-main\.png/);

const js=read('assets/js/app.js');
for(const fn of ['renderTeams','openTeamEditor','loadTeamData','transferTeamCaptain','dissolveMyTeam','renderTeamLeaderboard']) assert.ok(js.includes(`function ${fn}`)||js.includes(`async function ${fn}`),`missing ${fn}`);
for(const rpc of ['create_team_v050','join_public_team_v050','request_team_join_v050','join_team_by_code_v050','get_team_leaderboard_v050']) assert.ok(js.includes(rpc),`missing RPC call ${rpc}`);
assert.match(js,/A1|focus|score/i); // non-régression navigation présente dans l'application
assert.equal((js.match(/function avatarHTML\s*\(/g)||[]).length,1,'avatarHTML doit être unique');

const css=read('assets/css/app.css');
const shapes=['circle','medallion','rounded','square','diamond','hex','shield-classic','shield-point','shield-modern','banner','royal','prestige'];
const frames=['wood','bronze','silver','gold','royal-gold','steel','leather','obsidian','neon','champions','royal','night'];
for(const k of shapes) assert.ok(css.includes(`shape-${k}`),`shape ${k}`);
for(const k of frames) assert.ok(css.includes(`frame-${k}`),`frame ${k}`);

const sql=read('sql/011_patch_v0.5.0_teams.sql');
for(const table of ['teams','team_memberships','team_join_requests','team_invites','team_events']) assert.match(sql,new RegExp(`create table if not exists public\\.${table}`,'i'));
for(const rpc of ['create_team_v050','update_team_v050','transfer_team_captain_v050','get_team_leaderboard_v050']) assert.ok(sql.includes(`function public.${rpc}`));
assert.match(sql,/team-logos/);
assert.match(sql,/supabase_realtime/);
assert.match(sql,/"0\.5\.0"/);
assert.ok(exists('sql/HOTFIX_V0.5.0_EXISTING_DB.sql'));
assert.ok(exists('sql/000_INSTALL_FRESH_V0.5.0.sql'));

assert.ok(exists('assets/branding/owl/owl-masked-main.png'));
const assets=read('docs/ASSETS_MANIFEST.md');
assert.match(assets,/owl-masked-main\.png/);
assert.match(assets,/Hibou masqué/i);
assert.ok(exists('docs/TEST_CHECKLIST_V0.5.0.md'));
assert.match(read('README.md'),/V0\.5\.0 — Teams/);
assert.match(read('CHANGELOG.md'),/V0\.5\.0 — Teams/);
assert.ok(exists('INSTALLATION_V0.5.0.txt'));

execFileSync(process.execPath,['--check',path.join(root,'assets/js/app.js')],{stdio:'inherit'});
execFileSync(process.execPath,['--check',path.join(root,'sw.js')],{stdio:'inherit'});
execFileSync(process.execPath,['--check',path.join(root,'config.example.js')],{stdio:'inherit'});
console.log('V0.5.0 release tests: OK');
