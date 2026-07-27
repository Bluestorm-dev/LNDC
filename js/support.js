"use strict";

// Le Nid des Champions V0.6.4 — tickets privés au Hibou
window.__nidcErrors = window.__nidcErrors || [];
window.addEventListener("error",e=>{window.__nidcErrors.push({at:new Date().toISOString(),message:String(e.message||"Erreur JS"),source:e.filename||null,line:e.lineno||null});window.__nidcErrors=window.__nidcErrors.slice(-10);});
window.addEventListener("unhandledrejection",e=>{window.__nidcErrors.push({at:new Date().toISOString(),message:String(e.reason?.message||e.reason||"Promise rejetée")});window.__nidcErrors=window.__nidcErrors.slice(-10);});

function technicalTicketContext(){
  const visible=$$(".view").find(v=>!v.classList.contains("hidden"));
  return {app_version:CFG.APP_VERSION||"0.6.4",user_agent:navigator.userAgent,platform:navigator.userAgentData?.platform||navigator.platform||null,mobile:/Mobi|Android/i.test(navigator.userAgent),screen:`${window.innerWidth}x${window.innerHeight}`,view:visible?.id?.replace("view-","")||"unknown",timezone:Intl.DateTimeFormat().resolvedOptions().timeZone||null,at:new Date().toISOString(),recent_errors:(window.__nidcErrors||[]).slice(-5)};
}

function demoTickets(){return JSON.parse(localStorage.getItem("nidc_demo_support_tickets")||"[]");}
function demoTicketMessages(){return JSON.parse(localStorage.getItem("nidc_demo_support_messages")||"[]");}

async function loadSupportData(){
  if(!state.user)return;
  if(demoMode){state.supportTickets=demoTickets().filter(t=>t.user_id===state.user.id);if(state.profile?.role==="super_admin")state.adminSupportTickets=demoTickets();return;}
  const {data,error}=await sb.from("support_tickets").select("*").eq("user_id",state.user.id).order("created_at",{ascending:false});if(error)throw new Error("Migration tickets V0.6.2 absente : exécute sql/HOTFIX_V0.6.2_EXISTING_DB.sql.");state.supportTickets=data||[];
  if(state.profile?.role==="super_admin"){const {data:all,error:aErr}=await sb.from("support_tickets").select("*").order("created_at",{ascending:false}).limit(300);if(aErr)throw aErr;state.adminSupportTickets=all||[];}
}

function supportStatusLabel(s){return ({received:"Reçu",read:"Lu",in_progress:"En cours",fixed:"Corrigé",resolved:"Résolu",closed:"Clos",rejected:"Rejeté"}[s]||s);}
function supportTypeLabel(t){return ({bug:"Bug",suggestion:"Suggestion",question:"Question",modification:"Demande de modification",other:"Autre"}[t]||t);}

function openSupportCenter(){
  const rows=state.supportTickets||[];const root=modal("🦉 Écrire au Hibou",`<div class="support-center"><div class="support-center-actions"><button id="newSupportTicketBtn" class="btn gold small">Nouveau ticket</button></div><div id="supportTicketList" class="support-ticket-list"></div></div>`);
  $("#newSupportTicketBtn",root).onclick=openNewSupportTicket;const list=$("#supportTicketList",root);list.innerHTML=rows.length?rows.map(t=>`<button class="support-ticket-row" type="button" data-ticket-open="${t.id}"><span class="support-priority ${esc(t.priority)}"></span><span><small>${esc(supportTypeLabel(t.ticket_type))} · ${esc(fmtDate(t.created_at))}</small><strong>${esc(t.subject)}</strong><em>${esc(supportStatusLabel(t.status))}</em></span></button>`).join(''):'<div class="empty">Aucune conversation. Le Hibou profite de ce répit.</div>';$$('[data-ticket-open]',list).forEach(b=>b.onclick=()=>openSupportTicket(b.dataset.ticketOpen));
}

