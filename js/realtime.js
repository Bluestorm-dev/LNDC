"use strict";

// Le Nid des Champions V0.7.1 — Realtime robuste, LIVE sans F5 et filet de sécurité
  function setupRealtime() {
    if(demoMode||!sb||!state.season)return;
    if(state.channel)sb.removeChannel(state.channel);
    state.channel=sb.channel(`nidc-live-v071-${state.season.id}`)
      .on("postgres_changes",{event:"*",schema:"public",table:"matches",filter:`season_id=eq.${state.season.id}`},payload=>queueRealtimeRefresh("matches",payload))
      .on("postgres_changes",{event:"*",schema:"public",table:"matchdays",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("matches"))
      .on("postgres_changes",{event:"*",schema:"public",table:"predictions",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("predictions"))
      .on("postgres_changes",{event:"*",schema:"public",table:"knockout_ties",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("matches"))
      .on("postgres_changes",{event:"*",schema:"public",table:"tie_predictions",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("predictions"))
      .on("postgres_changes",{event:"*",schema:"public",table:"champion_predictions",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("matches"))
      .on("postgres_changes",{event:"*",schema:"public",table:"teams",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("teams"))
      .on("postgres_changes",{event:"*",schema:"public",table:"team_memberships",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("teams"))
      .on("postgres_changes",{event:"*",schema:"public",table:"team_join_requests",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("teams"))
      .on("postgres_changes",{event:"*",schema:"public",table:"team_events",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("teams"))
      .on("postgres_changes",{event:"*",schema:"public",table:"notifications",filter:`user_id=eq.${state.user.id}`},()=>queueRealtimeRefresh("notifications"))
      .on("postgres_changes",{event:"*",schema:"public",table:"rival_duels",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("rivals"))
      .on("postgres_changes",{event:"*",schema:"public",table:"player_rivals",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("rivals"))
      .on("postgres_changes",{event:"*",schema:"public",table:"gamification_events",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("gamification"))
      .on("postgres_changes",{event:"*",schema:"public",table:"gamification_records",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("gamification"))
      .subscribe(status=>{
        const label=$("#backendStatus span:last-child");
        if(label)label.textContent=status==="SUBSCRIBED"?"Supabase · LIVE":status==="CHANNEL_ERROR"?"Supabase · secours auto":"Supabase";
        if(["CHANNEL_ERROR","TIMED_OUT","CLOSED"].includes(status))setTimeout(()=>{if(state.user&&state.season)setupRealtime();},1800);
      });
    startLiveFallback();
  }

  function liveSnapshotKey(rows){return (rows||[]).map(m=>`${m.id}:${m.status}:${m.home_score}:${m.away_score}:${m.updated_at||''}`).join('|');}

  async function refreshMyPredictionSnapshot(){
    if(demoMode||!sb||!state.season||!state.user)return;
    const [{data:preds,error:pErr},{data:history,error:hErr}]=await Promise.all([
      sb.from("predictions").select("id,match_id,home_score,away_score,points,updated_at").eq("user_id",state.user.id).eq("season_id",state.season.id),
      sb.rpc("get_my_prediction_history",{p_season_id:state.season.id})
    ]);
    if(pErr)throw pErr;
    state.predictions=new Map((preds||[]).map(p=>[p.match_id,p]));
    if(!hErr)state.history=(history||[]).filter(h=>{const m=(state.adminAllMatches||[]).find(x=>String(x.id)===String(h.match_id));return !m?.is_test||m.test_enabled!==false;});
  }

  async function refreshLiveSnapshot(force=false){
    if(demoMode||!sb||!state.season||state.livePollBusy||document.hidden)return;
    state.livePollBusy=true;
    try{
      const {data:rows,error}=await sb.from("matches").select("id,season_id,phase_id,matchday_id,kickoff_at,stadium,venue_country,status,data_source,is_test,test_enabled,home_score,away_score,points_multiplier,external_provider,external_match_id,external_stage,odds_home,odds_draw,odds_away,odds_provider,odds_bookmaker,odds_source_season,odds_is_test_shifted,odds_updated_at,tie_id,leg_number,went_to_extra_time,penalties_home,penalties_away,winner_club_id,updated_at,home_club:clubs!matches_home_club_id_fkey(id,name,short_name,tla,country,venue,logo_url,logo_source_url,logo_storage_path),away_club:clubs!matches_away_club_id_fkey(id,name,short_name,tla,country,venue,logo_url,logo_source_url,logo_storage_path)").eq("season_id",state.season.id).order("kickoff_at");
      if(error)throw error;
      const next=rows||[],key=liveSnapshotKey(next),prev=state.liveSnapshotKey||liveSnapshotKey(state.adminAllMatches||state.allMatches);
      if(force||key!==prev){
        state.liveSnapshotKey=key;state.adminAllMatches=next;state.allMatches=next.filter(m=>!m.is_test||m.test_enabled!==false);state.matches=state.allMatches.filter(m=>m.matchday_id===state.selectedMatchdayId);
        if(typeof maybeAutoSelectLiveRankingScope==="function")maybeAutoSelectLiveRankingScope();
        const promises=[refreshMyPredictionSnapshot(),loadRankingData(state.rankingScope,false)];
        if(typeof loadGamificationData==="function")promises.push(loadGamificationData());
        await Promise.all(promises);
        renderMatchPanels();renderHistory();renderRanking();renderCollectiveStats();renderLiveTicker();renderHome();updateKpis();if(typeof renderMuseum==="function")renderMuseum();if(typeof renderHomeMuseumCard==="function")renderHomeMuseumCard(); if(typeof renderHomeNarrativeCard==="function")renderHomeNarrativeCard();
      }
    }catch(err){console.warn("LIVE fallback",err);}finally{state.livePollBusy=false;}
  }

  function startLiveFallback(){
    if(state.livePollTimer)clearInterval(state.livePollTimer);
    // Realtime reste prioritaire. Ce filet de sécurité évite tout F5 si un événement
    // websocket est perdu par le navigateur, le réseau ou la publication Supabase.
    state.livePollTimer=setInterval(()=>refreshLiveSnapshot(false),4000);
    if(!state.liveFallbackEventsBound){
      state.liveFallbackEventsBound=true;
      document.addEventListener("visibilitychange",()=>{if(!document.hidden)refreshLiveSnapshot(true);});
      window.addEventListener("focus",()=>refreshLiveSnapshot(true));
      window.addEventListener("online",()=>refreshLiveSnapshot(true));
    }
  }

  function queueRealtimeRefresh(kind,payload=null) {
    clearTimeout(state.realtimeTimer);
    state.realtimeTimer=setTimeout(async()=>{
      try{
        if(kind==="matches"){
          // Le payload réveille immédiatement le front ; la lecture serveur reste la source de vérité.
          if(payload?.new?.id){state.liveSnapshotKey="";}
          await refreshLiveSnapshot(true);
        }else if(kind==="predictions"){
          await loadRankingData(state.rankingScope,false);await Promise.all([loadTeamData(),loadRivalData()]);renderRanking();renderCollectiveStats();renderTeams();renderHomeRival();renderRivalView();updateKpis();
        }else if(kind==="teams"){
          await loadTeamData();renderTeams();renderProfile();renderRanking();renderAdminTeams();
        }else if(kind==="notifications"){
          await loadNotificationData();renderNotificationBell();if(!$("#notificationDrawer")?.classList.contains("hidden"))renderNotificationCenter();
        }else if(kind==="rivals"){
          await loadRivalData();renderHomeRival();renderRivalView();
        }else if(kind==="gamification"){
          if(typeof loadGamificationData==="function")await loadGamificationData();if(state.profile?.role==="super_admin"&&typeof loadAdminGamificationData==="function")await loadAdminGamificationData();if(typeof renderMuseum==="function")renderMuseum();if(typeof renderHomeMuseumCard==="function")renderHomeMuseumCard(); if(typeof renderHomeNarrativeCard==="function")renderHomeNarrativeCard();if(typeof renderAdminGamification==="function")renderAdminGamification();
        }else{
          await loadData();renderAll();
        }
      }catch(err){console.error("Realtime refresh",err);}
    },120);
  }

  async function showMatchPredictions(matchId) {
    try {
      let rows=[];
      if(demoMode){
        const all=demoPredictionPool();
        rows=state.demoUsers.map(u=>{const p=all[`${u.id}:${matchId}`];if(!p)return null;const m=state.allMatches.find(x=>x.id===matchId);return{user_id:u.id,username:u.username,avatar_key:u.avatar_key,prediction_home:p.home_score,prediction_away:p.away_score,current_points:m&&["live","finished"].includes(m.status)?scorePoints(p.home_score,p.away_score,m.home_score,m.away_score,m.points_multiplier||1):0,is_me:u.id===state.user.id};}).filter(Boolean);
      } else {
        const {data,error}=await sb.rpc("get_match_predictions_v030",{p_match_id:matchId});if(error)throw error;rows=data||[];
      }
      const m=state.allMatches.find(x=>x.id===matchId);
      const root=modal(`Pronos du Nid · ${m?.home_club?.short_name||"?"} – ${m?.away_club?.short_name||"?"}`,rows.length?`<div class="nid-predictions">${rows.map(r=>`<div class="nid-prediction-row">${avatarHTML(r)}<strong>${r.is_me?'★ ':''}${esc(r.username)}${reactionButtonHTML(r.user_id,true)}</strong><span class="nid-prediction-score">${r.prediction_home}–${r.prediction_away}</span><span class="nid-prediction-points">${Number(r.current_points||0)} pt${Number(r.current_points||0)>1?'s':''}</span></div>`).join("")}</div>`:'<div class="empty">Aucun prono enregistré pour ce match.</div>');
      bindPlayerReactionButtons(root);
      return root;
    } catch(err) { toast(friendlyError(err),"error"); }
  }

  function toLocalDateTimeInput(date) {
    const parts=new Intl.DateTimeFormat("sv-SE",{year:"numeric",month:"2-digit",day:"2-digit",hour:"2-digit",minute:"2-digit",hour12:false,timeZone:"Europe/Paris"}).formatToParts(date).reduce((a,p)=>(a[p.type]=p.value,a),{});
    return `${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}`;
  }

  function parseFrenchLocalInput(value) {
    if(!value)return null;
    // En France métropolitaine, le navigateur de l'utilisateur est supposé en heure locale.
    const d=new Date(value);
    return Number.isNaN(d.getTime())?null:d.toISOString();
  }
