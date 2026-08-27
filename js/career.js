"use strict";

// Le Nid des Champions V0.9.0 — saison, carrière, mémoire, Hall of Fame et sondages

function resetSeasonBoundStateV090(){
  state.selectedMatchdayId=null;state.matches=[];state.allMatches=[];state.adminAllMatches=[];state.adminAllMatchdays=[];
  state.predictions=new Map();state.tiePredictions=new Map();state.knockoutTies=[];state.championStatus=null;state.championCandidates={1:[],2:[]};state.championBoards={1:[],2:[]};
  state.rankingRows=[];state.standings=[];state.collectiveStats=null;state.selectedEveningDate=null;
  state.myTeam=null;state.teamMembers=[];state.teamEvents=[];state.teamRequests=[];state.teamInvite=null;state.teamLeaderboardRows=[];
  state.currentRival=null;state.rivalDuels=[];state.rivalChanges=[];state.rivalSummary=null;
  state.museumSummary=null;state.gamificationEvents=[];state.gamificationRecords=[];state.gamificationLoadedOnce=false;
  state.uclMatches=[];state.uclStandings=[];state.uclCenterLoaded=false;state.uclCenterError=null;
  state.eveningRankingRows=[];state.solitaryLeaderboard=[];state.solitaryEvents=[];state.monthlyPolls=[];state.eveningLoadedDate=null;state.eveningError=null;
  state.seasonProfileStats=null;state.playerCareer=null;state.hallOfFame=[];state.seasonReplay=[];state.generalPolls=[];state.titleHolder=null;state.seasonMemoryLoaded=false;state.seasonMemoryError=null;
  if(typeof resetFinalSeasonDataV098==="function")resetFinalSeasonDataV098();
}

async function switchSeasonV090(slug){
  if(!slug||slug===state.season?.slug)return;
  try{
    state.selectedSeasonSlug=slug;resetSeasonBoundStateV090();
    await loadData();
    if(typeof loadGamificationData==="function")await loadGamificationData();
    if(typeof loadAdminGamificationData==="function"&&state.profile?.role==="super_admin")await loadAdminGamificationData();
    await loadSeasonMemoryData(true);
    renderAll();setupRealtime();setView("season");toast(`Saison chargée : ${state.season?.name||slug}`);
  }catch(err){toast(friendlyError(err),"error");}
}

function demoSeasonMemoryV090(){
  const lb=buildDemoLeaderboard("general");const mine=lb.find(r=>r.user_id===state.user?.id)||lb[0]||{};
  state.seasonProfileStats={...mine,qualifier_successes:0,forgotten:0,casseroles:0,casserole_points:0,genius:0,genius_points:0,solitary_successes:0,solitary_points:0,records:0,badges:0,best_rank:mine.rank||1,worst_rank:mine.rank||1,biggest_climb:0,biggest_drop:0,days_in_lead:mine.rank===1?1:0,form:[],rank_history:[],distinctions:[]};
  state.careerLeaderboard=lb.map((r,i)=>({rank:i+1,...r,seasons_played:1,total_points:r.points,total_played:r.played,career_average:r.average,podiums:i<3?1:0,titles:i===0?1:0,badges:0,records:0}));
  state.playerCareer={summary:state.careerLeaderboard.find(r=>r.user_id===state.user?.id)||{},seasons:[{season_id:state.season.id,season:state.season.name,slug:state.season.slug,status:state.season.status,rank:mine.rank,points:mine.points,played:mine.played,average:mine.average,exacts:mine.exact_scores,precision:mine.precision_pct}],distinctions:[],historical_records:[]};
  state.hallOfFame=lb.slice(0,3).map((r,i)=>({season_id:state.season.id,season_name:state.season.name,category:"podium",position:i+1,user_id:r.user_id,username:r.username,value:r.points,label:i===0?"Champion":i===1?"Vice-champion":"Troisième",metadata:{}}));
  state.seasonReplay=[];state.generalPolls=[];state.titleHolder=null;
}

