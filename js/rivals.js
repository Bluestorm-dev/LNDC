"use strict";

// Le Nid des Champions V0.6.2 — rival principal, duels et historique
function nextRivalChoiceMatchday(){
  const candidates=(state.matchdays||[]).map(md=>({md,first:Math.min(...state.allMatches.filter(m=>m.matchday_id===md.id&&m.status!=="cancelled").map(m=>new Date(m.kickoff_at).getTime()))})).filter(x=>Number.isFinite(x.first)&&x.first>Date.now()).sort((a,b)=>a.first-b.first);
  return candidates[0]?.md||null;
}

function demoRivalStore(){return JSON.parse(localStorage.getItem("nidc_demo_rivals")||"{}");}
function demoDuelStore(){return JSON.parse(localStorage.getItem("nidc_demo_rival_duels")||"[]");}

async function loadRivalData(){
  state.currentRival=null;state.rivalDuels=[];state.rivalChanges=[];state.rivalSummary=null;
  if(!state.user||!state.season)return;
  if(demoMode){
    const store=demoRivalStore();const current=store[`${state.season.id}:${state.user.id}`];
    if(current)state.currentRival=current;
    state.rivalDuels=demoDuelStore().filter(d=>d.season_id===state.season.id&&d.user_id===state.user.id);
    state.rivalChanges=JSON.parse(localStorage.getItem("nidc_demo_rival_changes")||"[]").filter(x=>x.season_id===state.season.id&&x.user_id===state.user.id);
    state.rivalSummary=buildLocalRivalSummary();return;
  }
  const [{data:r,error:rErr},{data:duels,error:dErr},{data:changes,error:cErr},{data:summary,error:sErr}] = await Promise.all([
    sb.from("player_rivals").select("*").eq("season_id",state.season.id).eq("user_id",state.user.id).maybeSingle(),
    sb.from("rival_duels").select("*").eq("season_id",state.season.id).eq("user_id",state.user.id).order("locked_at",{ascending:false}),
    sb.from("rival_changes").select("*").eq("season_id",state.season.id).eq("user_id",state.user.id).order("changed_at",{ascending:false}),
    sb.rpc("get_rival_summary_v060",{p_season_id:state.season.id,p_user_id:state.user.id})
  ]);
  if(rErr||dErr||cErr||sErr)throw new Error("Migration rivalités V0.6.2 absente : exécute sql/HOTFIX_V0.6.2_EXISTING_DB.sql.");
  state.currentRival=r||null;state.rivalDuels=duels||[];state.rivalChanges=changes||[];state.rivalSummary=summary?.[0]||null;
}

function buildLocalRivalSummary(){
  if(!state.currentRival)return null;const ds=(state.rivalDuels||[]).filter(d=>d.finalized_at&&String(d.rival_user_id)===String(state.currentRival.rival_user_id));
  const margins=ds.map(d=>Number(d.user_points||0)-Number(d.rival_points||0));let streak=0;for(const d of ds){if(d.result==="win")streak++;else break;}
  const store=demoRivalStore();const reverse=store[`${state.season.id}:${state.currentRival.rival_user_id}`];
  return {user_id:state.user.id,rival_user_id:state.currentRival.rival_user_id,duels:ds.length,wins:ds.filter(d=>d.result==="win").length,draws:ds.filter(d=>d.result==="draw").length,losses:ds.filter(d=>d.result==="loss").length,points_for:ds.reduce((a,d)=>a+Number(d.user_points||0),0),points_against:ds.reduce((a,d)=>a+Number(d.rival_points||0),0),best_margin:margins.length?Math.max(...margins):0,worst_margin:margins.length?Math.min(...margins):0,current_win_streak:streak,mutual:Boolean(reverse?.rival_user_id===state.user.id)};
}

function currentRivalProfile(){return state.currentRival?state.profileDirectory.get(String(state.currentRival.rival_user_id))||null:null;}
function leaderboardProfile(userId){return (state.standings||state.rankingRows||[]).find(r=>String(r.user_id)===String(userId))||null;}

