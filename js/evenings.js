"use strict";

// Le Nid des Champions V0.8.0 — Soirées européennes
function eveningDates(){
  return [...new Set((state.allMatches||[]).filter(m=>!m.is_test).map(m=>localDateKey(m.kickoff_at)))].sort();
}
function resolveEveningDate(){
  const dates=eveningDates();if(!dates.length)return null;
  if(state.selectedEveningDate&&dates.includes(state.selectedEveningDate))return state.selectedEveningDate;
  const today=localDateKey(new Date().toISOString());if(dates.includes(today))return today;
  const future=dates.find(d=>d>=today);return future||dates[dates.length-1];
}
function eveningDateLabel(date){if(!date)return"Soirée";return new Intl.DateTimeFormat("fr-FR",{weekday:"long",day:"numeric",month:"long",timeZone:"Europe/Paris"}).format(new Date(`${date}T12:00:00+02:00`));}
function eveningMatches(date=resolveEveningDate()){return (state.allMatches||[]).filter(m=>!m.is_test&&localDateKey(m.kickoff_at)===date);}
function eveningStatus(date=resolveEveningDate()){
  const ms=eveningMatches(date);if(!ms.length)return"empty";if(ms.some(m=>m.status==="live"))return"live";if(ms.every(m=>["finished","cancelled"].includes(m.status)))return"finished";if(ms.some(m=>new Date(m.kickoff_at).getTime()<=Date.now()))return"live";return"upcoming";
}
async function loadEveningHubData(force=false){
  if(!state.season||state.eveningLoading)return;const date=resolveEveningDate();state.selectedEveningDate=date;if(!date)return;
  if(state.eveningLoadedDate===date&&!force)return;
  state.eveningLoading=true;state.eveningError=null;
  try{
    if(demoMode){state.eveningRankingRows=buildDemoLeaderboard("evening");state.solitaryLeaderboard=[];state.solitaryEvents=[];state.monthlyPolls=[];state.eveningLoadedDate=date;return;}
    const args={p_season_id:state.season.id,p_scope:"evening",p_matchday_id:null,p_evening_date:date,p_include_live:true};
    const [rank,sol,events,polls]=await Promise.all([
      sb.rpc("get_leaderboard_v040",args),
      sb.rpc("get_hibou_solitaire_leaderboard_v080",{p_season_id:state.season.id}),
      sb.rpc("get_hibou_solitaire_events_v080",{p_season_id:state.season.id,p_evening_date:date}),
      sb.from("monthly_polls").select("id,season_id,month_key,poll_type,title,status,opens_at,closes_at,monthly_poll_candidates(id,label,description,image_url,source_event_id,sort_order,monthly_poll_votes(user_id))").eq("season_id",state.season.id).eq("status","open").order("opens_at",{ascending:false}).limit(4)
    ]);
    if(rank.error)throw rank.error;state.eveningRankingRows=rank.data||[];
    state.solitaryLeaderboard=sol.error?[]:(sol.data||[]);state.solitaryEvents=events.error?[]:(events.data||[]);state.monthlyPolls=polls.error?[]:(polls.data||[]);state.eveningLoadedDate=date;
  }catch(err){state.eveningError=friendlyError(err);state.eveningRankingRows=[];state.solitaryLeaderboard=[];state.solitaryEvents=[];state.monthlyPolls=[];}
  finally{state.eveningLoading=false;}
}
function eveningCompletion(){
  const ms=eveningMatches();const mine=ms.filter(m=>state.predictions.has(m.id)).length;return {mine,total:ms.length};
}
function eveningMyRow(){return (state.eveningRankingRows||[]).find(r=>String(r.user_id)===String(state.user?.id))||null;}
function eveningHibouOfNight(){return (state.eveningRankingRows||[])[0]||null;}
function eveningGamificationEvents(date=resolveEveningDate()){
  const ids=new Set(eveningMatches(date).map(m=>String(m.id)));
  return (state.gamificationEvents||[]).filter(e=>e.match_id&&ids.has(String(e.match_id)));
}
function eveningCollectiveStats(){
  const rows=state.eveningRankingRows||[],events=eveningGamificationEvents();
  const totalPoints=rows.reduce((n,r)=>n+Number(r.points||0),0);
  const totalPredictions=rows.reduce((n,r)=>n+Number(r.played||0),0);
  const exacts=rows.reduce((n,r)=>n+Number(r.exact_scores||0),0);
  const casseroles=events.filter(e=>e.event_type==="casserole");
  const genius=events.filter(e=>e.event_type==="genius");
  const topExact=[...rows].sort((a,b)=>Number(b.exact_scores||0)-Number(a.exact_scores||0)||Number(b.points||0)-Number(a.points||0))[0]||null;
  return {players:rows.length,totalPoints,totalPredictions,exacts,avgPoints:rows.length?totalPoints/rows.length:0,casseroles,genius,solitary:state.solitaryEvents||[],topExact};
}
function eveningStatsHTML(){
  const s=eveningCollectiveStats();
  return `<section class="evening-stats"><div class="section-title compact"><div><span class="eyebrow">Le Nid en chiffres</span><h3>Statistiques de la soirée</h3></div></div><div class="evening-stat-grid"><span><b>${s.players}</b><small>joueurs classés</small></span><span><b>${s.totalPredictions}</b><small>pronostics</small></span><span><b>${s.exacts}</b><small>scores exacts</small></span><span><b>${s.avgPoints.toFixed(1)}</b><small>pts / joueur</small></span><span><b>${s.casseroles.length}</b><small>🍳 casseroles</small></span><span><b>${s.genius.length}</b><small>✨ coups de Génie</small></span><span><b>${s.solitary.length}</b><small>🦉 choix solitaires</small></span></div></section>`;
}
function eveningMomentsHTML(){
  const s=eveningCollectiveStats(),owl=eveningHibouOfNight();
  const biggestCasserole=[...s.casseroles].sort((a,b)=>Number(b.points||0)-Number(a.points||0))[0];
  const biggestGenius=[...s.genius].sort((a,b)=>Number(b.points||0)-Number(a.points||0))[0];
  const solitary=[...s.solitary].sort((a,b)=>Number(b.solitary_points||0)-Number(a.solitary_points||0))[0];
  const owner=e=>e?state.profileDirectory.get(String(e.user_id))?.username||"Un joueur":null;
  const cards=[];
  if(owl)cards.push(`<article><span>🌙</span><small>Hibou de la nuit</small><strong>${esc(owl.username)}</strong><p>${Number(owl.points||0)} pts · ${Number(owl.exact_scores||0)} exact(s)</p></article>`);
  if(biggestGenius)cards.push(`<article><span>✨</span><small>Coup de Génie</small><strong>${esc(owner(biggestGenius))}</strong><p>+${Number(biggestGenius.points||0)} · ${esc(biggestGenius.title||"Le Nid n'avait pas vu venir ça")}</p></article>`);
  if(biggestCasserole)cards.push(`<article><span>🍳</span><small>Casserole de la soirée</small><strong>${esc(owner(biggestCasserole))}</strong><p>${Number(biggestCasserole.points||0)} pts casserole · ${esc(biggestCasserole.title||"Ça résonne encore")}</p></article>`);
  if(solitary)cards.push(`<article><span>🦉</span><small>Seul contre le Nid</small><strong>${esc(solitary.username||"Hibou solitaire")}</strong><p>+${Number(solitary.solitary_points||0)} · choix partagé par ${Number(solitary.group_count||0)}/${Number(solitary.total_predictions||0)}</p></article>`);
  if(s.topExact&&Number(s.topExact.exact_scores||0)>0)cards.push(`<article><span>🎯</span><small>Œil de la soirée</small><strong>${esc(s.topExact.username)}</strong><p>${Number(s.topExact.exact_scores||0)} score(s) exact(s)</p></article>`);
  return `<section class="evening-moments"><div class="section-title compact"><div><span class="eyebrow gold">Le film de la nuit</span><h3>Moments du Nid</h3></div></div><div class="evening-moment-track">${cards.join("")||'<div class="empty">Les moments forts apparaîtront au fil de la soirée.</div>'}</div></section>`;
}
function eveningPersonalNarrative(row,status){
  if(status==="upcoming"){const c=eveningCompletion();return narrativeText("evening_before",{player:state.profile?.username||"Joueur",played:c.mine,total:c.total,missing:Math.max(0,c.total-c.mine)},`${c.mine}/${c.total} pronostics prêts. Le Nid attend le reste.`);}
  if(status==="live")return narrativeText("evening_live",{player:state.profile?.username||"Joueur",points:Number(row?.points||0),rank:Number(row?.rank||0)},`${Number(row?.points||0)} points pour l’instant. Rien n’est encore rangé au Musée.`);
  const points=Number(row?.points||0),exacts=Number(row?.exact_scores||0),rank=Number(row?.rank||0);const key=points>=25?"summary_good":points>=10?"summary_neutral":"summary_bad";
  return narrativeText(key,{player:state.profile?.username||"Joueur",points,exacts,rank,rank_delta:Number(row?.variation||0)},`${points} points, ${exacts} exact(s), rang #${rank||'—'}. Le Hibou archive la soirée.`);
}
function eveningHeroHTML(){
  const date=resolveEveningDate(),status=eveningStatus(date),ms=eveningMatches(date),row=eveningMyRow(),completion=eveningCompletion();const live=ms.filter(m=>m.status==="live").length;
  const title=status==="live"?`${live||ms.length} match${(live||ms.length)>1?'s':''} en cours`:status==="finished"?`${Number(row?.points||0)} points ce soir`:`${completion.mine}/${completion.total} pronostics enregistrés`;
  return `<div class="evening-hero card card-pad ${status}"><div><span class="eyebrow gold">V0.8.0 · Soirée européenne</span><h2>🌙 ${esc(eveningDateLabel(date))}</h2><h3>${esc(title)}</h3><p>🦉 « ${esc(eveningPersonalNarrative(row,status))} »</p></div><div class="evening-hero-kpis"><span><b>${ms.length}</b><small>matchs</small></span><span><b>${row?`#${Number(row.rank||0)}`:'—'}</b><small>${status==='finished'?'rang soirée':'rang provisoire'}</small></span><span><b>${Number(row?.exact_scores||0)}</b><small>exacts</small></span></div></div>`;
}
function eveningLeaderboardHTML(){
  const rows=state.eveningRankingRows||[];const owl=eveningHibouOfNight();
  return `<div class="evening-award card card-pad"><span class="eyebrow gold">🦉 Hibou de la nuit</span>${owl?`<div class="evening-winner">${avatarHTML(owl)}<div><h3>${esc(owl.username)}</h3><p>#1 de la soirée · <b>${Number(owl.points||0)} pts</b> · ${Number(owl.exact_scores||0)} exact(s)</p></div></div>`:'<div class="empty">La nuit n’a pas encore choisi son Hibou.</div>'}</div>${eveningStatsHTML()}${eveningMomentsHTML()}<div class="card card-pad"><div class="section-title compact"><div><h3>Classement de la soirée</h3><p>Un classement indépendant de la journée UEFA.</p></div></div><div class="evening-rank-list">${rows.slice(0,12).map((r,i)=>`<div class="evening-rank-row ${String(r.user_id)===String(state.user?.id)?'me':''}"><b>#${i+1}</b>${avatarHTML(r)}<span><strong>${esc(r.username)}</strong><small>${Number(r.exact_scores||0)} exact(s) · ${Number(r.precision_pct||0).toFixed(1)}%</small></span><strong>${Number(r.points||0)} pts</strong></div>`).join('')||'<div class="empty">Le classement apparaîtra dès les premiers pronostics verrouillés.</div>'}</div></div>`;
}
function solitaryHTML(){
  const rows=state.solitaryLeaderboard||[],events=state.solitaryEvents||[];
  return `<div class="grid grid-2"><article class="card card-pad"><span class="eyebrow gold">🦉 Seul contre le Nid</span><h3>Hibou solitaire</h3><p class="muted">10 pts si tu es seul, 7 pts à deux, 5 pts si ton choix représente au plus 5 % du Nid. Ces points n’entrent jamais dans le classement officiel.</p><div class="evening-rank-list">${rows.slice(0,10).map((r,i)=>`<div class="evening-rank-row"><b>#${i+1}</b>${avatarHTML(r)}<span><strong>${esc(r.username)}</strong><small>${Number(r.successes||0)} réussite(s)</small></span><strong>${Number(r.solitary_points||0)} 🦉</strong></div>`).join('')||'<div class="empty">Aucun Hibou solitaire victorieux pour le moment.</div>'}</div></article><article class="card card-pad"><span class="eyebrow">Cette soirée</span><h3>Les choix qui ont tenu seuls</h3><div class="solitary-event-list">${events.map(e=>{const m=(state.allMatches||[]).find(x=>String(x.id)===String(e.match_id));return `<div><b>+${Number(e.solitary_points||0)}</b><span><strong>${esc(e.username)}</strong><small>${esc(m?`${m.home_club?.short_name||'?'} – ${m.away_club?.short_name||'?'}`:'Match')} · groupe ${Number(e.group_count||0)}/${Number(e.total_predictions||0)}</small></span></div>`;}).join('')||'<div class="empty">Aucun exploit solitaire sur cette soirée.</div>'}</div></article></div>`;
}
function eveningArchiveHTML(){
  const dates=eveningDates().slice().reverse();return `<div class="evening-archive">${dates.map(d=>{const ms=eveningMatches(d);const status=eveningStatus(d);return `<button data-evening-date="${esc(d)}" class="card ${d===state.selectedEveningDate?'active':''}"><span><b>${esc(eveningDateLabel(d))}</b><small>${ms.length} match${ms.length>1?'s':''}</small></span><span class="chip">${status==='finished'?'Terminé':status==='live'?'LIVE':'À venir'}</span></button>`;}).join('')||'<div class="empty">Aucune soirée au calendrier.</div>'}</div>`;
}
function monthlyPollsHTML(){
  const polls=state.monthlyPolls||[];return `<div class="monthly-polls">${polls.map(p=>`<article class="card card-pad"><span class="eyebrow">🗳️ ${p.poll_type==='casserole'?'Casserole du mois':'Coup de Génie du mois'}</span><h3>${esc(p.title)}</h3><div class="poll-candidates">${(p.monthly_poll_candidates||[]).sort((a,b)=>Number(a.sort_order||0)-Number(b.sort_order||0)).map(c=>{const votes=c.monthly_poll_votes||[];const mine=votes.some(v=>String(v.user_id)===String(state.user?.id));return `<button data-vote-candidate="${esc(c.id)}" class="${mine?'selected':''}"><span><strong>${esc(c.label)}</strong><small>${esc(c.description||'')}</small></span><b>${votes.length} vote${votes.length>1?'s':''}</b></button>`;}).join('')||'<div class="empty">Les candidats arrivent bientôt.</div>'}</div></article>`).join('')||'<article class="card card-pad"><div class="empty">Aucun vote mensuel ouvert pour le moment.</div></article>'}</div>`;
}
async function castMonthlyVote(candidateId){
  if(demoMode)return toast("Vote enregistré en mode démo.");const poll=(state.monthlyPolls||[]).find(p=>(p.monthly_poll_candidates||[]).some(c=>String(c.id)===String(candidateId)));if(!poll)return;
  const {error}=await sb.rpc("cast_monthly_vote_v080",{p_poll_id:poll.id,p_candidate_id:candidateId});if(error)return toast(friendlyError(error),"error");await loadEveningHubData(true);renderEveningHub();toast("🗳️ Vote enregistré.");
}
function renderEveningHub(){
  const root=$("#eveningHubRoot");if(!root)return;if(state.eveningLoading){root.innerHTML='<article class="card card-pad"><div class="empty">Le Hibou recompte la soirée…</div></article>';return;}
  const tab=state.eveningTab||"summary";root.innerHTML=`${eveningHeroHTML()}${state.eveningError?`<div class="ucl-warning">⚠ ${esc(state.eveningError)}</div>`:''}<div class="evening-tabs"><button data-evening-tab="summary" class="${tab==='summary'?'active':''}">Résumé</button><button data-evening-tab="solitary" class="${tab==='solitary'?'active':''}">Hibou solitaire</button><button data-evening-tab="archive" class="${tab==='archive'?'active':''}">Archives</button><button data-evening-tab="votes" class="${tab==='votes'?'active':''}">Votes mensuels</button></div><div id="eveningTabBody">${tab==='summary'?eveningLeaderboardHTML():tab==='solitary'?solitaryHTML():tab==='archive'?eveningArchiveHTML():monthlyPollsHTML()}</div>`;
  $$('[data-evening-tab]',root).forEach(b=>b.onclick=()=>{state.eveningTab=b.dataset.eveningTab;renderEveningHub();});
  $$('[data-evening-date]',root).forEach(b=>b.onclick=async()=>{state.selectedEveningDate=b.dataset.eveningDate;state.eveningLoadedDate=null;await loadEveningHubData(true);renderEveningHub();});
  $$('[data-vote-candidate]',root).forEach(b=>b.onclick=()=>castMonthlyVote(b.dataset.voteCandidate));
}