async function loadSeasonMemoryData(force=false){
  if(state.seasonMemoryLoading||(!force&&state.seasonMemoryLoaded))return;
  if(!state.season)return;
  state.seasonMemoryLoading=true;state.seasonMemoryError=null;
  try{
    if(demoMode){demoSeasonMemoryV090();state.seasonMemoryLoaded=true;return;}
    // Une photographie quotidienne est idempotente. Les archives restent figées.
    if(!["finished","archived"].includes(state.season.status)){
      const snapshot=await sb.rpc("capture_season_snapshot_v090",{p_season_id:state.season.id,p_snapshot_key:null,p_source:"frontend_daily"});
      if(snapshot.error)console.warn("Snapshot V0.9.0 non bloquant",snapshot.error);
    }
    const [profile,careerBoard,career,hall,replay,polls,title]=await Promise.all([
      sb.rpc("get_player_season_profile_v090",{p_season_id:state.season.id,p_user_id:state.user?.id}),
      sb.rpc("get_career_leaderboard_v090",{}),
      sb.rpc("get_player_career_v090",{p_user_id:state.user?.id}),
      sb.rpc("get_hall_of_fame_v090",{p_season_id:null}),
      sb.rpc("get_season_replay_v090",{p_season_id:state.season.id}),
      sb.from("polls").select("id,season_id,title,question,status,opens_at,closes_at,allow_change,show_results_before_close,poll_options(id,label,description,sort_order,poll_votes(user_id))").or(`season_id.eq.${state.season.id},season_id.is.null`).in("status",["open","closed"]).order("opens_at",{ascending:false}),
      sb.rpc("get_title_holder_v090",{p_season_id:state.season.id})
    ]);
    if(profile.error)throw profile.error;if(careerBoard.error)throw careerBoard.error;if(career.error)throw career.error;if(hall.error)throw hall.error;if(replay.error)throw replay.error;if(polls.error)throw polls.error;if(title.error)throw title.error;
    state.seasonProfileStats=profile.data?.[0]||null;state.careerLeaderboard=careerBoard.data||[];state.playerCareer=career.data||null;
    state.hallOfFame=hall.data||[];state.seasonReplay=replay.data||[];state.generalPolls=polls.data||[];state.titleHolder=title.data?.[0]||null;state.seasonMemoryLoaded=true;
  }catch(err){state.seasonMemoryError=friendlyError(err);console.warn("V0.9.0 mémoire",err);}finally{state.seasonMemoryLoading=false;}
}

function seasonStatusCopyV090(status){return({preparation:"Préparation",active:"En cours",finished:"Terminée",archived:"Archivée"}[status]||status||"—");}
function fmtCareerNumberV090(v,d=0){return Number(v||0).toLocaleString("fr-FR",{minimumFractionDigits:d,maximumFractionDigits:d});}
function formHTMLV090(form=[]){const map={exact:["🎯","Exact"],difference:["🟢","Écart"],result:["✓","Résultat"],miss:["·","Raté"]};return `<div class="career-form">${(form||[]).map(x=>{const m=map[x.result]||["·",x.result];return `<span class="form-${esc(x.result)}" title="${esc(m[1])} · ${Number(x.points||0)} pts">${m[0]}</span>`;}).join("")||'<span class="muted">Pas encore de forme récente.</span>'}</div>`;}

function rankSparklineV090(history=[]){
  const rows=(history||[]).filter(x=>Number.isFinite(Number(x.rank)));if(rows.length<2)return '<div class="career-spark-empty">L’historique se construira au fil des résultats.</div>';
  const w=620,h=150,pad=14,max=Math.max(...rows.map(x=>Number(x.rank)),3),min=Math.min(...rows.map(x=>Number(x.rank)),1),span=Math.max(1,max-min);
  const pts=rows.map((x,i)=>`${pad+(i*(w-pad*2)/Math.max(1,rows.length-1))},${pad+((Number(x.rank)-min)*(h-pad*2)/span)}`).join(" ");
  return `<svg class="career-rank-chart" viewBox="0 0 ${w} ${h}" role="img" aria-label="Évolution du rang"><polyline points="${pts}" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/><text x="${pad}" y="${h-4}">meilleur #${min}</text><text x="${w-110}" y="${h-4}">actuel #${rows.at(-1).rank}</text></svg>`;
}

