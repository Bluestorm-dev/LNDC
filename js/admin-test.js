"use strict";

// Le Nid des Champions V0.7.0 — laboratoire Super Admin / calendrier TEST
function testAdminAllowed(){return state.profile?.role==="super_admin"&&state.profile?.status==="active";}

function adminTestClubOptions(selected=""){
  return [...(state.clubs||[])]
    .sort((a,b)=>String(a.name||a.short_name).localeCompare(String(b.name||b.short_name),"fr"))
    .map(c=>`<option value="${esc(c.id)}" ${String(c.id)===String(selected)?"selected":""}>${esc(c.short_name||c.tla||c.name)} — ${esc(c.name)}</option>`).join("");
}

function adminTestDefaultKickoff(dayIndex,matchIndex){
  const d=new Date(Date.now()+(dayIndex===0?4:28)*3600_000+matchIndex*20*60_000);
  d.setSeconds(0,0);
  return toLocalDateTimeInput(d);
}

function adminTestMatchRow(dayIndex,matchIndex,homeId="",awayId=""){
  const clubs=[...(state.clubs||[])];
  const h=homeId||clubs[(dayIndex*4+matchIndex*2)%Math.max(1,clubs.length)]?.id||"";
  let a=awayId||clubs[(dayIndex*4+matchIndex*2+1)%Math.max(1,clubs.length)]?.id||"";
  if(a===h&&clubs.length>1)a=clubs.find(c=>c.id!==h)?.id||"";
  const home=clubs.find(c=>String(c.id)===String(h));
  return `<div class="admin-test-match-row" data-test-match-row>
    <div class="admin-test-match-title"><b>Match ${matchIndex+1}</b><button type="button" class="text-action" data-test-remove-match>Supprimer</button></div>
    <div class="admin-test-match-grid">
      <div class="field"><label>Équipe domicile</label><select data-test-home>${adminTestClubOptions(h)}</select></div>
      <div class="field"><label>Équipe extérieure</label><select data-test-away>${adminTestClubOptions(a)}</select></div>
      <div class="field"><label>Stade</label><input data-test-stadium value="${esc(home?.venue||"")}" placeholder="Stade"></div>
      <div class="field"><label>Pays</label><input data-test-country value="${esc(home?.country||"")}" placeholder="Pays"></div>
      <div class="field admin-test-datetime"><label>Date & heure</label><input data-test-kickoff type="datetime-local" value="${adminTestDefaultKickoff(dayIndex,matchIndex)}"></div>
    </div>
  </div>`;
}

function adminTestDayHTML(dayIndex){
  return `<section class="admin-test-day" data-test-day="${dayIndex}">
    <div class="admin-test-day-head"><div><span class="eyebrow">Journée TEST ${dayIndex+1}</span><h4>Journée ${dayIndex+1}</h4></div><button class="btn secondary small" type="button" data-test-add-match>+ Ajouter un match</button></div>
    <div class="admin-test-match-list">${adminTestMatchRow(dayIndex,0)}${adminTestMatchRow(dayIndex,1)}</div>
  </section>`;
}

function bindAdminTestRow(row){
  if(!row)return;
  const home=$("[data-test-home]",row),stadium=$("[data-test-stadium]",row),country=$("[data-test-country]",row);
  if(home)home.onchange=()=>{
    const club=state.clubs.find(c=>String(c.id)===String(home.value));
    if(stadium)stadium.value=club?.venue||"";
    if(country)country.value=club?.country||"";
  };
  const remove=$("[data-test-remove-match]",row);
  if(remove)remove.onclick=()=>{const list=row.parentElement;if(list?.children.length<=1){toast("Une journée TEST doit garder au moins un match.","error");return;}row.remove();renumberAdminTestRows(list);};
}

function renumberAdminTestRows(list){$$('[data-test-match-row]',list).forEach((row,i)=>{const b=$(".admin-test-match-title b",row);if(b)b.textContent=`Match ${i+1}`;});}

function initAdminTestBuilder(){
  const root=$("#adminTestDays");if(!root||root.dataset.ready==="1")return;
  root.innerHTML=adminTestDayHTML(0)+adminTestDayHTML(1);root.dataset.ready="1";
  $$('[data-test-match-row]',root).forEach(bindAdminTestRow);
  $$('[data-test-day]',root).forEach(day=>{
    const add=$("[data-test-add-match]",day);if(!add)return;
    add.onclick=()=>{
      const list=$(".admin-test-match-list",day),dayIndex=Number(day.dataset.testDay||0),i=$$('[data-test-match-row]',list).length;
      list.insertAdjacentHTML("beforeend",adminTestMatchRow(dayIndex,i));bindAdminTestRow(list.lastElementChild);
    };
  });
}

function adminTestSummary(){
  const raw=state.adminAllMatches?.length?state.adminAllMatches:state.allMatches||[];
  const tests=raw.filter(m=>m.is_test);
  const active=tests.filter(m=>m.test_enabled!==false&&m.status!=="cancelled").length;
  const disabled=tests.length-active;
  return {tests,active,disabled};
}

function renderAdminTest(){
  const section=$("#adminTestPanelSection"),nav=$("#adminTestNav");
  const allowed=testAdminAllowed();
  if(section)section.classList.toggle("hidden",!allowed);if(nav)nav.classList.toggle("hidden",!allowed);
  if(!allowed)return;
  initAdminTestBuilder();
  const {tests,active,disabled}=adminTestSummary();
  if($("#adminTestStatusText"))$("#adminTestStatusText").textContent=!tests.length?"Aucun match TEST actuellement.":`${tests.length} match${tests.length>1?"s":""} TEST · ${active} actif${active>1?"s":""} · ${disabled} désactivé${disabled>1?"s":""}.`;
  const on=$("#adminEnableTestsBtn"),off=$("#adminDisableTestsBtn");if(on)on.disabled=!tests.length||active===tests.length;if(off)off.disabled=!tests.length||active===0;
  if(on)on.onclick=()=>setAdminTestEnabled(true);if(off)off.onclick=()=>setAdminTestEnabled(false);
  const create=$("#adminCreateTestDaysBtn");if(create)create.onclick=createAdminTestSchedule;
  const del=$("#adminDeleteTestMatchesBtn");if(del)del.onclick=deleteAdminTestSchedule;
  const wipe=$("#adminDeleteAllMatchesBtn");if(wipe)wipe.onclick=deleteAdminAllMatches;
}

