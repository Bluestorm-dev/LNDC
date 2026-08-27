"use strict";

// Le Nid des Champions V0.7.2 — chargement des données et classements serveur
  function chooseDefaultMatchday() {
    if (state.selectedMatchdayId && state.matchdays.some(md=>md.id===state.selectedMatchdayId)) return;
    const upcoming = state.matchdays.find(md => state.allMatches.some(m => m.matchday_id===md.id && !isLocked(m)));
    state.selectedMatchdayId = upcoming?.id || state.matchdays[0]?.id || null;
  }

  async function loadData() {
    if(demoMode) {
      demoInit();
      const allPred=JSON.parse(localStorage.getItem("nidc_demo_predictions")||"{}");
      state.predictions=new Map(state.allMatches.map(m=>[m.id,allPred[`${state.user.id}:${m.id}`]]).filter(x=>x[1]));
      state.matches=state.allMatches.filter(m=>m.matchday_id===state.selectedMatchdayId);
      buildLocalHistory();
      loadDemoChampionState();
      await loadProfileDirectory();
      await loadRankingData(state.rankingScope,false);
      await loadTeamData();
      await Promise.all([loadNotificationData(),loadRivalData(),loadOwlData(),loadSupportData()]);
      return;
    }

    const slug=CFG.DEFAULT_SEASON_SLUG||"ucl-2026-27";
    let {data:season,error}=await sb.from("seasons").select("*").eq("slug",slug).maybeSingle();
    if(error) throw error;
    if(!season){({data:season,error}=await sb.from("seasons").select("*").eq("is_active",true).limit(1).maybeSingle());if(error)throw error;}
    state.season=season;
    if(!state.season) throw new Error("Aucune saison active.");

    const [{data:matchdays,error:mdErr},{data:clubs,error:clubErr},{data:matches,error:matErr},{data:phases,error:phaseErr},{data:ties,error:tieErr}] = await Promise.all([
      sb.from("matchdays").select("*").eq("season_id",state.season.id).order("number"),
      sb.from("clubs").select("id,name,short_name,tla,country,venue,logo_url,logo_source_url,logo_storage_path,external_provider,external_id,is_active").eq("is_active",true).order("name"),
      sb.from("matches").select("id,season_id,phase_id,matchday_id,kickoff_at,stadium,venue_country,status,data_source,is_test,test_enabled,home_score,away_score,points_multiplier,external_provider,external_match_id,external_stage,odds_home,odds_draw,odds_away,odds_provider,odds_bookmaker,odds_source_season,odds_is_test_shifted,odds_updated_at,tie_id,leg_number,went_to_extra_time,penalties_home,penalties_away,winner_club_id,home_club:clubs!matches_home_club_id_fkey(id,name,short_name,tla,country,venue,logo_url,logo_source_url,logo_storage_path),away_club:clubs!matches_away_club_id_fkey(id,name,short_name,tla,country,venue,logo_url,logo_source_url,logo_storage_path)").eq("season_id",state.season.id).order("kickoff_at"),
      sb.from("competition_phases").select("id,season_id,code,name,sort_order,default_multiplier").eq("season_id",state.season.id).order("sort_order"),
      sb.from("knockout_ties").select("*").eq("season_id",state.season.id).order("sort_order")
    ]);
    if(mdErr) throw mdErr; if(clubErr) throw clubErr; if(matErr) throw matErr; if(phaseErr) throw phaseErr; if(tieErr) throw new Error("Patch V0.4.0 absent : exécute sql/HOTFIX_V0.4.0_EXISTING_DB.sql.");
    state.adminAllMatchdays=matchdays||[]; state.adminAllMatches=matches||[]; state.matchdays=(matchdays||[]).filter(md=>!md.is_test||md.test_enabled!==false); state.clubs=clubs||[]; state.allMatches=(matches||[]).filter(m=>!m.is_test||m.test_enabled!==false); state.phases=phases||[]; state.knockoutTies=ties||[];
    maybeAutoSelectLiveRankingScope();
    const {data:memberships,error:membershipErr}=await sb.from("club_catalog_memberships").select("club_id,competition_code,competition_name,country,season_year,updated_at");
    state.clubMemberships=membershipErr?[]:(memberships||[]);
    chooseDefaultMatchday();
    state.matches=state.allMatches.filter(m=>m.matchday_id===state.selectedMatchdayId);
    const liveEvening=state.allMatches.find(m=>m.status==="live");
    if(liveEvening) state.selectedEveningDate=localDateKey(liveEvening.kickoff_at);
    else if(!state.selectedEveningDate) state.selectedEveningDate=deriveEveningDate();

    const {data:preds,error:pErr}=await sb.from("predictions").select("id,match_id,home_score,away_score,points,updated_at").eq("user_id",state.user.id).eq("season_id",state.season.id);
    if(pErr) throw pErr;
    state.predictions=new Map((preds||[]).map(p=>[p.match_id,p]));
    const {data:tiePreds,error:tpErr}=await sb.from("tie_predictions").select("id,tie_id,qualified_club_id,pick_timing,points,updated_at").eq("user_id",state.user.id).eq("season_id",state.season.id);
    if(tpErr) throw tpErr;
    state.tiePredictions=new Map((tiePreds||[]).map(p=>[p.tie_id,p]));
    await loadChampionData();
    await loadProfileDirectory();

    const {data:history,error:hErr}=await sb.rpc("get_my_prediction_history",{p_season_id:state.season.id});
    state.history=hErr ? [] : (history||[]).filter(h=>{const m=(state.adminAllMatches||[]).find(x=>String(x.id)===String(h.match_id));return !m?.is_test||m.test_enabled!==false;});
    await loadRankingData(state.rankingScope,false);
    await loadTeamData();
    await Promise.all([loadNotificationData(),loadRivalData(),loadOwlData(),loadSupportData()]);
  }


  function loadDemoChampionState() {
    const picks=JSON.parse(localStorage.getItem("nidc_demo_champions")||"{}");
    const first=picks[`${state.user?.id}:1`]||null, second=picks[`${state.user?.id}:2`]||null;
    const firstClub=first?state.clubs.find(c=>c.id===first.club_id):null;
    const secondClub=second?state.clubs.find(c=>c.id===second.club_id):null;
    state.championStatus={first_open:true,first_close_at:state.allMatches[0]?.kickoff_at||null,second_open:false,second_close_at:null,first_club_id:firstClub?.id||null,first_club_name:firstClub?.name||null,first_default:false,first_eliminated_at:null,first_points:0,second_club_id:secondClub?.id||null,second_club_name:secondClub?.name||null,second_eliminated_at:null,second_points:0};
    state.championCandidates={1:[...state.clubs],2:[]};
    state.championBoards={1:first?[{user_id:state.user.id,username:state.profile?.username,club_id:firstClub?.id,club_name:firstClub?.name,assigned_default:false,eliminated_at:null,points:0}]:[],2:[]};
  }

  async function loadChampionData() {
    if(demoMode){loadDemoChampionState();return;}
    const [st,c1,c2,b1,b2]=await Promise.all([
      sb.rpc("get_champion_status_v040",{p_season_id:state.season.id}),
      sb.rpc("get_champion_candidates_v040",{p_season_id:state.season.id,p_pick_number:1}),
      sb.rpc("get_champion_candidates_v040",{p_season_id:state.season.id,p_pick_number:2}),
      sb.rpc("get_champion_board_v040",{p_season_id:state.season.id,p_pick_number:1}),
      sb.rpc("get_champion_board_v040",{p_season_id:state.season.id,p_pick_number:2})
    ]);
    if(st.error) throw st.error;
    state.championStatus=st.data?.[0]||null;
    state.championCandidates={1:c1.error?[]:(c1.data||[]),2:c2.error?[]:(c2.data||[])};
    state.championBoards={1:b1.error?[]:(b1.data||[]),2:b2.error?[]:(b2.data||[])};
  }

  function clubById(id){return state.clubs.find(c=>c.id===id)||null;}
  function phaseById(id){return state.phases.find(p=>p.id===id)||null;}
  function phaseByCode(code){return state.phases.find(p=>p.code===code)||null;}

  async function selectMatchday(id) {
    state.selectedMatchdayId=id;
    state.matches=state.allMatches.filter(m=>m.matchday_id===id);
    state.selectedEveningDate=deriveEveningDate();
    if(["matchday","evening"].includes(state.rankingScope)) await loadRankingData(state.rankingScope,false);
    if(state.teamRankingMode==="matchday") await loadTeamData();
    renderMatchdayTabs(); renderMatchPanels(); updateKpis(); renderHome(); renderAdminMatches(); renderRanking(); renderCollectiveStats(); renderTeams();
  }

  function deriveEveningDate() {
    const live=state.allMatches.find(m=>m.status==="live");
    if(live) return localDateKey(live.kickoff_at);
    const selected=state.matches.find(m=>m.status==="live") || state.matches[0] || state.allMatches.find(m=>m.status==="finished") || state.allMatches[0];
    return selected ? localDateKey(selected.kickoff_at) : null;
  }

  function serverRankingScope(scope=state.rankingScope) {
    return ["precision","exacts"].includes(scope) ? "general" : scope;
  }

  function liveRankingContext(){
    const matches=state.allMatches||[];
    return {
      officialLive:matches.filter(m=>m.status==="live"&&!m.is_test),
      testLive:matches.filter(m=>m.status==="live"&&m.is_test&&m.test_enabled!==false)
    };
  }

  function maybeAutoSelectLiveRankingScope(){
    const {officialLive,testLive}=liveRankingContext();
    if(!state.rankingScopeManuallyChosen && testLive.length && !officialLive.length){
      state.rankingScope="test";
      state.rankingAutoTestActive=true;
    }else if(state.rankingAutoTestActive && !testLive.length){
      state.rankingScope="general";
      state.rankingAutoTestActive=false;
    }
    return state.rankingScope;
  }

  async function loadRankingData(scope=state.rankingScope, shouldRender=true) {
    state.rankingScope=scope||"general";
    const dbScope=serverRankingScope(state.rankingScope);
    const evening=state.selectedEveningDate || deriveEveningDate();
    state.selectedEveningDate=evening;
    if(demoMode) {
      state.rankingRows=buildDemoLeaderboard(dbScope);
      if(dbScope==="general") state.standings=buildDemoLeaderboard("general");
      state.collectiveStats=buildDemoCollective(dbScope);
    } else if(state.season) {
      const args={
        p_season_id:state.season.id,
        p_scope:dbScope,
        p_matchday_id:dbScope==="matchday"?state.selectedMatchdayId:null,
        p_evening_date:dbScope==="evening"?evening:null,
        p_include_live:true
      };
      if(dbScope==="test"){
        let {data:rows,error:rErr}=await sb.rpc("get_test_leaderboard_v071",{p_season_id:state.season.id,p_include_live:true});
        // Compatibilité pendant le déploiement du HOTFIX : l'ancien RPC reste un secours.
        if(rErr && /get_test_leaderboard_v071|function/i.test(String(rErr.message||rErr.details||""))){
          ({data:rows,error:rErr}=await sb.rpc("get_test_leaderboard_v070",{p_season_id:state.season.id,p_include_live:true}));
        }
        if(rErr) throw rErr;
        state.rankingRows=rows||[];
        state.collectiveStats=null;
      }else{
        const [{data:rows,error:rErr},{data:collective,error:cErr}]=await Promise.all([
          sb.rpc("get_leaderboard_v040",args),
          sb.rpc("get_collective_stats_v030",{
            p_season_id:state.season.id,
            p_scope:dbScope,
            p_matchday_id:dbScope==="matchday"?state.selectedMatchdayId:null,
            p_evening_date:dbScope==="evening"?evening:null
          })
        ]);
        if(rErr) throw rErr;
        state.rankingRows=rows||[];
        if(dbScope==="general") state.standings=rows||[];
        state.collectiveStats=cErr?null:(collective?.[0]||null);
      }
    }
    if(shouldRender){renderRanking();renderCollectiveStats();updateKpis();renderLiveTicker();}
  }

  async function setRankingScope(scope,options={}) {
    try {
      if(!options.automatic){
        state.rankingScopeManuallyChosen=true;
        state.rankingAutoTestActive=false;
      }
      $$('[data-ranking-scope]').forEach(btn=>btn.classList.toggle("active",btn.dataset.rankingScope===scope));
      await loadRankingData(scope,true);
    } catch(err) { toast(friendlyError(err),"error"); }
  }

  function selectedMatchday() { return state.matchdays.find(md=>md.id===state.selectedMatchdayId) || null; }
  function progressFor(matchdayId) {
    const matches=state.allMatches.filter(m=>m.matchday_id===matchdayId && m.status!=="cancelled");
    const done=matches.filter(m=>state.predictions.has(m.id)).length;
    return {done,total:matches.length,pct:matches.length?Math.round(done/matches.length*100):0};
  }
  function progressCount(){return progressFor(state.selectedMatchdayId).done;}
