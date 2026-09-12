"use strict";

// Le Nid des Champions V1.0.1 — LIVE C1, carrousels Team, classement, rivalités et fiches clubs.
(() => {
  const safe = value => Array.isArray(value) ? value : [];
  const byId = id => document.getElementById(id);
  const isLive = () => safe(state.allMatches).some(m => !m.is_test && m.status === "live");
  const liveMatches = () => safe(state.allMatches).filter(m => !m.is_test && m.status === "live").sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at));
  const currentTeam = () => state.myTeam || (typeof teamForUser === "function" ? teamForUser(state.user?.id) : null);
  const clubName = c => (typeof compactClubName === "function" ? compactClubName(c) : null) || c?.short_name || c?.name || "?";

  // ---------------------------------------------------------------------------
  // 1. Centre Ligue des champions : données complémentaires et classement LIVE.
  // ---------------------------------------------------------------------------
  const baseLoadUclCenterV101 = window.loadUclCenterData;

  async function loadUclExtraStatsV101(){
    if(!state.season || demoMode){state.uclScorersV101=[];state.uclDisciplineV101=[];return;}
    try{
      const [scorers,cards]=await Promise.all([
        sb.from("ucl_player_stats").select("season_id,player_external_id,player_name,club_id,position,nationality,played_matches,goals,assists,penalties,updated_at").eq("season_id",state.season.id).order("goals",{ascending:false}).order("assists",{ascending:false}),
        sb.from("ucl_discipline_stats").select("season_id,player_external_id,player_name,club_id,yellow_cards,red_cards,yellow_red_cards,updated_at").eq("season_id",state.season.id).order("red_cards",{ascending:false}).order("yellow_red_cards",{ascending:false}).order("yellow_cards",{ascending:false})
      ]);
      state.uclScorersV101=scorers.error?[]:(scorers.data||[]);
      state.uclDisciplineV101=cards.error?[]:(cards.data||[]);
      state.uclExtraStatsErrorV101=(scorers.error||cards.error)?"Statistiques joueurs à initialiser avec le HOTFIX V1.0.1.":null;
    }catch(err){state.uclScorersV101=[];state.uclDisciplineV101=[];state.uclExtraStatsErrorV101=friendlyError(err);}
  }

  function liveUclStandingsV101(matches){
    const rows=new Map(), form=new Map();
    const seed=club=>{
      if(!club?.id)return null;const key=String(club.id);
      if(!rows.has(key))rows.set(key,{club_id:club.id,club,played_games:0,won:0,draw:0,lost:0,points:0,goals_for:0,goals_against:0,goal_difference:0,form:""});
      return rows.get(key);
    };
    safe(state.uclStandingsOfficialV101||state.uclStandings).forEach(r=>seed(r.club||clubById(r.club_id)));
    safe(matches).filter(m=>/LEAGUE|REGULAR/i.test(String(m.stage||""))).forEach(m=>{seed(m.home_club);seed(m.away_club);});
    safe(matches).filter(m=>["finished","live"].includes(m.status)&&/LEAGUE|REGULAR/i.test(String(m.stage||""))).forEach(m=>{
      if(m.home_score==null||m.away_score==null)return;const h=seed(m.home_club),a=seed(m.away_club);if(!h||!a)return;
      const hs=Number(m.home_score),as=Number(m.away_score);h.played_games++;a.played_games++;h.goals_for+=hs;h.goals_against+=as;a.goals_for+=as;a.goals_against+=hs;
      let hf="D",af="D";if(hs>as){h.won++;a.lost++;h.points+=3;hf="W";af="L";}else if(as>hs){a.won++;h.lost++;a.points+=3;hf="L";af="W";}else{h.draw++;a.draw++;h.points++;a.points++;}
      if(m.status==="finished"){
        form.set(String(h.club_id),[...(form.get(String(h.club_id))||[]),hf].slice(-5));form.set(String(a.club_id),[...(form.get(String(a.club_id))||[]),af].slice(-5));
      }
    });
    const out=[...rows.values()].map(r=>({...r,goal_difference:r.goals_for-r.goals_against,form:(form.get(String(r.club_id))||[]).join(",")}));
    out.sort((a,b)=>b.points-a.points||b.goal_difference-a.goal_difference||b.goals_for-a.goals_for||String(a.club?.name||"").localeCompare(String(b.club?.name||""),"fr"));
    return out.map((r,i)=>({...r,position:i+1}));
  }

  function syncUclLiveFromMatchesV101(){
    if(!state.uclCenterLoaded)return;
    const localByExternal=new Map(safe(state.allMatches).filter(m=>m.external_match_id!=null).map(m=>[String(m.external_match_id),m]));
    const source=safe(state.uclMatches).length?state.uclMatches:(typeof uclCenterFallbackMatches==="function"?uclCenterFallbackMatches():[]);
    state.uclMatches=source.map(m=>{
      const local=m.external_match_id!=null?localByExternal.get(String(m.external_match_id)):null;
      if(!local)return m;
      return {...m,status:local.status,kickoff_at:local.kickoff_at,home_score:local.home_score,away_score:local.away_score,venue:local.stadium||m.venue,home_club:local.home_club||m.home_club,away_club:local.away_club||m.away_club,last_synced_at:local.updated_at||m.last_synced_at};
    });
    state.uclLiveProvisionalV101=state.uclMatches.some(m=>m.status==="live"&&/LEAGUE|REGULAR/i.test(String(m.stage||"")));
    state.uclStandings=liveUclStandingsV101(state.uclMatches);
  }
  window.syncUclLiveFromMatchesV101=syncUclLiveFromMatchesV101;

  if(typeof baseLoadUclCenterV101==="function")window.loadUclCenterData=async function(force=false){
    await baseLoadUclCenterV101(force);
    state.uclStandingsOfficialV101=safe(state.uclStandings).map(r=>({...r}));
    await loadUclExtraStatsV101();
    syncUclLiveFromMatchesV101();
  };

  function scorerRowsV101(){const rows=typeof window.uclDedupeRowsV102d==="function"?window.uclDedupeRowsV102d(state.uclScorersV101,"scorers"):safe(state.uclScorersV101);return rows.filter(x=>Number(x.goals||0)>0||Number(x.assists||0)>0);}
  function disciplineRowsV102d(){return typeof window.uclDedupeRowsV102d==="function"?window.uclDedupeRowsV102d(state.uclDisciplineV101,"discipline"):safe(state.uclDisciplineV101);}
  function cardScoreV101(x){return Number(x.red_cards||0)*100+Number(x.yellow_red_cards||0)*20+Number(x.yellow_cards||0);}
  function disciplineLabelV102d(x){if(typeof window.uclDisciplineLabelV102d==="function")return window.uclDisciplineLabelV102d(x);const parts=[],y=Number(x.yellow_cards||0),yr=Number(x.yellow_red_cards||0),r=Number(x.red_cards||0);if(y>0)parts.push(y+" 🟨");if(yr>0)parts.push(yr+" 🟨🟥");if(r>0)parts.push(r+" 🟥");return parts.join(" · ")||"0";}
  function playerStatClubV101(row){return typeof window.uclResolvePlayerClubV102e==="function"?window.uclResolvePlayerClubV102e(row):clubById(row.club_id);}
  function uclPlayerStatsHTMLV101(){
    const scorers=scorerRowsV101().slice(0,30),cards=disciplineRowsV102d().filter(x=>cardScoreV101(x)>0).sort((a,b)=>cardScoreV101(b)-cardScoreV101(a)).slice(0,30);
    return `<div class="ucl-stats-grid-v101">
      <section class="card card-pad"><div class="section-title compact"><div><span class="eyebrow gold">Buteurs</span><h3>Classement des buteurs</h3><p>Buts, passes décisives et matchs joués en C1.</p></div></div><div class="ucl-player-table-v101">${scorers.length?scorers.map((x,i)=>{const c=playerStatClubV101(x);return `<button type="button" class="ucl-player-row-v101" ${c?`data-ucl-club-v101="${esc(c.id)}"`:""}><span class="ucl-player-rank-v101">${i+1}</span>${c?crestHTML(c):'<span></span>'}<span><strong>${esc(x.player_name)}</strong><small>${esc(c?.short_name||c?.name||x.position||"")}</small></span><b>${Number(x.goals||0)}</b><small>${Number(x.assists||0)} pd · ${Number(x.played_matches||0)} mj</small></button>`}).join(""):'<div class="empty">Les buteurs apparaîtront après la prochaine synchronisation C1.</div>'}</div></section>
      <section class="card card-pad"><div class="section-title compact"><div><span class="eyebrow">Discipline</span><h3>Cartons</h3><p>Jaunes, doubles jaunes et rouges.</p></div></div><div class="ucl-player-table-v101">${cards.length?cards.map((x,i)=>{const c=playerStatClubV101(x);return `<button type="button" class="ucl-player-row-v101 ucl-discipline-row-v102d" ${c?`data-ucl-club-v101="${esc(c.id)}"`:""}><span class="ucl-player-rank-v101">${i+1}</span>${c?crestHTML(c):'<span></span>'}<span><strong>${esc(x.player_name)}</strong><small>${esc(c?.short_name||c?.name||"")}</small></span><b class="cards-v101">${esc(disciplineLabelV102d(x))}</b></button>`}).join(""):'<div class="empty">Les cartons apparaîtront après la prochaine synchronisation C1.</div>'}</div></section>
    </div>${state.uclExtraStatsErrorV101?`<div class="ucl-warning">⚠ ${esc(state.uclExtraStatsErrorV101)}</div>`:""}`;
  }

  function standingsLegendV101(){return `<div class="ucl-zones-v0912"><span class="direct"><b>1–8</b> Huitièmes directs</span><span class="playoff"><b>9–24</b> Barrages</span><span class="out"><b>25–36</b> Éliminés</span>${state.uclLiveProvisionalV101?'<span class="live-ucl-v101"><b>● LIVE</b> classement provisoire</span>':""}</div>`;}
  function uclInfoHTMLV101(){const tab=state.uclInfoTabV0912||"calendar";return `<div class="leaderboard-toolbar ucl-info-tabs-v0912"><button type="button" data-ucl-info-v101="calendar" class="${tab==="calendar"?"active":""}">Calendrier & résultats</button><button type="button" data-ucl-info-v101="clubs" class="${tab==="clubs"?"active":""}">Clubs</button></div><div class="ucl-info-body-v0912">${tab==="clubs"?uclClubsHTML():uclCalendarHTML()}</div>`;}

  function renderUclCenterV101(){
    const root=byId("uclCenterRoot");if(!root)return;if(state.uclCenterLoading){root.innerHTML='<article class="card card-pad"><div class="empty">Chargement du Centre Ligue des champions…</div></article>';return;}
    syncUclLiveFromMatchesV101();
    let tab=state.uclTab||"standings";if(!["standings","stats","knockout","info"].includes(tab))tab="standings";state.uclTab=tab;
    const body=tab==="standings"?`${standingsLegendV101()}${uclStandingsHTML()}`:tab==="stats"?uclPlayerStatsHTMLV101():tab==="knockout"?uclPhaseBracketHTML():uclInfoHTMLV101();
    root.innerHTML=`<div class="ucl-hero card card-pad"><div><span class="eyebrow gold">Ligue des champions</span><h2>La C1 en direct dans le Nid</h2><p>Classement LIVE, buteurs, cartons, calendrier, phases finales et fiches clubs enrichies.</p></div><button id="uclRefreshBtn" class="btn ${isAdminProfile()?"gold":"secondary"} small">↻ ${isAdminProfile()?"Synchroniser":"Actualiser"}</button></div><div class="ucl-tabs"><button data-ucl-tab-v101="standings" class="${tab==="standings"?"active":""}">Classement</button><button data-ucl-tab-v101="stats" class="${tab==="stats"?"active":""}">Buteurs & cartons</button><button data-ucl-tab-v101="knockout" class="${tab==="knockout"?"active":""}">Phases finales</button><button data-ucl-tab-v101="info" class="${tab==="info"?"active":""}">Infos</button></div><div id="uclTabBody">${body}</div>`;
    root.querySelectorAll("[data-ucl-tab-v101]").forEach(b=>b.onclick=()=>{state.uclTab=b.dataset.uclTabV101;renderUclCenterV101();});
    root.querySelectorAll("[data-ucl-info-v101]").forEach(b=>b.onclick=()=>{state.uclInfoTabV0912=b.dataset.uclInfoV101;renderUclCenterV101();});
    root.querySelectorAll("[data-ucl-club],[data-ucl-club-v101]").forEach(b=>b.onclick=()=>openClubSheetV101(b.dataset.uclClub||b.dataset.uclClubV101));
    root.querySelectorAll("[data-ucl-calendar-filter]").forEach(b=>b.onclick=()=>{state.uclCalendarFilter=b.dataset.uclCalendarFilter;renderUclCenterV101();});
    const search=byId("uclClubSearchInput");if(search)search.oninput=debounce(()=>{state.uclClubSearch=search.value;renderUclCenterV101();},140);
    const refresh=byId("uclRefreshBtn");if(refresh)refresh.onclick=async()=>{refresh.disabled=true;try{if(isAdminProfile())await syncFootballData("center");await window.loadUclCenterData(true);renderUclCenterV101();}catch(err){toast(friendlyError(err),"error");}finally{refresh.disabled=false;}};
  }
  window.renderUclCenter=renderUclCenterV101;

  // ---------------------------------------------------------------------------
  // 2. Fiche club enrichie.
  // ---------------------------------------------------------------------------
  function squadGroupV101(position){const p=String(position||"").toLowerCase();if(/keeper|goal/.test(p))return"Gardiens";if(/back|defen|centre-back/.test(p))return"Défense";if(/midfield/.test(p))return"Milieu";return"Attaque";}
  function clubHistoryV101(clubId){
    const ms=safe(state.uclMatches).filter(m=>String(m.home_club?.id)===String(clubId)||String(m.away_club?.id)===String(clubId)).filter(m=>m.status==="finished");let w=0,d=0,l=0,gf=0,ga=0;
    ms.forEach(m=>{const home=String(m.home_club?.id)===String(clubId),a=Number(home?m.home_score:m.away_score),b=Number(home?m.away_score:m.home_score);gf+=a;ga+=b;if(a>b)w++;else if(a<b)l++;else d++;});
    return {played:ms.length,w,d,l,gf,ga};
  }
  function clubFixtureMiniV101(m,clubId){const home=String(m.home_club?.id)===String(clubId),opp=home?m.away_club:m.home_club;const score=["live","finished"].includes(m.status)?`${m.home_score??0}–${m.away_score??0}`:"VS";return `<button type="button" class="club-fixture-v101" data-club-match-v101="${esc(m.id)}"><time>${esc(fmtDate(m.kickoff_at))}<small>${esc(fmtTime(m.kickoff_at))}</small></time>${crestHTML(opp)}<span><strong>${esc(clubName(opp))}</strong><small>${esc(uclStatusLabel(m.status))}</small></span><b>${esc(score)}</b></button>`;}

  function openClubSheetV101(clubId){
    const club=safe(state.clubs).find(c=>String(c.id)===String(clubId));if(!club)return;
    syncUclLiveFromMatchesV101();
    const standing=safe(state.uclStandings).find(r=>String(r.club_id)===String(clubId));
    const matches=safe(state.uclMatches).filter(m=>String(m.home_club?.id)===String(clubId)||String(m.away_club?.id)===String(clubId)).sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at));
    const now=Date.now(),next=matches.filter(m=>m.status!=="cancelled"&&new Date(m.kickoff_at).getTime()>now).slice(0,5),recent=matches.filter(m=>m.status==="finished").slice(-5).reverse();
    const scorers=scorerRowsV101().filter(x=>String(x.club_id)===String(clubId)).sort((a,b)=>Number(b.goals)-Number(a.goals)||Number(b.assists)-Number(a.assists));const best=scorers[0];
    const cards=disciplineRowsV102d().filter(x=>String(x.club_id)===String(clubId));const totals=cards.reduce((a,x)=>({y:a.y+Number(x.yellow_cards||0),yr:a.yr+Number(x.yellow_red_cards||0),r:a.r+Number(x.red_cards||0)}),{y:0,yr:0,r:0});
    const squad=safe(club.squad);const groups=["Gardiens","Défense","Milieu","Attaque"].map(label=>[label,squad.filter(p=>squadGroupV101(p.position)===label)]).filter(([,items])=>items.length);
    const hist=clubHistoryV101(clubId),titles=Number(club.ucl_titles||0);
    const palette=[club.club_colors,club.country].filter(Boolean).join(" · ")||"Informations à compléter";
    const root=modal(club.name,`<div class="club-sheet-v101 club-sheet-v102">
      <header class="club-hero-v102">${crestHTML(club,true)}<div><span class="eyebrow gold">Fiche club · Ligue des champions</span><h2>${esc(club.name)}</h2><p>${esc([club.short_name&&club.short_name!==club.name?club.short_name:null,club.tla,club.country].filter(Boolean).join(" · "))}</p></div>${state.uclLiveProvisionalV101?'<span class="club-live-v101">● LIVE</span>':""}</header>
      <div class="club-summary-v102"><article><small>Classement C1</small><b>${standing?`#${Number(standing.position)}`:"—"}</b><span>${Number(standing?.points||0)} pts</span></article><article><small>Bilan</small><b>${standing?`${Number(standing.won||0)}-${Number(standing.draw||0)}-${Number(standing.lost||0)}`:"—"}</b><span>V-N-D</span></article><article><small>Différence</small><b>${standing?`${Number(standing.goal_difference||0)>0?"+":""}${Number(standing.goal_difference||0)}`:"—"}</b><span>buts</span></article><article class="club-titles-v102"><small>Palmarès C1</small><b>${titles?`${"★".repeat(Math.min(titles,5))}`:"—"}</b><span>${titles} titre${titles>1?"s":""}</span></article></div>
      <section class="club-identity-v102"><div><span class="eyebrow">Identité</span><dl><div><dt>Pays</dt><dd>${esc(club.country||"—")}</dd></div><div><dt>Stade</dt><dd>${esc(club.venue||"—")}</dd></div><div><dt>Fondé</dt><dd>${club.founded?Number(club.founded):"—"}</dd></div><div><dt>Entraîneur</dt><dd>${esc(club.coach_name||"—")}</dd></div><div><dt>Couleurs</dt><dd>${esc(palette)}</dd></div><div><dt>Nom court</dt><dd>${esc(club.short_name||club.tla||"—")}</dd></div></dl>${club.address?`<p>📍 ${esc(club.address)}</p>`:""}${club.website?`<p>🌐 ${esc(club.website)}</p>`:""}</div><aside><span class="eyebrow gold">Histoire européenne</span><h3>${esc(club.ucl_best_result|| (titles?`${titles} Ligue${titles>1?"s":""} des champions`:"À compléter"))}</h3><p>${esc(club.ucl_history||"Le palmarès historique peut être complété manuellement par le Super Admin.")}</p></aside></section>
      <div class="club-feature-grid-v102"><article><span>⚽</span><div><small>Meilleur buteur C1</small><h3>${esc(best?.player_name||"—")}</h3><p>${best?`${Number(best.goals||0)} but${Number(best.goals||0)>1?"s":""} · ${Number(best.assists||0)} passe(s) décisive(s)`:"Aucune donnée API/manuelle."}</p></div></article><article><span>🟨</span><div><small>Discipline C1</small><h3>${totals.y} jaunes · ${totals.r} rouges</h3><p>${totals.yr} double(s) jaune/rouge · ${cards.length} joueur(s)</p></div></article><article><span>📚</span><div><small>Saison C1 dans le Nid</small><h3>${hist.played} match${hist.played>1?"s":""}</h3><p>${hist.w} V · ${hist.d} N · ${hist.l} D · ${hist.gf}-${hist.ga} buts</p></div></article></div>
      <section class="club-section-v102"><div class="section-title compact"><div><span class="eyebrow gold">Effectif</span><h3>Composition & joueurs</h3></div><span class="chip">${squad.length||"—"}</span></div>${groups.length?`<div class="club-squad-v101">${groups.map(([label,items])=>`<div><h4>${label}</h4>${items.map(p=>`<span><b>${esc(p.name)}</b><small>${esc([p.position,p.nationality].filter(Boolean).join(" · "))}</small></span>`).join("")}</div>`).join("")}</div>`:'<div class="empty">Effectif non fourni par l’API. Le Super Admin peut le saisir dans Compétition → Données C1 manuelles.</div>'}</section>
      <section class="club-section-v102"><div class="section-title compact"><div><h3>Prochains matchs</h3><p>Un clic ouvre la journée de pronostics.</p></div></div><div class="club-fixtures-grid-v101">${next.length?next.map(m=>clubFixtureMiniV101(m,clubId)).join(""):'<div class="empty">Aucun match à venir.</div>'}</div></section>
      <section class="club-section-v102"><div class="section-title compact"><div><h3>Derniers résultats</h3></div></div><div class="club-fixtures-grid-v101">${recent.length?recent.map(m=>clubFixtureMiniV101(m,clubId)).join(""):'<div class="empty">Aucun résultat.</div>'}</div></section>
    </div>`);
    root.querySelector(".modal-card")?.classList.add("club-sheet-modal-v101","club-sheet-modal-v102");
    root.querySelectorAll("[data-club-match-v101]").forEach(b=>b.onclick=()=>{const match=safe(state.allMatches).find(m=>String(m.external_match_id)===String(safe(state.uclMatches).find(u=>String(u.id)===String(b.dataset.clubMatchV101))?.external_match_id)||String(m.id)===String(b.dataset.clubMatchV101));root.innerHTML="";if(match&&typeof goToMatchV0912==="function")goToMatchV0912(match.id);});
  }
  window.openClubSheetV101=openClubSheetV101;window.openClubSheetV0912=openClubSheetV101;window.openClubSheetV0913=openClubSheetV101;window.openUclClub=openClubSheetV101;

  // Les anciennes releases lient leurs propres closures sur les équipes des cartes.
  // V1.0.1 reprend la main après chaque rendu pour garantir la nouvelle fiche club.
  const baseRenderMatchPanelsV101=window.renderMatchPanels;
  window.renderMatchPanels=function(){
    const result=baseRenderMatchPanelsV101?.apply(this,arguments);
    document.querySelectorAll("#matchesPanel .match[data-match]").forEach(card=>{
      const match=safe(state.allMatches).find(m=>String(m.id)===String(card.dataset.match));if(!match)return;
      const teams=card.querySelectorAll(".teams>.team");[[teams[0],match.home_club],[teams[1],match.away_club]].forEach(([el,club])=>{if(!el||!club)return;const open=()=>openClubSheetV101(club.id);el.onclick=e=>{if(e.target.closest("button,input"))return;e.preventDefault();open();};el.onkeydown=e=>{if(e.key==="Enter"||e.key===" "){e.preventDefault();open();}};});
    });
    return result;
  };

  // ---------------------------------------------------------------------------
  // 3. Ruban LIVE façon flash infos.
  // ---------------------------------------------------------------------------
  window.renderLiveTicker=function(){
    const official=liveMatches(),tests=safe(state.allMatches).filter(m=>m.status==="live"&&m.is_test),live=state.rankingScope==="test"?tests:official;
    const ticker=byId("liveTicker"),badge=byId("rankingLiveBadge"),testTab=byId("rankingTestTab"),testButton=byId("openTestLiveRanking");
    const hasTests=safe(state.adminAllMatches?.length?state.adminAllMatches:state.allMatches).some(m=>m.is_test&&m.test_enabled!==false);if(testTab)testTab.classList.toggle("hidden",!hasTests);
    if(testButton){testButton.classList.toggle("hidden",!tests.length||state.rankingScope==="test");testButton.onclick=async()=>{await setRankingScope("test");setView("ranking");};}
    if(ticker){ticker.classList.toggle("hidden",!live.length);if(live.length){const items=live.map(m=>`<button type="button" data-flash-match-v101="${esc(m.id)}"><b>${esc(clubName(m.home_club))}</b> ${m.home_score??0}–${m.away_score??0} <b>${esc(clubName(m.away_club))}</b></button>`).join('<span class="flash-sep-v101">◆</span>');ticker.innerHTML=`<div class="live-flash-v101"><span class="live-flash-label-v101"><i></i>${state.rankingScope==="test"?"TEST LIVE":"LIVE"}</span><div class="live-flash-viewport-v101"><div class="live-flash-track-v101"><div class="live-flash-set-v101">${items}</div><div class="live-flash-set-v101" aria-hidden="true">${items}</div></div></div></div>`;ticker.querySelectorAll("[data-flash-match-v101]").forEach(b=>b.onclick=()=>showMatchPredictions?.(b.dataset.flashMatchV101));}else ticker.innerHTML="";}
    if(badge){badge.classList.toggle("live",!!live.length);badge.innerHTML=live.length?`<span class="pulse-dot"></span><b>${state.rankingScope==="test"?"🧪 CLASSEMENT LIVE TEST":"CLASSEMENT LIVE"}</b><small>${live.length} match${live.length>1?"s":""} en cours</small>`:`<span class="pulse-dot"></span><b>${state.rankingScope==="test"?"🧪 TEST":"HORS LIVE"}</b><small>${state.rankingScope==="test"?"Laboratoire séparé":"Aucun match officiel en cours"}</small>`;}
  };

  // ---------------------------------------------------------------------------
  // 4. Classement : points LIVE provisoires visibles et fin de page propre.
  // ---------------------------------------------------------------------------
  function rankingRowsV101(){let rows=safe(state.rankingRows).slice();if(state.rankingScope==="precision")rows.sort((a,b)=>Number(b.precision_pct||0)-Number(a.precision_pct||0)||Number(b.exact_scores||0)-Number(a.exact_scores||0)||Number(b.points||0)-Number(a.points||0));if(state.rankingScope==="exacts")rows.sort((a,b)=>Number(b.exact_scores||0)-Number(a.exact_scores||0)||Number(b.points||0)-Number(a.points||0));return rows.map((r,i)=>({...r,display_rank:i+1}));}
  function rankVarV101(v){v=Number(v||0);return v>0?`<span class="rank-var up">▲ ${v}</span>`:v<0?`<span class="rank-var down">▼ ${Math.abs(v)}</span>`:'<span class="rank-var same">—</span>';}
  function primaryV101(r){if(state.rankingScope==="precision")return[`${Number(r.precision_pct||0).toFixed(1)}%`,"précision"];if(state.rankingScope==="exacts")return[String(Number(r.exact_scores||0)),"exacts"];return[String(Number(r.points||0).toFixed(0)),"points"];}
  window.renderRanking=function(){
    const body=byId("rankingBody");if(!body)return;document.querySelectorAll("[data-ranking-scope]").forEach(b=>b.classList.toggle("active",b.dataset.rankingScope===state.rankingScope));const rows=rankingRowsV101(),live=liveMatches().length>0;
    const label={general:"Général",matchday:`J${selectedMatchday()?.number||"?"}`,evening:"Soirée",precision:"Précision",exacts:"Scores exacts",test:"🧪 TEST"}[state.rankingScope]||"Général";
    if(byId("rankingSubtitle"))byId("rankingSubtitle").textContent=state.rankingScope==="general"?"Le plus de points gagne. En cas d’égalité : exacts, moyenne, bons écarts puis pronostics joués.":state.rankingScope==="matchday"?`Seulement ${selectedMatchday()?.name||"la journée sélectionnée"}.`:state.rankingScope==="evening"?`La photo de la soirée du ${state.selectedEveningDate||"jour sélectionné"}.`:state.rankingScope==="precision"?"Qui transforme le plus souvent ses pronostics en bons résultats.":"Qui trouve le plus de scores parfaitement exacts.";
    if(byId("rankingContext"))byId("rankingContext").innerHTML=`<span class="context-pill">${esc(label)}</span><span class="context-pill">${rows.length} joueur${rows.length>1?"s":""}</span>${live&&state.rankingScope==="general"?'<span class="context-pill live-context-v100">● provisoire LIVE</span>':""}`;if(byId("collectiveScopeChip"))byId("collectiveScopeChip").textContent=label;
    body.innerHTML=rows.length?rows.map(r=>{const rank=Number(r.display_rank),me=String(r.user_id)===String(state.user?.id),rival=String(r.user_id)===String(state.currentRival?.rival_user_id||""),team=teamForUser(r.user_id),[primary,plabel]=primaryV101(r);const official=r.official_points==null?Number(r.points||0):Number(r.official_points||0),delta=Number(r.points||0)-official;const liveChip=live&&state.rankingScope==="general"?`<em class="ranking-live-delta-v101">${delta>0?"+":""}${Number(delta).toFixed(0)} LIVE</em>`:"";return `<article class="ranking-row-v100 ranking-row-v101 ${me?"me":""} ${rival?"rival":""} ${rank<=3?`podium-${rank}`:""}"><div class="ranking-pos-v100"><span class="rank-medal">${rank}</span>${state.rankingScope==="general"?rankVarV101(r.variation):""}</div><div class="ranking-player-v100">${avatarHTML(r)}<div><div class="ranking-name-line-v100"><button data-player-profile="${esc(r.user_id)}" type="button">${esc(r.username)}</button>${reactionButtonHTML(r.user_id,true)}${rival?'<span class="rival-mini-v100">⚔ Rival</span>':""}</div>${team?`<small>${esc(team.team_name||team.name||"")}</small>`:""}</div></div><div class="ranking-main-v100"><strong>${esc(primary)}</strong><small>${esc(plabel)}</small>${liveChip}</div><div class="ranking-details-v100"><span><b>${Number(r.points||0).toFixed(0)}</b> pts</span><span><b>${Number(r.exact_scores||0)}</b> exacts</span><span><b>${Number(r.precision_pct||0).toFixed(1)}%</b> précis.</span><span><b>${Number(r.played||0)}</b> joués</span></div></article>`;}).join(""):'<div class="empty">Aucun classement.</div>';
    body.querySelectorAll("[data-player-profile]").forEach(b=>b.onclick=e=>{e.stopPropagation();openPlayerQuickProfile?.(b.dataset.playerProfile);});bindPlayerReactionButtons?.(body);
    const mine=rows.find(r=>String(r.user_id)===String(state.user?.id)),sticky=byId("myRankingSticky");if(sticky){sticky.classList.toggle("hidden",!mine);if(mine){const[p,l]=primaryV101(mine);sticky.innerHTML=`<span class="sticky-rank">#${mine.display_rank}</span>${state.rankingScope==="general"?rankVarV101(mine.variation):""}<span class="sticky-name">${avatarHTML(mine)}<b>${esc(mine.username)}</b></span><span class="sticky-main-v100"><b>${esc(p)}</b><small>${esc(l)}</small></span>`;}}
    updateKpis?.();
  };

  // ---------------------------------------------------------------------------
  // 5. Player modal : forme compréhensible + casseroles/génie détaillés.
  // ---------------------------------------------------------------------------
  function formDetailedV101(form=[]){const map={exact:["🎯","Exact"],difference:["↔","Bon écart"],result:["✓","Bon résultat"],miss:["0","Raté"]};return `<div class="form-detail-v101">${safe(form).map(x=>{const m=map[x.result]||["·",String(x.result||"Match")];return `<span class="form-detail-${esc(x.result||"miss")}"><b>${m[0]}</b><small>${esc(m[1])}</small><em>${Number(x.points||0)} pt${Number(x.points||0)>1?"s":""}</em></span>`;}).join("")||'<span class="muted">Pas encore de forme récente.</span>'}</div>`;}
  window.openPlayerQuickProfile=async function(userId){
    const p=state.profileDirectory.get(String(userId));if(!p)return toast("Joueur introuvable.","error");const lb=safe(state.rankingRows).find(r=>String(r.user_id)===String(userId))||{},team=teamForUser(userId);let seasonStats=null,career=null;
    if(demoMode&&String(userId)===String(state.user?.id)){seasonStats=state.seasonProfileStats;career=state.playerCareer;}else if(!demoMode&&state.season){try{const[sp,cp]=await Promise.all([sb.rpc("get_player_season_profile_v090",{p_season_id:state.season.id,p_user_id:userId}),sb.rpc("get_player_career_v090",{p_user_id:userId})]);if(!sp.error)seasonStats=sp.data?.[0]||null;if(!cp.error)career=cp.data||null;}catch(_){}}
    const picks=await loadPublicChampionPicksV100(userId),ss=seasonStats||lb||{},cs=career?.summary||{},dist=career?.distinctions||seasonStats?.distinctions||[];const mv=safe(state.nidMovementStatsV101).find(x=>String(x.user_id)===String(userId))||{};
    const root=modal(`Profil · ${p.username}`,`<div class="public-player-profile public-player-profile-v101"><div class="public-player-head">${avatarHTML({...p,user_id:p.id||userId})}<div><span class="eyebrow">Joueur du Nid</span><h2>${esc(p.username)}</h2><p>${esc(p.club_heart||"Aucun club de cœur")}${team?` · 🛡 ${esc(team.team_name||team.name||"")}`:""}</p></div></div><div class="rival-stats-grid compact"><div><span>Rang</span><strong>#${lb.rank||ss.rank||"—"}</strong></div><div><span>Points</span><strong>${Number(lb.points??ss.points??0).toFixed(0)}</strong></div><div><span>Exacts</span><strong>${Number(ss.exact_scores||lb.exact_scores||0)}</strong></div><div><span>Moyenne</span><strong>${Number(ss.average||lb.average||0).toFixed(2)}</strong></div></div>${publicChampionPicksHTMLV100(picks)}<div class="section-title compact"><div><span class="eyebrow gold">Saison & carrière</span><h4>Repères du joueur</h4></div></div><div class="career-stat-grid compact"><article><span>Meilleur rang</span><strong>#${ss.best_rank||ss.rank||"—"}</strong><small>saison actuelle</small></article><article><span>Rang carrière</span><strong>#${cs.rank||"—"}</strong><small>${cs.seasons_played||0} saison(s)</small></article><article><span>Casserole</span><strong>${Number(ss.casserole_points??mv.casserole_points??0)}</strong><small>${Number(ss.casseroles??mv.casserole_events??0)} événement(s)</small></article><article><span>Génie</span><strong>${Number(ss.genius_points??mv.genius_points??0)}</strong><small>${Number(ss.genius??mv.genius_events??0)} coup(s)</small></article><article><span>Série à zéro</span><strong>${Number(mv.zero_streak||0)}</strong><small>prono(s) de suite</small></article><article><span>Titres</span><strong>${cs.titles||0}</strong><small>${cs.podiums||0} podium(s)</small></article></div><div class="section-title compact"><div><span class="eyebrow">Forme récente</span><h4>Ce que signifient les 5 derniers résultats</h4></div></div>${formDetailedV101(ss.form||[])}${dist.length?`<div class="distinction-list compact">${dist.map(d=>`<span><b>${esc(d.icon||"🏆")}</b><span><strong>${esc(d.label)}</strong><small>${esc(d.description||"")}</small></span></span>`).join("")}</div>`:""}<div class="actions"><button id="openPlayerMuseumBtn" class="btn secondary small" type="button">🏛️ Voir son Musée</button>${String(userId)!==String(state.user?.id)?'<button id="reactFromPlayerProfile" class="btn secondary small" type="button">😊 Envoyer une réaction</button>':""}${state.profile?.role==="super_admin"?'<button id="superOwlFromPlayerProfile" class="btn gold small" type="button">🦉 Envoyer un message du Hibou</button>':""}${String(userId)===String(state.currentRival?.rival_user_id||"")?'<button id="openProfileRivalCompare" class="btn secondary small" type="button">⚔ Comparer au rival</button>':""}</div></div>`);
    byId("openPlayerMuseumBtn")&&(byId("openPlayerMuseumBtn").onclick=()=>openPlayerMuseum(userId));byId("reactFromPlayerProfile")&&(byId("reactFromPlayerProfile").onclick=()=>openPlayerReactionPicker(userId));byId("superOwlFromPlayerProfile")&&(byId("superOwlFromPlayerProfile").onclick=()=>openAdminOwlMessageForPlayer(userId));byId("openProfileRivalCompare")&&(byId("openProfileRivalCompare").onclick=openRivalQuickCompare);
  };

  // ---------------------------------------------------------------------------
  // 6. Mouvement du Nid + habillage Team des deux carrousels.
  // ---------------------------------------------------------------------------
  async function loadMovementV101(force=false){
    if(!state.season||demoMode)return;const now=Date.now();if(!force&&now-Number(state.nidMovementStatsLoadedAtV101||0)<15000)return;if(state.nidMovementStatsLoadingV101)return;state.nidMovementStatsLoadingV101=true;
    try{const {data,error}=await sb.rpc("get_nid_movement_v101",{p_season_id:state.season.id});if(!error){state.nidMovementStatsV101=data||[];state.nidMovementStatsLoadedAtV101=Date.now();}}catch(_){}finally{state.nidMovementStatsLoadingV101=false;}
  }
  window.loadMovementV101=loadMovementV101;
  function storyPlayerV101(userId){const p=state.profileDirectory?.get?.(String(userId));return p?`<div class="nid-story-player-v100">${avatarHTML({...p,user_id:userId})}<strong>${esc(p.username||"Joueur")}</strong></div>`:"";}
  function movementStoriesV101(){
    const rows=safe(state.nidMovementRankingV100?.length?state.nidMovementRankingV100:state.rankingRows).filter(r=>r.user_id),stats=safe(state.nidMovementStatsV101),stories=[];
    const leader=rows.slice().sort((a,b)=>Number(a.rank||999)-Number(b.rank||999))[0];if(leader)stories.push({kind:"leader",icon:"👑",user:leader.user_id,eyebrow:"Classement",title:"Le patron du Nid",value:`#1 · ${Number(leader.points||0)} pts`,text:`${Number(leader.exact_scores||0)} exact(s) · ${Number(leader.precision_pct||0).toFixed(1)}% de précision`});
    const zero=stats.slice().sort((a,b)=>Number(b.zero_streak||0)-Number(a.zero_streak||0))[0];if(Number(zero?.zero_streak||0)>0)stories.push({kind:"zero",icon:"🥶",user:zero.user_id,eyebrow:"Série de zéro",title:"Le trou d’air",value:`${Number(zero.zero_streak)} zéro${Number(zero.zero_streak)>1?"s":""} de suite`,text:"Le Hibou commence à sortir la couverture de survie."});
    const cass=stats.slice().sort((a,b)=>Number(b.casserole_points||0)-Number(a.casserole_points||0))[0];if(Number(cass?.casserole_events||0)>0)stories.push({kind:"casserole",icon:"🍳",user:cass.user_id,eyebrow:"Casseroles",title:"La poêle chauffe",value:`${Number(cass.casserole_points||0)} pts casserole`,text:`${Number(cass.casserole_events||0)} casserole(s) comptabilisées`});
    const gen=stats.slice().sort((a,b)=>Number(b.genius_points||0)-Number(a.genius_points||0))[0];if(Number(gen?.genius_events||0)>0)stories.push({kind:"genius",icon:"💡",user:gen.user_id,eyebrow:"Génie",title:"Les neurones fument",value:`+${Number(gen.genius_points||0)} pts génie`,text:`${Number(gen.genius_events||0)} coup(s) de génie`});
    safe(state.gamificationEvents).filter(e=>["casserole","genius"].includes(e.event_type)).slice(0,6).forEach(e=>stories.push({kind:e.event_type,icon:e.event_type==="casserole"?"🍳":"✨",user:e.user_id,eyebrow:e.event_type==="casserole"?"Casserole récente":"Génie récent",title:e.title||(e.event_type==="casserole"?"Ça sent le brûlé":"Éclair de lucidité"),value:`${Number(e.points||0)>0?"+":""}${Number(e.points||0)} pt${Math.abs(Number(e.points||0))>1?"s":""}`,text:e.message||String(e.subtype||"").replaceAll("_"," ")}));
    safe(state.gamificationRecords).filter(r=>r.active!==false&&String(r.scope||"nid")==="nid").slice(0,5).forEach(r=>stories.push({kind:"record",icon:"🏆",user:r.user_id,eyebrow:"Record du Nid",title:r.record_name||r.record_key||"Record",value:String(Number(r.value||0)),text:r.is_equal?"Record égalé":"Une nouvelle marque à battre"}));
    const seen=new Set();return stories.filter(s=>{const k=`${s.kind}:${s.title}:${s.user||""}`;if(seen.has(k))return false;seen.add(k);return true;}).slice(0,14);
  }
  function renderMovementV101(){const root=byId("homeActivityCarouselV0912");if(!root)return;const stories=movementStoriesV101();root.innerHTML=stories.length?stories.map(s=>`<article class="home-carousel-card-v0912 home-life-card-v0912 nid-story-v100 nid-story-v101 story-${esc(s.kind)}" ${s.user?`data-story-player-v101="${esc(s.user)}" tabindex="0" role="button"`:""}><div class="nid-story-top-v100"><span class="nid-story-icon-v100">${s.icon}</span><span class="eyebrow">${esc(s.eyebrow)}</span></div>${s.user?storyPlayerV101(s.user):""}<h4>${esc(s.title)}</h4><strong class="nid-story-value-v100">${esc(s.value||"")}</strong><p>${esc(s.text||"")}</p></article>`).join(""):'<div class="empty">Le Nid attend ses premières histoires.</div>';root.querySelectorAll("[data-story-player-v101]").forEach(c=>{const open=()=>openPlayerQuickProfile(c.dataset.storyPlayerV101);c.onclick=open;c.onkeydown=e=>{if(e.key==="Enter"||e.key===" "){e.preventDefault();open();}};});startCarouselFromCurrentV101(root);}
  function startCarouselFromCurrentV101(root){const cards=[...root.querySelectorAll(".home-carousel-card-v0912")];if(!cards.length)return;let i=0;cards.forEach((c,n)=>c.classList.toggle("active-auto-v0912",n===0));if(root._v101Timer)clearInterval(root._v101Timer);if(cards.length>1)root._v101Timer=setInterval(()=>{if(document.hidden)return;i=(i+1)%cards.length;cards.forEach((c,n)=>c.classList.toggle("active-auto-v0912",n===i));},5400);}
  function applyTeamCarouselV101(){const team=currentTeam();document.querySelectorAll("#homeUpcomingCarouselV0912 .home-carousel-card-v0912,#homeActivityCarouselV0912 .home-carousel-card-v0912").forEach(card=>{card.classList.add("team-carousel-v101");[...card.classList].filter(c=>c.startsWith("bg-")).forEach(c=>card.classList.remove(c));if(team){card.classList.add(`bg-${team.background_style||"diagonal"}`);card.setAttribute("style",teamVisualVars(team));}else card.removeAttribute("style");});}
  const baseRenderHomeV101=window.renderHome;
  window.renderHome=function(){const r=baseRenderHomeV101?.apply(this,arguments);renderMovementV101();applyTeamCarouselV101();loadMovementV101().then(()=>{if(!byId("view-home")?.classList.contains("hidden")){renderMovementV101();applyTeamCarouselV101();}});return r;};
  const baseRenderRelease100V101=window.renderRelease100;
  if(typeof baseRenderRelease100V101==="function")window.renderRelease100=function(){const r=baseRenderRelease100V101.apply(this,arguments);renderMovementV101();applyTeamCarouselV101();return r;};

  // ---------------------------------------------------------------------------
  // 7. Pronostics : passer automatiquement à la prochaine journée non terminée.
  // ---------------------------------------------------------------------------
  const baseSetViewV101=window.setView;
  window.setView=function(name){
    if(name==="matches"){
      const current=state.matchdays?.find(md=>String(md.id)===String(state.selectedMatchdayId));const currentMatches=safe(state.allMatches).filter(m=>String(m.matchday_id)===String(current?.id)&&!m.is_test);const done=currentMatches.length&&currentMatches.every(m=>["finished","cancelled"].includes(m.status));
      if(done){const next=safe(state.matchdays).filter(md=>Number(md.number||999)>Number(current?.number||0)).sort((a,b)=>Number(a.number)-Number(b.number)).find(md=>safe(state.allMatches).some(m=>String(m.matchday_id)===String(md.id)&&!m.is_test&&!["finished","cancelled"].includes(m.status)));if(next){state.selectedMatchdayId=next.id;state.matches=safe(state.allMatches).filter(m=>String(m.matchday_id)===String(next.id));setTimeout(()=>selectMatchday(next.id).catch(()=>{}),0);}}
    }
    return baseSetViewV101(name);
  };

  // ---------------------------------------------------------------------------
  // 8. Rivalités : relecture après fin de journée, en complément du trigger SQL.
  // ---------------------------------------------------------------------------
  window.maybeRefreshRivalsAfterMatchV101=function(){clearTimeout(state.rivalFinishTimerV101);state.rivalFinishTimerV101=setTimeout(async()=>{try{await loadRivalData();renderHomeRival();renderRivalView();}catch(_){}},350);};

  window.renderRelease101=function(){syncUclLiveFromMatchesV101();renderMovementV101();applyTeamCarouselV101();};
})();