function rivalToneCopy(kind){
  const tone=state.notificationPreferences?.owl_tone||"automatic";
  const hard=tone==="sans_pitie"||(tone==="automatic"&&kind==="loss");
  if(kind==="win")return hard?"Le Hibou hésite entre applaudir et envoyer une carte de condoléances à ton rival.":"Belle plume. Ton rival vient de prendre un courant d’air.";
  if(kind==="loss")return hard?"Le Hibou a cherché une excuse crédible. Il n’en a trouvé aucune.":tone==="sage"?"Il reste des journées pour répondre.":"Ça pique. On évite peut-être le classement pendant cinq minutes.";
  return tone==="sage"?"Un duel très équilibré.":"Un nul. La manière élégante de dire que personne n’a réussi à se débarrasser de l’autre.";
}

function renderHomeRival(){
  const root=$("#homeRivalCard");if(!root)return;const rival=currentRivalProfile(),summary=state.rivalSummary,md=nextRivalChoiceMatchday();
  if(!rival){root.innerHTML=`<div class="home-card-head"><div><span class="eyebrow">Rivalité</span><h3>Choisis ta Némésis</h3></div><span class="chip">⚔️</span></div><p class="muted">Un rival principal, aucun point bonus : juste l’honneur et les piques du Hibou.</p><button id="homeChooseRivalBtn" class="btn small">Choisir mon rival</button>`;$("#homeChooseRivalBtn").onclick=openRivalPicker;return;}
  const my=leaderboardProfile(state.user.id),rr=leaderboardProfile(rival.id);root.innerHTML=`<div class="home-card-head"><div><span class="eyebrow">Duel principal</span><h3>${summary?.mutual?'⚔️ Rivalité mutuelle':'⚔️ Mon rival'}</h3></div><button id="homeRivalOpen" class="text-action">Voir le duel →</button></div><div class="home-rival-versus"><div>${avatarHTML({...state.profile,user_id:state.user.id})}<strong>${esc(state.profile.username)}</strong><small>#${my?.rank||'—'} · ${my?.points||0} pts</small></div><b>VS</b><div>${avatarHTML(rival)}<strong>${esc(rival.username)}</strong><small>#${rr?.rank||'—'} · ${rr?.points||0} pts</small></div></div><div class="rival-mini-record"><span>${Number(summary?.wins||0)} V</span><span>${Number(summary?.draws||0)} N</span><span>${Number(summary?.losses||0)} D</span></div><p class="muted">${esc(rivalToneCopy((state.rivalDuels||[])[0]?.result||'draw'))}</p>${md?`<button id="homeChangeRivalBtn" class="btn secondary small">Changer pour ${esc(md.name)}</button>`:''}`;
  $("#homeRivalOpen").onclick=()=>{setView("rival");renderRivalView();};if($("#homeChangeRivalBtn"))$("#homeChangeRivalBtn").onclick=openRivalPicker;
}

