"use strict";

// Le Nid des Champions V0.6.4 — authentification et accès
  function toggleAuthTab(which) {
    const loginTab = which === "login";
    $("#loginForm").classList.toggle("hidden", !loginTab);
    $("#registerForm").classList.toggle("hidden", loginTab);
    $("#tabLogin").classList.toggle("active", loginTab);
    $("#tabRegister").classList.toggle("active", !loginTab);
  }

  async function login(e) {
    e.preventDefault();
    setMsg("#loginMsg", "Connexion…");
    const username = $("#loginUsername").value.trim();
    const password = $("#loginPassword").value;
    try {
      if (demoMode) {
        let p = state.demoUsers.find(u => u.username.toLowerCase() === username.toLowerCase());
        if (!p) {
          p = {id:`demo-${Date.now()}`, username:username||"NouveauHibou", role:"player", status:"active", club_heart:"", avatar_key:"owl"};
          state.demoUsers.push(p);
          localStorage.setItem("nidc_demo_users", JSON.stringify(state.demoUsers));
        }
        state.user={id:p.id}; state.profile=p;
        localStorage.setItem("nidc_demo_session", JSON.stringify({id:p.id}));
        setMsg("#loginMsg", "Bienvenue dans le Nid.", "ok");
        await afterLogin();
        return;
      }
      const {data,error} = await sb.functions.invoke("login-by-username", {body:{username,password}});
      if (error) throw new Error("Le service de connexion du Nid est indisponible. Vérifie que login-by-username est bien déployée avec verify_jwt=false.");
      if (!data?.ok) {
        if (data?.code === "pending") throw new Error("🦉 Ta demande attend encore l'autorisation du Super Admin.");
        if (data?.code === "rejected") throw new Error("Ta demande d'inscription n'a pas été acceptée par le Hibou.");
        if (data?.code === "suspended") throw new Error("Ton compte est actuellement suspendu.");
        throw new Error(data?.error || "Pseudo ou mot de passe incorrect.");
      }
      if (!data?.access_token || !data?.refresh_token) throw new Error("Connexion impossible.");
      const {error:setErr} = await sb.auth.setSession({access_token:data.access_token,refresh_token:data.refresh_token});
      if (setErr) throw setErr;
      state.user = (await sb.auth.getUser()).data.user;
      await loadProfile();
      await afterLogin();
    } catch (err) { setMsg("#loginMsg", friendlyError(err), "error"); }
  }

  async function register(e) {
    e.preventDefault();
    setMsg("#registerMsg", "Création de la demande…");
    const username=$("#regUsername").value.trim(), first_name=$("#regFirstName").value.trim(), email=$("#regEmail").value.trim(), password=$("#regPassword").value;
    try {
      if (!/^[\p{L}\p{N}_. -]{2,24}$/u.test(username)) throw new Error("Pseudo invalide (2 à 24 caractères).");
      if (demoMode) {
        if (state.demoUsers.some(u=>u.username.toLowerCase()===username.toLowerCase())) throw new Error("Ce pseudo est déjà pris.");
        const p={id:`demo-${Date.now()}`,username,role:"player",status:"active",club_heart:"",avatar_key:"owl"};
        state.demoUsers.push(p); localStorage.setItem("nidc_demo_users",JSON.stringify(state.demoUsers));
        setMsg("#registerMsg","Compte de démonstration créé. Tu peux te connecter.","ok");
        toggleAuthTab("login"); $("#loginUsername").value=username; return;
      }
      const {data:available,error:aerr}=await sb.rpc("is_username_available",{p_username:username});
      if(aerr) throw aerr;
      if(!available) throw new Error("Ce pseudo est déjà pris.");
      registrationInProgress=true;
      const {data,error}=await sb.auth.signUp({email,password,options:{data:{username,first_name}}});
      if(error) throw error;
      if(data.session) await sb.auth.signOut();
      setMsg("#registerMsg","🦉 Demande créée. Le Super Admin doit maintenant ouvrir la porte du Nid.","ok");
      $("#registerForm").reset(); toggleAuthTab("login"); $("#loginUsername").value=username;
    } catch(err) { setMsg("#registerMsg",friendlyError(err),"error"); }
    finally { registrationInProgress=false; }
  }

  function forgotPassword() {
    const root = modal("Mot de passe oublié", `<p class="muted">Indique l'adresse e-mail réelle utilisée à l'inscription.</p><div class="field"><label>E-mail</label><input id="forgotEmail" type="email" /></div><button id="sendReset" class="btn">Envoyer le lien</button><div id="forgotMsg" class="form-msg"></div>`);
    $("#sendReset",root).onclick = async () => {
      const email=$("#forgotEmail",root).value.trim();
      if(demoMode){$("#forgotMsg",root).textContent="Mode démo : aucun e-mail envoyé.";return;}
      const {error}=await sb.auth.resetPasswordForEmail(email,{redirectTo:location.href.split("#")[0]});
      $("#forgotMsg",root).textContent=error?friendlyError(error):"Lien envoyé si cette adresse existe.";
    };
  }

  function passwordHelp() {
    const root=modal("Demander au Hibou",`<p class="muted">Le Super Admin retrouvera la demande dans l'administration.</p><div class="field"><label>Pseudo</label><input id="helpUsername" /></div><div class="field"><label>E-mail de contact</label><input id="helpEmail" type="email" /></div><div class="field"><label>Message</label><textarea id="helpMessage" rows="3"></textarea></div><button id="sendHelp" class="btn gold">Envoyer au Hibou</button><div id="helpMsg" class="form-msg"></div>`);
    $("#sendHelp",root).onclick=async()=>{
      const payload={p_username:$("#helpUsername",root).value.trim(),p_contact_email:$("#helpEmail",root).value.trim(),p_message:$("#helpMessage",root).value.trim()};
      if(demoMode){$("#helpMsg",root).textContent="🦉 Le Hibou de démonstration a pris note.";return;}
      const {error}=await sb.rpc("request_password_help",payload);
      $("#helpMsg",root).textContent=error?friendlyError(error):"🦉 Demande envoyée au Hibou masqué.";
    };
  }

  function showPasswordReset() {
    const root=modal("Choisir un nouveau mot de passe",`<div class="field"><label>Nouveau mot de passe</label><input id="newPassword" type="password" minlength="8" /></div><button id="saveNewPassword" class="btn">Enregistrer</button><div id="newPasswordMsg" class="form-msg"></div>`);
    $("#saveNewPassword",root).onclick=async()=>{
      const {error}=await sb.auth.updateUser({password:$("#newPassword",root).value});
      $("#newPasswordMsg",root).textContent=error?friendlyError(error):"Mot de passe modifié.";
    };
  }

  async function logout() {
    if(demoMode){localStorage.removeItem("nidc_demo_session");state.user=null;state.profile=null;showAuth();return;}
    await sb.auth.signOut();
  }

  async function loadProfile() {
    const {data,error}=await sb.from("profiles").select("id,username,avatar_key,avatar_source,avatar_storage_path,avatar_moderation_status,avatar_rejection_reason,avatar_updated_at,club_heart,role,status").eq("id",state.user.id).single();
    if(error) throw error;
    state.profile=data;
  }

  async function guardAccountAccess() {
    if(!state.profile) return false;
    if(state.profile.status === "active") return true;
    const msg=state.profile.status==="pending"?"🦉 Ta demande attend encore l'autorisation du Super Admin.":state.profile.status==="rejected"?"Ta demande d'inscription n'a pas été acceptée.":"Ce compte n'est pas autorisé à entrer dans le Nid.";
    await sb.auth.signOut(); state.user=null; state.profile=null; showAuth(); toggleAuthTab("login"); setMsg("#loginMsg",msg,"error"); return false;
  }

  async function afterLogin() {
    showApp();
    await loadData();
    if(typeof loadGamificationData==="function")await loadGamificationData();
    if(typeof loadAdminGamificationData==="function"&&state.profile?.role==="super_admin")await loadAdminGamificationData();
    if(typeof loadSeasonMemoryData==="function")await loadSeasonMemoryData(true);
    renderAll();
    setView("home");
    setupRealtime();
    if(typeof consumePendingDeepLink==="function") consumePendingDeepLink();
  }