function seasonOverviewHTMLV090(){
  const p=state.seasonProfileStats||{};const title=state.titleHolder;const distinctions=p.distinctions||[];
  return `<div class="season-memory-overview">
    ${title?`<article class="memory-banner champion-holder"><span>🏆</span><div><span class="eyebrow gold">Champion en titre</span><h3>${esc(title.username)}</h3><p>Champion ${esc(title.source_season_name||"de la saison précédente")}</p></div></article>`:""}
    ${state.seasonMemoryError?`<div class="ucl-warning">⚠ ${esc(state.seasonMemoryError)} · Exécute HOTFIX_V0.9.0_EXISTING_DB.sql si la migration n’est pas encore installée.</div>`:""}
    <div class="career-stat-grid">
      <article><span>Rang</span><strong>#${p.rank||"—"}</strong><small>meilleur #${p.best_rank||"—"}</small></article>
      <article><span>Points</span><strong>${fmtCareerNumberV090(p.points)}</strong><small>${fmtCareerNumberV090(p.average,2)} / match</small></article>
      <article><span>Précision</span><strong>${fmtCareerNumberV090(p.precision_pct,1)}%</strong><small>${Number(p.exact_scores||0)} exacts</small></article>
      <article><span>Remontée max</span><strong>+${Number(p.biggest_climb||0)}</strong><small>chute max −${Number(p.biggest_drop||0)}</small></article>
      <article><span>En tête</span><strong>${fmtCareerNumberV090(p.days_in_lead,1)} j</strong><small>mémoire du classement</small></article>
      <article><span>Oublis</span><strong>${Number(p.forgotten||0)}</strong><small>${Number(p.played||0)} pronostics joués</small></article>
      <article><span>Génie</span><strong>${Number(p.genius_points||0)}</strong><small>${Number(p.genius||0)} événement(s)</small></article>
      <article><span>Hibou solitaire</span><strong>${Number(p.solitary_points||0)}</strong><small>${Number(p.solitary_successes||0)} réussite(s)</small></article>
    </div>
    <div class="grid grid-2 career-detail-grid">
      <article class="card card-pad"><span class="eyebrow">Forme récente</span><h3>Les 5 derniers verdicts</h3>${formHTMLV090(p.form)}</article>
      <article class="card card-pad"><span class="eyebrow">Mémoire du rang</span><h3>La courbe de la saison</h3>${rankSparklineV090(p.rank_history)}</article>
    </div>
    ${distinctions.length?`<article class="card card-pad"><span class="eyebrow gold">Distinctions permanentes</span><div class="distinction-list">${distinctions.map(d=>`<span><b>${esc(d.icon||"🏆")}</b><span><strong>${esc(d.label)}</strong><small>${esc(d.description||"")}</small></span></span>`).join("")}</div></article>`:""}
  </div>`;
}

function careerLeaderboardHTMLV090(){
  const rows=state.careerLeaderboard||[];const mine=rows.find(r=>String(r.user_id)===String(state.user?.id));
  return `<div class="career-summary-band">${mine?`<span><small>Ton rang carrière</small><b>#${mine.rank}</b></span><span><small>Points carrière</small><b>${fmtCareerNumberV090(mine.total_points)}</b></span><span><small>Saisons</small><b>${mine.seasons_played}</b></span><span><small>Moyenne</small><b>${fmtCareerNumberV090(mine.career_average,2)}</b></span>`:'<span class="muted">La carrière commencera avec les premiers résultats.</span>'}</div>
  <article class="card table-wrap"><table class="ranking career-ranking"><thead><tr><th>#</th><th>Joueur</th><th>Saisons</th><th>Points</th><th>Moy.</th><th>Exacts</th><th>Podiums</th><th>Titres</th></tr></thead><tbody>${rows.map(r=>`<tr class="${String(r.user_id)===String(state.user?.id)?'me':''}"><td><b>#${r.rank}</b></td><td><div class="player-cell">${avatarHTML(r)}<button class="player-profile-link" data-player-profile="${r.user_id}">${esc(r.username)}</button></div></td><td>${r.seasons_played}</td><td><b>${fmtCareerNumberV090(r.total_points)}</b></td><td>${fmtCareerNumberV090(r.career_average,2)}</td><td>${r.exact_scores}</td><td>${r.podiums}</td><td>${r.titles}</td></tr>`).join("")||'<tr><td colspan="8" class="empty">Pas encore de classement carrière.</td></tr>'}</tbody></table></article>`;
}

function hallOfFameHTMLV090(){
  const all=state.hallOfFame||[];const seasons=state.availableSeasons||[];
  if(!all.length)return '<article class="card card-pad"><div class="empty">Le Hall of Fame attend ses premiers héros.</div></article>';
  const labels={podium:"Podium",best_score:"Meilleur scoreur",best_exact:"Scores exacts",poele_or:"Poêle d’Or",genius:"Génie",solitary:"Hibou solitaire",team:"Meilleure Team",record:"Record du Nid"};
  return `<div class="hall-seasons">${seasons.map(s=>{const rows=all.filter(x=>String(x.season_id)===String(s.id));if(!rows.length)return"";return `<section class="hall-season card card-pad"><div class="hall-season-head"><div><span class="eyebrow gold">${esc(seasonStatusCopyV090(s.status))}</span><h3>${esc(s.name)}</h3></div><span class="chip">Mémoire du Nid</span></div><div class="hall-grid">${rows.map(r=>`<article class="hall-entry hall-${esc(r.category)}"><span>${r.category==='podium'?(r.position===1?'🥇':r.position===2?'🥈':'🥉'):r.category==='best_score'?'📊':r.category==='poele_or'?'🍳':r.category==='genius'?'✨':r.category==='solitary'?'🦉':r.category==='team'?'🛡':r.category==='record'?'📈':'🎯'}</span><div><small>${esc(labels[r.category]||r.category)}</small><strong>${esc(r.username||r.label||'—')}</strong><em>${esc(r.label||'')}${r.value!=null?` · ${fmtCareerNumberV090(r.value,Number(r.value)%1?1:0)}`:''}</em></div></article>`).join("")}</div></section>`;}).join("")}</div>`;
}