function renderRivalView(){
  const root=$("#rivalPagePanel");if(!root)return;const rival=currentRivalProfile(),summary=state.rivalSummary;
  if(!rival){root.innerHTML=`<article class="card card-pad rival-empty"><span class="rival-big-icon">⚔️</span><h2>Pas encore de rival principal</h2><p class="muted">Choisis n’importe quel joueur actif du Nid. Il n’a rien à accepter, mais il sera prévenu. 😈</p><button id="rivalPageChooseBtn" class="btn gold">Choisir mon rival</button></article>`;$("#rivalPageChooseBtn").onclick=openRivalPicker;return;}
  const mine=leaderboardProfile(state.user.id)||{},his=leaderboardProfile(rival.id)||{},duels=(state.rivalDuels||[]),finals=duels.filter(d=>d.finalized_at);
  const best=finals.slice().sort((a,b)=>(b.user_points-b.rival_points)-(a.user_points-a.rival_points))[0];const worst=finals.slice().sort((a,b)=>(a.user_points-a.rival_points)-(b.user_points-b.rival_points))[0];
  root.innerHTML=`<article class="card card-pad rival-hero ${summary?.mutual?'mutual':''}"><span class="eyebrow gold">${summary?.mutual?'RIVALITÉ MUTUELLE':'RIVAL PRINCIPAL'}</span><div class="rival-hero-versus"><div>${avatarHTML({...state.profile,user_id:state.user.id})}<h2>${esc(state.profile.username)}</h2><span>#${mine.rank||'—'} · ${mine.points||0} pts</span></div><div class="rival-vs-mark">⚔️<small>${Number(summary?.wins||0)}-${Number(summary?.draws||0)}-${Number(summary?.losses||0)}</small></div><div>${avatarHTML(rival)}<h2>${esc(rival.username)}</h2><span>#${his.rank||'—'} · ${his.points||0} pts</span></div></div><div class="actions rival-hero-actions"><button id="changeRivalBtn" class="btn secondary small">Changer de rival</button><button id="quickRivalCompareBtn" class="btn small">Comparaison rapide</button></div></article><div class="rival-stats-grid"><article class="card card-pad"><span>Duels</span><strong>${Number(summary?.duels||0)}</strong><small>${Number(summary?.wins||0)} victoires · ${Number(summary?.draws||0)} nuls · ${Number(summary?.losses||0)} défaites</small></article><article class="card card-pad"><span>Points duel</span><strong>${Number(summary?.points_for||0)}–${Number(summary?.points_against||0)}</strong><small>cumul sur les journées finalisées</small></article><article class="card card-pad"><span>Plus grosse victoire</span><strong>${best?`${best.user_points}–${best.rival_points}`:'—'}</strong><small>${best?matchdayName(best.matchday_id):'Aucun duel finalisé'}</small></article><article class="card card-pad"><span>Plus grosse claque</span><strong>${worst&&worst.result==='loss'?`${worst.user_points}–${worst.rival_points}`:'—'}</strong><small>${Number(summary?.current_win_streak||0)} victoire(s) de suite actuellement</small></article></div><article class="card card-pad"><div class="section-title compact"><div><span class="eyebrow">Historique</span><h3>Confrontations UEFA</h3></div><span class="chip">${finals.length}</span></div><div class="rival-duel-history">${duels.length?duels.map(renderRivalDuelRow).join(''):'<div class="empty">Le premier duel sera figé au coup d’envoi de la prochaine journée.</div>'}</div></article><article class="card card-pad"><div class="section-title compact"><div><span class="eyebrow">Trajectoire</span><h3>Courbe des duels</h3></div></div>${rivalTrendHTML(finals)}</article><article class="card card-pad"><div class="section-title compact"><div><span class="eyebrow">Mémoire</span><h3>Anciens rivaux & records</h3></div></div>${renderRivalRecords()}${renderFormerRivals()}</article>`;
  $("#changeRivalBtn").onclick=openRivalPicker;$("#quickRivalCompareBtn").onclick=openRivalQuickCompare;$$(`[data-former-rival]`,root).forEach(b=>b.onclick=()=>openFormerRival(b.dataset.formerRival));
}

function matchdayName(id){return state.matchdays.find(md=>String(md.id)===String(id))?.name||"Journée UEFA";}
function renderRivalDuelRow(d){const rival=state.profileDirectory.get(String(d.rival_user_id));const result=d.finalized_at?(d.result==='win'?'win':d.result==='loss'?'loss':'draw'):'pending';return `<div class="rival-duel-row ${result}"><span>${esc(matchdayName(d.matchday_id))}${d.is_mutual?' · ⚔️ mutuelle':''}</span><strong>${d.finalized_at?`${d.user_points} — ${d.rival_points}`:'À jouer'}</strong><small>${esc(rival?.username||'Rival')} · ${d.finalized_at?(d.result==='win'?'Victoire':d.result==='loss'?'Défaite':'Nul'):'verrouillé'}</small></div>`;}

