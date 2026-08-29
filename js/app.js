"use strict";

// Le Nid des Champions V0.9.10 — orchestration et démarrage
  async function boot() {
    bindStaticEvents();
    if ("serviceWorker" in navigator) navigator.serviceWorker.register("./sw.js").catch(()=>{});

    if (demoMode) {
      $("#configWarning").classList.remove("hidden");
      $("#configWarning").innerHTML = "<b>Mode démonstration.</b> Configure <code>config.js</code> et Supabase pour passer en réel.";
      $("#backendStatus span:last-child").textContent = "Démo locale";
      $("#demoBanner").classList.remove("hidden");
      $("#demoBanner").innerHTML = "🛠️ <b>V0.9.10 en mode démo :</b> phase de ligue, champions, phases finales et LIVE sont simulés localement quand les données sont disponibles.";
      demoInit();
      const demoSession = JSON.parse(localStorage.getItem("nidc_demo_session") || "null");
      if (demoSession) {
        state.user = {id:demoSession.id};
        state.profile = state.demoUsers.find(u=>u.id===demoSession.id) || state.demoUsers[0];
        await afterLogin();
      } else showAuth();
      return;
    }

    const {data:{session}} = await sb.auth.getSession();
    if (session) {
      state.user = session.user;
      await loadProfile();
      if (await guardAccountAccess()) await afterLogin();
    } else showAuth();

    sb.auth.onAuthStateChange(async (event, session) => {
      if (event === "PASSWORD_RECOVERY") return showPasswordReset();
      if (event === "SIGNED_OUT") { state.user=null; state.profile=null; showAuth(); }
      if (event === "SIGNED_IN" && session && !state.user && !registrationInProgress) {
        state.user = session.user;
        await loadProfile();
        if (await guardAccountAccess()) await afterLogin();
      }
    });
  }

  function bindStaticEvents() {
    $("#tabLogin").onclick = () => toggleAuthTab("login");
    $("#tabRegister").onclick = () => toggleAuthTab("register");
    $("#loginForm").onsubmit = login;
    $("#registerForm").onsubmit = register;
    $("#forgotBtn").onclick = forgotPassword;
    $("#helpPasswordBtn").onclick = passwordHelp;
    $("#logoutBtn").onclick = logout;
    if($("#profileLogoutBtn")) $("#profileLogoutBtn").onclick = logout;
    if($("#notificationBell")) $("#notificationBell").onclick = () => openNotificationCenter();
    $$('[data-view]').forEach(b => b.addEventListener("click", () => setView(b.dataset.view)));
    $$('[data-jump]').forEach(b => b.addEventListener("click", () => setView(b.dataset.jump)));
    $("#saveProfileBtn").onclick = saveProfile;
    $("#profileAdminBtn").onclick = () => setView("admin");
    $("#syncClubsBtn").onclick = () => syncFootballData("clubs");
    $("#syncClubCatalogBtn").onclick = () => syncFootballData("catalog");
    $("#syncCalendarBtn").onclick = () => syncFootballData("calendar");
    if($("#syncUclCenterBtn")) $("#syncUclCenterBtn").onclick = () => syncFootballData("center");
    $("#syncOddsBtn").onclick = syncOdds;
    $("#clubPreviewFilter").onchange = e => { state.clubPreviewFilter=e.target.value||"CL"; renderClubPreview(); };
    $("#createMatchdayBtn").onclick = createMatchday;
    $("#createMatchBtn").onclick = createMatch;
    $("#seedKnockoutBtn").onclick = seedKnockoutTest;
    $("#assignDefaultChampionBtn").onclick = assignDefaultChampion;
    $("#createKnockoutTieBtn").onclick = createKnockoutTie;
    $("#adminKoSingle").onchange = toggleKnockoutBuilderLeg2;
    $("#adminMdNumber").oninput = () => { const n=Number($("#adminMdNumber").value||1); $("#adminMdName").value=`Journée ${n}`; };
    $$('[data-ranking-scope]').forEach(btn => btn.onclick = () => setRankingScope(btn.dataset.rankingScope));
    $$('[data-team-ranking]').forEach(btn => btn.onclick = () => setTeamRankingMode(btn.dataset.teamRanking));
    if($("#createTeamBtn")) $("#createTeamBtn").onclick = () => openTeamEditor();
    if($("#joinByCodeBtn")) $("#joinByCodeBtn").onclick = openJoinCodeModal;
    if($("#teamSearchInput")) $("#teamSearchInput").oninput = () => renderTeamDirectory();
    if($("#teamVisibilityFilter")) $("#teamVisibilityFilter").onchange = () => renderTeamDirectory();
    if($("#adminTeamSearch")) $("#adminTeamSearch").oninput = () => renderAdminTeams();
    if(typeof bindPreprodSafetyV0910==="function") bindPreprodSafetyV0910();
  }

  function renderAll() {
    $("#seasonLabel").textContent=state.season?.name||"Saison";
    $("#seasonName").textContent=state.season?.name||"—";
    $("#seasonStatus").textContent=state.season?.status||"—";
    const isAdmin=["admin","super_admin"].includes(state.profile?.role);
    $("#adminNav").classList.toggle("hidden",!isAdmin);
    $("#profileAdminBtn").classList.toggle("hidden",!isAdmin);
    renderProfile(); if(typeof renderProfileCareerV090==="function")renderProfileCareerV090(); if(typeof renderAccountPrivacyV095==="function")renderAccountPrivacyV095(); renderChampions(); renderKnockout(); renderMatchdayTabs(); renderMatchPanels(); renderHistory(); renderRanking(); renderCollectiveStats(); renderLiveTicker(); renderSeason(); if(typeof renderSeasonMemory==="function")renderSeasonMemory(); if(typeof renderFinalSeasonHubV098==="function")renderFinalSeasonHubV098(); if(typeof renderOnboardingCardV099==="function")renderOnboardingCardV099(); if(typeof maybeOfferTutorialV099==="function")maybeOfferTutorialV099().catch(()=>{}); renderTeams(); renderHome(); if(typeof renderUclCenter==="function"&&state.uclCenterLoaded)renderUclCenter(); if(typeof renderEveningHub==="function"&&state.eveningLoadedDate)renderEveningHub(); if(typeof renderMuseum==="function")renderMuseum(); if(typeof renderHomeMuseumCard==="function")renderHomeMuseumCard(); if(typeof renderHomeNarrativeCard==="function")renderHomeNarrativeCard(); if(typeof renderHomeEveningCard==="function")renderHomeEveningCard(); renderNotificationBell(); renderNotificationPreferences(); renderHomePushPrompt(); renderOwlHome(); renderHomeRival(); renderRivalView(); if(isAdmin) renderAdmin(); if(isAdmin&&typeof renderAdminMonthlyPollPanel==="function") renderAdminMonthlyPollPanel(); if(isAdmin&&typeof renderAdminGeneralPollPanelV090==="function")renderAdminGeneralPollPanelV090(); if(isAdmin&&typeof renderAdminDistinctionPanelV090==="function")renderAdminDistinctionPanelV090(); if(isAdmin&&typeof renderAdminSeasonManagementV090==="function")renderAdminSeasonManagementV090(); if(isAdmin&&typeof renderAdminFinaleV098==="function")renderAdminFinaleV098(); if(isAdmin&&typeof renderAdminPreseasonV099==="function")renderAdminPreseasonV099(); if(isAdmin&&typeof renderPreprodSafetyV0910==="function"){loadPreprodSafetyV0910().then(()=>renderPreprodSafetyV0910()).catch(()=>{});renderPreprodSafetyV0910();} updateKpis(); if(typeof applyFeatureFlagsV095==="function")applyFeatureFlagsV095();
  }

  boot().catch(err=>{console.error(err);toast(friendlyError(err),"error");showAuth();});
