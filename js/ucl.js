"use strict";

// Le Nid des Champions V0.8.0 — Centre Ligue des champions
function uclStageLabel(stage){
  const s=String(stage||"").toUpperCase();
  const map={
    LEAGUE_STAGE:"Phase de ligue",REGULAR_SEASON:"Phase de ligue",LEAGUE:"Phase de ligue",
    PLAYOFFS:"Barrages",KNOCKOUT_PLAYOFF:"Barrages",LAST_16:"Huitièmes de finale",ROUND_OF_16:"Huitièmes de finale",
    QUARTER_FINALS:"Quarts de finale",QUARTER_FINAL:"Quarts de finale",SEMI_FINALS:"Demi-finales",SEMI_FINAL:"Demi-finales",FINAL:"Finale"
  };
  return map[s]||String(stage||"Compétition").replaceAll("_"," ");
}
function uclStatusLabel(status){return ({scheduled:"À venir",live:"LIVE",finished:"Terminé",postponed:"Reporté",cancelled:"Annulé",suspended:"Suspendu"}[status]||status||"À venir");}
function uclCenterFallbackMatches(){
  return (state.allMatches||[]).filter(m=>!m.is_test).map(m=>({
    id:`fallback-${m.id}`,external_match_id:m.external_match_id||null,season_id:m.season_id,stage:m.external_stage||(m.tie_id?"KNOCKOUT":"LEAGUE_STAGE"),matchday:(state.matchdays||[]).find(md=>md.id===m.matchday_id)?.number||null,
    kickoff_at:m.kickoff_at,status:m.status,home_score:m.home_score,away_score:m.away_score,winner:null,venue:m.stadium,
    home_club:m.home_club,away_club:m.away_club,last_synced_at:m.updated_at||null
  }));
}
function uclComputeStandingsFromMatches(matches){
  const rows=new Map();
  const ensure=club=>{if(!club)return null;const k=String(club.id);if(!rows.has(k))rows.set(k,{club_id:club.id,club,played_games:0,won:0,draw:0,lost:0,points:0,goals_for:0,goals_against:0,goal_difference:0,form:""});return rows.get(k);};
  const form=new Map();
  for(const m of (matches||[]).filter(x=>x.status==="finished"&&/LEAGUE|REGULAR/i.test(String(x.stage||"")))){
    const h=ensure(m.home_club),a=ensure(m.away_club);if(!h||!a||m.home_score==null||m.away_score==null)continue;
    const hs=Number(m.home_score),as=Number(m.away_score);h.played_games++;a.played_games++;h.goals_for+=hs;h.goals_against+=as;a.goals_for+=as;a.goals_against+=hs;
    let hf="D",af="D";if(hs>as){h.won++;a.lost++;h.points+=3;hf="W";af="L";}else if(as>hs){a.won++;h.lost++;a.points+=3;hf="L";af="W";}else{h.draw++;a.draw++;h.points++;a.points++;}
    form.set(String(h.club_id),[...(form.get(String(h.club_id))||[]),hf].slice(-5));form.set(String(a.club_id),[...(form.get(String(a.club_id))||[]),af].slice(-5));
  }
  const arr=[...rows.values()].map(r=>({...r,goal_difference:r.goals_for-r.goals_against,form:(form.get(String(r.club_id))||[]).join(",")}));
  arr.sort((a,b)=>b.points-a.points||b.goal_difference-a.goal_difference||b.goals_for-a.goals_for||String(a.club?.name||"").localeCompare(String(b.club?.name||""),"fr"));
  return arr.map((r,i)=>({...r,position:i+1}));
}
async function loadUclCenterData(force=false){
  if(!state.season||state.uclCenterLoading)return;
  if(state.uclCenterLoaded&&!force)return;
  state.uclCenterLoading=true;state.uclCenterError=null;
  try{
    if(demoMode){
      state.uclMatches=uclCenterFallbackMatches();state.uclStandings=uclComputeStandingsFromMatches(state.uclMatches);state.uclCenterLoaded=true;return;
    }
    const [mr,sr]=await Promise.all([
      sb.from("ucl_matches").select("id,season_id,external_provider,external_match_id,stage,matchday,kickoff_at,status,home_score,away_score,half_time_home,half_time_away,winner,venue,last_synced_at,home_club:clubs!ucl_matches_home_club_id_fkey(id,name,short_name,tla,country,venue,logo_url,logo_source_url,logo_storage_path),away_club:clubs!ucl_matches_away_club_id_fkey(id,name,short_name,tla,country,venue,logo_url,logo_source_url,logo_storage_path)").eq("season_id",state.season.id).order("kickoff_at"),
      sb.from("ucl_standings").select("season_id,club_id,position,played_games,won,draw,lost,points,goals_for,goals_against,goal_difference,form,table_type,updated_at,club:clubs!ucl_standings_club_id_fkey(id,name,short_name,tla,country,venue,logo_url,logo_source_url,logo_storage_path)").eq("season_id",state.season.id).eq("table_type","TOTAL").order("position")
    ]);
    if(mr.error||sr.error){
      state.uclCenterError="Migration V0.8.0 absente ou Centre CL non initialisé.";
      state.uclMatches=uclCenterFallbackMatches();state.uclStandings=uclComputeStandingsFromMatches(state.uclMatches);
    }else{
      state.uclMatches=mr.data||[];state.uclStandings=(sr.data||[]).map(r=>({...r,club:r.club||clubById(r.club_id)}));
      if(!state.uclMatches.length)state.uclMatches=uclCenterFallbackMatches();
      if(!state.uclStandings.length)state.uclStandings=uclComputeStandingsFromMatches(state.uclMatches);
    }
    state.uclCenterLoaded=true;
  }catch(err){state.uclCenterError=friendlyError(err);state.uclMatches=uclCenterFallbackMatches();state.uclStandings=uclComputeStandingsFromMatches(state.uclMatches);}
  finally{state.uclCenterLoading=false;}
}
function uclFormHTML(form){
  const items=String(form||"").split(/[\s,;]+/).filter(Boolean).slice(-5);
  return `<span class="ucl-form">${items.map(x=>`<i class="${x==='W'?'win':x==='D'?'draw':'loss'}">${x==='W'?'V':x==='D'?'N':'D'}</i>`).join("")||'<small>—</small>'}</span>`;
}
function uclMatchCardHTML(m,compact=false){
  const hasScore=m.home_score!==null&&m.home_score!==undefined&&m.away_score!==null&&m.away_score!==undefined;
  const score=m.status==="finished"||m.status==="live"?(hasScore?`${m.home_score}–${m.away_score}`:(m.status==="live"?"LIVE":"—")):"—";
  return `<article class="ucl-match-card ${compact?'compact':''} ${esc(m.status||'scheduled')}">
    <div class="ucl-match-meta"><span>${esc(uclStageLabel(m.stage))}${m.matchday?` · J${Number(m.matchday)}`:""}</span><time>${esc(fmtDate(m.kickoff_at))}</time><b>${esc(uclStatusLabel(m.status))}</b></div>
    <div class="ucl-match-teams"><button type="button" data-ucl-club="${esc(m.home_club?.id||'')}" class="ucl-club-link">${crestHTML(m.home_club)}<span>${esc(m.home_club?.short_name||m.home_club?.name||'?')}</span></button><strong>${score}</strong><button type="button" data-ucl-club="${esc(m.away_club?.id||'')}" class="ucl-club-link">${crestHTML(m.away_club)}<span>${esc(m.away_club?.short_name||m.away_club?.name||'?')}</span></button></div>
  </article>`;
}
function uclStandingsHTML(){
  const rows=state.uclStandings||[];
  return `<div class="ucl-table-wrap"><table class="ucl-table"><thead><tr><th>#</th><th>Club</th><th>MJ</th><th>V</th><th>N</th><th>D</th><th>BP</th><th>BC</th><th>Diff</th><th>Pts</th><th>Forme</th></tr></thead><tbody>${rows.map(r=>{const p=Number(r.position||0);const zone=p<=8?'direct':p<=24?'playoff':'out';return `<tr class="zone-${zone}" data-ucl-club-row="${esc(r.club_id)}"><td><span class="ucl-position">${p}</span></td><td><button class="ucl-table-club" data-ucl-club="${esc(r.club_id)}">${crestHTML(r.club||clubById(r.club_id))}<b>${esc(r.club?.short_name||r.club?.name||clubById(r.club_id)?.name||'Club')}</b></button></td><td>${Number(r.played_games||0)}</td><td>${Number(r.won||0)}</td><td>${Number(r.draw||0)}</td><td>${Number(r.lost||0)}</td><td>${Number(r.goals_for||0)}</td><td>${Number(r.goals_against||0)}</td><td>${Number(r.goal_difference||0)>0?'+':''}${Number(r.goal_difference||0)}</td><td><strong>${Number(r.points||0)}</strong></td><td>${uclFormHTML(r.form)}</td></tr>`;}).join("")||'<tr><td colspan="11" class="empty">Classement pas encore disponible.</td></tr>'}</tbody></table></div>`;
}
function uclPhaseBracketHTML(){
  const groups=new Map();
  (state.uclMatches||[]).filter(m=>!/LEAGUE|REGULAR/i.test(String(m.stage||""))).forEach(m=>{const k=uclStageLabel(m.stage);if(!groups.has(k))groups.set(k,[]);groups.get(k).push(m);});
  if(!groups.size&&(state.knockoutTies||[]).length){
    return `<div class="ucl-phase-grid">${(state.phases||[]).filter(p=>p.code!=="LEAGUE").map(p=>{const ties=(state.knockoutTies||[]).filter(t=>t.phase_id===p.id);return `<section><h4>${esc(p.name)}</h4>${ties.length?ties.map(t=>`<div class="ucl-tie-line"><span>${esc(clubById(t.team_a_club_id)?.short_name||'?')}</span><b>VS</b><span>${esc(clubById(t.team_b_club_id)?.short_name||'?')}</span></div>`).join(''):'<div class="empty mini">Tirage à venir.</div>'}</section>`;}).join('')}</div>`;
  }
  return `<div class="ucl-phase-grid">${[...groups.entries()].map(([label,matches])=>`<section><h4>${esc(label)}</h4>${matches.sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at)).map(m=>uclMatchCardHTML(m,true)).join('')}</section>`).join('')||'<div class="empty">La phase finale apparaîtra ici dès sa publication.</div>'}</div>`;
}
function uclOverviewHTML(){
  const matches=state.uclMatches||[],now=Date.now();const live=matches.filter(m=>m.status==="live");const next=matches.filter(m=>new Date(m.kickoff_at).getTime()>now&&!["cancelled"].includes(m.status)).slice(0,6);const recent=matches.filter(m=>m.status==="finished").slice().sort((a,b)=>new Date(b.kickoff_at)-new Date(a.kickoff_at)).slice(0,6);
  return `<div class="ucl-overview-grid"><article class="card card-pad ucl-status-card"><span class="eyebrow gold">La compétition en direct</span><h3>${live.length?`${live.length} match${live.length>1?'s':''} LIVE`:'Ligue des champions 2026–27'}</h3><p>${(state.uclStandings||[]).length} clubs classés · ${matches.length} rencontres connues.</p>${state.uclCenterError?`<div class="ucl-warning">⚠ ${esc(state.uclCenterError)}</div>`:''}</article><article class="card card-pad"><span class="eyebrow">Zones du classement</span><div class="ucl-zones"><span class="direct"><b>1–8</b> Huitièmes directs</span><span class="playoff"><b>9–24</b> Barrages</span><span class="out"><b>25–36</b> Éliminés</span></div></article></div>
  ${live.length?`<div class="section-title compact"><div><h3>🔴 LIVE</h3><p>Scores réels synchronisés.</p></div></div><div class="ucl-match-grid">${live.map(m=>uclMatchCardHTML(m)).join('')}</div>`:''}
  <div class="section-title compact"><div><h3>Prochains matchs</h3><p>Les prochaines affiches connues.</p></div></div><div class="ucl-match-grid">${next.map(m=>uclMatchCardHTML(m)).join('')||'<div class="empty">Calendrier pas encore disponible.</div>'}</div>
  <div class="section-title compact"><div><h3>Derniers résultats</h3><p>Les résultats officiels les plus récents.</p></div></div><div class="ucl-match-grid">${recent.map(m=>uclMatchCardHTML(m)).join('')||'<div class="empty">Aucun résultat pour le moment.</div>'}</div>`;
}
function uclCalendarHTML(){
  const matches=state.uclMatches||[];const phases=[...new Set(matches.map(m=>uclStageLabel(m.stage)))];
  const filter=state.uclCalendarFilter||"all";
  const filtered=matches.filter(m=>filter==="all"||uclStageLabel(m.stage)===filter);
  const dates=new Map();for(const m of filtered){const k=localDateKey(m.kickoff_at);if(!dates.has(k))dates.set(k,[]);dates.get(k).push(m);}
  return `<div class="ucl-filter-row"><button data-ucl-calendar-filter="all" class="${filter==='all'?'active':''}">Tout</button>${phases.map(p=>`<button data-ucl-calendar-filter="${esc(p)}" class="${filter===p?'active':''}">${esc(p)}</button>`).join('')}</div><div class="ucl-calendar-days">${[...dates.entries()].sort((a,b)=>a[0].localeCompare(b[0])).map(([date,ms])=>`<section class="card card-pad"><h4>${esc(new Intl.DateTimeFormat('fr-FR',{weekday:'long',day:'numeric',month:'long',year:'numeric',timeZone:'Europe/Paris'}).format(new Date(`${date}T12:00:00+02:00`)))}</h4><div class="ucl-match-grid">${ms.map(m=>uclMatchCardHTML(m,true)).join('')}</div></section>`).join('')||'<div class="empty">Aucun match dans ce filtre.</div>'}</div>`;
}
function uclClubsHTML(){
  const memberIds=new Set((state.clubMemberships||[]).filter(x=>x.competition_code==="CL"&&Number(x.season_year)===2026).map(x=>String(x.club_id)));
  let clubs=(state.clubs||[]).filter(c=>memberIds.size?memberIds.has(String(c.id)):(state.uclMatches||[]).some(m=>String(m.home_club?.id)===String(c.id)||String(m.away_club?.id)===String(c.id)));
  const q=String(state.uclClubSearch||"").toLocaleLowerCase('fr');if(q)clubs=clubs.filter(c=>`${c.name} ${c.short_name||''} ${c.country||''}`.toLocaleLowerCase('fr').includes(q));
  return `<div class="ucl-club-search"><input id="uclClubSearchInput" type="search" placeholder="Rechercher PSG, Real Madrid…" value="${esc(state.uclClubSearch||'')}"></div><div class="ucl-club-grid">${clubs.map(c=>{const standing=(state.uclStandings||[]).find(r=>String(r.club_id)===String(c.id));return `<button class="card ucl-club-card" data-ucl-club="${esc(c.id)}">${crestHTML(c,true)}<span><strong>${esc(c.name)}</strong>${clubCountryHTML(c)}<small>${standing?`#${standing.position} · ${standing.points} pts · ${standing.goal_difference>0?'+':''}${standing.goal_difference}`:'Classement à venir'}</small></span>${standing?uclFormHTML(standing.form):''}</button>`;}).join('')||'<div class="empty">Clubs pas encore disponibles.</div>'}</div>`;
}
function openUclClub(clubId){
  state.uclSelectedClubId=clubId;const club=(state.clubs||[]).find(c=>String(c.id)===String(clubId));if(!club)return;
  const standing=(state.uclStandings||[]).find(r=>String(r.club_id)===String(clubId));
  const ms=(state.uclMatches||[]).filter(m=>String(m.home_club?.id)===String(clubId)||String(m.away_club?.id)===String(clubId));const now=Date.now();
  const recent=ms.filter(m=>m.status==="finished").sort((a,b)=>new Date(b.kickoff_at)-new Date(a.kickoff_at)).slice(0,5);const next=ms.filter(m=>new Date(m.kickoff_at).getTime()>now&&!["cancelled"].includes(m.status)).sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at)).slice(0,5);
  const root=modal(`⚽ ${club.name}`,`<div class="ucl-club-profile-head">${crestHTML(club,true)}<div><h2>${esc(club.name)}</h2>${clubCountryHTML(club)}<p>${esc(club.venue||'Stade non renseigné')}</p></div></div>${standing?`<div class="ucl-club-kpis"><span><b>#${standing.position}</b><small>classement</small></span><span><b>${standing.points}</b><small>points</small></span><span><b>${standing.won}-${standing.draw}-${standing.lost}</b><small>V-N-D</small></span><span><b>${standing.goal_difference>0?'+':''}${standing.goal_difference}</b><small>différence</small></span><span>${uclFormHTML(standing.form)}<small>forme</small></span></div>`:'<div class="ucl-warning">Le classement officiel n’est pas encore disponible.</div>'}<div class="section-title compact"><div><h4>5 derniers matchs</h4><p>La forme récente du club.</p></div></div><div class="ucl-match-grid">${recent.map(m=>uclMatchCardHTML(m,true)).join('')||'<div class="empty">Aucun résultat.</div>'}</div><div class="section-title compact"><div><h4>5 prochains matchs</h4><p>Le programme à venir en Ligue des champions.</p></div></div><div class="ucl-match-grid">${next.map(m=>uclMatchCardHTML(m,true)).join('')||'<div class="empty">Aucun match annoncé.</div>'}</div>`);
  $$('[data-ucl-club]',root).forEach(b=>b.onclick=()=>{if(b.dataset.uclClub&&b.dataset.uclClub!==String(clubId)){$("#modalRoot").innerHTML="";openUclClub(b.dataset.uclClub);}});
}
function bindUclCenterEvents(root){
  $$('[data-ucl-tab]',root).forEach(b=>b.onclick=()=>{state.uclTab=b.dataset.uclTab;renderUclCenter();});
  $$('[data-ucl-club]',root).forEach(b=>b.onclick=()=>b.dataset.uclClub&&openUclClub(b.dataset.uclClub));
  $$('[data-ucl-calendar-filter]',root).forEach(b=>b.onclick=()=>{state.uclCalendarFilter=b.dataset.uclCalendarFilter;renderUclCenter();});
  const s=$("#uclClubSearchInput",root);if(s)s.oninput=debounce(()=>{state.uclClubSearch=s.value;renderUclCenter();},140);
  const refresh=$("#uclRefreshBtn",root);if(refresh)refresh.onclick=async()=>{refresh.disabled=true;try{if(isAdminProfile())await syncFootballData("center");else await loadUclCenterData(true);await loadUclCenterData(true);renderUclCenter();}catch(err){toast(friendlyError(err),"error");}finally{refresh.disabled=false;}};
}
function renderUclCenter(){
  const root=$("#uclCenterRoot");if(!root)return;if(state.uclCenterLoading){root.innerHTML='<article class="card card-pad"><div class="empty">Chargement du Centre Ligue des champions…</div></article>';return;}
  const tab=state.uclTab||"overview";
  root.innerHTML=`<div class="ucl-hero card card-pad"><div><span class="eyebrow gold">V0.8.0 · Centre Ligue des champions</span><h2>⭐ Toute la C1, sans quitter le Nid</h2><p>Résultats réels, calendrier, classement, phases finales, forme et fiches des clubs.</p></div><button id="uclRefreshBtn" class="btn ${isAdminProfile()?'gold':'secondary'} small">↻ ${isAdminProfile()?'Synchroniser':'Actualiser'}</button></div><div class="ucl-tabs"><button data-ucl-tab="overview" class="${tab==='overview'?'active':''}">Vue d’ensemble</button><button data-ucl-tab="standings" class="${tab==='standings'?'active':''}">Classement</button><button data-ucl-tab="calendar" class="${tab==='calendar'?'active':''}">Calendrier & résultats</button><button data-ucl-tab="knockout" class="${tab==='knockout'?'active':''}">Phases finales</button><button data-ucl-tab="clubs" class="${tab==='clubs'?'active':''}">Clubs</button></div><div id="uclTabBody">${tab==='overview'?uclOverviewHTML():tab==='standings'?uclStandingsHTML():tab==='calendar'?uclCalendarHTML():tab==='knockout'?uclPhaseBracketHTML():uclClubsHTML()}</div>`;
  bindUclCenterEvents(root);
}