function renderFormerRivals(){
  const current=state.currentRival?.rival_user_id;const ids=[...new Set((state.rivalChanges||[]).flatMap(c=>[c.old_rival_user_id,c.rival_user_id]).filter(Boolean))].filter(id=>String(id)!==String(current));
  if(!ids.length)return '<div class="empty">Aucun ancien rival pour le moment.</div>';
  return `<div class="former-rivals">${ids.map(id=>{const p=state.profileDirectory.get(String(id));const ds=(state.rivalDuels||[]).filter(d=>String(d.rival_user_id)===String(id)&&d.finalized_at);return `<button type="button" data-former-rival="${id}">${avatarHTML(p||{id,user_id:id,username:'?'})}<span><strong>${esc(p?.username||'Ancien rival')}</strong><small>${ds.filter(d=>d.result==='win').length}V · ${ds.filter(d=>d.result==='draw').length}N · ${ds.filter(d=>d.result==='loss').length}D</small></span></button>`;}).join('')}</div>`;
}

function rivalTrendHTML(finals){
  if(!finals.length)return '<div class="empty">Pas encore assez de duels pour tracer la trajectoire.</div>';
  const rows=finals.slice().reverse();let a=0,b=0;const values=rows.map(d=>{a+=Number(d.user_points||0);b+=Number(d.rival_points||0);return[a,b];});const max=Math.max(1,...values.flat());const w=640,h=180,pad=18;const points=idx=>values.map((v,i)=>`${pad+(i*(w-pad*2)/Math.max(1,values.length-1))},${h-pad-(v[idx]*(h-pad*2)/max)}`).join(' ');
  return `<div class="rival-trend"><svg viewBox="0 0 ${w} ${h}" role="img" aria-label="Évolution cumulée des points en duel"><polyline class="me" points="${points(0)}"></polyline><polyline class="rival" points="${points(1)}"></polyline></svg><div><span>● ${esc(state.profile.username)}</span><span>● ${esc(currentRivalProfile()?.username||'Rival')}</span></div></div>`;
}
function renderRivalRecords(){
  const groups=new Map();for(const d of (state.rivalDuels||[]).filter(x=>x.finalized_at)){const g=groups.get(String(d.rival_user_id))||{id:d.rival_user_id,n:0,w:0,l:0,d:0};g.n++;g[d.result==='win'?'w':d.result==='loss'?'l':'d']++;groups.set(String(d.rival_user_id),g);}const arr=[...groups.values()];if(!arr.length)return '';
  const most=arr.slice().sort((a,b)=>b.n-a.n)[0],nemesis=arr.slice().sort((a,b)=>b.l-a.l)[0],victim=arr.slice().sort((a,b)=>b.w-a.w)[0];const name=x=>state.profileDirectory.get(String(x?.id))?.username||'—';return `<div class="rival-records"><span><small>Le plus affronté</small><strong>${esc(name(most))}</strong></span><span><small>Bête noire</small><strong>${esc(name(nemesis))}</strong></span><span><small>Victime préférée 😈</small><strong>${esc(name(victim))}</strong></span></div>`;
}
function openFormerRival(id){const p=state.profileDirectory.get(String(id));const ds=(state.rivalDuels||[]).filter(d=>String(d.rival_user_id)===String(id)&&d.finalized_at);modal(`Ancienne rivalité · ${p?.username||'Rival'}`,`<div class="former-rival-summary">${avatarHTML(p||{id,user_id:id,username:'?'})}<h3>${esc(p?.username||'Ancien rival')}</h3><p>${ds.filter(d=>d.result==='win').length} victoire(s) · ${ds.filter(d=>d.result==='draw').length} nul(s) · ${ds.filter(d=>d.result==='loss').length} défaite(s)</p>${ds.map(renderRivalDuelRow).join('')||'<div class="empty">Aucun duel finalisé.</div>'}</div>`);}

function openRivalQuickCompare(){
  const rival=currentRivalProfile();if(!rival)return;const mine=leaderboardProfile(state.user.id)||{},his=leaderboardProfile(rival.id)||{};
  modal(`⚔️ ${state.profile.username} vs ${rival.username}`,`<div class="quick-rival-grid"><div>${avatarHTML({...state.profile,user_id:state.user.id})}<strong>${esc(state.profile.username)}</strong><span>${mine.points||0} pts</span><small>${mine.exact_scores||0} exacts · moyenne ${mine.average||0}</small></div><b>VS</b><div>${avatarHTML(rival)}<strong>${esc(rival.username)}</strong><span>${his.points||0} pts</span><small>${his.exact_scores||0} exacts · moyenne ${his.average||0}</small></div></div>`);
}

