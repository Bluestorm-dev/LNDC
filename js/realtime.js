"use strict";

// Le Nid des Champions V0.6.4 — Realtime et pronostics révélés
  function setupRealtime() {
    if(demoMode||!sb||!state.season)return;
    if(state.channel)sb.removeChannel(state.channel);
    state.channel=sb.channel("nidc-live-v060")
      .on("postgres_changes",{event:"*",schema:"public",table:"matches",filter:`season_id=eq.${state.season.id}`},()=>queueRealtimeRefresh("matches"))
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
      .subscribe(status=>{const label=$("#backendStatus span:last-child");if(label)label.textContent=status==="SUBSCRIBED"?"Supabase · LIVE":"Supabase";});
  }

  function queueRealtimeRefresh(kind) {
    clearTimeout(state.realtimeTimer);
    state.realtimeTimer=setTimeout(async()=>{
      try{
        if(kind==="predictions"){
          await loadRankingData(state.rankingScope,false);await Promise.all([loadTeamData(),loadRivalData()]);renderRanking();renderCollectiveStats();renderTeams();renderHomeRival();renderRivalView();updateKpis();
        }else if(kind==="teams"){
          await loadTeamData();renderTeams();renderProfile();renderRanking();renderAdminTeams();
        }else if(kind==="notifications"){
          await loadNotificationData();renderNotificationBell();if(!$("#notificationDrawer")?.classList.contains("hidden"))renderNotificationCenter();
        }else if(kind==="rivals"){
          await loadRivalData();renderHomeRival();renderRivalView();
        }else{
          await loadData();renderAll();
        }
      }catch(err){console.error("Realtime refresh",err);}
    },180);
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