function collectAdminTestPayload(){
  const days=$$('[data-test-day]',$("#adminTestDays"));
  if(days.length!==2)throw new Error("Le laboratoire doit contenir exactement 2 journées TEST.");
  return {days:days.map((day,dayIndex)=>{
    const matches=$$('[data-test-match-row]',day).map(row=>{
      const home=$("[data-test-home]",row)?.value,away=$("[data-test-away]",row)?.value,kickoff=$("[data-test-kickoff]",row)?.value;
      if(!home||!away||!kickoff)throw new Error(`Journée ${dayIndex+1} : un match est incomplet.`);
      if(home===away)throw new Error(`Journée ${dayIndex+1} : une équipe ne peut pas jouer contre elle-même.`);
      const iso=parseFrenchLocalInput(kickoff);if(!iso)throw new Error(`Journée ${dayIndex+1} : date/heure invalide.`);
      return {home_club_id:home,away_club_id:away,stadium:$("[data-test-stadium]",row)?.value.trim()||null,country:$("[data-test-country]",row)?.value.trim()||null,kickoff_at:iso};
    });
    if(!matches.length)throw new Error(`La journée ${dayIndex+1} doit contenir au moins un match.`);
    return {name:`TEST — Journée ${dayIndex+1}`,matches};
  })};
}

async function createAdminTestSchedule(){
  if(!testAdminAllowed())return;
  try{
    const payload=collectAdminTestPayload();
    const existing=adminTestSummary().tests.length;
    if(existing&&!confirm(`Les ${existing} match(s) TEST existants seront remplacés. Continuer ?`))return;
    setMsg("#adminTestStatusMsg","Création des 2 journées TEST…");
    const {data,error}=await sb.rpc("admin_create_test_schedule_v067",{p_season_id:state.season.id,p_payload:payload});if(error)throw error;
    await loadData();renderAll();setAdminSection("test",{scroll:false});setMsg("#adminTestStatusMsg",`${data?.matches_created||0} match(s) TEST créés dans 2 journées.`,"ok");toast("🧪 Calendrier TEST prêt.");
  }catch(err){setMsg("#adminTestStatusMsg",friendlyError(err),"error");}
}

async function setAdminTestEnabled(enabled){
  if(!testAdminAllowed())return;
  try{
    setMsg("#adminTestStatusMsg",enabled?"Réactivation des matchs TEST…":"Désactivation complète des matchs TEST…");
    const {data,error}=await sb.rpc("admin_set_test_schedule_enabled_v067",{p_season_id:state.season.id,p_enabled:enabled});if(error)throw error;
    await loadData();renderAll();setAdminSection("test",{scroll:false});setMsg("#adminTestStatusMsg",enabled?"Matchs TEST réactivés : visibles, pronostiquables et pris en compte par le Cron.":"Matchs TEST désactivés : masqués, hors classement et ignorés par le Cron.","ok");toast(enabled?"▶ Matchs TEST réactivés.":"⏸ Matchs TEST complètement désactivés.");
  }catch(err){setMsg("#adminTestStatusMsg",friendlyError(err),"error");}
}

async function deleteAdminTestSchedule(){
  if(!testAdminAllowed()||!confirm("Supprimer définitivement tous les matchs, journées et confrontations finales marqués TEST ? Les pronostics liés seront aussi supprimés."))return;
  try{setMsg("#adminTestDangerMsg","Suppression des matchs TEST…");const {data,error}=await sb.rpc("admin_delete_test_schedule_v067",{p_season_id:state.season.id});if(error)throw error;await loadData();renderAll();setAdminSection("test",{scroll:false});setMsg("#adminTestDangerMsg",`${data?.matches_deleted||0} match(s), ${data?.matchdays_deleted||0} journée(s) et ${data?.ties_deleted||0} confrontation(s) TEST supprimés.`,"ok");toast("Matchs TEST supprimés.");}catch(err){setMsg("#adminTestDangerMsg",friendlyError(err),"error");}
}

async function deleteAdminAllMatches(){
  if(!testAdminAllowed())return;
  if(!confirm("ATTENTION : cela va supprimer TOUS les matchs, TOUTES les journées et TOUT le tableau de phase finale de la saison, avec les pronostics associés. Continuer ?"))return;
  const word=prompt('Dernière sécurité : écris exactement VIDER pour confirmer.');if(word!=="VIDER"){toast("Suppression annulée.");return;}
  try{setMsg("#adminTestDangerMsg","Remise à zéro complète du calendrier…");const {data,error}=await sb.rpc("admin_delete_all_matches_v067",{p_season_id:state.season.id});if(error)throw error;state.selectedMatchdayId=null;await loadData();renderAll();setAdminSection("test",{scroll:false});setMsg("#adminTestDangerMsg",`${data?.matches_deleted||0} match(s), ${data?.matchdays_deleted||0} journée(s) et ${data?.ties_deleted||0} confrontation(s) finales supprimés.`,"ok");toast("⚠ Calendrier vidé.");}catch(err){setMsg("#adminTestDangerMsg",friendlyError(err),"error");}
}