function replayHTMLV090(){
  const rows=state.seasonReplay||[];if(!rows.length)return '<article class="card card-pad"><div class="empty">Le replay se construira avec les changements de leader, records, casseroles, badges légendaires et phases finales.</div></article>';
  return `<div class="season-replay">${rows.map(e=>`<article class="replay-event"><div class="replay-icon">${esc(e.icon||'🦉')}</div><div><time>${esc(new Intl.DateTimeFormat('fr-FR',{day:'2-digit',month:'long',year:'numeric',timeZone:'Europe/Paris'}).format(new Date(e.event_at)))}</time><h4>${esc(e.title)}</h4><p>${esc(e.subtitle||e.username||'')}</p></div></article>`).join("")}</div>`;
}

function pollsHTMLV090(){
  const polls=state.generalPolls||[];return `<div class="general-polls">${polls.map(p=>{const options=(p.poll_options||[]).sort((a,b)=>Number(a.sort_order||0)-Number(b.sort_order||0));const total=options.reduce((n,o)=>n+(o.poll_votes||[]).length,0);return `<article class="card card-pad general-poll"><div class="poll-head"><div><span class="eyebrow">🗳️ Sondage du Nid</span><h3>${esc(p.title)}</h3><p>${esc(p.question)}</p></div><span class="chip">${p.status==='open'?'OUVERT':'CLOS'}</span></div><div class="poll-candidates">${options.map(o=>{const votes=o.poll_votes||[],mine=votes.some(v=>String(v.user_id)===String(state.user?.id)),pctv=total?Math.round(votes.length*100/total):0;return `<button type="button" data-general-poll-option="${o.id}" data-poll-id="${p.id}" class="${mine?'selected':''}" ${p.status==='open'?'':'disabled'}><span><strong>${esc(o.label)}</strong><small>${esc(o.description||'')}</small></span><b>${(p.show_results_before_close||p.status!=='open')?`${pctv}% · ${votes.length}`:(mine?'Ton vote':'Choisir')}</b></button>`;}).join("")}</div><small class="muted">${total} vote${total>1?'s':''}${p.closes_at?` · fermeture ${fmtDate(p.closes_at)}`:''}</small></article>`;}).join("")||'<article class="card card-pad"><div class="empty">Aucun sondage général ouvert ou archivé pour cette saison.</div></article>'}</div>`;
}

async function castGeneralPollVoteV090(pollId,optionId){
  if(demoMode)return toast("Vote enregistré en mode démo.");
  const {error}=await sb.rpc("cast_poll_vote_v090",{p_poll_id:pollId,p_option_id:optionId});if(error)return toast(friendlyError(error),"error");
  state.seasonMemoryLoaded=false;await loadSeasonMemoryData(true);renderSeasonMemory();toast("🗳️ Vote enregistré.");
}

function renderSeasonMemory(){
  const root=$("#seasonMemoryRoot");if(!root)return;
  const seasons=state.availableSeasons||[];const tab=state.seasonMemoryTab||"overview";
  const archived=["finished","archived"].includes(state.season?.status);
  root.innerHTML=`<div class="season-memory-head card card-pad"><div><span class="eyebrow gold">V0.9.0 · Saison, carrière & mémoire</span><h2>Le temps long du Nid</h2><p>Une saison se joue. Une carrière se raconte.</p>${archived?'<span class="season-readonly-chip">🔒 Archive en lecture seule</span>':state.season?.is_active?'<span class="season-active-chip">● Saison active</span>':''}</div><label class="season-switcher"><span>Saison affichée</span><select id="seasonSwitcherV090">${seasons.map(s=>`<option value="${esc(s.slug)}" ${s.slug===state.season?.slug?'selected':''}>${esc(s.name)} · ${esc(seasonStatusCopyV090(s.status))}${s.is_active?' · ACTIVE':''}</option>`).join("")}</select></label></div>
  <div class="season-memory-tabs"><button data-memory-tab="overview" class="${tab==='overview'?'active':''}">Ma saison</button><button data-memory-tab="career" class="${tab==='career'?'active':''}">Carrière</button><button data-memory-tab="hall" class="${tab==='hall'?'active':''}">Hall of Fame</button><button data-memory-tab="replay" class="${tab==='replay'?'active':''}">Replay</button><button data-memory-tab="polls" class="${tab==='polls'?'active':''}">Sondages</button></div>
  <div id="seasonMemoryBody">${state.seasonMemoryLoading?'<article class="card card-pad"><div class="empty">Le Hibou recompte les saisons…</div></article>':tab==='overview'?seasonOverviewHTMLV090():tab==='career'?careerLeaderboardHTMLV090():tab==='hall'?hallOfFameHTMLV090():tab==='replay'?replayHTMLV090():pollsHTMLV090()}</div>`;
  const sw=$("#seasonSwitcherV090",root);if(sw)sw.onchange=()=>switchSeasonV090(sw.value);
  $$('[data-memory-tab]',root).forEach(b=>b.onclick=()=>{state.seasonMemoryTab=b.dataset.memoryTab;renderSeasonMemory();});
  $$('[data-player-profile]',root).forEach(b=>b.onclick=()=>openPlayerQuickProfile(b.dataset.playerProfile));
  $$('[data-general-poll-option]',root).forEach(b=>b.onclick=()=>castGeneralPollVoteV090(b.dataset.pollId,b.dataset.generalPollOption));
}

