import fs from 'node:fs';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'..');
const read=(p)=>fs.readFileSync(path.join(root,p),'utf8');
const exists=(p)=>fs.existsSync(path.join(root,p));

assert.equal(read('VERSION').trim(),'0.5.3');
assert.match(read('sw.js'),/nid-champions-v0\.5\.3/);
assert.match(read('config.example.js'),/APP_VERSION:\s*"0\.5\.3"/);
assert.match(read('config.js'),/APP_VERSION:\s*"0\.5\.3"/);

const assetsManifest=JSON.parse(read('assets/assets-manifest.json'));
assert.equal(assetsManifest.version,'0.5.3');
assert.equal(assetsManifest.avatars.official_count,90);
assert.equal(assetsManifest.avatars.uploads.bucket,'player-avatars');
const catalog=JSON.parse(read('assets/avatars/avatar-catalog.json'));
assert.equal(catalog.length,90,'official avatar catalog must contain 90 entries');
assert.equal(new Set(catalog.map(x=>x.key)).size,90,'avatar keys must be unique');
for(const a of catalog){
  assert.match(a.key,/^avatar-hibou-[a-z0-9-]+$/);
  const rel=`assets/avatars/nid/${a.file}`;
  assert.ok(exists(rel),`missing avatar asset ${rel}`);
  const png=fs.readFileSync(path.join(root,rel));
  assert.equal(png.subarray(1,4).toString(),'PNG',`${rel} is not PNG`);
}

const html=read('index.html');
for(const id of ['avatarEditor','avatarModerationPanel','profileAvatar','sidebarUserAvatar','rankingBody','teamLeaderboard']) {
  assert.ok(html.includes(`id="${id}"`),`missing #${id}`);
}
assert.match(html,/PNG\/JPG\/WebP/i);
assert.match(html,/Modération des avatars/);

const js=read('assets/js/app.js');
for(const needle of [
  'OFFICIAL_AVATARS','AVATAR_MAX_BYTES','image/png','image/jpeg','image/webp',
  'player-avatars','createSignedUrls','select_player_avatar_v053','submit_player_avatar_v053',
  'admin_list_avatar_moderation_v053','admin_moderate_avatar_v053',
  'avatarCoreHTML','avatarHTML','profileDirectory','renderAvatarEditor','loadAvatarModeration'
]) assert.ok(js.includes(needle),`missing avatar feature ${needle}`);
assert.match(js,/avatar_moderation_status==="approved" \|\| allowPending/);
assert.match(js,/avatarHTML\(r\)/,'revealed predictions / shared avatar renderer missing');
assert.match(js,/\$\{avatarHTML\(r\)\}/,'ranking/revealed avatar renderer missing');
assert.match(js,/state\.teamMembers\.slice\(0,4\)\.map\(m=>avatarHTML\(m\)\)/,'Team avatar integration missing');

const css=read('assets/css/app.css');
for(const needle of ['player-avatar-core','avatar-editor-grid','avatar-library','avatar-preview-stage','avatar-moderation-row']) {
  assert.ok(css.includes(needle),`missing CSS ${needle}`);
}

const sql=read('sql/012_patch_v0.5.3_player_avatars.sql');
for(const needle of [
  'create table if not exists public.player_avatar_catalog',
  "values('player-avatars','player-avatars',false,3145728",
  'player_avatars_authorized_read','player_avatars_own_insert','player_avatars_own_update','player_avatars_own_delete',
  'select_player_avatar_v053','submit_player_avatar_v053',
  'admin_list_avatar_moderation_v053','admin_moderate_avatar_v053',
  "avatar_moderation_status='pending'","avatar_moderation_status=case when v_decision='approve'",
  "'avatar_'||v_decision"
]) assert.ok(sql.toLowerCase().includes(needle.toLowerCase()),`missing SQL ${needle}`);
const catalogRows=(sql.match(/\('avatar-hibou-[^']+'\s*,/g)||[]).length;
assert.equal(catalogRows,90,'SQL official avatar catalog must seed 90 rows');

for(const p of [
  'sql/HOTFIX_V0.5.3_EXISTING_DB.sql','sql/000_INSTALL_FRESH_V0.5.3.sql',
  'INSTALLATION_V0.5.3.txt','docs/TEST_CHECKLIST_V0.5.3.md',
  'README.md','CHANGELOG.md','docs/ASSETS_MANIFEST.md'
]) assert.ok(exists(p),`missing release artifact ${p}`);
assert.match(read('README.md'),/V0\.5\.3 — Avatars joueurs/);
assert.match(read('CHANGELOG.md'),/V0\.5\.3 — Avatars joueurs/);
assert.match(read('docs/ASSETS_MANIFEST.md'),/DONE — les 90 PNG sont livrés/);

// Team engine and V0.5.2 visual system must still be present.
for(const rpc of ['create_team_v050','join_public_team_v050','get_team_leaderboard_v050']) assert.ok(js.includes(rpc),`Team regression: ${rpc}`);
for(const shape of ['circle','hex','shield-classic','prestige']) assert.ok(css.includes(`.shape-${shape}{--team-clip:`),`Team shape regression ${shape}`);

execFileSync(process.execPath,['--check',path.join(root,'assets/js/app.js')],{stdio:'inherit'});
execFileSync(process.execPath,['--check',path.join(root,'sw.js')],{stdio:'inherit'});
execFileSync(process.execPath,['--check',path.join(root,'config.example.js')],{stdio:'inherit'});

console.log('V0.5.3 release tests: OK');