function openNewSupportTicket(){
  const root=modal("Nouveau message au Hibou",`<form id="newSupportTicketForm"><div class="field"><label>Type</label><select id="supportType"><option value="bug">Bug</option><option value="suggestion">Suggestion</option><option value="question">Question</option><option value="modification">Demande de modification</option><option value="other">Autre</option></select></div><div class="field"><label>Sujet</label><input id="supportSubject" maxlength="160" required placeholder="En quelques mots…"></div><div class="field"><label>Message</label><textarea id="supportMessage" rows="6" required placeholder="Explique ce qui se passe…"></textarea></div><div class="support-captures-box"><strong>Captures d’écran</strong><p class="muted">PNG, JPG ou WebP · 3 maximum · 5 Mo par image.</p><input id="supportFiles" type="file" multiple accept="image/png,image/jpeg,image/webp"><div id="supportFilePreview" class="support-file-preview"></div></div><div class="actions"><button class="btn" type="submit">Envoyer au Hibou</button></div><div id="supportCreateMsg" class="form-msg"></div></form>`);
  $("#supportFiles",root).onchange=()=>previewSupportFiles($("#supportFiles",root));$("#newSupportTicketForm",root).onsubmit=createSupportTicket;
}

function validateSupportFiles(input){const files=[...(input?.files||[])];if(files.length>3)throw new Error("3 captures maximum.");for(const f of files){if(!["image/png","image/jpeg","image/webp"].includes(f.type))throw new Error("Captures : PNG, JPG ou WebP uniquement.");if(f.size>5*1024*1024)throw new Error(`${f.name} dépasse 5 Mo.`);}return files;}
function previewSupportFiles(input){const box=$("#supportFilePreview");try{const files=validateSupportFiles(input);box.innerHTML=files.map(f=>`<span>📎 ${esc(f.name)} · ${(f.size/1024/1024).toFixed(1)} Mo</span>`).join('');}catch(err){input.value="";box.innerHTML=`<span class="error">${esc(friendlyError(err))}</span>`;}}

async function createSupportTicket(e){
  e.preventDefault();const type=$("#supportType").value,subject=$("#supportSubject").value.trim(),message=$("#supportMessage").value.trim();let files=[];try{files=validateSupportFiles($("#supportFiles"));if(subject.length<3||!message)throw new Error("Sujet et message sont obligatoires.");setMsg("#supportCreateMsg","Envoi au Hibou…");let ticketId;
    if(demoMode){ticketId=`ticket-${Date.now()}`;const tickets=demoTickets();tickets.unshift({id:ticketId,user_id:state.user.id,season_id:state.season?.id,ticket_type:type,subject,status:"received",priority:"normal",technical_context:technicalTicketContext(),created_at:new Date().toISOString(),updated_at:new Date().toISOString()});localStorage.setItem("nidc_demo_support_tickets",JSON.stringify(tickets));const msgs=demoTicketMessages();msgs.push({id:`msg-${Date.now()}`,ticket_id:ticketId,author_id:state.user.id,author_kind:"player",body:message,created_at:new Date().toISOString()});localStorage.setItem("nidc_demo_support_messages",JSON.stringify(msgs));}
    else{const {data,error}=await sb.rpc("create_support_ticket_v060",{p_season_id:state.season?.id||null,p_type:type,p_subject:subject,p_message:message,p_technical_context:technicalTicketContext()});if(error)throw error;ticketId=data;for(const f of files)await uploadSupportCapture(ticketId,f);}
    await loadSupportData();toast("🦉 Message envoyé au Hibou.");openSupportTicket(ticketId);
  }catch(err){setMsg("#supportCreateMsg",friendlyError(err),"error");}
}