function openRivalPicker(){
  const md=nextRivalChoiceMatchday();if(!md)return toast("Aucune prochaine journée UEFA disponible pour changer de rival.","error");
  const first=state.allMatches.filter(m=>m.matchday_id===md.id&&m.status!=="cancelled").sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at))[0];
  const players=[...state.profileDirectory.values()].filter(p=>String(p.id)!==String(state.user.id)&&p.status==="active").sort((a,b)=>String(a.username).localeCompare(String(b.username),"fr"));
  const root=modal("Choisir mon rival",`<div class="rival-picker-intro"><p>Choix valable pour <b>${esc(md.name)}</b>. Verrouillage au premier coup d’envoi${first?` : <b>${esc(fmtDate(first.kickoff_at))}</b>`:''}.</p><p class="muted">Un seul changement est autorisé par journée UEFA.</p></div><input id="rivalPickerSearch" type="search" placeholder="Rechercher un joueur…"><div id="rivalPickerList" class="rival-picker-list"></div>`);
  const render=()=>{const q=$("#rivalPickerSearch",root).value.trim().toLowerCase();const box=$("#rivalPickerList",root);const list=players.filter(p=>!q||String(p.username).toLowerCase().includes(q));box.innerHTML=list.map(p=>`<button type="button" data-rival-pick="${p.id}" class="rival-picker-player">${avatarHTML(p)}<span><strong>${esc(p.username)}</strong><small>${esc(p.club_heart||'Club de cœur non indiqué')}</small></span><b>Choisir ⚔️</b></button>`).join('')||'<div class="empty">Aucun joueur.</div>';$$('[data-rival-pick]',box).forEach(b=>b.onclick=()=>chooseRival(md.id,b.dataset.rivalPick));};
  $("#rivalPickerSearch",root).oninput=render;render();
}

async function chooseRival(matchdayId,rivalUserId){
  try{
    if(demoMode){
      const store=demoRivalStore(),key=`${state.season.id}:${state.user.id}`,old=store[key]?.rival_user_id||null;const changes=JSON.parse(localStorage.getItem("nidc_demo_rival_changes")||"[]");if(changes.some(x=>x.season_id===state.season.id&&x.user_id===state.user.id&&x.matchday_id===matchdayId))throw new Error("Tu as déjà changé de rival pour cette journée UEFA.");
      store[key]={season_id:state.season.id,user_id:state.user.id,rival_user_id:rivalUserId,changed_matchday_id:matchdayId,changed_at:new Date().toISOString()};localStorage.setItem("nidc_demo_rivals",JSON.stringify(store));changes.push({id:`rc-${Date.now()}`,season_id:state.season.id,matchday_id:matchdayId,user_id:state.user.id,old_rival_user_id:old,rival_user_id:rivalUserId,changed_at:new Date().toISOString()});localStorage.setItem("nidc_demo_rival_changes",JSON.stringify(changes));
      const targetKey=`nidc_demo_notifications:${rivalUserId}`;const target=JSON.parse(localStorage.getItem(targetKey)||"[]");target.unshift({id:`rn-${Date.now()}`,user_id:rivalUserId,category:"rival",title:"⚔️ Tu as été choisi comme rival",body:`${state.profile.username} t’a dans le viseur pour le Nid.`,importance:"info",deep_link:"rival",created_at:new Date().toISOString(),read_at:null,deleted_at:null});localStorage.setItem(targetKey,JSON.stringify(target));
    }else{const {error}=await sb.rpc("set_my_rival_v060",{p_season_id:state.season.id,p_matchday_id:matchdayId,p_rival_user_id:rivalUserId});if(error)throw error;}
    $("#modalRoot").innerHTML="";await Promise.all([loadRivalData(),loadNotificationData()]);renderRivalView();renderHomeRival();renderNotificationBell();toast("⚔️ Rival enregistré. Il vient d’être prévenu.");
  }catch(err){toast(friendlyError(err),"error");}
}