function renderProfileCareerV090(){
  const root=$("#profileCareerRoot");if(!root)return;const c=state.playerCareer||{},s=c.summary||{},dist=c.distinctions||[],seasons=c.seasons||[];
  root.innerHTML=`<div class="profile-career-head"><div><span class="eyebrow gold">Carrière</span><h3>Ton histoire dans le Nid</h3></div><button class="btn secondary small" type="button" data-open-career>Voir le classement carrière</button></div><div class="career-stat-grid compact"><article><span>Rang carrière</span><strong>#${s.rank||'—'}</strong></article><article><span>Saisons</span><strong>${s.seasons_played||0}</strong></article><article><span>Points</span><strong>${fmtCareerNumberV090(s.total_points)}</strong></article><article><span>Moyenne</span><strong>${fmtCareerNumberV090(s.career_average,2)}</strong></article><article><span>Podiums</span><strong>${s.podiums||0}</strong></article><article><span>Titres</span><strong>${s.titles||0}</strong></article></div>${dist.length?`<div class="distinction-list compact">${dist.map(d=>`<span><b>${esc(d.icon||'🏆')}</b><span><strong>${esc(d.label)}</strong><small>${esc(d.description||'')}</small></span></span>`).join('')}</div>`:''}<div class="career-season-strip">${seasons.map(x=>`<button data-profile-season="${esc(x.slug)}"><strong>${esc(x.season)}</strong><small>#${x.rank||'—'} · ${fmtCareerNumberV090(x.points)} pts</small></button>`).join('')}</div>`;
  const open=$("[data-open-career]",root);if(open)open.onclick=()=>{state.seasonMemoryTab="career";setView("season");renderSeasonMemory();};
  $$('[data-profile-season]',root).forEach(b=>b.onclick=()=>switchSeasonV090(b.dataset.profileSeason));
}