async function uploadSupportCapture(ticketId,file){
  const ext=file.type==="image/png"?"png":file.type==="image/webp"?"webp":"jpg";const path=`${state.user.id}/${ticketId}/${Date.now()}-${Math.random().toString(36).slice(2,8)}.${ext}`;
  const {error:upErr}=await sb.storage.from("support-captures").upload(path,file,{contentType:file.type,cacheControl:"3600",upsert:false});if(upErr)throw upErr;
  const {error}=await sb.from("support_ticket_attachments").insert({ticket_id:ticketId,user_id:state.user.id,storage_path:path,mime_type:file.type,size_bytes:file.size});if(error)throw error;
}

async function fetchSupportConversation(ticketId){
  if(demoMode){return {messages:demoTicketMessages().filter(m=>m.ticket_id===ticketId),attachments:[]};}
  const [{data:messages,error:mErr},{data:atts,error:aErr}]=await Promise.all([sb.from("support_ticket_messages").select("*").eq("ticket_id",ticketId).order("created_at"),sb.from("support_ticket_attachments").select("*").eq("ticket_id",ticketId).order("created_at")]);if(mErr||aErr)throw mErr||aErr;const attachments=atts||[];if(attachments.length){const {data:signed}=await sb.storage.from("support-captures").createSignedUrls(attachments.map(a=>a.storage_path),3600);const map=new Map((signed||[]).map(x=>[x.path,x.signedUrl]));attachments.forEach(a=>a.signed_url=map.get(a.storage_path));}return {messages:messages||[],attachments};
}

async function openSupportTicket(ticketId){
  const ticket=(state.supportTickets||[]).find(t=>String(t.id)===String(ticketId))||(state.adminSupportTickets||[]).find(t=>String(t.id)===String(ticketId));if(!ticket)return toast("Ticket introuvable.","error");
  try{const convo=await fetchSupportConversation(ticketId);const root=modal(ticket.subject,`<div class="support-thread-head"><span class="chip">${esc(supportTypeLabel(ticket.ticket_type))}</span><span class="chip">${esc(supportStatusLabel(ticket.status))}</span><span class="chip priority-${esc(ticket.priority)}">${esc(ticket.priority)}</span></div><div class="support-thread">${convo.messages.map(m=>`<article class="support-message ${m.author_kind}"><strong>${m.author_kind==='owl'?'🦉 Hibou masqué':esc(state.profileDirectory.get(String(m.author_id))?.username||'Joueur')}</strong><p>${esc(m.body).replace(/\n/g,'<br>')}</p><small>${esc(fmtDate(m.created_at))}</small></article>`).join('')}</div>${convo.attachments.length?`<div class="support-attachments"><strong>Captures</strong>${convo.attachments.map(a=>`<a href="${esc(a.signed_url||'#')}" target="_blank" rel="noopener">📎 Capture · ${(a.size_bytes/1024/1024).toFixed(1)} Mo</a>`).join('')}</div>`:''}<form id="supportReplyForm"><div class="field"><label>Répondre</label><textarea id="supportReplyBody" rows="4" required></textarea></div><div class="actions"><button class="btn small" type="submit">Envoyer</button>${ticket.user_id===state.user.id&&!['closed','rejected','resolved'].includes(ticket.status)?`<button id="resolveSupportTicketBtn" class="btn secondary small" type="button">Marquer comme résolu</button>`:''}</div><div id="supportReplyMsg" class="form-msg"></div></form>${ticket.ticket_type==='bug'?`<details class="technical-ticket"><summary>Informations techniques</summary><pre>${esc(JSON.stringify(ticket.technical_context||{},null,2))}</pre></details>`:''}`);
    $("#supportReplyForm",root).onsubmit=e=>replySupportTicket(e,ticketId);if($("#resolveSupportTicketBtn",root))$("#resolveSupportTicketBtn",root).onclick=()=>resolveSupportTicket(ticketId);
  }catch(err){toast(friendlyError(err),"error");}
}

