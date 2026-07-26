import fs from 'node:fs';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'..');
const read=(p)=>fs.readFileSync(path.join(root,p),'utf8');
const exists=(p)=>fs.existsSync(path.join(root,p));

assert.equal(read('VERSION').trim(),'0.5.2');
assert.match(read('sw.js'),/nid-champions-v0\.5\.2/);
assert.match(read('config.example.js'),/APP_VERSION:\s*"0\.5\.2"/);

const html=read('index.html');
for(const id of ['view-teams','myTeamPanel','teamLeaderboard','teamDirectory','profileTeamCard','adminTeamsPanel']) {
  assert.ok(html.includes(`id="${id}"`),`missing #${id}`);
}

const js=read('assets/js/app.js');
for(const needle of [
  'team-editor-v051','teamEditColorMode','data-color-mode="single"','data-color-mode="two"',
  'TEAM_STYLE_PRESETS','teamChoiceMarkHTML','team-preview-emblem','team-preview-member',
  'team-rank-preview','team-preview-mini-card','resetTeamStyle'
]) assert.ok(js.includes(needle),`missing V0.5.2 UI feature: ${needle}`);
for(const preset of ['champions','royal','forest','obsidian','neon']) assert.ok(js.includes(`${preset}:{label:`),`missing preset ${preset}`);
assert.match(js,/colorMode==="single"\?primary/);
assert.match(js,/background_style:colorMode==="single"\?"solid"/);
assert.ok(js.includes("URL.createObjectURL(file)"),'upload preview missing');

// V0.5.0 engine stays present.
for(const rpc of ['create_team_v050','join_public_team_v050','request_team_join_v050','join_team_by_code_v050','get_team_leaderboard_v050']) {
  assert.ok(js.includes(rpc),`missing RPC call ${rpc}`);
}
const sql=read('sql/011_patch_v0.5.0_teams.sql');
for(const table of ['teams','team_memberships','team_join_requests','team_invites','team_events']) {
  assert.match(sql,new RegExp(`create table if not exists public\\.${table}`,'i'));
}

const css=read('assets/css/app.css');
for(const needle of [
  'team-editor-modal-card','team-editor-preview-panel','team-visual-grid','team-color-mode',
  'team-logo-glyph','--team-clip','--team-frame-bg','team-preview-emblem',
  'team-preview-member','team-preview-mini-card'
]) assert.ok(css.includes(needle),`missing CSS ${needle}`);

const shapes=['circle','medallion','rounded','square','diamond','hex','shield-classic','shield-point','shield-modern','banner','royal','prestige'];
const frames=['wood','bronze','silver','gold','royal-gold','steel','leather','obsidian','neon','champions','royal','night'];
for(const k of shapes) assert.ok(css.includes(`.shape-${k}{--team-clip:`),`V0.5.2 clip shape ${k}`);
for(const k of frames) assert.ok(css.includes(`.frame-${k}{--team-frame-bg:`),`V0.5.2 material frame ${k}`);
assert.match(css,/\.team-logo\{[\s\S]*background:transparent!important/);
assert.match(css,/grid-template-columns:minmax\(0,1\.55fr\) minmax\(340px,.72fr\)/);

assert.ok(exists('docs/TEST_CHECKLIST_V0.5.2.md'));
assert.ok(exists('INSTALLATION_V0.5.2.txt'));
assert.match(read('README.md'),/V0\.5\.2/);
assert.match(read('CHANGELOG.md'),/V0\.5\.2/);
assert.match(read('docs/ASSETS_MANIFEST.md'),/sans fond opaque/i);
assert.ok(exists('assets/branding/owl/owl-masked-main.png'));

execFileSync(process.execPath,['--check',path.join(root,'assets/js/app.js')],{stdio:'inherit'});
execFileSync(process.execPath,['--check',path.join(root,'sw.js')],{stdio:'inherit'});
execFileSync(process.execPath,['--check',path.join(root,'config.example.js')],{stdio:'inherit'});

console.log('V0.5.2 release tests: OK');

// V0.5.2 visual regression guards
const cssText = fs.readFileSync(path.join(root, 'assets/css/app.css'),'utf8');
assert(cssText.includes('.shape-circle{--team-clip:circle('), 'circle shape missing');
assert(cssText.includes('.shape-hex{--team-clip:polygon('), 'hex shape missing');
assert(cssText.includes('.shape-shield-classic{--team-clip:polygon('), 'shield shape missing');
assert(!/\.team-avatar,\.team-badge-visual,\.team-choice-mark,\.team-preset-swatch\s*\{[^}]*--team-clip:/s.test(cssText), 'generic team visual block must not override shape variable');
assert(!/\.team-avatar,\.team-badge-visual,\.team-choice-mark,\.team-preset-swatch\s*\{[^}]*--team-frame-bg:/s.test(cssText), 'generic team visual block must not override frame variable');
const jsText = fs.readFileSync(path.join(root, 'assets/js/app.js'),'utf8');
assert(jsText.includes('team-color-mode-card'), 'explicit 1/2 color selector missing');
assert(jsText.includes('shape:selectedShape,frame_style:key'), 'frame preview must use selected shape');
console.log('V0.5.2 visual guards OK');