async function renderAdminGeneralPollPanelV090(){
  const root=$("#adminGeneralPollPanel");if(!root)return;if(state.profile?.role!=="super_admin"){root.classList.add("hidden");return;}root.classList.remove("hidden");
  if(demoMode){root.innerHTML='<span class="eyebrow">🗳️ Sondages V0.9</span><h3>Mode démo</h3><p class="muted">La création réelle utilise Supabase.</p>';return;}
  const {data:polls,error}=await sb.from("polls").select("id,title,question,status,opens_at,closes_at,poll_options(id)").or(`season_id.eq.${state.season.id},season_id.is.null`).order("created_at",{ascending:false}).limit(12);
  if(error){root.innerHTML=`<div class="ucl-warning">Migration V0.9.0 requise : ${esc(friendlyError(error))}</div>`;return;}
  root.innerHTML=`<div class="admin-subhead"><div><span class="eyebrow gold">🗳️ V0.9.0</span><h4>Sondages généraux</h4><p>Règles, suggestions ou décisions du Nid. Les votes mensuels Casserole/Génie restent séparés.</p></div></div><div class="grid grid-2"><div class="field"><label>Titre</label><input id="pollTitleV090" maxlength="80" placeholder="Ex. Vote du Nid"></div><div class="field"><label>Durée</label><select id="pollDaysV090"><option value="2">2 jours</option><option value="3">3 jours</option><option value="5" selected>5 jours</option><option value="7">7 jours</option></select></div></div><div class="field"><label>Question</label><input id="pollQuestionV090" maxlength="220" placeholder="Quelle règle préférez-vous ?"></div><div class="field"><label>Réponses · une par ligne</label><textarea id="pollOptionsV090" rows="4" placeholder="Choix A\nChoix B"></textarea></div><div class="actions"><button id="createPollV090" class="btn gold small">Ouvrir le sondage</button></div><div id="pollMsgV090" class="form-msg"></div><div class="admin-poll-list">${(polls||[]).map(p=>`<div><span><strong>${esc(p.title)}</strong><small>${esc(p.question)} · ${(p.poll_options||[]).length} choix</small></span>${p.status==='open'?`<button data-close-poll-v090="${p.id}" class="btn secondary small">Fermer</button>`:`<span class="chip">${esc(p.status)}</span>`}</div>`).join('')||'<div class="empty">Aucun sondage général.</div>'}</div>`;
  $("#createPollV090",root).onclick=async()=>{const title=$("#pollTitleV090",root).value.trim(),question=$("#pollQuestionV090",root).value.trim(),lines=$("#pollOptionsV090",root).value.split(/\r?\n/).map(x=>x.trim()).filter(Boolean);if(!title||!question||lines.length<2)return setMsg("#pollMsgV090","Titre, question et au moins 2 réponses sont nécessaires.","error");const days=Number($("#pollDaysV090",root).value||5),closes=new Date(Date.now()+days*86400000).toISOString();const {error}=await sb.rpc("admin_create_poll_v090",{p_season_id:state.season.id,p_title:title,p_question:question,p_options:lines.map(label=>({label})),p_opens_at:new Date().toISOString(),p_closes_at:closes,p_allow_change:true,p_show_results_before_close:true});if(error)return setMsg("#pollMsgV090",friendlyError(error),"error");state.seasonMemoryLoaded=false;await renderAdminGeneralPollPanelV090();setMsg("#pollMsgV090","Sondage ouvert.","ok");};
  $$('[data-close-poll-v090]',root).forEach(b=>b.onclick=async()=>{const {error}=await sb.rpc("admin_close_poll_v090",{p_poll_id:b.dataset.closePollV090});if(error)return toast(friendlyError(error),"error");state.seasonMemoryLoaded=false;await renderAdminGeneralPollPanelV090();toast("Sondage fermé.");});
}