function renderHomeEveningCard(){
  const root=$("#homeEveningCard");if(!root)return;const date=resolveEveningDate();if(!date){root.classList.add("hidden");return;}
  const ms=eveningMatches(date);if(!ms.length){root.classList.add("hidden");return;}
  const status=eveningStatus(date),now=Date.now(),times=ms.map(m=>new Date(m.kickoff_at).getTime()).filter(Number.isFinite),first=Math.min(...times),last=Math.max(...times);
  const contextual=status==="live"||(status==="upcoming"&&first-now<=36*3600000)||(status==="finished"&&now-last<=48*3600000);
  root.classList.toggle("hidden",!contextual);if(!contextual)return;
  if((status==="live"||status==="finished")&&state.eveningLoadedDate!==date&&!state.eveningLoading){loadEveningHubData().then(()=>renderHomeEveningCard()).catch(()=>{});}
  const row=state.eveningLoadedDate===date?eveningMyRow():null,completion=eveningCompletion(),owl=state.eveningLoadedDate===date?eveningHibouOfNight():null;
  const label=status==="live"?"🔴 La soirée est LIVE":status==="finished"?"🌙 La soirée est terminée":"🌙 Ce soir dans le Nid";
  const headline=status==="live"?`${Number(row?.points||0)} pts · ${row?`#${Number(row.rank||0)} provisoire`:"classement en cours"}`:status==="finished"?`${Number(row?.points||0)} pts${row?` · #${Number(row.rank||0)} de la soirée`:""}`:`${completion.mine}/${completion.total} pronostics prêts`;
  const detail=status==="finished"&&owl?`Hibou de la nuit : ${owl.username} · ${Number(owl.points||0)} pts`:status==="upcoming"?`${Math.max(0,completion.total-completion.mine)} pronostic(s) restent à saisir.`:`${ms.filter(m=>m.status==="live").length||ms.length} match(s) en cours.`;
  root.innerHTML=`<div><span class="eyebrow gold">${esc(label)}</span><h3>${esc(headline)}</h3><p>${esc(detail)}</p></div><button id="homeOpenEveningBtn" class="btn gold small">Ouvrir la soirée</button>`;
  $("#homeOpenEveningBtn",root).onclick=()=>setView("evenings");
}

