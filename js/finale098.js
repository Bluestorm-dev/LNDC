"use strict";

// Le Nid des Champions V0.9.8 — fin de saison, PDF, diplôme, Livre d'or et archive.
(function(){
  state.final098=state.final098||{seasonId:null,loaded:false,loading:false,error:null,readiness:null,archive:null,guestbook:[]};
  const q=s=>$(s);
  const avatarPath=p=>typeof officialAvatarUrl==="function"?officialAvatarUrl(p?.avatar_key):`assets/avatars/nid/avatar-hibou-humour-personnages-chanceux.png`;
  const finalUrlV098=(mode="season",extra={})=>{const u=new URL("finale.html",location.href);u.searchParams.set("season",state.season?.slug||"");u.searchParams.set("mode",mode);Object.entries(extra).forEach(([k,v])=>{if(v!=null)u.searchParams.set(k,v)});return u.href;};
  const diplomaUrlV098=(extra={})=>{const u=new URL("diplome.html",location.href);u.searchParams.set("season",state.season?.slug||"");Object.entries(extra).forEach(([k,v])=>{if(v!=null)u.searchParams.set(k,v)});return u.href;};
  window.finalUrlV098=finalUrlV098;window.diplomaUrlV098=diplomaUrlV098;

  async function loadFinalSeasonDataV098(force=false){
    const f=state.final098;if(!state.season||f.loading)return;if(!force&&f.loaded&&f.seasonId===state.season.id)return;
    f.loading=true;f.error=null;f.seasonId=state.season.id;
    try{
      if(demoMode){f.readiness={ready:false,total_matches:(state.allMatches||[]).length,finished_matches:(state.allMatches||[]).filter(m=>m.status==="finished").length,unfinished_matches:(state.allMatches||[]).filter(m=>!["finished","cancelled"].includes(m.status)).length,players:(state.rankingRows||[]).length,guestbook_entries:0,reason:"Mode démonstration."};f.archive=null;f.guestbook=[];f.loaded=true;return;}
      const [r,a,g]=await Promise.all([
        sb.rpc("get_season_closeout_readiness_v098",{p_season_id:state.season.id}),
        sb.rpc("get_final_archive_meta_v098",{p_season_id:state.season.id}),
        sb.rpc("get_guestbook_v098",{p_season_id:state.season.id})
      ]);
      if(r.error)throw r.error;if(a.error)throw a.error;if(g.error)throw g.error;
      f.readiness=r.data||null;f.archive=a.data?.[0]||null;f.guestbook=g.data||[];f.loaded=true;
    }catch(err){f.error=friendlyError(err);console.warn("V0.9.8 finale",err);}finally{f.loading=false;renderFinalSeasonHubV098();if(isAdminProfile())renderAdminFinaleV098();}
  }
  window.loadFinalSeasonDataV098=loadFinalSeasonDataV098;

  function resetFinalSeasonDataV098(){state.final098={seasonId:state.season?.id||null,loaded:false,loading:false,error:null,readiness:null,archive:null,guestbook:[]};}
  window.resetFinalSeasonDataV098=resetFinalSeasonDataV098;

  function guestbookHTMLV098(){
    const f=state.final098,rows=f.guestbook||[],mine=rows.find(x=>x.is_mine),status=state.season?.status;
    const canWrite=["finished"].includes(status)||isAdminProfile();
    return `<article class="card card-pad guestbook-v098"><div class="section-title compact"><div><span class="eyebrow gold">Livre d’or</span><h3>Un mot pour la saison</h3><p>${status==="archived"?"Le Livre d’or est figé avec l’archive.":canWrite?"Chaque joueur peut laisser un message, modifiable jusqu’à l’archivage.":"Il ouvrira lorsque la saison sera terminée."}</p></div><span class="chip">${rows.filter(x=>x.status==="published").length}</span></div>
      ${canWrite&&status!=="archived"?`<div class="field"><label for="guestbookMessageV098">Ton message · 500 caractères max.</label><textarea id="guestbookMessageV098" maxlength="500" placeholder="Un souvenir, une casserole, une déclaration au Hibou…">${esc(mine?.message||"")}</textarea></div><div class="actions"><button id="saveGuestbookV098" class="btn gold small" type="button">✍ Enregistrer mon mot</button></div><div id="guestbookMsgV098" class="form-msg"></div>`:""}
      <div class="guestbook-list-v098">${rows.filter(x=>x.status==="published").length?rows.filter(x=>x.status==="published").map(x=>`<blockquote class="guestbook-note-v098"><header><img src="${esc(avatarPath(x))}" alt=""><span><strong>${esc(x.username)}</strong><time>${esc(fmtShortDate(x.updated_at||x.created_at))}</time></span></header><p>${esc(x.message)}</p></blockquote>`).join(""):'<div class="empty">Le Livre d’or attend ses premières plumes.</div>'}</div></article>`;
  }

  function renderFinalSeasonHubV098(){
    const root=q("#seasonFinaleRootV098");if(!root||!state.season)return;
    const f=state.final098;if(f.seasonId!==state.season.id){resetFinalSeasonDataV098();}
    if(!f.loaded&&!f.loading){loadFinalSeasonDataV098();}
    if(f.loading&&!f.loaded){root.innerHTML='<article class="card card-pad"><div class="empty">Préparation de la fin de saison…</div></article>';return;}
    const r=f.readiness||{},arch=f.archive;
    root.innerHTML=`<div class="final098-hub"><article class="card card-pad final098-hero"><div class="final098-title"><div><span class="eyebrow gold">V0.9.8 · Fin de saison</span><h3>Le carnet de cette aventure européenne</h3><p class="muted">Collector A4, carnet personnel, diplôme, Hall of Fame, Replay et Livre d’or réunis avant l’archivage.</p></div><span class="final098-status ${r.ready?'':'warn'}">${r.ready?'✓ Prête à archiver':'◷ Saison en cours'}</span></div>${f.error?`<div class="form-msg error">${esc(f.error)} · Exécute HOTFIX_V0.9.8_EXISTING_DB.sql si nécessaire.</div>`:""}<div class="final098-grid"><div class="final098-kpi"><small>Matchs terminés</small><b>${Number(r.finished_matches||0)}/${Number(r.total_matches||0)}</b></div><div class="final098-kpi"><small>Joueurs</small><b>${Number(r.players||0)}</b></div><div class="final098-kpi"><small>Livre d’or</small><b>${Number(r.guestbook_entries||0)}</b></div><div class="final098-kpi"><small>Archive finale</small><b>${arch?.is_final?'✓':'—'}</b></div></div><div class="final098-actions"><a class="btn gold small" href="${esc(finalUrlV098('season'))}" target="_blank" rel="noopener">📘 Collector saison</a><a class="btn secondary small" href="${esc(finalUrlV098('player',{player:state.user?.id||''}))}" target="_blank" rel="noopener">🦉 Mon carnet A4</a><a class="btn secondary small" href="${esc(diplomaUrlV098())}" target="_blank" rel="noopener">🏅 Mon diplôme</a></div></article>${guestbookHTMLV098()}</div>`;
    const save=q("#saveGuestbookV098");if(save)save.onclick=saveGuestbookV098;
  }
  window.renderFinalSeasonHubV098=renderFinalSeasonHubV098;

  async function saveGuestbookV098(){const msg=q("#guestbookMessageV098")?.value||"";setMsg("#guestbookMsgV098","Enregistrement…");try{if(demoMode){setMsg("#guestbookMsgV098","Mode démo : message simulé.","ok");return;}const {error}=await sb.rpc("save_guestbook_entry_v098",{p_season_id:state.season.id,p_message:msg});if(error)throw error;await loadFinalSeasonDataV098(true);setMsg("#guestbookMsgV098","Mot enregistré dans le Livre d’or.","ok");}catch(err){setMsg("#guestbookMsgV098",friendlyError(err),"error");}}

  function renderAdminFinaleV098(){
    const root=q("#adminFinalSeasonPanelV098");if(!root||!isAdminProfile()||!state.season)return;
    const f=state.final098;if(f.seasonId!==state.season.id||!f.loaded){if(!f.loading)loadFinalSeasonDataV098();root.innerHTML='<div class="empty">Chargement de la clôture…</div>';return;}
    const r=f.readiness||{},a=f.archive,superAdmin=state.profile?.role==="super_admin";
    root.innerHTML=`<div class="section-title compact"><div><span class="eyebrow gold">Fin de saison · V0.9.8</span><h3>Clôture, PDF & archive</h3><p>Prépare les documents avant la dernière journée puis fige définitivement la saison quand tout est terminé.</p></div><span class="chip">${r.ready?'PRÊTE':'À CONTRÔLER'}</span></div><div class="admin-final098-grid"><div><div class="admin-final098-readiness"><span><small>Officiels</small><b>${Number(r.finished_matches||0)}/${Number(r.total_matches||0)}</b></span><span><small>À terminer</small><b>${Number(r.unfinished_matches||0)}</b></span><span><small>Joueurs</small><b>${Number(r.players||0)}</b></span></div><p class="muted">${esc(r.reason||'—')}</p><div class="actions"><a class="btn secondary small" target="_blank" rel="noopener" href="${esc(finalUrlV098('season'))}">📘 Prévisualiser le collector</a><a class="btn secondary small" target="_blank" rel="noopener" href="${esc(diplomaUrlV098({all:1}))}">🏅 Diplômes joueurs</a><button id="adminExportFinalV098" class="btn secondary small" type="button">⇩ Export global JSON</button></div>${superAdmin?`<div class="actions" style="margin-top:10px"><button id="adminBuildArchiveV098" class="btn small" type="button">📦 Construire l’archive</button><button id="adminArchiveSeasonV098" class="btn danger small" type="button" ${r.ready?'':'disabled'}>🔒 Archiver définitivement</button></div>`:""}<div id="adminFinalMsgV098" class="form-msg"></div>${a?`<p class="admin-final098-log">Archive ${a.is_final?'finale':'préparatoire'} · ${esc(a.snapshot_hash||'')} · ${esc(fmtDate(a.updated_at||a.created_at))}</p>`:''}</div><div><h4>Modération du Livre d’or</h4><div class="admin-guestbook-v098">${(f.guestbook||[]).length?(f.guestbook||[]).map(x=>`<div><span><strong>${esc(x.username)}</strong><p>${esc(x.message)}</p><small>${esc(x.status)}</small></span><button class="btn secondary small" data-guestbook-toggle-v098="${x.id}" data-status="${x.status==='published'?'hidden':'published'}">${x.status==='published'?'Masquer':'Publier'}</button></div>`).join(''):'<div class="empty">Aucun message.</div>'}</div></div></div>`;
    q("#adminExportFinalV098")?.addEventListener("click",exportFinalV098);q("#adminBuildArchiveV098")?.addEventListener("click",buildArchiveV098);q("#adminArchiveSeasonV098")?.addEventListener("click",archiveSeasonV098);$$('[data-guestbook-toggle-v098]',root).forEach(b=>b.onclick=()=>moderateGuestbookV098(b.dataset.guestbookToggleV098,b.dataset.status));
  }
  window.renderAdminFinaleV098=renderAdminFinaleV098;

  async function exportFinalV098(){setMsg("#adminFinalMsgV098","Préparation de l’export…");try{const {data,error}=await sb.rpc("get_final_season_report_v098",{p_season_id:state.season.id});if(error)throw error;const blob=new Blob([JSON.stringify(data,null,2)+"\n"],{type:"application/json;charset=utf-8"});const a=document.createElement("a");a.href=URL.createObjectURL(blob);a.download=`nid-final-${state.season.slug}-v0.9.8.json`;a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1000);setMsg("#adminFinalMsgV098","Export global généré.","ok");}catch(err){setMsg("#adminFinalMsgV098",friendlyError(err),"error");}}
  async function buildArchiveV098(){if(state.profile?.role!=="super_admin")return;setMsg("#adminFinalMsgV098","Construction de l’archive…");try{const {error}=await sb.rpc("admin_create_final_archive_v098",{p_season_id:state.season.id,p_force:true});if(error)throw error;await loadFinalSeasonDataV098(true);setMsg("#adminFinalMsgV098","Archive préparatoire mise à jour.","ok");}catch(err){setMsg("#adminFinalMsgV098",friendlyError(err),"error");}}
  async function archiveSeasonV098(){if(state.profile?.role!=="super_admin")return;const c=prompt("Cette action fige la saison. Tape ARCHIVER pour confirmer.","");if(c!=="ARCHIVER")return;setMsg("#adminFinalMsgV098","Archivage définitif…");try{const {error}=await sb.rpc("admin_archive_season_v098",{p_season_id:state.season.id,p_confirmation:"ARCHIVER"});if(error)throw error;state.selectedSeasonSlug=state.season.slug;resetSeasonBoundStateV090();resetFinalSeasonDataV098();await loadData();await loadSeasonMemoryData(true);renderAll();toast("🔒 Saison archivée. Le collector est figé.");}catch(err){setMsg("#adminFinalMsgV098",friendlyError(err),"error");}}
  async function moderateGuestbookV098(id,status){try{const {error}=await sb.rpc("admin_set_guestbook_status_v098",{p_entry_id:id,p_status:status});if(error)throw error;await loadFinalSeasonDataV098(true);toast(status==="hidden"?"Message masqué.":"Message republié.");}catch(err){toast(friendlyError(err),"error");}}
})();