async function renderAdminDistinctionPanelV090(){
  const root=$("#adminDistinctionPanel");if(!root)return;if(state.profile?.role!=="super_admin"){root.classList.add("hidden");return;}root.classList.remove("hidden");
  const players=[...state.profileDirectory.values()].filter(p=>p.status!=="disabled").sort((a,b)=>String(a.username).localeCompare(String(b.username),'fr'));
  let worldCupWinner=null,worldCupError=null;
  if(!demoMode){
    const r=await sb.from("player_distinctions").select("id,user_id,code,label,description,icon,active,awarded_at,metadata").eq("code","nid-pronos-world-cup-2026").eq("active",true).maybeSingle();
    if(r.error)worldCupError=r.error;else worldCupWinner=r.data||null;
  }
  const currentPlayer=worldCupWinner?state.profileDirectory.get(String(worldCupWinner.user_id)):null;
  const playerOptions=players.map(p=>`<option value="${p.id}" ${String(p.id)===String(worldCupWinner?.user_id||'')?'selected':''}>${esc(p.username)}</option>`).join('');
  root.innerHTML=`<div class="admin-subhead"><div><span class="eyebrow gold">🏆 Mémoire</span><h4>Palmarès & distinctions permanentes</h4><p>Ces titres suivent le joueur d'une saison à l'autre et restent visibles dans sa carrière.</p></div></div>
    <section class="legacy-winner-card">
      <div class="legacy-winner-copy"><span class="eyebrow gold">🌍 Héritage · Coupe du monde 2026</span><h4>Vainqueur du Nid des Pronos</h4><p>Désigne manuellement le joueur qui a remporté l'édition Coupe du monde. Un seul vainqueur peut être actif à la fois.</p></div>
      <div class="legacy-winner-current">${worldCupError?`<span class="chip danger">Migration V0.9.0 requise</span>`:worldCupWinner?`<span class="legacy-trophy">🏆</span><span><small>Vainqueur enregistré</small><strong>${esc(currentPlayer?.username||'Joueur')}</strong><em>${esc(worldCupWinner.label||'Vainqueur du Nid des Pronos — Coupe du monde 2026')}</em></span>`:'<span class="muted">Aucun vainqueur Coupe du monde enregistré.</span>'}</div>
      <div class="grid grid-2 legacy-winner-actions"><div class="field"><label>Joueur vainqueur</label><select id="worldCupWinnerPlayerV090">${playerOptions}</select></div><div class="actions"><button id="setWorldCupWinnerV090" class="btn gold small" type="button" ${players.length?'':'disabled'}>🏆 Désigner vainqueur</button>${worldCupWinner?'<button id="clearWorldCupWinnerV090" class="btn danger small" type="button">Retirer le titre</button>':''}</div></div>
      <div id="worldCupWinnerMsgV090" class="form-msg"></div>
    </section>
    <details class="admin-advanced-distinction"><summary>＋ Ajouter une autre distinction historique</summary><div class="grid grid-3"><div class="field"><label>Joueur</label><select id="distPlayerV090">${playerOptions}</select></div><div class="field"><label>Code</label><input id="distCodeV090" value="distinction-historique"></div><div class="field"><label>Icône</label><input id="distIconV090" value="🏆" maxlength="8"></div></div><div class="field"><label>Libellé</label><input id="distLabelV090" value="Distinction du Nid"></div><div class="field"><label>Description</label><input id="distDescV090" value="Distinction historique attribuée par le Super Admin."></div><div class="actions"><button id="awardDistV090" class="btn secondary small">Attribuer / mettre à jour</button></div><div id="distMsgV090" class="form-msg"></div></details>`;

  const refreshMemory=async()=>{state.seasonMemoryLoaded=false;await loadSeasonMemoryData(true);renderProfileCareerV090();renderSeasonMemory();};
  const setWinner=$("#setWorldCupWinnerV090",root);if(setWinner)setWinner.onclick=async()=>{
    if(demoMode)return setMsg("#worldCupWinnerMsgV090","Disponible avec Supabase.","error");
    const userId=$("#worldCupWinnerPlayerV090",root)?.value;if(!userId)return setMsg("#worldCupWinnerMsgV090","Choisis un joueur.","error");
    const player=state.profileDirectory.get(String(userId));
    if(!confirm(`Désigner ${player?.username||'ce joueur'} comme vainqueur du Nid des Pronos — Coupe du monde 2026 ?`))return;
    setWinner.disabled=true;
    const {error}=await sb.rpc("admin_set_world_cup_winner_v090",{p_user_id:userId});
    if(error){setWinner.disabled=false;return setMsg("#worldCupWinnerMsgV090",friendlyError(error),"error");}
    await refreshMemory();await renderAdminDistinctionPanelV090();toast(`🏆 ${player?.username||'Joueur'} est enregistré comme vainqueur du Nid des Pronos — Coupe du monde 2026.`);
  };
  const clearWinner=$("#clearWorldCupWinnerV090",root);if(clearWinner)clearWinner.onclick=async()=>{
    if(!confirm("Retirer la distinction Coupe du monde 2026 ? Le joueur restera dans l'historique, mais le titre ne sera plus affiché."))return;
    clearWinner.disabled=true;const {error}=await sb.rpc("admin_set_world_cup_winner_v090",{p_user_id:null});
    if(error){clearWinner.disabled=false;return setMsg("#worldCupWinnerMsgV090",friendlyError(error),"error");}
    await refreshMemory();await renderAdminDistinctionPanelV090();toast("Distinction Coupe du monde retirée.");
  };
  const award=$("#awardDistV090",root);if(award)award.onclick=async()=>{if(demoMode)return setMsg("#distMsgV090","Disponible avec Supabase.","error");const {error}=await sb.rpc("admin_set_distinction_v090",{p_user_id:$("#distPlayerV090",root).value,p_code:$("#distCodeV090",root).value,p_label:$("#distLabelV090",root).value,p_description:$("#distDescV090",root).value,p_icon:$("#distIconV090",root).value,p_source_season_id:null,p_active:true,p_metadata:{source:"manual_admin"}});if(error)return setMsg("#distMsgV090",friendlyError(error),"error");await refreshMemory();setMsg("#distMsgV090","Distinction enregistrée.","ok");};
}


async function refreshSeasonDirectoryV090(){
  if(demoMode)return;
  const {data,error}=await sb.from("seasons").select("*").order("created_at",{ascending:false});
  if(error)throw error;
  state.availableSeasons=data||[];
  const current=state.availableSeasons.find(x=>x.id===state.season?.id);
  if(current)state.season={...state.season,...current};
}