async function replySupportTicket(e,ticketId){e.preventDefault();const body=$("#supportReplyBody").value.trim();if(!body)return;setMsg("#supportReplyMsg","Envoi…");try{if(demoMode){const msgs=demoTicketMessages();msgs.push({id:`msg-${Date.now()}`,ticket_id:ticketId,author_id:state.user.id,author_kind:state.profile?.role==='super_admin'?'owl':'player',body,created_at:new Date().toISOString()});localStorage.setItem("nidc_demo_support_messages",JSON.stringify(msgs));}else{const {error}=await sb.rpc("reply_support_ticket_v060",{p_ticket_id:ticketId,p_body:body});if(error)throw error;}await Promise.all([loadSupportData(),loadNotificationData()]);openSupportTicket(ticketId);renderNotificationBell();}catch(err){setMsg("#supportReplyMsg",friendlyError(err),"error");}}
async function resolveSupportTicket(ticketId){try{if(demoMode){const rows=demoTickets().map(t=>t.id===ticketId?{...t,status:"resolved",resolved_by_user_at:new Date().toISOString()}:t);localStorage.setItem("nidc_demo_support_tickets",JSON.stringify(rows));}else{const {error}=await sb.rpc("resolve_my_support_ticket_v060",{p_ticket_id:ticketId});if(error)throw error;}await loadSupportData();toast("Ticket marqué comme résolu.");openSupportCenter();}catch(err){toast(friendlyError(err),"error");}}

function renderAdminSupport(){
  const root=$("#adminSupportPanel");if(!root)return;if(state.profile?.role!=="super_admin"){root.innerHTML='<div class="empty">Les tickets au Hibou sont privés et réservés au Super Admin.</div>';return;}
  const rows=state.adminSupportTickets||[];root.innerHTML=`<div class="support-admin-filters"><span class="chip">${rows.filter(t=>!['closed','rejected','resolved'].includes(t.status)).length} ouvert(s)</span></div><div class="support-admin-list">${rows.length?rows.map(t=>{const p=state.profileDirectory.get(String(t.user_id));return `<div class="support-admin-row" data-admin-ticket="${t.id}"><span class="support-priority ${esc(t.priority)}"></span><div><small>${esc(supportTypeLabel(t.ticket_type))} · ${esc(p?.username||'Joueur')} · ${esc(fmtDate(t.created_at))}</small><strong>${esc(t.subject)}</strong><span>${esc(supportStatusLabel(t.status))}</span></div><div class="actions"><button class="btn secondary small" data-ticket-read>Ouvrir</button><select data-ticket-priority><option value="normal">Normal</option><option value="important">Important</option><option value="urgent">Urgent</option></select><select data-ticket-status>${['received','read','in_progress','fixed','resolved','closed','rejected'].map(s=>`<option value="${s}">${supportStatusLabel(s)}</option>`).join('')}</select><button class="btn small" data-ticket-save>Enregistrer</button></div></div>`;}).join(''):'<div class="empty">Aucun ticket.</div>'}</div>`;
  $$('[data-admin-ticket]',root).forEach(row=>{const id=row.dataset.adminTicket,t=rows.find(x=>String(x.id)===String(id));$("[data-ticket-priority]",row).value=t.priority;$("[data-ticket-status]",row).value=t.status;$("[data-ticket-read]",row).onclick=()=>openSupportTicket(id);$("[data-ticket-save]",row).onclick=()=>adminSaveSupportTicket(row,id);});
}
async function adminSaveSupportTicket(row,id){try{const status=$("[data-ticket-status]",row).value,priority=$("[data-ticket-priority]",row).value;if(demoMode){const rows=demoTickets().map(t=>t.id===id?{...t,status,priority}:t);localStorage.setItem("nidc_demo_support_tickets",JSON.stringify(rows));}else{const {error}=await sb.rpc("admin_update_support_ticket_v060",{p_ticket_id:id,p_status:status,p_priority:priority});if(error)throw error;}await loadSupportData();renderAdminSupport();toast("Ticket mis à jour.");}catch(err){toast(friendlyError(err),"error");}}
