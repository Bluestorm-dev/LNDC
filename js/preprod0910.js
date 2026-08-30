"use strict";

// Le Nid des Champions V0.9.10 — sécurisation pré-production.
(() => {
  state.preprod0910 = state.preprod0910 || { health:null, windows:[], editableClubIds:[], loaded:false };

  const norm = value => String(value||"")
    .normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase()
    .replace(/\b(fc|cf|afc|sk|fk|kv|ssc|vfb|rc|club|football|calcio|1907)\b/g," ")
    .replace(/[^a-z0-9]+/g," ").trim().replace(/\s+/g," ");

  const aliases = {
    "inter":"internazionale milano",
    "leipzig":"rb leipzig",
    "lens":"racing lens",
    "lille":"lille osc",
    "napoli":"napoli",
    "roma":"as roma",
    "sporting cp":"sporting clube portugal",
    "atletico madrid":"atletico madrid",
    "bayern munchen":"bayern munchen",
    "borussia dortmund":"borussia dortmund",
    "paris saint germain":"paris saint germain",
    "slovan bratislava":"slovan bratislava",
    "slavia praha":"slavia praha",
    "psv eindhoven":"psv eindhoven",
    "bodo glimt":"bodo glimt",
    "porto":"porto",
    "stuttgart":"stuttgart",
    "como":"como",
    "aek athens":"pae aek",
    "aek athenes":"pae aek",
    "pae aek":"aek athens",
  };

  function scoreClubMatch(source, club){
    const a=norm(source), b=norm(club.name), c=norm(club.short_name), d=norm(club.tla);
    if(a===b||a===c)return 100;
    const mapped=aliases[a];
    if(mapped && (b===mapped||c===mapped||b.includes(mapped)||mapped.includes(b)))return 95;
    const at=new Set(a.split(" ")), bt=new Set(b.split(" "));
    let common=0; for(const t of at)if(t.length>2&&bt.has(t))common++;
    if(common>=2)return 80+common;
    if(a.length>=5&&(b.includes(a)||a.includes(b)))return 75;
    if(d && a===d)return 70;
    return 0;
  }

  function resolveClubV0910(name){
    const candidates=(state.clubs||[]).map(c=>({club:c,score:scoreClubMatch(name,c)})).filter(x=>x.score>0).sort((a,b)=>b.score-a.score);
    if(!candidates.length)return null;
    if(candidates.length>1 && candidates[0].score===candidates[1].score && candidates[0].club.id!==candidates[1].club.id)return null;
    return candidates[0].club;
  }

  async function loadPreprodSafetyV0910(force=false){
    if(demoMode||!state.season)return;
    if(state.preprod0910.loaded&&!force)return;
    const year=seasonStartYear();
    const [h,w,memberships]=await Promise.all([
      sb.rpc("get_calendar_health_v0910",{p_season_id:state.season.id}),
      sb.from("competition_schedule_windows_v0910").select("phase_code,matchday_number,leg_number,label,starts_at,ends_at,source").eq("season_id",state.season.id).order("starts_at"),
      sb.from("club_catalog_memberships").select("club_id").eq("competition_code","CL").eq("season_year",year)
    ]);
    if(!h.error)state.preprod0910.health=h.data||null;
    if(!w.error)state.preprod0910.windows=w.data||[];
    if(!memberships.error)state.preprod0910.editableClubIds=[...new Set((memberships.data||[]).map(x=>String(x.club_id)))];
    state.preprod0910.loaded=true;
  }

  function calendarHealthHtmlV0910(){
    const h=state.preprod0910.health;
    if(!h)return '<div class="empty">Actualise l’état du calendrier.</div>';
    const total=Number(h.official_matches||0), ext=Number(h.with_external_id||0), odds=Number(h.with_odds||0), locked=Number(h.manual_locked||0);
    return `<div class="calendar-health-grid">
      <span><b>${total}/144</b><small>matchs locaux</small></span><span><b>${Number(h.matchdays||0)}/8</b><small>journées</small></span>
      <span><b>${ext}</b><small>liés Football-Data</small></span><span><b>${locked}</b><small>verrouillés manuellement</small></span><span><b>${odds}</b><small>avec cotes 1N2</small></span>
    </div><p class="${h.complete?'form-msg ok':'form-msg'}">${h.complete?'✓ Calendrier de phase de ligue complet.':'⚠️ Calendrier incomplet : le Nid conserve les matchs locaux et accepte les mises à jour partielles du fournisseur.'}</p>`;
  }

  function editableClubsV0910(){
    const ids=new Set((state.preprod0910.editableClubIds||[]).map(String));
    return (state.clubs||[]).filter(c=>ids.has(String(c.id))||c.metadata_source==='manual').slice().sort((a,b)=>a.name.localeCompare(b.name,'fr'));
  }

  function matchOddsLabelV0910(m){
    const vals=[m.odds_home,m.odds_draw,m.odds_away];
    if(!vals.every(v=>v!==null&&v!==undefined&&Number.isFinite(Number(v))))return '<span class="muted">Aucune cote</span>';
    return `<span class="manual-odds-summary"><b>1 ${Number(vals[0]).toFixed(2)}</b><b>N ${Number(vals[1]).toFixed(2)}</b><b>2 ${Number(vals[2]).toFixed(2)}</b><small>${esc(m.odds_bookmaker||m.odds_provider||'')}</small></span>`;
  }

  function renderPreprodSafetyV0910(){
    const health=$("#calendarHealthV0910"); if(health)health.innerHTML=calendarHealthHtmlV0910();
    const sel=$("#adminClubManualSelectV0910");
    if(sel){
      const previous=sel.value, clubs=editableClubsV0910();
      sel.innerHTML=clubs.map(c=>`<option value="${c.id}">${esc(c.name)}${c.country?` · ${esc(c.country)}`:''}${c.metadata_source==='manual'?' · Manuel':''}</option>`).join('')||'<option value="">Aucun club C1</option>';
      if(previous&&clubs.some(c=>String(c.id)===String(previous)))sel.value=previous;
    }
    const windows=$("#officialWindowsV0910");
    if(windows){
      windows.innerHTML=(state.preprod0910.windows||[]).map(w=>{
        const day=Number(w.matchday_number||0);
        const inner=`<b>${esc(w.label)}</b><small>${new Date(w.starts_at).toLocaleDateString('fr-FR',{day:'2-digit',month:'short',year:'numeric'})}</small>`;
        return w.phase_code==='LEAGUE'&&day>=1&&day<=8?`<button type="button" class="schedule-window-chip editable" data-edit-matchday-v0910="${day}" title="Ouvrir les matchs de cette journée">${inner}<em>Modifier les matchs</em></button>`:`<span class="schedule-window-chip">${inner}</span>`;
      }).join('')||'<span class="muted">Fenêtres officielles chargées après migration SQL.</span>';
      $$('[data-edit-matchday-v0910]',windows).forEach(btn=>btn.onclick=()=>openMatchdayEditorV0910(Number(btn.dataset.editMatchdayV0910)));
    }
  }

  async function refreshCalendarHealthV0910(){
    state.preprod0910.loaded=false; await loadPreprodSafetyV0910(true); renderPreprodSafetyV0910();
  }

  async function seedOfficialCalendarV0910(){
    setMsg("#syncStatus","Lecture du calendrier officiel UEFA 2026/27 intégré au Nid…");
    try{
      const response=await fetch("assets/data/ucl-2026-27-official.json",{cache:"no-store"});
      if(!response.ok)throw new Error("Fichier de calendrier officiel introuvable.");
      const data=await response.json();
      if(!Array.isArray(data.fixtures)||data.fixtures.length!==144)throw new Error("Le calendrier officiel intégré n'a pas 144 matchs.");
      const unresolved=new Set(), resolved=data.fixtures.map(f=>{
        const home=resolveClubV0910(f.home),away=resolveClubV0910(f.away);
        if(!home)unresolved.add(f.home);if(!away)unresolved.add(f.away);
        return {...f,home_club_id:home?.id||null,away_club_id:away?.id||null};
      });
      if(unresolved.size)throw new Error(`Clubs non reconnus : ${[...unresolved].join(', ')}. Lance d'abord « Clubs C1 + logos » ou ajoute/corrige ces équipes manuellement.`);
      const {data:result,error}=await sb.rpc("admin_seed_official_calendar_v0910",{p_season_id:state.season.id,p_fixtures:resolved});
      if(error)throw error;
      await loadData(); await loadChampionData(); await refreshCalendarHealthV0910(); renderAll();
      setMsg("#syncStatus",`✓ Calendrier UEFA : 144 matchs contrôlés · ${result?.inserted||0} ajoutés · ${result?.updated||0} actualisés · ${result?.skipped||0} protégés manuellement.`,"ok");
      toast("📅 Calendrier officiel chargé.");
    }catch(err){setMsg("#syncStatus",friendlyError(err),"error");}
  }

  function clubEditorHtmlV0910(club){
    return `<div class="field"><label>Nom officiel</label><input id="clubNameV0910" value="${esc(club?.name||'')}"></div>
    <div class="grid grid-2"><div class="field"><label>Nom court</label><input id="clubShortV0910" value="${esc(club?.short_name||'')}"></div><div class="field"><label>Sigle</label><input id="clubTlaV0910" maxlength="6" value="${esc(club?.tla||'')}"></div></div>
    <div class="grid grid-2"><div class="field"><label>Pays</label><input id="clubCountryV0910" value="${esc(club?.country||'')}"></div><div class="field"><label>Stade</label><input id="clubVenueV0910" value="${esc(club?.venue||'')}"></div></div>
    <div class="field"><label>Logo (URL facultative)</label><input id="clubLogoV0910" value="${esc(club?.logo_url||'')}"></div>
    ${club?'<label class="notification-toggle"><span>Protéger ces métadonnées des mises à jour Football-Data</span><input id="clubLockV0910" type="checkbox" checked></label>':''}
    <div class="actions"><button id="saveClubV0910" class="btn gold">Enregistrer</button></div>
    ${club?`<hr class="admin-editor-separator-v0910"><section class="club-merge-v0910"><span class="eyebrow">Doublon de club</span><h4>Fusionner avec cette fiche</h4><p class="muted">La fiche ouverte sera conservée. Matchs, données C1 et identité Football-Data du doublon seront rattachés ici. Réservé au Super Admin.</p><div class="field"><label>Doublon à absorber</label><select id="clubMergeSourceV0910"><option value="">— Choisir un doublon —</option>${editableClubsV0910().filter(c=>String(c.id)!==String(club.id)).map(c=>`<option value="${c.id}">${esc(c.name)}${c.external_provider?` · ${esc(c.external_provider)}`:''}</option>`).join('')}</select></div><button id="mergeClubV0910" class="btn danger">Fusionner le doublon</button></section>`:''}
    <div id="clubEditorMsgV0910" class="form-msg"></div>`;
  }

  function openClubEditorV0910(clubId=null){
    const club=clubId?editableClubsV0910().find(c=>String(c.id)===String(clubId)):null;
    if(clubId&&!club)return toast("Seuls les clubs de la Ligue des champions et les clubs créés manuellement sont modifiables.","error");
    const root=modal(club?"Modifier une équipe":"Ajouter une équipe",clubEditorHtmlV0910(club));
    $("#saveClubV0910",root).onclick=async()=>{
      try{
        const args={name:$("#clubNameV0910",root).value.trim(),short:$("#clubShortV0910",root).value.trim(),tla:$("#clubTlaV0910",root).value.trim(),country:$("#clubCountryV0910",root).value.trim(),venue:$("#clubVenueV0910",root).value.trim(),logo:$("#clubLogoV0910",root).value.trim()};
        if(!args.name||!args.short)throw new Error("Nom et nom court requis.");
        if(club){
          const {error}=await sb.rpc("admin_update_club_metadata_v0910",{p_club_id:club.id,p_name:args.name,p_short_name:args.short,p_tla:args.tla||null,p_country:args.country||null,p_venue:args.venue||null,p_logo_url:args.logo||null,p_lock_manual:$("#clubLockV0910",root).checked});if(error)throw error;
        }else{
          const {error}=await sb.rpc("admin_create_club_v0910",{p_name:args.name,p_short_name:args.short,p_tla:args.tla||null,p_country:args.country||null,p_venue:args.venue||null,p_logo_url:args.logo||null,p_competition_code:"CL",p_season_year:seasonStartYear()});if(error)throw error;
        }
        root.innerHTML="";await loadData();renderAll();await refreshCalendarHealthV0910();toast(club?"Équipe modifiée.":"Équipe ajoutée.");
      }catch(err){setMsg("#clubEditorMsgV0910",friendlyError(err),"error");}
    };
    if(club && $("#mergeClubV0910",root))$("#mergeClubV0910",root).onclick=async()=>{
      try{
        const sourceId=$("#clubMergeSourceV0910",root)?.value;
        if(!sourceId)throw new Error("Choisis le doublon à fusionner.");
        const source=editableClubsV0910().find(c=>String(c.id)===String(sourceId));
        if(!source)throw new Error("Doublon introuvable ou non modifiable.");
        if(!confirm(`Fusionner « ${source.name} » dans « ${club.name} » ?\n\nLa fiche « ${club.name} » sera conservée.`))return;
        const {error}=await sb.rpc("admin_merge_clubs_v0910",{p_keep_id:club.id,p_remove_id:sourceId});
        if(error)throw error;
        root.innerHTML="";
        await loadData(); await refreshCalendarHealthV0910(); renderAll();
        toast(`🔗 ${source.name} fusionné dans ${club.name}.`);
      }catch(err){setMsg("#clubEditorMsgV0910",friendlyError(err),"error");}
    };
  }

  function openSelectedClubEditorV0910(){const id=$("#adminClubManualSelectV0910")?.value;if(id)openClubEditorV0910(id);}

  function openMatchdayEditorV0910(number){
    const md=(state.matchdays||[]).find(x=>!x.is_test&&Number(x.number)===Number(number));
    if(!md)return toast(`Journée ${number} introuvable.`,"error");
    const matches=(state.allMatches||[]).filter(m=>!m.is_test&&String(m.matchday_id)===String(md.id)).sort((a,b)=>new Date(a.kickoff_at)-new Date(b.kickoff_at));
    const root=modal(`${esc(md.name||`Journée ${number}`)} — ${matches.length} match${matches.length>1?'s':''}`,`<div class="matchday-editor-v0910">
      <p class="muted">Clique sur un match pour corriger équipes, horaire, stade ou saisir les cotes 1N2 manuellement. Une correction de calendrier peut être verrouillée face à Football-Data.</p>
      <div class="matchday-editor-list-v0910">${matches.map(m=>`<article class="matchday-edit-row-v0910"><div><b>${esc(m.home_club?.short_name||m.home_club?.name||'?')} – ${esc(m.away_club?.short_name||m.away_club?.name||'?')}</b><small>${new Date(m.kickoff_at).toLocaleString('fr-FR',{dateStyle:'short',timeStyle:'short'})}${m.stadium?` · ${esc(m.stadium)}`:''}</small>${matchOddsLabelV0910(m)}</div><button class="btn small" data-edit-match-v0910="${m.id}">✏️ Modifier</button></article>`).join('')||'<div class="empty">Aucun match dans cette journée.</div>'}</div>
    </div>`);
    $$('[data-edit-match-v0910]',root).forEach(btn=>btn.onclick=()=>{const id=btn.dataset.editMatchV0910;root.innerHTML="";openMatchScheduleEditorV0910(id);});
  }

  function openMatchScheduleEditorV0910(matchId){
    const m=state.allMatches.find(x=>String(x.id)===String(matchId));if(!m)return;
    const allowedClubs=editableClubsV0910();
    const clubOptions=id=>allowedClubs.map(c=>`<option value="${c.id}" ${String(c.id)===String(id)?'selected':''}>${esc(c.name)}</option>`).join('');
    const mdOptions=['<option value="">— Sans journée —</option>',...(state.matchdays||[]).filter(md=>!md.is_test).map(md=>`<option value="${md.id}" ${String(md.id)===String(m.matchday_id)?'selected':''}>${esc(md.name)}</option>`)] ;
    const oddsEditable=!['live','finished'].includes(String(m.status||''))&&new Date(m.kickoff_at).getTime()>Date.now();
    const root=modal("Modifier le match",`<div class="grid grid-2"><div class="field"><label>Domicile</label><select id="matchHomeV0910">${clubOptions(m.home_club?.id)}</select></div><div class="field"><label>Extérieur</label><select id="matchAwayV0910">${clubOptions(m.away_club?.id)}</select></div></div>
      <div class="grid grid-2"><div class="field"><label>Journée</label><select id="matchMdV0910">${mdOptions.join('')}</select></div><div class="field"><label>Date / heure</label><input id="matchKickoffV0910" type="datetime-local" value="${toLocalDateTimeInput(new Date(m.kickoff_at))}"></div></div>
      <div class="grid grid-2"><div class="field"><label>Stade</label><input id="matchStadiumV0910" value="${esc(m.stadium||'')}"></div><div class="field"><label>Pays du stade</label><input id="matchCountryV0910" value="${esc(m.venue_country||'')}"></div></div>
      <label class="notification-toggle"><span>Verrouiller cette correction manuelle face à Football-Data</span><input id="matchLockV0910" type="checkbox" checked></label>
      <div class="actions"><button id="saveMatchV0910" class="btn gold">Enregistrer le match</button>${m.manual_schedule_lock?'<button id="unlockMatchV0910" class="btn secondary">Rendre à nouveau modifiable par Football-Data</button>':''}</div>
      <hr class="admin-editor-separator-v0910">
      <section class="manual-odds-editor-v0910"><span class="eyebrow">Cotes 1N2 manuelles</span><h4>Saisie pré-match</h4><p class="muted">Utilisée si Football-Data ne fournit pas les cotes. Les trois valeurs sont obligatoires et doivent être supérieures à 1,00.</p>
        <div class="manual-odds-grid-v0910"><div class="field"><label>1 · Domicile</label><input id="oddsHomeV0910" type="number" min="1.01" step="0.01" value="${m.odds_home??''}" ${oddsEditable?'':'disabled'}></div><div class="field"><label>N · Nul</label><input id="oddsDrawV0910" type="number" min="1.01" step="0.01" value="${m.odds_draw??''}" ${oddsEditable?'':'disabled'}></div><div class="field"><label>2 · Extérieur</label><input id="oddsAwayV0910" type="number" min="1.01" step="0.01" value="${m.odds_away??''}" ${oddsEditable?'':'disabled'}></div></div>
        <div class="field"><label>Bookmaker / source (facultatif)</label><input id="oddsBookmakerV0910" value="${esc(m.odds_bookmaker||'')}" placeholder="Ex. Betclic, Winamax, saisie manuelle" ${oddsEditable?'':'disabled'}></div>
        <div class="actions"><button id="saveOddsV0910" class="btn" ${oddsEditable?'':'disabled'}>💶 Enregistrer les cotes</button><button id="clearOddsV0910" class="btn secondary" ${oddsEditable?'':'disabled'}>Effacer les cotes</button></div>${oddsEditable?'':'<p class="form-msg">🔒 Les cotes ne sont plus modifiables après le coup d’envoi.</p>'}
      </section><div id="matchEditorMsgV0910" class="form-msg"></div>`);
    $("#saveMatchV0910",root).onclick=async()=>{try{const kickoff=parseFrenchLocalInput($("#matchKickoffV0910",root).value);if(!kickoff)throw new Error("Date invalide.");const {error}=await sb.rpc("admin_update_match_schedule_v0910",{p_match_id:m.id,p_home_club_id:$("#matchHomeV0910",root).value,p_away_club_id:$("#matchAwayV0910",root).value,p_kickoff_at:kickoff,p_matchday_id:$("#matchMdV0910",root).value||null,p_stadium:$("#matchStadiumV0910",root).value.trim()||null,p_venue_country:$("#matchCountryV0910",root).value.trim()||null,p_lock_manual:$("#matchLockV0910",root).checked});if(error)throw error;root.innerHTML="";await loadData();await refreshCalendarHealthV0910();renderAll();toast("Match modifié et protégé.");}catch(err){setMsg("#matchEditorMsgV0910",friendlyError(err),"error");}};
    if($("#unlockMatchV0910",root))$("#unlockMatchV0910",root).onclick=async()=>{try{const {error}=await sb.rpc("admin_unlock_match_schedule_v0910",{p_match_id:m.id});if(error)throw error;root.innerHTML="";await loadData();renderAll();toast("Le match pourra de nouveau être mis à jour par Football-Data.");}catch(err){setMsg("#matchEditorMsgV0910",friendlyError(err),"error");}};
    const saveOdds=async clear=>{try{const home=Number($("#oddsHomeV0910",root)?.value),draw=Number($("#oddsDrawV0910",root)?.value),away=Number($("#oddsAwayV0910",root)?.value);const {error}=await sb.rpc("admin_update_match_odds_v0910",{p_match_id:m.id,p_odds_home:clear?null:home,p_odds_draw:clear?null:draw,p_odds_away:clear?null:away,p_bookmaker:clear?null:($("#oddsBookmakerV0910",root)?.value.trim()||null),p_clear:Boolean(clear)});if(error)throw error;root.innerHTML="";await loadData();await refreshCalendarHealthV0910();renderAll();toast(clear?"Cotes effacées.":"💶 Cotes 1N2 enregistrées manuellement.");}catch(err){setMsg("#matchEditorMsgV0910",friendlyError(err),"error");}};
    if($("#saveOddsV0910",root))$("#saveOddsV0910",root).onclick=()=>saveOdds(false);
    if($("#clearOddsV0910",root))$("#clearOddsV0910",root).onclick=()=>saveOdds(true);
  }

  async function openPrelaunchResetV0910(){
    try{
      const {data,error}=await sb.rpc("admin_prelaunch_reset_preview_v0910",{p_season_id:state.season.id});if(error)throw error;
      const root=modal("Reset avant ouverture",`<div class="prelaunch-warning"><b>⚠️ Nettoyage irréversible des données de recette</b><p>Les comptes, équipes, clubs et le calendrier réel sont conservés. Pronostics, choix champions, badges obtenus, records, événements de gamification et scénarios de répétition sont nettoyés.</p></div>
      <div class="calendar-health-grid"><span><b>${data.predictions||0}</b><small>pronos</small></span><span><b>${data.champion_picks||0}</b><small>favoris</small></span><span><b>${data.badges||0}</b><small>badges obtenus</small></span><span><b>${data.gamification_events||0}</b><small>événements</small></span><span><b>${data.test_matches||0}</b><small>matchs TEST</small></span><span><b>${data.preseason_runs||0}</b><small>répétitions</small></span></div>
      <div class="field"><label>Tape exactement <code>RESET AVANT OUVERTURE</code></label><input id="prelaunchConfirmV0910" autocomplete="off"></div><button id="runPrelaunchResetV0910" class="btn danger" ${data.allowed===false?'disabled':''}>Nettoyer avant ouverture</button><div id="prelaunchMsgV0910" class="form-msg">${data.allowed===false?'Reset bloqué : le premier coup d’envoi est déjà passé.':''}</div>`);
      $("#runPrelaunchResetV0910",root).onclick=async()=>{try{const confirmation=$("#prelaunchConfirmV0910",root).value;const {error:runError}=await sb.rpc("admin_prelaunch_reset_v0910",{p_season_id:state.season.id,p_confirmation:confirmation});if(runError)throw runError;root.innerHTML="";await loadData();await Promise.all([loadChampionData(),typeof loadGamificationData==='function'?loadGamificationData():Promise.resolve()]);renderAll();toast("🧹 Saison nettoyée avant ouverture.");}catch(err){setMsg("#prelaunchMsgV0910",friendlyError(err),"error");}};
    }catch(err){toast(friendlyError(err),"error");}
  }

  function bindPreprodSafetyV0910(){
    if($("#seedOfficialCalendarBtnV0910"))$("#seedOfficialCalendarBtnV0910").onclick=seedOfficialCalendarV0910;
    if($("#refreshCalendarHealthBtnV0910"))$("#refreshCalendarHealthBtnV0910").onclick=()=>refreshCalendarHealthV0910().catch(err=>toast(friendlyError(err),"error"));
    if($("#addClubBtnV0910"))$("#addClubBtnV0910").onclick=()=>openClubEditorV0910();
    if($("#editClubBtnV0910"))$("#editClubBtnV0910").onclick=openSelectedClubEditorV0910;
    if($("#prelaunchResetBtnV0910"))$("#prelaunchResetBtnV0910").onclick=openPrelaunchResetV0910;
  }

  Object.assign(window,{loadPreprodSafetyV0910,renderPreprodSafetyV0910,refreshCalendarHealthV0910,seedOfficialCalendarV0910,openClubEditorV0910,openMatchdayEditorV0910,openMatchScheduleEditorV0910,openPrelaunchResetV0910,bindPreprodSafetyV0910});
})();