async function renderAdminSeasonManagementV090(){
  const root=$("#adminSeasonManagementPanel");if(!root)return;
  if(state.profile?.role!=="super_admin"){root.classList.add("hidden");return;}
  root.classList.remove("hidden");
  if(demoMode){root.innerHTML='<span class="eyebrow gold">🗓 Multi-saisons</span><h3>Mode démo</h3><p class="muted">Création et activation disponibles avec Supabase.</p>';return;}
  try{await refreshSeasonDirectoryV090();}catch(err){root.innerHTML=`<div class="ucl-warning">Migration V0.9.0 requise : ${esc(friendlyError(err))}</div>`;return;}
  const seasons=state.availableSeasons||[];
  root.innerHTML=`<div class="admin-subhead"><div><span class="eyebrow gold">🗓 V0.9.0 · Multi-saisons</span><h4>Créer, activer et archiver les saisons</h4><p>Une seule saison est active. Une saison terminée ou archivée devient consultable en lecture seule.</p></div><span class="chip">${seasons.length} saison${seasons.length>1?'s':''}</span></div>
    <div class="grid grid-3 season-create-grid">
      <div class="field"><label>Nom</label><input id="seasonNameV090" maxlength="100" placeholder="Champions League 2027–28"></div>
      <div class="field"><label>Slug</label><input id="seasonSlugV090" maxlength="80" placeholder="ucl-2027-28"></div>
      <div class="field"><label>Copier le barème / phases de</label><select id="seasonCopyV090"><option value="">Structure par défaut</option>${seasons.map(x=>`<option value="${x.id}" ${x.id===state.season?.id?'selected':''}>${esc(x.name)}</option>`).join("")}</select></div>
    </div>
    <div class="actions"><button id="createSeasonV090" class="btn gold small" type="button">＋ Créer en préparation</button></div>
    <div id="seasonAdminMsgV090" class="form-msg"></div>
    <div class="season-admin-list">${seasons.map(x=>`<article class="season-admin-row ${x.is_active?'active':''}">
      <div class="season-admin-main"><span class="season-state-dot"></span><span><strong>${esc(x.name)}</strong><small>${esc(x.slug)} · ${esc(seasonStatusCopyV090(x.status))}${x.is_active?' · saison active':''}</small></span></div>
      <div class="season-admin-actions">
        ${!x.is_active?`<button class="btn secondary small" data-activate-season="${x.id}">Activer</button>`:'<span class="chip">ACTIVE</span>'}
        <select data-season-status="${x.id}" aria-label="Statut ${esc(x.name)}">
          ${["preparation","active","finished","archived"].map(st=>`<option value="${st}" ${st===x.status?'selected':''}>${esc(seasonStatusCopyV090(st))}</option>`).join("")}
        </select>
        <button class="btn secondary small" data-save-season-status="${x.id}">Appliquer</button>
      </div>
    </article>`).join("")||'<div class="empty">Aucune saison.</div>'}</div>`;

  const name=$("#seasonNameV090",root),slug=$("#seasonSlugV090",root);
  if(name&&slug){
    name.oninput=()=>{if(!slug.dataset.touched){slug.value=name.value.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g,"").replace(/[–—]/g,"-").replace(/[^a-z0-9]+/g,"-").replace(/^-|-$/g,"");}};
    slug.oninput=()=>slug.dataset.touched="1";
  }
  $("#createSeasonV090",root).onclick=async()=>{
    const n=name.value.trim(),sl=slug.value.trim(),copy=$("#seasonCopyV090",root).value||null;
    if(!n||!sl)return setMsg("#seasonAdminMsgV090","Nom et slug sont obligatoires.","error");
    const {data,error}=await sb.rpc("admin_create_season_v090",{p_name:n,p_slug:sl,p_copy_from_season_id:copy});
    if(error)return setMsg("#seasonAdminMsgV090",friendlyError(error),"error");
    await refreshSeasonDirectoryV090();await renderAdminSeasonManagementV090();renderSeasonMemory();
    setMsg("#seasonAdminMsgV090",`Saison créée (${String(data||"").slice(0,8)}…). Elle reste en préparation tant que tu ne l’actives pas.`,"ok");
  };
  $$("[data-activate-season]",root).forEach(b=>b.onclick=async()=>{
    if(!confirm("Activer cette saison ? L’ancienne saison active sera désactivée."))return;
    const {error}=await sb.rpc("admin_set_active_season_v090",{p_season_id:b.dataset.activateSeason});
    if(error)return toast(friendlyError(error),"error");
    await refreshSeasonDirectoryV090();await renderAdminSeasonManagementV090();renderSeasonMemory();toast("Saison active mise à jour.");
  });
  $$("[data-save-season-status]",root).forEach(b=>b.onclick=async()=>{
    const id=b.dataset.saveSeasonStatus,select=$(`[data-season-status="${id}"]`,root),status=select?.value;
    if(["finished","archived"].includes(status)&&!confirm(`Passer cette saison en « ${seasonStatusCopyV090(status)} » ? Les pronostics deviendront en lecture seule.`))return;
    const {error}=await sb.rpc("admin_set_season_status_v090",{p_season_id:id,p_status:status});
    if(error)return toast(friendlyError(error),"error");
    await refreshSeasonDirectoryV090();await renderAdminSeasonManagementV090();renderSeasonMemory();toast("Statut de saison mis à jour.");
  });
}
