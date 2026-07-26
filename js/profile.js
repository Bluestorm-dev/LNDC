"use strict";

// Le Nid des Champions V0.5.5 — profil et éditeur avatar
  function renderProfile() {
    const heartName=state.profile?.club_heart||"";
    const heartClub=findClubByHeart(heartName);
    const username=state.profile?.username||"—";
    $("#profileUsername").textContent=username;
    $("#profileRole").textContent=state.profile?.role||"player";
    $("#profileClub").innerHTML=heartClub?`${crestHTML(heartClub)}<span>Club de cœur : ${esc(heartClub.name)}</span>`:`<span>Club de cœur : ${esc(heartName||"—")}</span>`;
    $("#profileUsernameInput").value=state.profile?.username||"";
    $("#profileClubInput").value=heartClub?.name||heartName;
    const options=$("#clubHeartOptions");
    if(options)options.innerHTML=state.clubs.map(c=>`<option value="${esc(c.name)}">${esc(c.short_name||c.tla||"")} · ${esc(clubCountry(c).name||"")}</option>`).join("");
    const avatarHost=$("#profileAvatar");
    if(avatarHost)avatarHost.innerHTML=avatarHTML({...state.profile,user_id:state.user?.id},{allowPending:true});
    const sideName=$("#sidebarUserName"),sideClub=$("#sidebarUserClub"),sideAvatar=$("#sidebarUserAvatar");
    if(sideName)sideName.textContent=username;
    if(sideClub)sideClub.textContent=`Club de cœur : ${heartClub?.short_name||heartClub?.name||heartName||"—"}`;
    if(sideAvatar){
      sideAvatar.innerHTML=avatarCoreHTML({...state.profile,user_id:state.user?.id});
      const team=teamForUser(state.user?.id);
      sideAvatar.classList.toggle("has-team",Boolean(team));
      if(team){sideAvatar.style.setProperty("--team-primary",safeTeamColor(team.primary_color));sideAvatar.style.setProperty("--team-secondary",safeTeamColor(team.secondary_color,"#7454ff"));}
    }
    renderAvatarEditor();
    renderProfileTeam();
  }

  function avatarStatusCopy(p=state.profile) {
    if(p?.avatar_source!=="upload") return "Avatar officiel du Nid.";
    if(p?.avatar_moderation_status==="pending") return "Upload reçu · en attente de validation par un Admin.";
    if(p?.avatar_moderation_status==="rejected") return `Upload refusé${p.avatar_rejection_reason?` · ${esc(p.avatar_rejection_reason)}`:""}. Ton avatar officiel reste affiché publiquement.`;
    return "Avatar personnel validé par un Admin.";
  }

  function renderAvatarPreviewOnly() {
    const stage=$("#avatarPreviewStage"),status=$("#avatarEditorStatus");
    if(stage)stage.innerHTML=avatarHTML({...state.avatarDraft||state.profile,user_id:state.user?.id},{allowPending:true});
    if(status)status.innerHTML=state.avatarDraft?.avatar_preview_url?"Aperçu local · rien n’est encore envoyé.":avatarStatusCopy(state.avatarDraft||state.profile);
  }

  function renderAvatarEditor() {
    const root=$("#avatarEditor");if(!root)return;
    const selected=normalizedAvatarKey(state.avatarDraft?.avatar_key||state.profile?.avatar_key);
    const groups=[...new Set(OFFICIAL_AVATARS.map(a=>a.c))];
    root.innerHTML=`<div class="avatar-editor-grid"><div class="avatar-picker-pane"><div class="avatar-editor-head"><div><span class="eyebrow">Bibliothèque officielle</span><h4>90 Hiboux du Nid</h4></div><span class="chip">PNG 512×512</span></div><div class="avatar-library">${groups.map(group=>`<section><h5>${esc(group)}</h5><div>${OFFICIAL_AVATARS.filter(a=>a.c===group).map(a=>`<button type="button" class="avatar-option ${a.k===selected?'active':''}" data-avatar-key="${esc(a.k)}" title="${esc(a.l)}"><img src="assets/avatars/nid/${esc(a.k)}.png" alt="" loading="lazy"><small>${esc(a.l)}</small></button>`).join('')}</div></section>`).join('')}</div></div><aside class="avatar-editor-side"><span class="eyebrow gold">Aperçu avec habillage Team</span><div id="avatarPreviewStage" class="avatar-preview-stage"></div><p id="avatarEditorStatus" class="muted avatar-status"></p><button id="useOfficialAvatarBtn" type="button" class="btn small">Utiliser l’avatar officiel sélectionné</button><div class="avatar-upload-box"><strong>Mon image</strong><p>PNG, JPG ou WebP · 3 Mo maximum. L’image sera affichée publiquement après validation Admin.</p><input id="avatarUploadInput" type="file" accept="image/png,image/jpeg,image/webp"><button id="uploadAvatarBtn" type="button" class="btn secondary small" ${state.avatarDraft?.avatar_file?"":"disabled"}>Envoyer pour modération</button></div></aside></div>`;
    $$('[data-avatar-key]',root).forEach(btn=>btn.onclick=()=>{state.avatarDraft={...state.profile,user_id:state.user?.id,avatar_source:"library",avatar_key:btn.dataset.avatarKey,avatar_storage_path:null,avatar_moderation_status:"approved",avatar_preview_url:null,avatar_file:null};renderAvatarEditor();});
    const useBtn=$("#useOfficialAvatarBtn",root);if(useBtn)useBtn.onclick=saveOfficialAvatar;
    const input=$("#avatarUploadInput",root),uploadBtn=$("#uploadAvatarBtn",root);
    if(input)input.onchange=()=>{
      const file=input.files?.[0];if(!file)return;
      if(!AVATAR_MIME_TYPES.has(file.type)){toast("Format refusé : PNG, JPG ou WebP uniquement.","error");input.value="";return;}
      if(file.size>AVATAR_MAX_BYTES){toast("Avatar trop lourd : 3 Mo maximum.","error");input.value="";return;}
      if(state.avatarDraft?.avatar_preview_url?.startsWith("blob:"))URL.revokeObjectURL(state.avatarDraft.avatar_preview_url);
      state.avatarDraft={...state.profile,user_id:state.user?.id,avatar_source:"upload",avatar_moderation_status:"pending",avatar_preview_url:URL.createObjectURL(file),avatar_file:file};
      uploadBtn.disabled=false;renderAvatarPreviewOnly();
    };
    if(uploadBtn)uploadBtn.onclick=uploadPlayerAvatar;
    renderAvatarPreviewOnly();
  }

  async function saveOfficialAvatar() {
    const key=normalizedAvatarKey(state.avatarDraft?.avatar_key||state.profile?.avatar_key);
    try{
      if(demoMode){Object.assign(state.profile,{avatar_source:"library",avatar_key:key,avatar_storage_path:null,avatar_moderation_status:"approved",avatar_rejection_reason:null});const i=state.demoUsers.findIndex(u=>u.id===state.user.id);if(i>=0)state.demoUsers[i]={...state.demoUsers[i],...state.profile};localStorage.setItem("nidc_demo_users",JSON.stringify(state.demoUsers));}
      else{const {error}=await sb.rpc("select_player_avatar_v053",{p_avatar_key:key});if(error)throw error;await loadProfile();}
      state.avatarDraft=null;await loadProfileDirectory();renderAll();toast("Avatar officiel appliqué.");
    }catch(err){toast(friendlyError(err),"error");}
  }

  async function uploadPlayerAvatar() {
    const file=state.avatarDraft?.avatar_file;if(!file)return;
    try{
      if(demoMode){Object.assign(state.profile,{avatar_source:"upload",avatar_storage_path:state.avatarDraft.avatar_preview_url,avatar_moderation_status:"pending",avatar_rejection_reason:null});const i=state.demoUsers.findIndex(u=>u.id===state.user.id);if(i>=0)state.demoUsers[i]={...state.demoUsers[i],...state.profile};localStorage.setItem("nidc_demo_users",JSON.stringify(state.demoUsers));}
      else{
        const ext=file.type==="image/png"?"png":file.type==="image/webp"?"webp":"jpg";
        const path=`${state.user.id}/${Date.now()}-${Math.random().toString(36).slice(2,9)}.${ext}`;
        const {error:upErr}=await sb.storage.from("player-avatars").upload(path,file,{cacheControl:"3600",upsert:false,contentType:file.type});if(upErr)throw upErr;
        const {error}=await sb.rpc("submit_player_avatar_v053",{p_storage_path:path});if(error)throw error;await loadProfile();
      }
      state.avatarDraft=null;await loadProfileDirectory();renderAll();toast("Avatar envoyé à la modération Admin.");
    }catch(err){toast(friendlyError(err),"error");}
  }
