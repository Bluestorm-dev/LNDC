"use strict";

// Le Nid des Champions V0.5.5a — Teams
  // ========================================================================
  // V0.5.2 — Teams · formes/cadres/couleurs corrigés
  // ========================================================================
  const TEAM_SHAPES = [
    ["circle","Cercle"],["medallion","Médaillon"],["rounded","Carré arrondi"],["square","Carré prestige"],
    ["diamond","Losange"],["hex","Hexagone"],["shield-classic","Écusson classique"],["shield-point","Écusson pointu"],
    ["shield-modern","Bouclier moderne"],["banner","Bannière"],["royal","Blason royal"],["prestige","Carte prestige"]
  ];
  const TEAM_FRAMES = [
    ["wood","Bois"],["bronze","Bronze"],["silver","Argent"],["gold","Or"],["royal-gold","Or royal"],["steel","Acier"],
    ["leather","Cuir"],["obsidian","Obsidienne"],["neon","Néon"],["champions","Champions"],["royal","Royal bleu/or"],["night","Nuit européenne"]
  ];
  const TEAM_BACKGROUNDS = [
    ["solid","Uni","single"],
    ["vertical","Dégradé vertical","gradient"],["horizontal","Dégradé horizontal","gradient"],["diagonal","Dégradé diagonal","gradient"],["radial","Radial","gradient"],["halo","Halo","gradient"],
    ["split-vertical","Moitié verticale","pattern"],["split-horizontal","Moitié horizontale","pattern"],["split-diagonal","Moitié diagonale","pattern"],
    ["stripes-vertical","Bandes verticales","pattern"],["stripes-horizontal","Bandes horizontales","pattern"],["stripes-diagonal","Bandes diagonales","pattern"],["quarters","Quartiers","pattern"]
  ];
  const TEAM_LOGOS = {
    owl:{label:"Hibou",glyph:"🦉"},star:{label:"Étoile",glyph:"✦"},shield:{label:"Garde",glyph:"⚜"},bolt:{label:"Éclair",glyph:"⚡"},
    crown:{label:"Couronne",glyph:"♛"},moon:{label:"Lune",glyph:"☾"},feather:{label:"Plume",glyph:"🪶"},torch:{label:"Flamme",glyph:"🔥"},
    ball:{label:"Football",glyph:"⚽"},tower:{label:"Tour",glyph:"♜"},diamond:{label:"Diamant",glyph:"◆"},eagle:{label:"Aigle",glyph:"🦅"}
  };
  const TEAM_STYLE_PRESETS = {
    champions:{label:"Champions bleu",shape:"shield-modern",frame_style:"champions",primary_color:"#0b2f73",secondary_color:"#6b4cff",background_style:"diagonal",color_mode:"two"},
    royal:{label:"Or royal",shape:"royal",frame_style:"royal-gold",primary_color:"#102b6a",secondary_color:"#315cff",background_style:"radial",color_mode:"two"},
    forest:{label:"Bois forêt",shape:"shield-classic",frame_style:"wood",primary_color:"#1f5b3a",secondary_color:"#163a67",background_style:"diagonal",color_mode:"two"},
    obsidian:{label:"Obsidienne",shape:"hex",frame_style:"obsidian",primary_color:"#111827",secondary_color:"#512a8a",background_style:"radial",color_mode:"two"},
    neon:{label:"Néon",shape:"hex",frame_style:"neon",primary_color:"#071c3f",secondary_color:"#6a2cff",background_style:"halo",color_mode:"two"}
  };

  function safeTeamColor(value,fallback="#315cff") { return /^#[0-9a-f]{6}$/i.test(String(value||"")) ? String(value) : fallback; }
  function teamVisualVars(team) {
    return `--team-primary:${safeTeamColor(team?.primary_color)};--team-secondary:${safeTeamColor(team?.secondary_color,"#7454ff")}`;
  }
  function teamClass(team,prefix="team-skin") {
    const shape=TEAM_SHAPES.some(x=>x[0]===team?.shape)?team.shape:"shield-classic";
    const frame=TEAM_FRAMES.some(x=>x[0]===team?.frame_style)?team.frame_style:"champions";
    const bg=TEAM_BACKGROUNDS.some(x=>x[0]===team?.background_style)?team.background_style:"diagonal";
    return `${prefix} shape-${shape} frame-${frame} bg-${bg}`;
  }
  function teamLogoHTML(team,large=false) {
    if(!team) return `<span class="team-logo ${large?'large':''}">🛡</span>`;
    if(team.logo_type==="upload" && team.logo_url) return `<span class="team-logo ${large?'large':''}"><img src="${esc(team.logo_url)}" alt="" loading="lazy"></span>`;
    const logo=TEAM_LOGOS[team.logo_asset_key]||TEAM_LOGOS.owl;
    return `<span class="team-logo ${large?'large':''}" aria-hidden="true">${logo.glyph}</span>`;
  }
  function teamForUser(userId) { return state.teamDirectoryMap?.get(String(userId))||null; }
  function profileForUser(profile) {
    const userId=profile?.user_id||profile?.id;
    const base=userId?state.profileDirectory?.get(String(userId)):null;
    return {...(base||{}),...(profile||{}),id:profile?.id||base?.id||userId,user_id:profile?.user_id||base?.user_id||userId};
  }
  function teamBadgeHTML(team,large=false) {
    if(!team) return "";
    return `<span class="team-badge-visual ${teamClass(team)} ${large?'large':''}" style="${teamVisualVars(team)}">${teamLogoHTML(team,large)}</span>`;
  }
  function teamFavoriteClub(team) {
    if(!team?.favorite_club_id) return null;
    return clubById(team.favorite_club_id) || {
      id:team.favorite_club_id,name:team.favorite_club_name,short_name:team.favorite_club_short,
      logo_url:team.favorite_club_logo_url,logo_storage_path:team.favorite_club_logo_storage_path
    };
  }

  function ensureDemoTeams() {
    let teams=JSON.parse(localStorage.getItem("nidc_demo_teams")||"null");
    let memberships=JSON.parse(localStorage.getItem("nidc_demo_team_memberships")||"null");
    if(!Array.isArray(teams)) {
      teams=[{id:"team-demo-stars",season_id:"season-demo",name:"Les Étoiles du Nid",slug:"etoiles-du-nid",slogan:"On vise la lucarne.",description:"Une Team de démonstration pour tester le système communautaire.",favorite_club_id:"c7",visibility:"private",status:"active",captain_user_id:"demo-ju",captain_username:"Ju",logo_type:"library",logo_asset_key:"star",logo_url:null,shape:"shield-classic",frame_style:"gold",primary_color:"#0b7a55",secondary_color:"#2457d6",background_style:"diagonal",created_at:new Date(Date.now()-10*86400000).toISOString()}];
      localStorage.setItem("nidc_demo_teams",JSON.stringify(teams));
    }
    if(!Array.isArray(memberships)) {
      memberships=[
        {id:"tm-demo-ju",season_id:"season-demo",team_id:"team-demo-stars",user_id:"demo-ju",joined_at:new Date(Date.now()-10*86400000).toISOString(),left_at:null,join_type:"creator"},
        {id:"tm-demo-tourteau",season_id:"season-demo",team_id:"team-demo-stars",user_id:"demo-tourteau",joined_at:new Date(Date.now()-8*86400000).toISOString(),left_at:null,join_type:"request"}
      ];
      localStorage.setItem("nidc_demo_team_memberships",JSON.stringify(memberships));
    }
    if(!localStorage.getItem("nidc_demo_team_events")) localStorage.setItem("nidc_demo_team_events",JSON.stringify([{id:1,team_id:"team-demo-stars",event_type:"team_created",actor_id:"demo-ju",target_user_id:"demo-ju",created_at:new Date(Date.now()-10*86400000).toISOString(),payload:{name:"Les Étoiles du Nid"}}]));
    if(!localStorage.getItem("nidc_demo_team_requests")) localStorage.setItem("nidc_demo_team_requests","[]");
    if(!localStorage.getItem("nidc_demo_team_invites")) localStorage.setItem("nidc_demo_team_invites",JSON.stringify({"team-demo-stars":"NID-DEMO2026"}));
    return {teams,memberships};
  }

  function demoTeamLeaderboard(matchdayOnly=false) {
    const {teams,memberships}=ensureDemoTeams();
    const lb=buildDemoLeaderboard(matchdayOnly?"matchday":"general");
    return teams.filter(t=>t.status==="active").map(t=>{
      const members=memberships.filter(m=>m.team_id===t.id&&!m.left_at);
      const scores=members.map(m=>Number(lb.find(x=>x.user_id===m.user_id)?.points||0)).sort((a,b)=>b-a);
      const total=scores.reduce((a,b)=>a+b,0),average=scores.length?total/scores.length:0,top3=scores.slice(0,3).reduce((a,b)=>a+b,0);
      return {...t,team_id:t.id,team_name:t.name,current_members:members.length,contributors:members.length,total_points:total,average_points:average,top3_points:top3};
    }).sort((a,b)=>b.average_points-a.average_points).map((r,i,all)=>({...r,rank_average:i+1,rank_top3:[...all].sort((a,b)=>b.top3_points-a.top3_points).findIndex(x=>x.id===r.id)+1}));
  }

  function refreshDemoTeamState() {
    const {teams,memberships}=ensureDemoTeams();
    const activeTeams=teams.filter(t=>t.status==="active");
    state.teamDirectory=teams.map(t=>({...t,team_id:t.id,captain_username:state.demoUsers.find(u=>u.id===t.captain_user_id)?.username||null,member_count:memberships.filter(m=>m.team_id===t.id&&!m.left_at).length}));
    const myMembership=memberships.find(m=>m.season_id===state.season.id&&m.user_id===state.user?.id&&!m.left_at);
    const my=activeTeams.find(t=>t.id===myMembership?.team_id)||null;
    state.myTeam=my?{...my,team_id:my.id,captain_username:state.demoUsers.find(u=>u.id===my.captain_user_id)?.username||"—",is_captain:my.captain_user_id===state.user?.id,joined_at:myMembership.joined_at,member_count:memberships.filter(m=>m.team_id===my.id&&!m.left_at).length}:null;
    state.teamDirectoryMap=new Map();
    memberships.filter(m=>!m.left_at).forEach(m=>{
      const t=activeTeams.find(x=>x.id===m.team_id);const p=state.demoUsers.find(u=>u.id===m.user_id);if(t&&p)state.teamDirectoryMap.set(String(m.user_id),{...t,team_id:t.id,team_name:t.name,is_captain:t.captain_user_id===m.user_id,user_id:m.user_id,username:p.username});
    });
    if(state.myTeam){
      state.teamMembers=memberships.filter(m=>m.team_id===state.myTeam.id&&!m.left_at).map(m=>{const p=state.demoUsers.find(u=>u.id===m.user_id)||{};const lb=state.standings.find(x=>x.user_id===m.user_id)||{};return{user_id:m.user_id,username:p.username||"?",avatar_key:p.avatar_key,club_heart:p.club_heart,is_captain:state.myTeam.captain_user_id===m.user_id,joined_at:m.joined_at,points:lb.points||0,exact_scores:lb.exact_scores||0,average:lb.average||0,rank:lb.rank||null};});
      const events=JSON.parse(localStorage.getItem("nidc_demo_team_events")||"[]").filter(e=>e.team_id===state.myTeam.id).sort((a,b)=>new Date(b.created_at)-new Date(a.created_at));
      state.teamEvents=events.map(e=>({...e,event_id:e.id,actor_username:state.demoUsers.find(u=>u.id===e.actor_id)?.username||null,target_username:state.demoUsers.find(u=>u.id===e.target_user_id)?.username||null}));
      state.teamRequests=JSON.parse(localStorage.getItem("nidc_demo_team_requests")||"[]").filter(r=>r.team_id===state.myTeam.id&&r.status==="pending").map(r=>{const p=state.demoUsers.find(u=>u.id===r.user_id)||{};return{request_id:r.id,user_id:r.user_id,username:p.username,avatar_key:p.avatar_key,club_heart:p.club_heart,requested_at:r.requested_at};});
      state.teamInvite=(JSON.parse(localStorage.getItem("nidc_demo_team_invites")||"{}"))[state.myTeam.id]||null;
    } else {state.teamMembers=[];state.teamEvents=[];state.teamRequests=[];state.teamInvite=null;}
    state.teamLeaderboardRows=demoTeamLeaderboard(state.teamRankingMode==="matchday");
  }

  async function loadTeamData() {
    state.teamMigrationError=null;
    if(demoMode){refreshDemoTeamState();return;}
    if(!state.season)return;
    try{
      const [dir,my,memberDir,lb]=await Promise.all([
        sb.rpc("get_team_directory_v050",{p_season_id:state.season.id}),
        sb.rpc("get_my_team_v050",{p_season_id:state.season.id}),
        sb.rpc("get_team_member_directory_v050",{p_season_id:state.season.id}),
        sb.rpc("get_team_leaderboard_v050",{p_season_id:state.season.id,p_matchday_id:state.teamRankingMode==="matchday"?state.selectedMatchdayId:null})
      ]);
      const err=dir.error||my.error||memberDir.error||lb.error;if(err)throw err;
      state.teamDirectory=dir.data||[];
      state.myTeam=my.data?.[0]||null;
      state.teamDirectoryMap=new Map((memberDir.data||[]).map(r=>[String(r.user_id),r]));
      state.teamLeaderboardRows=lb.data||[];
      if(state.myTeam){
        const [members,events,requests,invite]=await Promise.all([
          sb.rpc("get_team_members_v050",{p_team_id:state.myTeam.team_id}),
          sb.rpc("get_team_history_v050",{p_team_id:state.myTeam.team_id}),
          state.myTeam.is_captain?sb.rpc("get_team_join_requests_v050",{p_team_id:state.myTeam.team_id}):Promise.resolve({data:[],error:null}),
          state.myTeam.is_captain?sb.rpc("get_team_active_invite_v050",{p_team_id:state.myTeam.team_id}):Promise.resolve({data:null,error:null})
        ]);
        if(members.error)throw members.error;if(events.error)throw events.error;
        state.teamMembers=members.data||[];state.teamEvents=events.data||[];state.teamRequests=requests.error?[]:(requests.data||[]);state.teamInvite=invite.error?null:invite.data;
      }else{state.teamMembers=[];state.teamEvents=[];state.teamRequests=[];state.teamInvite=null;}
    }catch(err){
      console.warn("Teams V0.5.0",err);
      state.teamMigrationError=/PGRST202|Could not find the function|does not exist/i.test(err?.message||"")?"Le patch SQL V0.5.0 Teams n'est pas encore installé dans Supabase.":friendlyError(err);
      state.teamDirectory=[];state.myTeam=null;state.teamDirectoryMap=new Map();state.teamMembers=[];state.teamEvents=[];state.teamRequests=[];state.teamLeaderboardRows=[];
    }
  }

  function currentTeamLeaderboardRow(){return state.teamLeaderboardRows.find(r=>String(r.team_id)===String(state.myTeam?.team_id))||null;}
  function teamMetric(row,mode=state.teamRankingMode){return mode==="top3"?Number(row.top3_points||0):mode==="matchday"?Number(row.average_points||0):Number(row.average_points||0);}
  function teamMetricLabel(row,mode=state.teamRankingMode){return mode==="top3"?`${Number(row.top3_points||0).toFixed(0)} pts`:`${Number(row.average_points||0).toFixed(2)} pts/joueur`;}

  function renderTeams(){
    if(!$("#myTeamPanel"))return;
    const err=state.teamMigrationError;
    if(err){$("#myTeamPanel").innerHTML=`<article class="card card-pad"><div class="form-msg error">${esc(err)}</div><p class="muted">Exécute <code>sql/HOTFIX_V0.5.0_EXISTING_DB.sql</code>, puis recharge l'application.</p></article>`;renderTeamDirectory();renderTeamLeaderboard();return;}
    renderMyTeamPanel();renderTeamDirectory();renderTeamLeaderboard();renderProfileTeam();
  }

  function renderMyTeamPanel(){
    const root=$("#myTeamPanel");if(!root)return;
    const t=state.myTeam;
    if(!t){
      const recoverable=(state.teamDirectory||[]).filter(x=>x.status==="dissolved"&&String(x.captain_user_id||"")===String(state.user?.id||""));
      root.innerHTML=`<article class="card team-empty-card"><img src="assets/branding/owl/owl-masked-main.png" alt="" class="team-empty-owl"><div><span class="eyebrow gold">Une seule Team active</span><h2>Tu n'as pas encore trouvé ton Nid.</h2><p class="muted">Crée ta communauté ou rejoins une Team existante. Tes anciens points ne seront jamais déplacés rétroactivement.</p><div class="actions"><button class="btn gold" data-team-create>Créer une Team</button><button class="btn secondary" data-team-code>Rejoindre avec un code</button></div></div></article>${recoverable.length?`<article class="card card-pad team-recover-card"><span class="eyebrow">Anciennes Teams</span><h3>Une Team dissoute peut être réactivée.</h3><p class="muted">Ces Teams restent archivées tant que tu ne les réactives pas.</p><div class="team-recover-list">${recoverable.map(x=>`<div class="team-recover-row">${teamBadgeHTML(x)}<div><strong>${esc(x.name)}</strong><small>Dissoute · ancien capitaine</small></div><button class="btn secondary small" data-reclaim-team="${x.team_id}">Réactiver</button></div>`).join('')}</div></article>`:''}`;
      $$('[data-team-create]',root).forEach(b=>b.onclick=()=>openTeamEditor());$$('[data-team-code]',root).forEach(b=>b.onclick=openJoinCodeModal);$$('[data-reclaim-team]',root).forEach(b=>b.onclick=()=>reclaimTeam(b.dataset.reclaimTeam));return;
    }
    const fav=teamFavoriteClub(t),lb=currentTeamLeaderboardRow();
    root.innerHTML=`<article class="card team-home-card" style="${teamVisualVars(t)}">
      <div class="team-home-banner bg-${esc(t.background_style)}"><div class="team-home-identity">${teamBadgeHTML(t,true)}<div><span class="eyebrow">Ma Team</span><h2>${esc(t.name)}</h2>${t.slogan?`<p>« ${esc(t.slogan)} »</p>`:''}<div class="team-meta-pills"><span>👑 ${esc(t.captain_username||'Capitaine')}</span><span>${Number(t.member_count||state.teamMembers.length)} membre${Number(t.member_count||state.teamMembers.length)>1?'s':''}</span><span>${t.visibility==='private'?'🔒 Privée':'🌐 Publique'}</span></div></div></div>
      ${fav?`<div class="team-favorite">${crestHTML(fav)}<span>Équipe fétiche<strong>${esc(fav.name||t.favorite_club_name)}</strong></span></div>`:'<div class="team-favorite muted">Aucune équipe fétiche</div>'}</div>
      <div class="team-tabs"><button class="${state.teamTab==='overview'?'active':''}" data-team-tab="overview">Vue d'ensemble</button><button class="${state.teamTab==='members'?'active':''}" data-team-tab="members">Membres</button><button class="${state.teamTab==='management'?'active':''}" data-team-tab="management">⚙ Gestion</button><button class="${state.teamTab==='rankings'?'active':''}" data-team-tab="rankings">Classements</button><button class="${state.teamTab==='history'?'active':''}" data-team-tab="history">Historique</button></div>
      <div id="myTeamTabBody" class="team-tab-body"></div>
    </article>`;
    $$('[data-team-tab]',root).forEach(b=>b.onclick=()=>{state.teamTab=b.dataset.teamTab;renderMyTeamPanel();});
    renderMyTeamTabBody(lb);
  }

  function renderMyTeamTabBody(lb){
    const root=$("#myTeamTabBody"),t=state.myTeam;if(!root||!t)return;
    const members=state.teamMembers||[];

    if(state.teamTab==="members"){
      root.innerHTML=`<div class="team-members-head"><div><span class="eyebrow">Effectif</span><h4>${members.length} membre${members.length>1?'s':''}</h4></div><button class="btn secondary small" data-open-team-management>⚙ Gérer la Team</button></div>
        <div class="team-member-list">${members.map(m=>`<div class="team-member-row">${avatarHTML(m)}<div class="team-member-copy"><strong>${m.is_captain?'👑 ':''}${esc(m.username)}</strong><small>${esc(m.club_heart||'Aucun club de cœur')} · ${m.rank?`#${m.rank}`:'non classé'}</small></div><span><b>${Number(m.points||0).toFixed(0)}</b><small> pts</small></span></div>`).join('')}</div>`;
      const manage=$("[data-open-team-management]",root);if(manage)manage.onclick=()=>{state.teamTab="management";renderMyTeamPanel();};
      return;
    }

    if(state.teamTab==="management"){
      const requests=t.is_captain?(state.teamRequests||[]):[];
      const otherMembers=members.filter(m=>!m.is_captain);
      root.innerHTML=`<div class="team-management-grid">
        <section class="team-management-card"><div class="team-management-card-head"><div><span class="eyebrow">Identité</span><h4>Apparence & informations</h4></div><span>🛡</span></div><p class="muted">Nom, slogan, visibilité, emblème, forme, cadre et couleurs de la Team.</p>${t.is_captain?'<button class="btn secondary small" data-team-edit-management>Personnaliser la Team</button>':'<small class="muted">Seul le capitaine peut modifier l’identité de la Team.</small>'}</section>
        ${t.is_captain?`<section class="team-management-card"><div class="team-management-card-head"><div><span class="eyebrow">Invitations</span><h4>Code privé</h4></div><span>🔑</span></div><div class="team-invite-code">${esc(state.teamInvite||'Aucun code actif')}</div><button class="btn secondary small" data-team-invite-management>${state.teamInvite?'Régénérer le code':'Générer un code'}</button></section>`:''}
      </div>
      ${t.is_captain&&requests.length?`<section class="team-management-section"><div class="team-management-title"><div><span class="eyebrow">Demandes</span><h4>Adhésions en attente</h4></div><span class="chip">${requests.length}</span></div><div class="team-requests">${requests.map(r=>`<div class="team-request-row">${avatarHTML(r)}<div><strong>${esc(r.username)}</strong><small>${esc(r.club_heart||'Aucun club de cœur')}</small></div><div class="actions"><button class="btn small" data-request-accept="${r.request_id}">Accepter</button><button class="btn secondary small" data-request-reject="${r.request_id}">Refuser</button></div></div>`).join('')}</div></section>`:''}
      ${t.is_captain?`<section class="team-management-section"><div class="team-management-title"><div><span class="eyebrow">Capitanat</span><h4>Donner le capitanat</h4></div></div>${otherMembers.length?`<p class="muted">Choisis un membre actif. Après le transfert, il devient immédiatement capitaine.</p><div class="team-management-members">${otherMembers.map(m=>`<div class="team-management-member">${avatarHTML(m)}<div><strong>${esc(m.username)}</strong><small>${esc(m.club_heart||'Membre de la Team')}</small></div><button class="btn secondary small" data-transfer-captain="${m.user_id}">Donner le capitanat</button></div>`).join('')}</div>`:'<p class="muted">Tu es actuellement le seul membre : aucun transfert de capitanat n’est possible.</p>'}</section>
      <section class="team-management-section"><div class="team-management-title"><div><span class="eyebrow">Effectif</span><h4>Gérer les membres</h4></div></div>${otherMembers.length?`<div class="team-management-members">${otherMembers.map(m=>`<div class="team-management-member">${avatarHTML(m)}<div><strong>${esc(m.username)}</strong><small>${Number(m.points||0).toFixed(0)} pts · ${m.rank?`#${m.rank}`:'non classé'}</small></div><button class="text-action danger-text" data-kick-member="${m.user_id}">Exclure</button></div>`).join('')}</div>`:'<p class="muted">Aucun autre membre à gérer.</p>'}</section>`:''}
      <section class="team-danger-panel"><div><span class="eyebrow">Zone sensible</span><h4>${t.is_captain?'Quitter ou dissoudre':'Quitter la Team'}</h4><p>${t.is_captain?(otherMembers.length?'Pour quitter, tu dois transmettre le capitanat. Le Nid peut enchaîner les deux actions pour toi.':'Tu peux quitter sans supprimer la Team : elle restera visible, vacante et pourra être reprise plus tard.'):'Tes points déjà gagnés resteront attachés à cette Team dans son historique.'}</p></div><div class="actions">${t.is_captain?(otherMembers.length?'<button class="btn secondary" data-captain-leave-team>Transférer puis quitter</button>':'<button class="btn secondary" data-leave-team>Quitter la Team</button>'):'<button class="btn secondary" data-leave-team>Quitter la Team</button>'}${t.is_captain?'<button class="btn danger" data-dissolve-team>Dissoudre la Team</button>':''}</div></section>`;

      const edit=$("[data-team-edit-management]",root);if(edit)edit.onclick=()=>openTeamEditor(t);
      const invite=$("[data-team-invite-management]",root);if(invite)invite.onclick=regenerateTeamInvite;
      $$('[data-request-accept]',root).forEach(b=>b.onclick=()=>processTeamRequest(b.dataset.requestAccept,true));
      $$('[data-request-reject]',root).forEach(b=>b.onclick=()=>processTeamRequest(b.dataset.requestReject,false));
      $$('[data-transfer-captain]',root).forEach(b=>b.onclick=()=>transferTeamCaptain(b.dataset.transferCaptain));
      $$('[data-kick-member]',root).forEach(b=>b.onclick=()=>kickTeamMember(b.dataset.kickMember));
      const leave=$("[data-leave-team]",root);if(leave)leave.onclick=leaveMyTeam;
      const captainLeave=$("[data-captain-leave-team]",root);if(captainLeave)captainLeave.onclick=openCaptainLeaveModal;
      const dissolve=$("[data-dissolve-team]",root);if(dissolve)dissolve.onclick=dissolveMyTeam;
      return;
    }

    if(state.teamTab==="history"){
      root.innerHTML=`<div class="team-history">${(state.teamEvents||[]).length?(state.teamEvents||[]).map(teamEventHTML).join(''):'<div class="empty">L’histoire de la Team commence à peine.</div>'}</div>`;return;
    }
    if(state.teamTab==="rankings"){
      root.innerHTML=`<div class="team-stat-grid"><div><span>Rang moyenne</span><strong>${lb?`#${lb.rank_average}`:'—'}</strong></div><div><span>Moyenne</span><strong>${Number(lb?.average_points||0).toFixed(2)}</strong></div><div><span>Rang Top 3</span><strong>${lb?`#${lb.rank_top3}`:'—'}</strong></div><div><span>Top 3</span><strong>${Number(lb?.top3_points||0).toFixed(0)}</strong></div></div><p class="muted team-rule-note">Les points restent attribués à la Team dont le joueur faisait partie au coup d’envoi du match. Aucun transfert rétroactif.</p>`;return;
    }
    root.innerHTML=`<div class="team-overview-grid"><div class="team-stat-grid"><div><span>Rang</span><strong>${lb?`#${lb.rank_average}`:'—'}</strong></div><div><span>Moyenne</span><strong>${Number(lb?.average_points||0).toFixed(2)}</strong></div><div><span>Top 3</span><strong>${Number(lb?.top3_points||0).toFixed(0)}</strong></div><div><span>Membres</span><strong>${Number(t.member_count||members.length)}</strong></div></div><div class="team-style-preview"><span class="eyebrow">Signature visuelle</span><div class="team-preview-avatars">${members.slice(0,4).map(m=>avatarHTML(m)).join('')||avatarHTML(state.profile)}</div><small>${TEAM_SHAPES.find(x=>x[0]===t.shape)?.[1]||t.shape} · ${TEAM_FRAMES.find(x=>x[0]===t.frame_style)?.[1]||t.frame_style}</small>${t.is_captain?'<button class="btn secondary small" data-team-edit-overview>Modifier l’apparence</button>':''}<button class="text-action" data-open-team-management>⚙ Gérer la Team →</button></div></div>${t.description?`<p class="team-description">${esc(t.description)}</p>`:''}`;
    const e=$("[data-team-edit-overview]",root);if(e)e.onclick=()=>openTeamEditor(t);
    const manage=$("[data-open-team-management]",root);if(manage)manage.onclick=()=>{state.teamTab="management";renderMyTeamPanel();};
  }

  function teamEventHTML(e){
    const labels={team_created:"Team créée",member_joined:"Nouveau membre",member_left:"Départ",member_kicked:"Membre exclu",captain_transferred:"Capitanat transféré",identity_changed:"Identité modifiée",team_vacated:"Team devenue vacante",team_reclaimed:"Team reprise",team_reactivated:"Team réactivée",team_dissolved:"Team dissoute",join_requested:"Demande d'adhésion",join_rejected:"Demande refusée",invite_regenerated:"Code d'invitation renouvelé"};
    const who=e.target_username||e.actor_username||"Le Nid";
    return `<div class="team-history-row"><span>${esc(fmtDate(e.created_at))}</span><div><strong>${esc(labels[e.event_type]||e.event_type)}</strong><small>${esc(who)}</small></div></div>`;
  }

  function renderTeamDirectory(){
    const root=$("#teamDirectory");if(!root)return;
    const q=String($("#teamSearchInput")?.value||"").trim().toLocaleLowerCase("fr"),vis=$("#teamVisibilityFilter")?.value||"all";
    let teams=(state.teamDirectory||[]).filter(t=>t.status==="active");
    if(q)teams=teams.filter(t=>`${t.name} ${t.captain_username||''} ${t.slogan||''}`.toLocaleLowerCase("fr").includes(q));
    if(vis!=="all")teams=teams.filter(t=>t.visibility===vis);
    root.innerHTML=teams.length?teams.map(t=>{
      const mine=String(t.team_id)===String(state.myTeam?.team_id),fav=teamFavoriteClub(t),vacant=!t.captain_user_id||Number(t.member_count||0)===0;
      const captainLabel=vacant?'Capitaine à reprendre':esc(t.captain_username||'—');
      const action=mine?'<span class="chip">MA TEAM</span>':state.myTeam?'<span class="muted">Une seule Team active</span>':vacant?`<button class="btn gold small" data-reclaim-team="${t.team_id}">Reprendre la Team</button>`:t.visibility==='public'?`<button class="btn small" data-join-public="${t.team_id}">Rejoindre</button>`:`<button class="btn secondary small" data-request-private="${t.team_id}">Demander à rejoindre</button>`;
      return `<article class="card team-directory-card ${vacant?'vacant':''}" style="${teamVisualVars(t)}"><div class="team-directory-identity">${teamBadgeHTML(t,true)}<div><span class="eyebrow">${vacant?'🪹 Team vacante':t.visibility==='private'?'🔒 Team privée':'🌐 Team publique'}</span><h3>${esc(t.name)}</h3>${t.slogan?`<p>« ${esc(t.slogan)} »</p>`:''}</div></div><div class="team-directory-meta"><span>👑 ${captainLabel}</span><span>${Number(t.member_count||0)} membre${Number(t.member_count||0)>1?'s':''}</span>${fav?`<span>${crestHTML(fav)} ${esc(fav.short_name||fav.name)}</span>`:''}</div><div class="team-directory-actions">${action}<button class="text-action" data-view-team="${t.team_id}">Voir</button></div></article>`;
    }).join(''):'<div class="empty">Aucune Team ne correspond à la recherche.</div>';
    $$('[data-join-public]',root).forEach(b=>b.onclick=()=>joinPublicTeam(b.dataset.joinPublic));$$('[data-request-private]',root).forEach(b=>b.onclick=()=>requestPrivateTeam(b.dataset.requestPrivate));$$('[data-reclaim-team]',root).forEach(b=>b.onclick=()=>reclaimTeam(b.dataset.reclaimTeam));$$('[data-view-team]',root).forEach(b=>b.onclick=()=>showPublicTeam(b.dataset.viewTeam));
  }

  function renderTeamLeaderboard(){
    const root=$("#teamLeaderboard");if(!root)return;
    const mode=state.teamRankingMode||"average";const rows=[...(state.teamLeaderboardRows||[])];
    rows.sort((a,b)=>mode==="top3"?Number(a.rank_top3)-Number(b.rank_top3):Number(a.rank_average)-Number(b.rank_average));
    if($("#teamRankingScopeChip"))$("#teamRankingScopeChip").textContent=mode==="top3"?"Top 3":mode==="matchday"?selectedMatchday()?.name||"Journée":"Moyenne";
    root.innerHTML=rows.length?rows.map((r,i)=>`<article class="card team-rank-card ${String(r.team_id)===String(state.myTeam?.team_id)?'my-team':''}"><span class="team-rank-number">#${i+1}</span>${teamBadgeHTML(r)}<div class="team-rank-copy"><strong>${esc(r.team_name||r.name)}</strong><small>${Number(r.current_members||0)} membre${Number(r.current_members||0)>1?'s':''} · ${Number(r.contributors||0)} contributeur${Number(r.contributors||0)>1?'s':''}</small></div><b>${teamMetricLabel(r,mode)}</b></article>`).join(''):'<div class="empty">Aucune Team classée pour le moment.</div>';
  }

  async function setTeamRankingMode(mode){state.teamRankingMode=mode;$$('[data-team-ranking]').forEach(b=>b.classList.toggle('active',b.dataset.teamRanking===mode));if(demoMode){refreshDemoTeamState();renderTeamLeaderboard();renderMyTeamPanel();return;}try{const {data,error}=await sb.rpc('get_team_leaderboard_v050',{p_season_id:state.season.id,p_matchday_id:mode==='matchday'?state.selectedMatchdayId:null});if(error)throw error;state.teamLeaderboardRows=data||[];renderTeamLeaderboard();renderMyTeamPanel();}catch(err){toast(friendlyError(err),'error');}}

  function renderProfileTeam(){
    const root=$("#profileTeamCard");if(!root)return;const t=state.myTeam;
    if(!t){root.innerHTML=`<div class="profile-team-empty"><span>🛡</span><div><strong>Aucune Team</strong><p class="muted">Ton avatar utilise encore le cadre neutre du Nid.</p></div><button class="btn secondary small" data-profile-teams> Trouver mon Nid </button></div>`;const b=$("[data-profile-teams]",root);if(b)b.onclick=()=>setView('teams');return;}
    const fav=teamFavoriteClub(t);root.innerHTML=`<div class="profile-team-summary">${teamBadgeHTML(t,true)}<div><span class="eyebrow">${t.is_captain?'👑 Capitaine':'Membre'}</span><h3>${esc(t.name)}</h3><p>${esc(t.slogan||'')}</p></div><div class="profile-team-right">${fav?`<span>${crestHTML(fav)}<small>Équipe fétiche</small><strong>${esc(fav.short_name||fav.name)}</strong></span>`:''}<button class="btn secondary small" data-profile-teams>Ouvrir la Team</button></div></div>`;const b=$("[data-profile-teams]",root);if(b)b.onclick=()=>setView('teams');
  }

  function showPublicTeam(teamId){
    const t=(state.teamDirectory||[]).find(x=>String(x.team_id)===String(teamId));if(!t)return;const fav=teamFavoriteClub(t);const lb=(state.teamLeaderboardRows||[]).find(x=>String(x.team_id)===String(teamId));
    modal(t.name,`<div class="public-team-modal" style="${teamVisualVars(t)}"><div class="public-team-head">${teamBadgeHTML(t,true)}<div><span class="eyebrow">${t.visibility==='private'?'🔒 Privée':'🌐 Publique'}</span><h2>${esc(t.name)}</h2><p>${esc(t.slogan||'')}</p></div></div><p>${esc(t.description||'Aucune description.')}</p><div class="team-stat-grid"><div><span>Membres</span><strong>${Number(t.member_count||0)}</strong></div><div><span>Rang</span><strong>${lb?`#${lb.rank_average}`:'—'}</strong></div><div><span>Moyenne</span><strong>${Number(lb?.average_points||0).toFixed(2)}</strong></div><div><span>Top 3</span><strong>${Number(lb?.top3_points||0).toFixed(0)}</strong></div></div>${fav?`<div class="public-team-fav">${crestHTML(fav,true)}<div><small>Équipe fétiche</small><strong>${esc(fav.name)}</strong></div></div>`:''}<p class="muted">Capitaine : <b>${esc(t.captain_username||'Aucun — Team à reprendre')}</b></p></div>`);
  }

  function teamChoiceMarkHTML(team){
    return `<span class="team-choice-mark ${teamClass(team)}" style="${teamVisualVars(team)}"><span class="team-choice-dot"></span></span>`;
  }

  function teamEditorHTML(team){
    const isEdit=Boolean(team),fav=team?.favorite_club_id||"";
    const clubOpts=['<option value="">Aucune équipe fétiche</option>',...state.clubs.map(c=>`<option value="${c.id}" ${String(c.id)===String(fav)?'selected':''}>${esc(c.name)} · ${esc(clubCountry(c).name||'')}</option>`)].join('');
    const selectedShape=TEAM_SHAPES.some(x=>x[0]===team?.shape)?team.shape:"shield-classic";
    const selectedFrame=TEAM_FRAMES.some(x=>x[0]===team?.frame_style)?team.frame_style:"champions";
    const selectedBg=TEAM_BACKGROUNDS.some(x=>x[0]===team?.background_style)?team.background_style:"diagonal";
    const selectedPrimary=safeTeamColor(team?.primary_color);
    const selectedSecondary=safeTeamColor(team?.secondary_color,"#7454ff");
    const colorMode=selectedBg==="solid"?"single":"two";
    const logos=Object.entries(TEAM_LOGOS).map(([key,l])=>`<button type="button" class="team-logo-option ${team?.logo_type!=='upload'&&((!team?.logo_asset_key&&key==='owl')||team?.logo_asset_key===key)?'active':''}" data-logo-key="${key}" title="${esc(l.label)}"><span class="team-logo-glyph">${l.glyph}</span><small>${esc(l.label)}</small></button>`).join('');
    const shapes=TEAM_SHAPES.map(([key,label])=>{
      const demo={shape:key,frame_style:"champions",primary_color:"#173a79",secondary_color:"#6c55ff",background_style:"diagonal"};
      return `<button type="button" class="team-visual-option ${key===selectedShape?'active':''}" data-shape-key="${key}">${teamChoiceMarkHTML(demo)}<small>${esc(label)}</small></button>`;
    }).join('');
    const frames=TEAM_FRAMES.map(([key,label])=>{
      const demo={shape:selectedShape,frame_style:key,primary_color:selectedPrimary,secondary_color:selectedSecondary,background_style:colorMode==="single"?"solid":selectedBg};
      return `<button type="button" class="team-visual-option ${key===selectedFrame?'active':''}" data-frame-key="${key}"><span class="team-frame-preview-wrap">${teamChoiceMarkHTML(demo)}</span><small>${esc(label)}</small></button>`;
    }).join('');
    const backgroundOption=(key,label)=>`<button type="button" class="team-background-option ${key===selectedBg?'active':''}" data-background-key="${key}"><i class="team-bg-demo bg-${key}" style="--c1:${selectedPrimary};--c2:${selectedSecondary}"></i><small>${esc(label)}</small></button>`;
    const gradientButtons=TEAM_BACKGROUNDS.filter(([, ,group])=>group==="gradient").map(([key,label])=>backgroundOption(key,label)).join('');
    const patternButtons=TEAM_BACKGROUNDS.filter(([, ,group])=>group==="pattern").map(([key,label])=>backgroundOption(key,label)).join('');
    const presets=Object.entries(TEAM_STYLE_PRESETS).map(([key,p])=>`<button type="button" class="team-preset" data-team-preset="${key}"><span class="team-preset-swatch ${teamClass(p)}" style="${teamVisualVars(p)}"></span><b>${esc(p.label)}</b></button>`).join('');
    return `<div class="team-editor-v051">
      <div class="team-editor-fields-v051">
        <section class="team-editor-block">
          <div class="team-editor-block-head"><div><span class="eyebrow">Identité</span><h4>Les bases de la Team</h4></div><small>Nom, visibilité et club fétiche.</small></div>
          <div class="grid grid-2"><div class="field"><label>Nom *</label><input id="teamEditName" maxlength="30" value="${esc(team?.name||'')}" placeholder="Les Hiboux"></div><div class="field"><label>Visibilité</label><select id="teamEditVisibility"><option value="public" ${team?.visibility!=='private'?'selected':''}>Publique</option><option value="private" ${team?.visibility==='private'?'selected':''}>Privée</option></select></div></div>
          <div class="field"><label>Slogan</label><input id="teamEditSlogan" maxlength="80" value="${esc(team?.slogan||'')}" placeholder="La nuit nous appartient"></div>
          <div class="field"><label>Description courte</label><textarea id="teamEditDescription" maxlength="160" rows="2" placeholder="160 caractères maximum">${esc(team?.description||'')}</textarea></div>
          <div class="field"><label>Équipe fétiche <span class="muted">(optionnelle)</span></label><select id="teamEditFavorite">${clubOpts}</select></div>
        </section>

        <section class="team-editor-block">
          <div class="team-editor-block-head"><div><span class="eyebrow">Emblème</span><h4>Choisis le symbole</h4></div><small>Les pictos sont volontairement transparents. De vraies images viendront ensuite.</small></div>
          <div class="team-logo-library">${logos}</div>
          <div class="field team-upload-field"><label>Ou uploader ton propre logo</label><input id="teamEditLogoFile" type="file" accept="image/png,image/jpeg,image/webp,image/svg+xml"><small class="field-help">PNG transparent conseillé · JPG/WebP/SVG acceptés · 3 Mo max.</small></div>
        </section>

        <section class="team-editor-block">
          <div class="team-editor-block-head"><div><span class="eyebrow">Forme</span><h4>Silhouette du blason</h4></div><small>Le cadre suivra exactement cette forme.</small></div>
          <input id="teamEditShape" type="hidden" value="${esc(selectedShape)}">
          <div class="team-visual-grid team-shape-grid">${shapes}</div>
        </section>

        <section class="team-editor-block">
          <div class="team-editor-block-head"><div><span class="eyebrow">Cadre</span><h4>Matière & finition</h4></div><small>Bois, or, argent, obsidienne, néon…</small></div>
          <input id="teamEditFrame" type="hidden" value="${esc(selectedFrame)}">
          <div class="team-visual-grid team-frame-grid">${frames}</div>
        </section>

        <section class="team-editor-block">
          <div class="team-editor-block-head"><div><span class="eyebrow">Couleurs</span><h4>Une ou deux couleurs</h4></div><small>Avec deux couleurs, choisis un dégradé ou un vrai motif de blason.</small></div>
          <input id="teamEditColorMode" type="hidden" value="${colorMode}">
          <input id="teamEditBackground" type="hidden" value="${esc(colorMode==="single"?"solid":selectedBg==="solid"?"diagonal":selectedBg)}">
          <div class="team-color-mode team-color-mode-cards">
            <button type="button" class="team-color-mode-card ${colorMode==="single"?'active':''}" data-color-mode="single"><b>1 couleur</b><span>Fond uni</span><i class="color-mode-demo one" style="--c1:${selectedPrimary}"></i></button>
            <button type="button" class="team-color-mode-card ${colorMode==="two"?'active':''}" data-color-mode="two"><b>2 couleurs</b><span>Dégradé ou motif</span><i class="color-mode-demo two" style="--c1:${selectedPrimary};--c2:${selectedSecondary}"></i></button>
          </div>
          <div class="team-color-pickers">
            <label class="team-color-picker"><span>Couleur principale</span><div><input id="teamEditPrimary" type="color" value="${selectedPrimary}"><code id="teamPrimaryHex">${selectedPrimary.toUpperCase()}</code></div></label>
            <label id="teamSecondaryWrap" class="team-color-picker ${colorMode==="single"?'hidden':''}"><span>Couleur secondaire</span><div><input id="teamEditSecondary" type="color" value="${selectedSecondary}"><code id="teamSecondaryHex">${selectedSecondary.toUpperCase()}</code></div></label>
          </div>
          <div id="teamGradientWrap" class="team-gradient-wrap ${colorMode==="single"?'hidden':''}">
            <span class="field-mini-label">Dégradés</span><div class="team-background-grid">${gradientButtons}</div>
            <span class="field-mini-label team-pattern-title">Motifs de blason</span><div class="team-background-grid">${patternButtons}</div>
          </div>
          <div class="team-presets"><span class="field-mini-label">Presets rapides</span><div>${presets}</div></div>
        </section>
      </div>

      <aside class="team-editor-preview-panel">
        <div class="team-editor-preview-sticky">
          <div class="team-preview-title"><span class="eyebrow gold">Aperçu en direct</span><small>Le vrai rendu dans le Nid.</small></div>
          <div id="teamLivePreview"></div>
          <button id="resetTeamStyle" type="button" class="btn secondary">Réinitialiser le style</button>
          <button id="saveTeamEditor" class="btn gold">${isEdit?'Enregistrer la Team':'Créer la Team'}</button>
          <div id="teamEditorMsg" class="form-msg"></div>
        </div>
      </aside>
    </div>`;
  }

  function openTeamEditor(team=null){
    if(!team&&!state.myTeam&&state.teamMigrationError)return toast(state.teamMigrationError,'error');
    const root=modal(team?'Personnaliser ma Team':'Créer une Team',teamEditorHTML(team));
    root.querySelector('.modal-card')?.classList.add('team-editor-modal-card');
    let selectedLogo=team?.logo_type==='upload'?null:(team?.logo_asset_key||'owl');
    let localUploadPreview=null;

    const draftFromEditor=()=>{
      const primary=$("#teamEditPrimary",root).value;
      const mode=$("#teamEditColorMode",root).value;
      const useUpload=Boolean(localUploadPreview)||(selectedLogo===null&&team?.logo_type==='upload'&&team?.logo_url);
      return {
        ...team,
        name:$("#teamEditName",root).value||"Ma Team",
        slogan:$("#teamEditSlogan",root).value||"",
        shape:$("#teamEditShape",root).value,
        frame_style:$("#teamEditFrame",root).value,
        primary_color:primary,
        secondary_color:mode==="single"?primary:$("#teamEditSecondary",root).value,
        background_style:mode==="single"?"solid":$("#teamEditBackground",root).value,
        logo_type:useUpload?'upload':'library',
        logo_asset_key:useUpload?null:(selectedLogo||'owl'),
        logo_url:localUploadPreview||(useUpload?(team?.logo_url||null):null)
      };
    };

    function syncEditorUi(){
      const mode=$("#teamEditColorMode",root).value;
      $("#teamSecondaryWrap",root).classList.toggle("hidden",mode==="single");
      $("#teamGradientWrap",root).classList.toggle("hidden",mode==="single");
      $$("[data-color-mode]",root).forEach(b=>b.classList.toggle("active",b.dataset.colorMode===mode));
      const currentShape=$("#teamEditShape",root).value;
      const currentPrimary=$("#teamEditPrimary",root).value, currentSecondary=$("#teamEditSecondary",root).value;
      $$([".team-frame-preview-wrap .team-choice-mark"],root).forEach(mark=>{TEAM_SHAPES.forEach(([key])=>mark.classList.remove(`shape-${key}`));mark.classList.add(`shape-${currentShape}`);});
      const oneDemo=$(".color-mode-demo.one",root),twoDemo=$(".color-mode-demo.two",root);
      if(oneDemo)oneDemo.style.setProperty("--c1",currentPrimary);
      if(twoDemo){twoDemo.style.setProperty("--c1",currentPrimary);twoDemo.style.setProperty("--c2",currentSecondary);}
      $$(".team-bg-demo",root).forEach(d=>{d.style.setProperty("--c1",currentPrimary);d.style.setProperty("--c2",currentSecondary);});
      $$("[data-shape-key]",root).forEach(b=>b.classList.toggle("active",b.dataset.shapeKey===$("#teamEditShape",root).value));
      $$("[data-frame-key]",root).forEach(b=>b.classList.toggle("active",b.dataset.frameKey===$("#teamEditFrame",root).value));
      $$("[data-background-key]",root).forEach(b=>b.classList.toggle("active",b.dataset.backgroundKey===$("#teamEditBackground",root).value));
      $("#teamPrimaryHex",root).textContent=$("#teamEditPrimary",root).value.toUpperCase();
      $("#teamSecondaryHex",root).textContent=$("#teamEditSecondary",root).value.toUpperCase();
    }

    function preview(){
      syncEditorUi();
      const draft=draftFromEditor();
      const playerCore=avatarCoreHTML(state.profile||{username:"Joueur",avatar_key:"avatar-hibou-or"},{allowPending:true});
      const draftAvatar=`<span class="team-avatar ${teamClass(draft)}" style="${teamVisualVars(draft)}">${playerCore}<i>${teamLogoHTML(draft)}</i></span>`;
      const visibility=$("#teamEditVisibility",root).value==="private"?"Privée 🔒":"Publique";
      $("#teamLivePreview",root).innerHTML=`
        <div class="team-preview-emblem"><span>Blason Team</span>${teamBadgeHTML(draft,true)}<strong>${esc(draft.name)}</strong>${draft.slogan?`<small>« ${esc(draft.slogan)} »</small>`:""}</div>
        <div class="team-preview-member"><div><span>Avatar membre</span><small>L'habillage reste derrière l'avatar personnel.</small></div><div>${draftAvatar}<strong>${esc(state.profile?.username||'Joueur')}</strong></div></div>
        <div class="team-rank-preview"><b>#4</b>${draftAvatar}<span><strong>${esc(state.profile?.username||'Joueur')}</strong><small>${esc(draft.name)}</small></span><strong>186 pts</strong></div>
        <div class="team-preview-mini-card bg-${esc(draft.background_style)}" style="${teamVisualVars(draft)}"><div>${teamBadgeHTML(draft)}<span><small>${visibility}</small><strong>${esc(draft.name)}</strong></span></div><b>12 membres</b></div>`;
    }

    $$('[data-logo-key]',root).forEach(b=>b.onclick=()=>{
      selectedLogo=b.dataset.logoKey;
      if(localUploadPreview){URL.revokeObjectURL(localUploadPreview);localUploadPreview=null;}
      $("#teamEditLogoFile",root).value="";
      $$('[data-logo-key]',root).forEach(x=>x.classList.toggle('active',x===b));
      preview();
    });
    $("#teamEditLogoFile",root).addEventListener("change",e=>{
      const file=e.target.files?.[0];
      if(!file)return;
      if(localUploadPreview)URL.revokeObjectURL(localUploadPreview);
      localUploadPreview=URL.createObjectURL(file);
      selectedLogo=null;
      $$('[data-logo-key]',root).forEach(x=>x.classList.remove('active'));
      preview();
    });
    $$('[data-shape-key]',root).forEach(b=>b.onclick=()=>{$("#teamEditShape",root).value=b.dataset.shapeKey;preview();});
    $$('[data-frame-key]',root).forEach(b=>b.onclick=()=>{$("#teamEditFrame",root).value=b.dataset.frameKey;preview();});
    $$('[data-color-mode]',root).forEach(b=>b.onclick=()=>{
      $("#teamEditColorMode",root).value=b.dataset.colorMode;
      if(b.dataset.colorMode==="single")$("#teamEditBackground",root).value="solid";
      else if($("#teamEditBackground",root).value==="solid")$("#teamEditBackground",root).value="diagonal";
      preview();
    });
    $$('[data-background-key]',root).forEach(b=>b.onclick=()=>{$("#teamEditBackground",root).value=b.dataset.backgroundKey;preview();});
    $$('[data-team-preset]',root).forEach(b=>b.onclick=()=>{
      const p=TEAM_STYLE_PRESETS[b.dataset.teamPreset];if(!p)return;
      $("#teamEditShape",root).value=p.shape;
      $("#teamEditFrame",root).value=p.frame_style;
      $("#teamEditPrimary",root).value=p.primary_color;
      $("#teamEditSecondary",root).value=p.secondary_color;
      $("#teamEditBackground",root).value=p.background_style;
      $("#teamEditColorMode",root).value=p.color_mode;
      preview();
    });
    ["#teamEditName","#teamEditSlogan","#teamEditVisibility","#teamEditPrimary","#teamEditSecondary"].forEach(sel=>$(sel,root).addEventListener("input",preview));
    $("#resetTeamStyle",root).onclick=()=>{
      $("#teamEditShape",root).value="shield-classic";
      $("#teamEditFrame",root).value="champions";
      $("#teamEditPrimary",root).value="#315cff";
      $("#teamEditSecondary",root).value="#7454ff";
      $("#teamEditBackground",root).value="diagonal";
      $("#teamEditColorMode",root).value="two";
      preview();
    };
    preview();
    $("#saveTeamEditor",root).onclick=()=>saveTeamEditor(team,selectedLogo,root);
  }

  async function uploadTeamLogo(file){
    if(!file)return null;if(file.size>3*1024*1024)throw new Error('Le logo dépasse 3 Mo.');
    if(demoMode)return await new Promise((resolve,reject)=>{const r=new FileReader();r.onload=()=>resolve(r.result);r.onerror=reject;r.readAsDataURL(file);});
    const ext=(file.name.split('.').pop()||'png').replace(/[^a-z0-9]/gi,'').toLowerCase()||'png';const path=`${state.user.id}/${Date.now()}-${Math.random().toString(36).slice(2,8)}.${ext}`;
    const {error}=await sb.storage.from('team-logos').upload(path,file,{cacheControl:'31536000',upsert:false,contentType:file.type||undefined});if(error)throw error;return sb.storage.from('team-logos').getPublicUrl(path).data.publicUrl;
  }

  async function saveTeamEditor(existing,selectedLogo,root){
    setMsg('#teamEditorMsg','Enregistrement…');try{const file=$("#teamEditLogoFile",root).files?.[0];let logoUrl=existing?.logo_url||null,logoType=existing?.logo_type||'library';if(file){logoUrl=await uploadTeamLogo(file);logoType='upload';selectedLogo=null;}else if(selectedLogo!==null){logoType='library';logoUrl=null;}
      const colorMode=$("#teamEditColorMode",root)?.value||"two",primary=$("#teamEditPrimary",root).value;
      const values={name:$("#teamEditName",root).value.trim(),slogan:$("#teamEditSlogan",root).value.trim(),description:$("#teamEditDescription",root).value.trim(),favorite_club_id:$("#teamEditFavorite",root).value||null,visibility:$("#teamEditVisibility",root).value,logo_type:logoType,logo_asset_key:logoType==='library'?selectedLogo:null,logo_url:logoUrl,shape:$("#teamEditShape",root).value,frame_style:$("#teamEditFrame",root).value,primary_color:primary,secondary_color:colorMode==="single"?primary:$("#teamEditSecondary",root).value,background_style:colorMode==="single"?"solid":$("#teamEditBackground",root).value};
      if(values.name.length<3)throw new Error('Le nom doit contenir au moins 3 caractères.');
      if(demoMode){demoSaveTeam(existing,values);}else if(existing){const {error}=await sb.rpc('update_team_v050',{p_team_id:existing.team_id,...Object.fromEntries(Object.entries(values).map(([k,v])=>[`p_${k}`,v]))});if(error)throw error;}else{const {error}=await sb.rpc('create_team_v050',{p_season_id:state.season.id,...Object.fromEntries(Object.entries(values).map(([k,v])=>[`p_${k}`,v]))});if(error)throw error;}
      $("#modalRoot").innerHTML='';await reloadTeamsAfterMutation();toast(existing?'🛡 Team mise à jour.':'🛡 Bienvenue dans ta nouvelle Team.');
    }catch(err){setMsg('#teamEditorMsg',friendlyError(err),'error');}}

  function demoSaveTeam(existing,values){const store=ensureDemoTeams(),teams=store.teams,memberships=store.memberships,now=new Date().toISOString();if(existing){const idx=teams.findIndex(t=>t.id===existing.team_id);if(idx>=0)teams[idx]={...teams[idx],...values};demoLogTeam(existing.team_id,'identity_changed',state.user.id,null,{name:values.name});}else{if(memberships.some(m=>m.season_id===state.season.id&&m.user_id===state.user.id&&!m.left_at))throw new Error('Tu appartiens déjà à une Team.');const id=`team-${Date.now()}`;teams.push({id,team_id:id,season_id:state.season.id,slug:`demo-${Date.now()}`,status:'active',captain_user_id:state.user.id,...values,created_at:now});memberships.push({id:`tm-${Date.now()}`,season_id:state.season.id,team_id:id,user_id:state.user.id,joined_at:now,left_at:null,join_type:'creator'});demoLogTeam(id,'team_created',state.user.id,state.user.id,{name:values.name});}localStorage.setItem('nidc_demo_teams',JSON.stringify(teams));localStorage.setItem('nidc_demo_team_memberships',JSON.stringify(memberships));}
  function demoLogTeam(teamId,event_type,actor_id,target_user_id,payload={}){const a=JSON.parse(localStorage.getItem('nidc_demo_team_events')||'[]');a.push({id:Date.now()+Math.random(),team_id:teamId,event_type,actor_id,target_user_id,payload,created_at:new Date().toISOString()});localStorage.setItem('nidc_demo_team_events',JSON.stringify(a));}

  async function reloadTeamsAfterMutation(){await loadTeamData();renderTeams();renderProfile();renderRanking();renderAdminTeams();}
  async function joinPublicTeam(id){try{if(demoMode){demoJoinTeam(id,'public');}else{const {error}=await sb.rpc('join_public_team_v050',{p_team_id:id});if(error)throw error;}await reloadTeamsAfterMutation();toast('🛡 Tu as rejoint la Team.');}catch(err){toast(friendlyError(err),'error');}}
  async function requestPrivateTeam(id){try{if(demoMode){const req=JSON.parse(localStorage.getItem('nidc_demo_team_requests')||'[]');if(!req.some(r=>r.team_id===id&&r.user_id===state.user.id&&r.status==='pending'))req.push({id:`req-${Date.now()}`,team_id:id,user_id:state.user.id,status:'pending',requested_at:new Date().toISOString()});localStorage.setItem('nidc_demo_team_requests',JSON.stringify(req));demoLogTeam(id,'join_requested',state.user.id,state.user.id,{});}else{const {error}=await sb.rpc('request_team_join_v050',{p_team_id:id});if(error)throw error;}toast('Demande envoyée au capitaine.');}catch(err){toast(friendlyError(err),'error');}}
  function demoJoinTeam(id,joinType){const {teams,memberships}=ensureDemoTeams();const t=teams.find(x=>x.id===id&&x.status==='active');if(!t)throw new Error('Team introuvable.');if(memberships.some(m=>m.season_id===state.season.id&&m.user_id===state.user.id&&!m.left_at))throw new Error('Tu appartiens déjà à une Team.');memberships.push({id:`tm-${Date.now()}`,season_id:state.season.id,team_id:id,user_id:state.user.id,joined_at:new Date().toISOString(),left_at:null,join_type:joinType});localStorage.setItem('nidc_demo_team_memberships',JSON.stringify(memberships));demoLogTeam(id,'member_joined',state.user.id,state.user.id,{join_type:joinType});}

  async function reclaimTeam(id){
    const t=(state.teamDirectory||[]).find(x=>String(x.team_id)===String(id));
    if(!t)return toast('Team introuvable.','error');
    const verb=t.status==='dissolved'?'Réactiver':'Reprendre';
    if(!confirm(`${verb} la Team « ${t.name} » ? Tu en deviendras capitaine.`))return;
    try{
      if(demoMode){
        const {teams,memberships}=ensureDemoTeams(),team=teams.find(x=>String(x.id)===String(id));
        if(!team)throw new Error('Team introuvable.');
        if(memberships.some(m=>m.season_id===state.season.id&&m.user_id===state.user.id&&!m.left_at))throw new Error('Tu appartiens déjà à une Team.');
        const active=memberships.filter(m=>m.team_id===team.id&&!m.left_at);
        if(team.status==='active'&&(team.captain_user_id||active.length))throw new Error('Cette Team n’est plus vacante.');
        if(team.status==='dissolved'&&String(team.captain_user_id)!==String(state.user.id))throw new Error('Seul son dernier capitaine peut réactiver cette Team.');
        const wasDissolved=team.status==='dissolved';team.status='active';team.dissolved_at=null;team.captain_user_id=state.user.id;
        memberships.push({id:`tm-${Date.now()}`,season_id:state.season.id,team_id:team.id,user_id:state.user.id,joined_at:new Date().toISOString(),left_at:null,join_type:'public'});
        localStorage.setItem('nidc_demo_teams',JSON.stringify(teams));localStorage.setItem('nidc_demo_team_memberships',JSON.stringify(memberships));
        demoLogTeam(team.id,wasDissolved?'team_reactivated':'team_reclaimed',state.user.id,state.user.id,{});
      }else{const {error}=await sb.rpc('reclaim_team_v055a',{p_team_id:id});if(error)throw error;}
      await reloadTeamsAfterMutation();toast(`🛡 ${verb} réussie. Tu es capitaine.`);
    }catch(err){toast(friendlyError(err),'error');}
  }

  function openJoinCodeModal(){const root=modal('Rejoindre avec un code',`<p class="muted">Le code est fourni par le capitaine d'une Team privée.</p><div class="field"><label>Code d'invitation</label><input id="teamJoinCode" placeholder="NID-XXXXXXXX"></div><button id="teamJoinCodeBtn" class="btn">Rejoindre</button><div id="teamJoinCodeMsg" class="form-msg"></div>`);$("#teamJoinCodeBtn",root).onclick=async()=>{try{const code=$("#teamJoinCode",root).value.trim();if(!code)throw new Error('Entre un code.');if(demoMode){const invites=JSON.parse(localStorage.getItem('nidc_demo_team_invites')||'{}');const entry=Object.entries(invites).find(([,v])=>String(v).toUpperCase()===code.toUpperCase());if(!entry)throw new Error('Code invalide.');demoJoinTeam(entry[0],'code');}else{const {error}=await sb.rpc('join_team_by_code_v050',{p_season_id:state.season.id,p_code:code});if(error)throw error;}$("#modalRoot").innerHTML='';await reloadTeamsAfterMutation();toast('🛡 Code accepté. Bienvenue dans la Team.');}catch(err){setMsg('#teamJoinCodeMsg',friendlyError(err),'error');}};}

  async function processTeamRequest(id,accept){try{if(demoMode){const req=JSON.parse(localStorage.getItem('nidc_demo_team_requests')||'[]'),r=req.find(x=>x.id===id);if(!r)throw new Error('Demande introuvable.');r.status=accept?'accepted':'rejected';if(accept){const {memberships}=ensureDemoTeams();if(memberships.some(m=>m.season_id===state.season.id&&m.user_id===r.user_id&&!m.left_at))throw new Error('Ce joueur appartient déjà à une Team.');memberships.push({id:`tm-${Date.now()}`,season_id:state.season.id,team_id:r.team_id,user_id:r.user_id,joined_at:new Date().toISOString(),left_at:null,join_type:'request'});localStorage.setItem('nidc_demo_team_memberships',JSON.stringify(memberships));demoLogTeam(r.team_id,'member_joined',state.user.id,r.user_id,{join_type:'request'});}else demoLogTeam(r.team_id,'join_rejected',state.user.id,r.user_id,{});localStorage.setItem('nidc_demo_team_requests',JSON.stringify(req));}else{const {error}=await sb.rpc('process_team_join_request_v050',{p_request_id:id,p_accept:accept});if(error)throw error;}await reloadTeamsAfterMutation();toast(accept?'Membre accepté.':'Demande refusée.');}catch(err){toast(friendlyError(err),'error');}}

  async function regenerateTeamInvite(){try{let code;if(demoMode){code=`NID-${Math.random().toString(36).slice(2,10).toUpperCase()}`;const inv=JSON.parse(localStorage.getItem('nidc_demo_team_invites')||'{}');inv[state.myTeam.id]=code;localStorage.setItem('nidc_demo_team_invites',JSON.stringify(inv));demoLogTeam(state.myTeam.id,'invite_regenerated',state.user.id,null,{});}else{const {data,error}=await sb.rpc('regenerate_team_invite_v050',{p_team_id:state.myTeam.team_id});if(error)throw error;code=data;}await loadTeamData();renderMyTeamPanel();toast(`Code actif : ${code}`);}catch(err){toast(friendlyError(err),'error');}}

  function openCaptainLeaveModal(){
    const candidates=(state.teamMembers||[]).filter(m=>!m.is_captain);
    if(!candidates.length)return toast('Tu es seul dans la Team : dissous-la pour la quitter.','error');
    const root=modal('Transférer puis quitter',`<p class="muted">Choisis le nouveau capitaine. Le capitanat lui sera transmis, puis tu quitteras immédiatement la Team.</p><div class="captain-leave-list">${candidates.map(m=>`<button class="captain-leave-choice" data-captain-leave-target="${m.user_id}">${avatarHTML(m)}<span><strong>${esc(m.username)}</strong><small>${esc(m.club_heart||'Membre actif')}</small></span><b>Choisir →</b></button>`).join('')}</div><div id="captainLeaveMsg" class="form-msg"></div>`);
    $$('[data-captain-leave-target]',root).forEach(b=>b.onclick=()=>captainTransferAndLeave(b.dataset.captainLeaveTarget,root));
  }

  async function captainTransferAndLeave(userId,root){
    const member=(state.teamMembers||[]).find(m=>String(m.user_id)===String(userId));
    if(!member)return;
    if(!confirm(`Donner le capitanat à ${member.username}, puis quitter la Team ?`))return;
    setMsg('#captainLeaveMsg','Transfert du capitanat…');
    try{
      if(demoMode){
        const {teams,memberships}=ensureDemoTeams();
        const t=teams.find(x=>x.id===state.myTeam.id);if(!t)throw new Error('Team introuvable.');
        t.captain_user_id=userId;
        const mine=memberships.find(x=>x.team_id===t.id&&x.user_id===state.user.id&&!x.left_at);if(!mine)throw new Error('Adhésion introuvable.');
        mine.left_at=new Date().toISOString();mine.leave_type='left';
        localStorage.setItem('nidc_demo_teams',JSON.stringify(teams));localStorage.setItem('nidc_demo_team_memberships',JSON.stringify(memberships));
        demoLogTeam(t.id,'captain_transferred',state.user.id,userId,{old_captain_user_id:state.user.id});
        demoLogTeam(t.id,'member_left',state.user.id,state.user.id,{});
      }else{
        const transfer=await sb.rpc('transfer_team_captain_v050',{p_team_id:state.myTeam.team_id,p_new_captain_user_id:userId});if(transfer.error)throw transfer.error;
        setMsg('#captainLeaveMsg','Capitanat transmis. Départ de la Team…');
        const leave=await sb.rpc('leave_team_v050',{p_season_id:state.season.id});if(leave.error)throw leave.error;
      }
      $("#modalRoot").innerHTML='';await reloadTeamsAfterMutation();toast(`👑 ${member.username} est capitaine. Tu as quitté la Team.`);
    }catch(err){setMsg('#captainLeaveMsg',friendlyError(err),'error');}
  }

  async function leaveMyTeam(){
    if(!confirm('Quitter cette Team ? Si tu es le dernier membre, la Team restera visible et vacante. Les points déjà gagnés resteront dans son historique.'))return;
    try{
      if(demoMode){
        const {teams,memberships}=ensureDemoTeams();const m=memberships.find(x=>x.season_id===state.season.id&&x.user_id===state.user.id&&!x.left_at);if(!m)throw new Error('Aucune Team.');
        const t=teams.find(x=>x.id===m.team_id);const others=memberships.filter(x=>x.team_id===m.team_id&&!x.left_at&&x.user_id!==state.user.id);
        if(t?.captain_user_id===state.user.id&&others.length)throw new Error('Transfère d’abord le capitanat avant de quitter la Team.');
        m.left_at=new Date().toISOString();m.leave_type='left';
        if(t?.captain_user_id===state.user.id){t.captain_user_id=null;demoLogTeam(m.team_id,'team_vacated',state.user.id,null,{});}
        localStorage.setItem('nidc_demo_teams',JSON.stringify(teams));localStorage.setItem('nidc_demo_team_memberships',JSON.stringify(memberships));demoLogTeam(m.team_id,'member_left',state.user.id,state.user.id,{});
      }else{const {error}=await sb.rpc('leave_team_v050',{p_season_id:state.season.id});if(error)throw error;}
      await reloadTeamsAfterMutation();toast('Tu as quitté la Team.');
    }catch(err){toast(friendlyError(err),'error');}
  }
  async function kickTeamMember(userId){const m=state.teamMembers.find(x=>String(x.user_id)===String(userId));if(!confirm(`Exclure ${m?.username||'ce membre'} ?`))return;try{if(demoMode){const {memberships}=ensureDemoTeams();const tm=memberships.find(x=>x.team_id===state.myTeam.id&&x.user_id===userId&&!x.left_at);if(!tm)throw new Error('Membre introuvable.');tm.left_at=new Date().toISOString();tm.leave_type='kicked';localStorage.setItem('nidc_demo_team_memberships',JSON.stringify(memberships));demoLogTeam(state.myTeam.id,'member_kicked',state.user.id,userId,{});}else{const {error}=await sb.rpc('kick_team_member_v050',{p_team_id:state.myTeam.team_id,p_user_id:userId});if(error)throw error;}await reloadTeamsAfterMutation();toast('Membre exclu.');}catch(err){toast(friendlyError(err),'error');}}
  async function transferTeamCaptain(userId){const m=state.teamMembers.find(x=>String(x.user_id)===String(userId));if(!confirm(`Transférer le capitanat à ${m?.username||'ce membre'} ?`))return;try{if(demoMode){const {teams}=ensureDemoTeams();const t=teams.find(x=>x.id===state.myTeam.id);t.captain_user_id=userId;localStorage.setItem('nidc_demo_teams',JSON.stringify(teams));demoLogTeam(t.id,'captain_transferred',state.user.id,userId,{old_captain_user_id:state.user.id});}else{const {error}=await sb.rpc('transfer_team_captain_v050',{p_team_id:state.myTeam.team_id,p_new_captain_user_id:userId});if(error)throw error;}await reloadTeamsAfterMutation();toast('👑 Capitanat transféré.');}catch(err){toast(friendlyError(err),'error');}}
  async function dissolveMyTeam(){if(!confirm('Dissoudre cette Team ? Elle sera archivée et ne sera plus visible dans l’annuaire actif. Elle pourra être réactivée par son dernier capitaine.'))return;try{if(demoMode){const {teams,memberships}=ensureDemoTeams();const t=teams.find(x=>x.id===state.myTeam.id);t.status='dissolved';t.dissolved_at=new Date().toISOString();memberships.filter(m=>m.team_id===t.id&&!m.left_at).forEach(m=>{m.left_at=t.dissolved_at;m.leave_type='dissolved';});localStorage.setItem('nidc_demo_teams',JSON.stringify(teams));localStorage.setItem('nidc_demo_team_memberships',JSON.stringify(memberships));demoLogTeam(t.id,'team_dissolved',state.user.id,null,{name:t.name});}else{const {error}=await sb.rpc('dissolve_team_v050',{p_team_id:state.myTeam.team_id});if(error)throw error;}await reloadTeamsAfterMutation();toast('Team dissoute et archivée.');}catch(err){toast(friendlyError(err),'error');}}

  function renderAdminTeams(){
    const root=$("#adminTeamsPanel");if(!root)return;
    const q=String($("#adminTeamSearch")?.value||'').toLocaleLowerCase('fr');
    const rows=(state.teamDirectory||[]).filter(t=>!q||`${t.name} ${t.captain_username||''}`.toLocaleLowerCase('fr').includes(q));
    root.innerHTML=rows.length?rows.map(t=>`<div class="admin-team-row">${teamBadgeHTML(t)}<div><strong>${esc(t.name)}</strong><small>👑 ${esc(t.captain_username||'Vacante')} · ${Number(t.member_count||0)} membre${Number(t.member_count||0)>1?'s':''} · ${t.status}</small></div><button class="btn secondary small" data-admin-open-team="${t.team_id}">Voir</button></div>`).join(''):'<div class="empty">Aucune Team.</div>';
    $$('[data-admin-open-team]',root).forEach(b=>b.onclick=()=>adminOpenTeam(b.dataset.adminOpenTeam));
  }
  function teamLogoStoragePathFromUrl(url){
    if(!url)return null;const marker='/storage/v1/object/public/team-logos/';const i=String(url).indexOf(marker);if(i<0)return null;return decodeURIComponent(String(url).slice(i+marker.length).split('?')[0]);
  }
  async function superAdminDeleteTeam(teamId,t){
    if(state.profile?.role!=="super_admin")return toast('Suppression définitive réservée au Super Admin.','error');
    const check=prompt(`SUPPRESSION DÉFINITIVE de « ${t?.name||'cette Team'} ».\n\nTape SUPPRIMER pour confirmer.`);
    if(check!=="SUPPRIMER")return;
    try{
      if(demoMode){const {teams,memberships}=ensureDemoTeams();const idx=teams.findIndex(x=>String(x.id)===String(teamId));if(idx>=0)teams.splice(idx,1);for(let i=memberships.length-1;i>=0;i--)if(String(memberships[i].team_id)===String(teamId))memberships.splice(i,1);const events=JSON.parse(localStorage.getItem('nidc_demo_team_events')||'[]').filter(e=>String(e.team_id)!==String(teamId));const requests=JSON.parse(localStorage.getItem('nidc_demo_team_requests')||'[]').filter(r=>String(r.team_id)!==String(teamId));const invites=JSON.parse(localStorage.getItem('nidc_demo_team_invites')||'{}');delete invites[teamId];localStorage.setItem('nidc_demo_teams',JSON.stringify(teams));localStorage.setItem('nidc_demo_team_memberships',JSON.stringify(memberships));localStorage.setItem('nidc_demo_team_events',JSON.stringify(events));localStorage.setItem('nidc_demo_team_requests',JSON.stringify(requests));localStorage.setItem('nidc_demo_team_invites',JSON.stringify(invites));}
      else{
        const path=teamLogoStoragePathFromUrl(t?.logo_url);if(path){const rm=await sb.storage.from('team-logos').remove([path]);if(rm.error)console.warn('Logo Team non supprimé du Storage',rm.error);}
        const {error}=await sb.rpc('super_admin_delete_team_v055a',{p_team_id:teamId});if(error)throw error;
      }
      $("#modalRoot").innerHTML='';await reloadTeamsAfterMutation();toast('Team supprimée définitivement.');
    }catch(err){toast(friendlyError(err),'error');}
  }
  async function adminOpenTeam(teamId){
    try{
      let members=[],events=[];
      if(demoMode){const t=state.teamDirectory.find(x=>String(x.team_id)===String(teamId));members=ensureDemoTeams().memberships.filter(m=>m.team_id===teamId&&!m.left_at).map(m=>{const p=state.demoUsers.find(u=>u.id===m.user_id)||{};return{user_id:m.user_id,username:p.username,is_captain:t?.captain_user_id===m.user_id};});events=JSON.parse(localStorage.getItem('nidc_demo_team_events')||'[]').filter(e=>e.team_id===teamId);}
      else{const [m,e]=await Promise.all([sb.rpc('get_team_members_v050',{p_team_id:teamId}),sb.rpc('get_team_history_v050',{p_team_id:teamId})]);if(m.error)throw m.error;if(e.error)throw e.error;members=m.data||[];events=e.data||[];}
      const t=state.teamDirectory.find(x=>String(x.team_id)===String(teamId));if(!t)throw new Error('Team introuvable.');
      const isSuper=state.profile?.role==='super_admin';
      const root=modal(`Admin · ${t.name}`,`<div class="admin-team-modal"><div class="public-team-head">${teamBadgeHTML(t,true)}<div><h2>${esc(t.name)}</h2><p>👑 ${esc(t.captain_username||'Aucun capitaine')} · ${t.visibility} · ${t.status}</p></div></div><h4>Membres</h4>${members.length?members.map(m=>`<div class="admin-team-member"><span>${m.is_captain?'👑 ':''}${esc(m.username)}</span>${!m.is_captain&&t.status==='active'?`<button class="text-action" data-admin-transfer="${m.user_id}">Nommer capitaine</button>`:''}</div>`).join(''):'<div class="empty">Aucun membre actif.</div>'}<h4>Derniers événements</h4>${events.slice(0,10).map(teamEventHTML).join('')||'<div class="empty">Aucun événement.</div>'}<div class="actions">${t.status==='active'?'<button class="btn danger small" id="adminDissolveTeam">Dissoudre la Team</button>':''}${isSuper?'<button class="btn danger small super-admin-delete" id="superAdminDeleteTeam">Supprimer définitivement</button>':''}</div>${isSuper?'<p class="muted admin-hard-delete-note">La suppression définitive efface la Team, ses adhésions, demandes, invitations et événements. À utiliser uniquement pour modération.</p>':''}</div>`);
      $$('[data-admin-transfer]',root).forEach(b=>b.onclick=async()=>{try{if(demoMode){const {teams}=ensureDemoTeams();teams.find(x=>x.id===teamId).captain_user_id=b.dataset.adminTransfer;localStorage.setItem('nidc_demo_teams',JSON.stringify(teams));}else{const {error}=await sb.rpc('transfer_team_captain_v050',{p_team_id:teamId,p_new_captain_user_id:b.dataset.adminTransfer});if(error)throw error;}$("#modalRoot").innerHTML='';await reloadTeamsAfterMutation();toast('Capitaine corrigé.');}catch(err){toast(friendlyError(err),'error');}});
      const dissolve=$("#adminDissolveTeam",root);if(dissolve)dissolve.onclick=async()=>{if(!confirm('Dissoudre cette Team depuis l’administration ? Elle restera archivée.'))return;try{if(demoMode){const {teams}=ensureDemoTeams();teams.find(x=>x.id===teamId).status='dissolved';localStorage.setItem('nidc_demo_teams',JSON.stringify(teams));}else{const {error}=await sb.rpc('dissolve_team_v050',{p_team_id:teamId});if(error)throw error;}$("#modalRoot").innerHTML='';await reloadTeamsAfterMutation();toast('Team dissoute par Admin.');}catch(err){toast(friendlyError(err),'error');}};
      const hard=$("#superAdminDeleteTeam",root);if(hard)hard.onclick=()=>superAdminDeleteTeam(teamId,t);
    }catch(err){toast(friendlyError(err),'error');}
  }