async function renderAdminMonthlyPollPanel(){
  const root=$("#adminMonthlyPollPanel");if(!root)return;if(state.profile?.role!=="super_admin"){root.classList.add("hidden");return;}root.classList.remove("hidden");
  if(demoMode){root.innerHTML='<span class="eyebrow">🗳️ Votes mensuels</span><h3>Mode démo</h3><p class="muted">La création réelle des votes est disponible avec Supabase.</p>';return;}
  const {data:polls,error}=await sb.from("monthly_polls").select("id,month_key,poll_type,title,status,opens_at,closes_at,monthly_poll_candidates(id)").eq("season_id",state.season.id).order("month_key",{ascending:false}).limit(8);
  if(error){root.innerHTML=`<div class="ucl-warning">Migration V0.8.0 requise : ${esc(friendlyError(error))}</div>`;return;}
  const now=new Date();const month=`${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-01`;
  root.innerHTML=`<div class="admin-subhead"><div><span class="eyebrow gold">🗳️ V0.8.0</span><h4>Votes mensuels</h4><p>Le Hibou peut préparer automatiquement jusqu’à 5 candidats depuis les Casseroles ou les Coups de Génie du mois.</p></div></div><div class="grid grid-3"><div class="field"><label>Mois</label><input id="monthlyPollMonth" type="month" value="${month.slice(0,7)}"></div><div class="field"><label>Type</label><select id="monthlyPollType"><option value="casserole">Casserole du mois</option><option value="genius">Coup de Génie du mois</option></select></div><div class="field"><label>Durée du vote</label><select id="monthlyPollDays"><option value="3">3 jours</option><option value="5">5 jours</option><option value="7" selected>7 jours</option></select></div></div><div class="actions"><button id="createMonthlyPollBtn" class="btn gold small">Préparer et ouvrir le vote</button></div><div id="monthlyPollMsg" class="form-msg"></div><div class="evening-rank-list" style="margin-top:12px">${(polls||[]).map(p=>`<div class="evening-rank-row"><b>${p.poll_type==='casserole'?'🍳':'✨'}</b><span style="grid-column:2/4"><strong>${esc(p.title)}</strong><small>${esc(p.month_key)} · ${(p.monthly_poll_candidates||[]).length} candidat(s) · ${esc(p.status)}</small></span>${p.status==='open'?`<button class="btn secondary small" data-close-monthly-poll="${p.id}">Fermer</button>`:'<span class="chip">Clos</span>'}</div>`).join('')||'<div class="empty">Aucun vote créé.</div>'}</div>`;
  $("#createMonthlyPollBtn",root).onclick=async()=>{
    const ym=$("#monthlyPollMonth",root).value,type=$("#monthlyPollType",root).value,days=Number($("#monthlyPollDays",root).value||7);if(!ym)return;
    const start=new Date(`${ym}-01T00:00:00+02:00`),end=new Date(start);end.setMonth(end.getMonth()+1);
    const candidates=(state.gamificationEvents||[]).filter(e=>e.event_type===type&&new Date(e.created_at)>=start&&new Date(e.created_at)<end).sort((a,b)=>Number(b.points||0)-Number(a.points||0)||new Date(b.created_at)-new Date(a.created_at)).slice(0,5).map(e=>({source_event_id:e.id,label:e.title||(type==='casserole'?'Casserole':'Coup de Génie'),description:e.message||'',image_url:e.media_url||null}));
    if(candidates.length<2)return setMsg("#monthlyPollMsg","Il faut au moins 2 événements ce mois-ci pour ouvrir un vote.","error");
    const closes=new Date(Date.now()+days*86400000).toISOString();const title=type==='casserole'?`Casserole du mois · ${ym}`:`Coup de Génie du mois · ${ym}`;
    const {error}=await sb.rpc("admin_create_monthly_poll_v080",{p_season_id:state.season.id,p_month_key:`${ym}-01`,p_poll_type:type,p_title:title,p_candidates:candidates,p_opens_at:new Date().toISOString(),p_closes_at:closes});if(error)return setMsg("#monthlyPollMsg",friendlyError(error),"error");setMsg("#monthlyPollMsg","Vote ouvert.","ok");state.eveningLoadedDate=null;await renderAdminMonthlyPollPanel();
  };
  $$('[data-close-monthly-poll]',root).forEach(b=>b.onclick=async()=>{const {error}=await sb.rpc("admin_close_monthly_poll_v080",{p_poll_id:b.dataset.closeMonthlyPoll});if(error)return toast(friendlyError(error),"error");await renderAdminMonthlyPollPanel();toast("Vote mensuel fermé.");});
}
